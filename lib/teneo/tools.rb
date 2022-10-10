# frozen_string_literal: true

require_relative "tools/version"

require_relative "tools/extensions"
require_relative "tools/parameter"

module Teneo
  module Tools
    autoload :Logger, "teneo/tools/logger"
    autoload :Checksum, "teneo/tools/checksum"
  end
end
