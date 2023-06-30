# frozen_string_literal: true

require "pathname"
require "fileutils"

require_relative 'blob'

module Teneo
  module Tools
    module Storage
      class Driver
        # Class variables

        def self.protocol(value = nil)
          @protocol = value unless value.nil?
          @protocol || ""
        end

        def self.description(value = nil)
          @description = value unless value.nil?
          @description || ""
        end

        def self.local?(value = nil)
          @local = value unless value.nil?
          @local || false
        end
      end
    end
  end
end
