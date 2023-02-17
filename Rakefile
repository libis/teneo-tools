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
  config.unreleased = true
end

desc "release the gem"
task update_changelog: :changelog do
  puts `git commit -am 'Changelog update'`
  puts `git push`
end

desc "bump patch version"
task :patch do
  puts `gem bump -v patch --no-commit`
  `rake publish`
end

desc "bump minor version"
task :minor do
  puts `gem bump -v minor --no-commit`
  `rake publish`
end

desc "bump major version"
task :major do
  puts `gem bump -v major --no-commit`
  `rake publish`
end

desc "publish the gem"
task :publish do
  puts `bundle install`
  puts `git commit -am 'Version bump: #{::Teneo::Tools::VERSION}'`
  puts `gem release --tag --push --github`
  puts `rake update_changelog`
end
