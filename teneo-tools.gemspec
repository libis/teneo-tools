# frozen_string_literal: true

require_relative "lib/teneo/tools/version"

Gem::Specification.new do |spec|
  spec.name = "teneo-tools"
  spec.version = Teneo::Tools::VERSION
  spec.authors = ["Kris Dekeyser"]
  spec.email = ["kris.dekeyser@libis.be"]

  spec.summary = "Various tool classes and modules for Teneo."
  spec.description = "This gem collects a number of utility classes and modules in use by the Teneo applications."
  spec.homepage = "https://github.com/libis/teneo-tools"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://github.com/libis/teneo-tools"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/libis/teneo-tools"
  spec.metadata["changelog_uri"] = "https://github.com/libis/teneo-tools/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "semantic_logger", "~> 4.11"
  spec.add_runtime_dependency "concurrent-ruby", "~> 1.0"

  spec.add_development_dependency "amazing_print", "~> 1.4"
  spec.add_development_dependency "timecop", "~> 0.9"
end
