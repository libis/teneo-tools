# frozen_string_literal: true

module Teneo
  module Tools
    module Parameter
      # Exception that will be raised when a parameter value does not pass the validation checks.
      class ValidationError < RuntimeError
      end

      # Exception that will be raised when an attempt is made to change the value of a frozen parameter.
      class FrozenError < RuntimeError
      end

      autoload :Definition, "teneo/tools/parameter/definition"
      autoload :Container, "teneo/tools/parameter/container"
    end
  end
end
