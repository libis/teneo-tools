# frozen_string_literal: true

require "fileutils"

module Teneo
  module Tools
    module Storage
      # Reference to a single (file) object in a storage object
      class Blob
        class Cleaner
          # @param [String] localpath
          def initialize(localpath:)
            @pid = Process.pid
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
          @localfile = to_localpath(path)
          make_finalizer
        end

        def driver_path
          @driver.relpath(@path)
        end

        def exist?
          @driver.exist?(driver_path)
        end

        def local?
          @driver.local?
        end

        def protocol
          @driver.protocol
        end

        def delete
          @driver.delete(driver_path)
        end

        def mtime
          @driver.mtime(driver_path)
        end

        def size
          @driver.size(driver_path)
        end

        def rename(new_name)
          do_move(File.join(File.dirname(@path), new_name))
        end

        def move(new_dir)
          do_move(File.join(File.dirname(@path), File.basename(@path)))
        end

        def localize(force: false)
          return nil if @driver.local?
          return nil if @localized && !force
          raise Errno::ENOENT unless exist?
          FileUtils.mkpath(File.dirname(@localfile))
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
            @driver.copy(source: path, target: target, **opts)
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

        protected

        def to_localpath(ext_path = nil)
          ext_path ||= @path
          local_path = if @driver.local?
            @driver.fullpath(ext_path)
          else
            ::File.join(driver.work_dir, ext_path)
          end
        end

        def make_finalizer
          unless driver.local?
            @cleaner = Cleaner.new(localpath: @localfile)
            ObjectSpace.define_finalizer(self, @cleaner)
          end
        end

        def do_move(new_path)
          new_localpath = to_localpath(new_path)
          if local?
            do_move_local(new_localpath)
          else
            if localized?
              do_move_local(new_localpath)
            end
            @driver.move(source: @path, target: new_path)
          end
          @localfile = new_localpath
          @path = new_path
        end

        def do_move_local(new_localpath)
          FileUtils.mkpath(File.dirname(new_localpath))
          FileUtils.move(@localfile, new_localpath)
        end

      end
    end
  end
end
