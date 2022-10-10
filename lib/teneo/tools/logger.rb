# frozen_string_literal: true

require "semantic_logger"

module Teneo
  module Tools

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
      class Appender
        include SemanticLogger::Appender
      end

      class Formatter < SemanticLogger::Formatters::Default
      end

      def self.included(klass)
        klass.include SemanticLogger::Loggable
        klass.class_eval do
          def logger_name
            "#{self.class.name}-#{self.object_id}"
          end

          def logger(name = nil)
            @semantic_logger ||= SemanticLogger[name || logger_name]
          end

          def add_appender(**appender, &block)
            appender = { filter: /^#{logger_name}$/ }.merge(appender)
            SemanticLogger.add_appender(**appender, &block)
          end

          def tagged(*args, &block)
            SemanticLogger.tagged(*args, &block)
          end
        end
      end

      def self.default_level=(level)
        SemanticLogger.default_level = level
      end

      def self.default_level
        SemanticLogger.default_level
      end

      def self.add_appender(**appender, &block)
        SemanticLogger.add_appender(**appender, &block)
      end

      def self.reopen
        SemanticLogger.reopen
      end

      def self.flush
        SemanticLogger.flush
      end
    end
  end
end
