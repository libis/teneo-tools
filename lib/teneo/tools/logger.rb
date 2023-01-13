# frozen_string_literal: true

require "logging"
require "amazing_print"

module Teneo
  module Tools
    # LOG_LEVELS = [:trace, :debug, :info, :warn, :error, :fatal]
    # Logging.init(LOG_LEVELS)
    ::Logging.init
    ::Logging.format_as "inspect"

    # This module adds logging functionality to any class.
    #
    # Just include the Teneo::Tools::Logger module and the methods debug, info, warn, error and fatal will be
    # available to the class instance. Each method takes a message argument and optional extra parameters.
    #
    # It is possible to overwrite the {#logger} method with your own implementation to use
    # a different logger for your class.
    #
    # The methods all call the {#message} method with the logging level as first argument
    # and the supplied arguments appended.
    #
    # Example:
    #
    #     require 'teneo/logger'
    #     class TestClass
    #       include Teneo::Tools::Logger
    #     end
    #     tc = TestClass.new
    #     tc.add_appender io: $stdout, level: :debug
    #     tc.add_appender io: $stderr, level: :error
    #     tc.debug 'message'
    #     tc.warn 'message'
    #     tc.error 'huge error: [%d] %s', 1000, 'Exit'
    #     tc.info 'Running application: %s', t.class.name
    #
    # produces:
    #     on stdout:
    #     ... D [...] TestClass-132456 -- message
    #     ... W [...] TestClass-132456 -- message
    #     ... E [...] TestClass-132456 -- huge error: [1000] Exit
    #     ... I [...] TestClass-132456 -- Running application TestLogger
    #     on stderr:
    #     ... E [...] TestClass-132456 -- huge error: [1000] Exit
    #

    module Logger
      Event = Struct.new(:message, :context, :payload, :exception, :duration, keyword_init: true) do
        BACKTRACE_SPLIT = "\n\t -- "

        def log_info
          context_info = "-- #{context}" if context && !context.to_s.blank?
          duration_info = format("(%0.1f ms)", duration) if duration && duration.is_a?(Numeric)
          msg_list = [":"]
          msg_list << "#{payload.to_s} ;" if payload
          msg_list << "#{message}"
          msg_list << "# Exception: #{exception.class.name} - #{exception.to_s}" if exception
          msg_info = msg_list.compact.join " "
          msg += BACKTRACE_SPLIT + exception.backtrace.join(BACKTRACE_SPLIT) if exception&.backtrace
          [context_info, duration_info, msg_info].compact.join " "
        rescue => e
          ap e
          ap e.backtrace
        end
      end

      DEFAULT_LOG_LAYOUT_PARAMETERS = {
        pattern: "%.1l, [%d #%p.%t] %5l %m\n",
        date_pattern: "%Y-%m-%dT%H:%M:%S.%6N",
        format_as: "string",
      }

      class Formatter < ::Logging::Layouts::Pattern
        def format_obj(obj)
          if obj.is_a?(::Teneo::Tools::Logger::Event)
            obj.log_info
          else
            super
          end
        end
      end

      module ClassMethods
        def default_formatter
          ::Teneo::Tools::Logger::Formatter.new(DEFAULT_LOG_LAYOUT_PARAMETERS)
        end

        def appender(type, *args, **opts)
          opts[:layout] = default_formatter
          if levels = opts.delete(:level_filter)
            opts[:filters] ||= []
            opts[:filters] << ::Logging::Filters::Level.new(*levels)
          end
          ::Logging.appenders.send(type, *args, **opts)
        end
      end

      def self.included(klass)
        klass.extend ClassMethods
        ::Logging::LEVELS.each do |level, number|
          klass.define_method(level) do |*args, **opts|
            event = build_logger_event(*args, **opts)
            logger.send(level, event)
          end
        end
      end

      def logger
        Logging.logger[logger_name]
      end

      def logger_name
        "#{self.class.name}"
      end

      def clear_appenders!
        logger.clear_appenders
      end

      def add_appender(*args, **opts)
        appender = self.class.appender(*args, **opts)
        logger.add_appenders(appender)
        appender
      end

      def default_level=(level)
        loger.level = level
      end

      def default_level
        logger.level
      end

      def clear!
        logger.appenders.each do |appender|
          if appender.respond_to?(:clear!)
            appender.clear!
          end
        end
      end

      def close
        logger.appenders.each do |appender|
          appender.close
        end
      end

      def reopen
        logger.appenders.each do |appender|
          appender.reopen
        end
      end

      def flush
        logger.appenders.each do |appender|
          appender.flush
        end
      end

      def context
        logger_name
      end

      def build_logger_event(*args, **opts)
        if args.size > 0
          begin
            message = args.first % args[1..]
          rescue
            message = args.join(" - ")
          end
        end
        opts[:message] ||= message || ""
        opts[:context] ||= context
        Teneo::Tools::Logger::Event.new(**opts)
      end
    end
  end
end
