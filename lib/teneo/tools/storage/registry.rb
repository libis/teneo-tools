# frozen_string_literal: true

require 'singleton'
require_relative 'driver'

module Teneo
  module Tools
    module Storage

      class Registry
        include singleton

        def drivers
            @drivers ||= ObjectSpace.each_object(Class).select { |klass| klass < Teneo::Tools::Storage::Driver }
        end
    
        def protocols
        drivers.map { |klass| klass.protocol }
        end

        def driver(protocol)
        drivers&.find { |d| d.protocol == protocol }
        end
    
      end
    end
end
