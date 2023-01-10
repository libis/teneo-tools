# frozen_string_literal: true

require "date"

module Teneo
  module Tools
    module Parameter

      # A {Teneo::Parameter::Definition} is like a class instance attribute on steroids. Contrary to regular attributes, Parameters are
      # type-safe, can have a descriptive text explaining their use, a constraint that limits the values and any other
      # properties for an application to use for their needs.
      #
      # Parameters are inherited from base classes and can be overwritten without affecting the parameters in the parent
      # class. For instance, a regular parameter in the parent class can be given a fixed value in the child class by
      # giving it a default value and setting it's frozen property to true. The same paremter in the parent class
      # instances will still be modifieable. But the parameter in the child class instances will be frozen, even if
      # accessed via the methods on parent class.
      #
      # Important: the parameter will exist both on the class level as on the instance level, but the parameter on the
      # class level is the parameter definition as described in the {Teneo::Parameter::Definition} class. On the instance level, there are
      # merely some parameter methods that access the parameter instance values with the help of the parameter definitions
      # on the class. The implementation of the parameter instances is dealt with by the {Teneo::Parameter::Container} module.
      Definition = Struct.new(:name, :default, :datatype, :description, :constraint, :frozen, :options, keyword_init: true) do

        # Create a Parameter instance.
        # @param :name - Required. String for the name of the parameter. Any valid attribute name is acceptable.
        # @param :default - Any value. Will be coverted to the given datatype if present. Default is nil.
        # @param :datatype - String. One of: bool, string, int, float, datetime, array, hash. If omitted it will be derived
        #       from the default value or set to the default 'string'.
        # @param :description - String describing the parameter's use.
        # @param :constraint - Array, Range, RegEx or single value. Default is nil meaning no constraint.
        # @param :frozen - Boolean. Default is false; if true the parameter value cannot be changed from the default value.
        # @param :options - Any Hash. It's up to the application to interprete and use this info.
        def initialize(**opts)
          super(**(opts.slice(*members)))
          self[:options] ||= {}
          self[:options].merge!(opts.except(*members))
          self[:datatype] ||= guess_datatype
        end

        # Duplicates the parameter
        def dup
          new_obj = super
          new_obj[:options] = Marshal.load(Marshal.dump(self[:options]))
          new_obj
        end

        # Merges other parameter data into the current parameter
        # @param [::Teneo::Parameter::Definition] other parameter definition to copy properties from
        def merge!(other)
          other.each do |k, v|
            if k == :options
              self[:options].merge!(v)
            else
              self[k] = v
            end
          end
          self
        end

        # Retrieve a specific property of the parameter.
        # If not found in the regular properties, the options Hash is scanned for the property.
        # @param [Symbol] key name of the property
        def [](key)
          return super(key) if members.include?(key)
          self[:options][key]
        end

        # Set a property of the parameter.
        # If the property is not one of the regular properties, the property will be set in the options Hash.
        # @param (see #[])
        # @param [Object] value value for the property. No type checking happens on this value
        def []=(key, value)
          return super(key, value) if members.include?(key)
          self[:options][key] = value
        end

        # Dumps the parameter properties into a Hash.
        # The options properties are merged into the hash. If you do not want that, use Struct#to_h instead.
        #
        # @return [Hash] parameter definition properties
        def to_hash
          super.inject({}) do |hash, key, value|
            key == :options ? value.each { |k, v| hash[k] = v } : hash[key] = value
            hash
          end
        end

        # Valid input strings for boolean parameter value, all converted to 'true'
        TRUE_BOOL = %w'true yes t y 1'
        # Valid input strings for boolean parameter value, all converted to 'false'
        FALSE_BOOL = %w'false no f n 0'

        # Parse any value and try to convert to the correct datatype and check the constraints.
        # Will throw an exception if not valid.
        # @param [Object] value Any value to parse, strings are best supported.
        # @return [Object] checked and converted value
        def parse(value = nil)
          result = value.nil? ? self[:default] : convert(value)
          check_constraint(result)
          result
        end

        # Parse any value and try to convert to the correct datatype and check the constraints.
        # Will return false if not valid, true otherwise.
        # @param [Object] value Any value to check
        def valid_value?(value)
          begin
            parse(value)
          rescue
            return false
          end
          true
        end

        private

        # TODO: see if we can use Dry::Types for this

        def guess_datatype
          self[:datatype] || case self[:default]
          when TrueClass, FalseClass
            "bool"
          when NilClass
            "string"
          when Integer
            "int"
          when Float
            "float"
          when DateTime, Date, Time
            "datetime"
          when Array
            "array"
          when Hash
            "hash"
          else
            self[:default].class.name.downcase
          end
        end

        def convert(v)
          case self[:datatype].to_s.downcase
          when "boolean", "bool"
            return true if TRUE_BOOL.include?(v.to_s.downcase)
            return false if FALSE_BOOL.include?(v.to_s.downcase)
            raise Teneo::Parameter::ValidationError, "No boolean information in '#{v.to_s}'. " +
                                                     "Valid values are: '#{TRUE_BOOL.join('\', \'')}" +
                                                     "' and '#{FALSE_BOOL.join('\', \'')}'."
          when "string", "nil"
            return v.to_s
          when "int", "integer"
            return Integer(v)
          when "float"
            return Float(v)
          when "datetime"
            return v.to_datetime if v.respond_to? :to_datetime
            return DateTime.parse(v)
          when "array"
            return v if v.is_a?(Array)
            return v.split(/[,;|\s]+/) if v.is_a?(String)
            # Alternatavely:
            # return JSON.parse(v) if v.is_a?(String)
            return v.to_a if v.respond_to?(:to_a)
          when "hash"
            return v if v.is_a?(Hash)
            return Hash[(0...v.size).zip(v)] if v.is_a?(Array)
            return JSON.parse(v) if v.is_a?(String)
          else
            raise Teneo::Parameter::ValidationError, "Datatype not supported: '#{self[:datatype]}'"
          end
          nil
        end

        def check_constraint(v, constraint = nil)
          constraint ||= self[:constraint]
          return if constraint.nil?
          unless constraint_checker(v, constraint)
            raise Teneo::Parameter::ValidationError, "Value '#{v}' is not allowed (constraint: #{constraint})."
          end
        end

        def constraint_checker(v, constraint)
          case constraint
          when Array
            constraint.each do |c|
              return true if (constraint_checker(v, c) rescue false)
            end
            return true if constraint.include? v
          when Range
            return true if constraint.cover? v
          when Regexp
            return true if v =~ constraint
          else
            return true if v == constraint
          end
          false
        end
      end # Definition
    end # Parameter
  end # Tools
end # Teneo
