# frozen_string_literal: true

require "pathname"
require 'bfs/fs'
BFS.unregister('file')

require_relative "driver"

module Teneo
  module Tools
    module Storage
      class LocalDriver < BFS::Bucket

        protocol 'file'
        description 'Local disk or mounted network drive'
        local? true

        def initialize(prefix:, location:, **opts)
          super(location, **opts)
          BFS.register(prefix:) do ||
          @bucket = BFS::FS.new(location, **opts)
        end

        def fullpath(path)
          File.join(@work_dir, path)
        end

        def relpath(path)
          Pathname.new(path).relative_path_from(Pathname.new(@work_dir)).to_s
        end

        def exist?(path)
          File.exist?(fullpath(path))
        end

        def mtime(path)

        end

        def size(path)
        end

        def mkpath(path)
        end

        def delete(path)
        end

        def copy(source:, target:)
        end

        def move(source:, target:)
        end

        def download(remote:, local:)
        end

        def upload(local:, remote:)
        end

      end
    end
  end
end
