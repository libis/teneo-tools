# frozen_string_literal: true

require 'uri'
require 'cgi'
module Teneo
  # Tools module
  module Tools
    module Storage
      # File information structure
      class FileInfo < Hash
        def initialize(**attrs)
          super(nil)

          update(size: 0, mtime: Time.at(0), mode: 0, metadata: {})
          update(attrs)
        end

        def path
          fetch(:path, nil)
        end

        def size
          fetch(:size, 0)
        end

        def content_type
          fetch(:content_type, nil)
        end

        def mtime
          fetch(:mtime, Time.at(0))
        end

        def mode
          fetch(:mode, 0)
        end

        def metadata
          fetch(:metadata, {})
        end
      end
    end

    def self.registry
      @registry ||= {}
    end

    def self.registered?(scheme:)
      registry.key?(scheme.to_s)
    end

    def self.register(scheme:, driver:)
      raise ArgumentError, "Scheme #{scheme} is already registered" if registered?(scheme)

      registry[scheme.to_s] = driver
    end

    def self.unregister(scheme:)
      raise ArgumentError, "Scheme #{scheme} is not registered" unless registered?(scheme)

      registry.delete(scheme.to_s)
    end

    def self.resolve(url:, &block)
      url = url.is_a?(::URI) ? url.dup : URI.parse(url)
      registry[url.scheme]&.resolve(url:, **parse_opts(url.query), &block)
    end

    def self.parse_opts(query:)
      CGI.parse(query.to_s).each_with_object({}) do |k, h, v|
        h[k.to_sym] = v.first
      end
    end

    def self.norm_path(path:)
      path = path.to_s.dup
      path.gsub!(File::SEPARATOR)
      path.sub!(%r{^/+}, '')
      path.sub!(%r{/+$}, '')
    end

    def self.norm_mode(mode:)
      mode = mode.to_i(8) if mode.is_a?(String)
      mode & 0o000777
    end

    def self.defer(obj, method)
      owner = Process.pid
      ObjectSpace.define_finalizer(obj, ->(*) { obj.send(method) if Process.pid == owner })
    end
  end
end

require_relative 'storage/errors'
require_relative 'storage/blob'
require_relative 'storage/driver'
require_relative 'storage/registry'
