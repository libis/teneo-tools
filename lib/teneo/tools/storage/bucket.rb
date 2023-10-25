# frozen_string_literal: true

require 'bfs'

module Teneo
  module Tools
    module Storage
      class Bucket

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

        def self.close_all
          ObjectSpace.each_object(self).select do |klass|
            klass < self
          end.each do |klass|
            klass.close_all
          end
          ObjectSpace.each_object(self) do |obj|
            obj.close
          end
        end

        def protocol
          self.class.protocol
        end

        def local?
          self.class.local?
        end

      end
    end
  end
end
