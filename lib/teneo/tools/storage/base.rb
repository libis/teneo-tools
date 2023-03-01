# frozen_string_literal: true

require 'pathname'
require 'fileutils'

module Teneo
  module Tools
    module Storage

      class Base

        # Driver and protocols

        def self.drivers
          @drivers ||= ObjectSpace.each_object(Class).select { |klass| klass < self }
        end
  
        def self.protocols
          drivers.map { |klass| klass.protocol }
        end
  
        def self.driver(protocol)
          drivers&.find { |d| d.protocol == protocol }
        end

        # Class variables

        def self.protocol(value = nil)
          @protocol = value unless value.nil?
          @protocol || ''
        end

        def self.description(value = nil)
          @description = value unless value.nil?
          @description || ''
        end
  
        def self.local?(value = nil)
          @local = value unless value.nil?
          @local || false
        end

      end

      # Reference to a single (file) object in a storage object
      class Blob

        class Cleaner
          # @param [String] tmpfile
          def initialize(tmpfile)
            @pid = Process.pid
            @tmpfile = tmpfile
          end

          def call(*_args)
            return if @pid != Process.pid
            return unless ::File.exist?(@tmpfile) && ::File.file?(@tempfile)
            ::File.delete(@tmpfile)
          rescue Errno::ENOENT
            # ignore
          end
        end

        attr_reader :driver, :path, :localized, :localfile, :options

        def initialize(driver:, path:, **options)
          @driver = driver
          @path = path
          @options = options
          @localized = false
          @localfile = ::File.join(driver.work_dir, path)

          unless (driver.local?)
            ObjectSpace.define_finalizer(self, Cleaner.new(@localfile))
          end
        end

        def localize(force: false)
          return nil if @driver.local?
          return nil if @localized && !force
          raise Errno::ENOENT unless exist?
          FileUtils.mkpath(::File.dirname(@localfile))
          if @driver.download(remote: @path, local: @localfile)
            @localized = true
          end
          @localized
        end
        
        
      end

    end
  end
end
