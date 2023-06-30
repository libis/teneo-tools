# frozen_string_literal: true

require "pathname"
require "fileutils"

module Teneo
  module Tools
    module Storage
      # Reference to a single (file) object in a storage object
      class Blob
        class Cleaner
          # @param [String] tmpfile
          def initialize(driver:, path:, localpath:)
            @pid = Process.pid
            @driver = driver
            @path = path
            @localpath = localpath
          end

          def call(*_args)
            return if @pid != Process.pid
            return unless ::File.exist?(@localpath) && ::File.file?(@localpath)
            ::File.delete(@localpath)
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
          if driver.local?
            @localfile = @driver.fullpath
          else
            @localfile = ::File.join(driver.work_dir, path)
            @cleaner = Cleaner.new(driver: driver, path: path, localpath: @localfile)
            ObjectSpace.define_finalizer(self, @cleaner)
          end
        end

        def localize(force: false)
          return nil if @driver.local?
          return nil if @localized && !force
          raise Errno::ENOENT unless exist?
          FileUtils.mkpath(::File.dirname(@localfile))
          if exist?
            @driver.download(remote: @path, local: @localfile)
          end
          @localized = true
        end

        def save
          return true if @driver.local? || !@localized
          @driver.mkpath(::File.dirname(@path))
          @driver.upload(local: @localfile, remote: @path)
          true
        end

        def touch
          return true if exist?
          FileUtils.mkpath(::File.dirname(@localfile))
          FileUtils.touch(@localfile)
          save
        end

        def open(**opts)
          localize
          mode = opts[:mode] || "rb"
          perm = opts[:perm] || @driver.perm || 0644
          ::File.open(@localfile, mode, perm, **opts) do |f|
            block_given? ? yield(f) : f.read
          end
        end

        def reader(**opts)
          return nil unless exist?
          localize
          return nil unless ::File.readable?(@localfile)
          opts[:mode] ||= "rb"
          self.open(**opts) do |f|
            block_given? ? yield(f) : f.read
          end
        end

        def writer(data = nil, **opts)
          return nil unless self.writable?(@localfile)
          opts[:mode] ||= "wb"
          self.open(**opts) do |f|
            block_given? ? yield(f, data) : f.write(data)
          end
          save
        end

        def append(data = nil, **opts)
          opts[:mode] ||= "ab"
          self.open(**opts) do |f|
            block_given? ? yield(f, data) : f.write(data)
          end
          save
        end

        BUFSIZE = 1024 * 1024
        def transfer(target, **opts)
          case target
          when nil
            return false
          when String
            @driver.cp(path, target, **opts)
          when ::Teneo::Storage::Blob
            target.writer(**opts) do |w|
              self.reader() do |r|
                do
                  w.write(r.read(BUFSIZE))
                until r.eof?
              end
            end
          end
        end
      end
    end
  end
end
