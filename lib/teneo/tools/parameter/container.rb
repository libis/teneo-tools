# frozen_string_literal: true

require "concurrent"

require_relative "definition"

module Teneo
  module Tools
    module Parameter

      # To use parameters a class should include the ParameterContainer module and add parameter
      # statements to the body of the class definition.
      #
      # Besides enabling the {Teneo::Parameter::Container::ClassMethods#parameter parameter} class method to
      # define parameters, the module adds the class method
      # {Teneo::Parameter::Container::ClassMethods#parameter_defs parameter_defs} that will return
      # a Hash with parameter names as keys and their respective parameter definitions as values.
      #
      # On each class instance the {Teneo::Parameter::Container#parameter parameter} method is added and serves
      # as both getter and setter for parameter instance values.
      # The methods {Teneo::Parameter::Container#[] []} and {Teneo::Parameter::Container#[]= []=} serve as
      # aliases for the getter and setter calls.
      #
      # Additionally two protected methods are available on the instance:
      # * {Teneo::Parameter::Container#parameters parameters}: returns the Hash that keeps track of the current
      #   parameter values for the instance.
      # * {Teneo::Parameter::Container#get_parameter_definition get_parameter_defintion}: retrieves the parameter
      #   definition from the instance's class for the given parameter name.
      #
      # Any class that derives from a class that included the ParameterContainer module will automatically inherit all
      # parameter definitions from all of it's base classes and can override any of these parameter definitions e.g. to
      # change the default values for the parameter.
      #
      module Container

        # Methods created on class level.
        module ClassMethods

          # Get a list of all parameter definitions.
          # The list is initialized with duplicates of the parameter definitions of the parent class and
          # each new parameter definition updates or appends the list.
          # @return [Hash] with parameter names as keys and {Teneo::Parameter::Definition} instance as value.
          def parameter_defs
            return @param_defs if @param_defs
            @param_defs = ::Concurrent::Hash.new
            begin
              self.superclass.parameter_defs.
                each_with_object(@param_defs) do |(name, param), hash|
                hash[name] = param.dup
              end
            rescue NoMethodError
              # ignored
            end
            @param_defs
          end

          # DSL method that allows creating parameter definitions on the class level.
          #
          # If the name argument is supplied, the prameter definition corresponding to the name is returned.
          #
          # Otherwise, it reads the hash argument. The first entry is interpreted as '<name>: <default>'.
          # The name for the parameter should be unique and the default value can be any value
          # of type TrueClass, FalseClass, String, Integer, Float, Date, Time, DateTime, Array, Hash or nil.
          #
          # The second up to last Hash entries are optional properties for the parameter. These are:
          # * datatype: the type of values the parameter will accept. Valid values are:
          #   * 'bool' or 'boolean'
          #   * 'string'
          #   * 'int'
          #   * 'float'
          #   * 'datetime'
          #   * 'array'
          #   * 'hash'
          #   Any other value will raise an Exception when the parameter is used. The value is case-insensitive and
          #   if not present, the datatype will be derived from the default value with 'string' being the default for
          #   NilClass. In any case the parameter will try its best to convert supplied values to the proper data type.
          #   For instance, an Integer parameter will accept 3, 3.1415, '3' and Rational(10/3) as valid values and
          #   store them as the integer value 3. Likewise DateTime parameters will try to interprete date and time strings.
          # * description: any descriptive text you want to add to clarify what this parameter is used for.
          #   Any tool can ask the class for its parameters and - for instance - can use this property to provide help
          #   in a GUI when asking the user for input.
          # * constraint: adds a validation condition to the parameter. The condition value can be:
          #   * an array: only values that convert to a value in the list are considered valid.
          #   * a range: only values that convert to a value in the given range are considered valid.
          #   * a regular expression: only values that match the regular expression are considered valid.
          #   * a string: only values that are '==' to the constraint are considered valid.
          # * frozen: if set to true, prevents the class instance to set the parameter to any value other than
          #   the default. Mostly useful when a derived class needs a parameter in the parent class to be set to a
          #   specific value. Setting a value on a frozen parameter with the 'parameter(name,value)' method throws a
          #   {::Libis::Tools::ParameterFrozenError}.
          # * options: a hash with any additional properties that you want to associate to the parameter. Any key-value pair in this
          #   hash is added to the retrievable properties of the parameter. Likewise any property defined, that is not in the list of
          #   known properties is added to the options hash. In this aspect the ::Libis::Tools::Parameter class behaves much like an
          #   OpenStruct even though it is implemented as a Struct.
          def parameter(name = nil, **options)
            return self.parameter_defs[name] if name
            param_ref = options.shift
            name = param_ref.first.to_s.to_sym
            default = param_ref.last
            param = (self.parameter_defs[name] = Teneo::Tools::Parameter::Definition.new(name: name, default: default))
            options.each { |key, value| param[key] = value }
            param
          end
        end

        # @!visibility private
        def self.included(base)
          base.extend(ClassMethods)
        end

        # Special constant to indicate a parameter has no value set. Nil cannot be used as it is a valid value.
        NO_VALUE = "##NAV##"

        # Getter/setter for parameter instances
        # With only one argument (the parameter name) it returns the current value for the parameter, but the optional
        # second argument will cause the method to set the parameter value. If the parameter is not available or
        # the given value is not a valid value for the parameter, the method will return the special constant
        # {Teneo::Parameter::Container::NO_VALUE NO_VALUE}.
        #
        # Setting a value on a frozen parameter with the 'parameter(name,value)' method throws a
        # {::Teneo::Parameter::FrozenError} exception.
        def parameter(name, value = NO_VALUE)
          param_def = get_parameter_definition(name)
          return NO_VALUE unless param_def
          if value.equal? NO_VALUE
            param_value = parameters[name]
            return param_def.parse(param_value)
          end
          return NO_VALUE unless param_def.valid_value?(value)
          raise Teneo::Tools::Parameter::FrozenError, "Parameter '#{param_def[:name]}' is frozen in '#{self.class.name}'" if param_def[:frozen]
          parameters[name] = value
        end

        # Alias for the {#parameter} getter.
        def [](name)
          parameter(name)
        end

        # Alias for the {#parameter} setter.
        # The only difference is that in case of a frozen parameter, this method silently ignores the exception,
        # but the default value still will not be changed.
        def []=(name, value)
          parameter name, value
        rescue Teneo::Tools::Parameter::FrozenError
          # ignored
        end

        protected

        def parameters
          @parameter_values ||= Hash.new
        end

        def get_parameter_definition(name)
          self.class.parameter_defs[name]
        end
      end # Container
    end # Parameter
  end # Tools
end # Teneo
