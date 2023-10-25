# frozen_string_literal: true

module Teneo
  module Tools
    module Storage
      # File not found error
      class FileNotFoundError < StandardError
        attr_reader :path

        def initialize(path)
          @path = path
          super "File not found: #{path}"
        end
      end

      # Method not implemented error
      class NotImplementedError < StandardError
        def initialize
          super 'Method not implemented'
        end
      end
    end
  end
end
