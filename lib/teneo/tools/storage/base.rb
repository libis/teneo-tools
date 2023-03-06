# frozen_string_literal: true

require "pathname"
require "fileutils"

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
