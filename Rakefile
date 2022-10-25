# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require_relative "lib/teneo/tools/version"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

require "github_changelog_generator/task"

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.user = "libis"
  config.project = "teneo-tools"
  config.future_release = ::Teneo::Tools::VERSION
end

desc "release the gem"
task :update_changelog do
  `rake changelog`
  `git commit -am 'Changelog update'`
  `git push`
end

desc "bump patch version"
task :patch do
  `gem bump patch`
end

desc "bump minor version"
task :minor do
  `gem bump minor`
end

desc "bump major version"
task :major do
  `gem bump major`
end

desc "publish the gem"
task :publish do
  `rake changelog`
  `gem bump #{::Teneo::Tools::VERSION} --tag --push --release`
end
