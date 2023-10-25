# frozen_string_literal: true

require 'fileutils'

require_relative 'errors'
require_relative 'blob'

module Teneo
  module Tools
    module Storage
      # Generic base storage driver
      class Driver
        # Class variables

        attr_reader :work_dir

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

        def self.close_all
          ObjectSpace.each_object(self).select { |klass| klass < self }.each(&:close_all)
          ObjectSpace.each_object(self, &:close)
        end

        def norm_path(path:)
          Storage.norm_path(path:)
        end

        def norm_mode(mode:)
          Storage.norm_mode(mode:)
        end

        def initialize(work_dir:, encoding: Encoding.default_external, perm: nil, **_opts)
          @work_dir = work_dir
          @encoding = encoding

          case perm
          when Integer
            @perm = perm
          when String
            @perm = perm.to_i(8)
          end

          Storage.defer(self, :finalize)
        end

        def fullpath(_path:)
          raise NotImplementedError
        end

        def relpath(_path:)
          raise NotImplementedError
        end

        def exist?(path)
          raise NotImplementedError
        end

        def info(_path:)
          raise NotImplementedError
        end

        def mtime(_path)
          raise NotImplementedError
        end

        def size(_path)
          raise NotImplementedError
        end

        def dirs(_path)
          raise NotImplementedError
        end

        def files(path)
          raise NotImplementedError
        end

        def mkpath(path)
          raise NotImplementedError
        end

        def delete(path)
          raise NotImplementedError
        end

        def copy(source:, target:)
          raise NotImplementedError
        end

        def move(source:, target:)
          raise NotImplementedError
        end

        def download(remote:, local:)
          raise NotImplementedError
        end

        def upload(local:, remote:)
          raise NotImplementedError
        end

        protected

        def safepath(path)
          ::File.expand_path(::File::SEPARATOR + path.gsub(/^#{Regexp.escape(::File::SEPARATOR)}+/, ''), ::File::SEPARATOR)
        end

      end
    end
  end
end
