require File.expand_path(File.dirname(__FILE__) + '/lib/active_snapshot/version.rb')

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :db_prepare do
  # if ENV['CI'] != "true"
  #   begin
  #     require 'pg'

  #     ### FOR LOCAL TESTING
  #     `dropdb active_snapshot_test && createdb active_snapshot_test` rescue true
  #   rescue LoadError
  #     # Do nothing
  #   end
  # end

  ### RUN GENERATOR
  # Dir.chdir("test/dummy_app") do
  #   ### Instantiates Rails
  #   require File.expand_path("test/dummy_app/config/environment.rb", __dir__)

  #   migration_path = "db/migrate"

  #   ### Generate Migration
  #   require "generators/active_snapshot/install/install_generator"

  #   generator = ActiveSnapshot::InstallGenerator.new

  #   Dir.glob(Rails.root.join(migration_path, "*#{generator.class::MIGRATION_NAME}.rb")).each do |f|
  #     FileUtils.rm(f)
  #   end

  #   generator.create_migration_file
  # end ### END chdir
end

#task default: [:db_prepare, :test]
task default: [:test]

task :console do
  require 'active_snapshot'

  require_relative 'test/dummy_app/app/models/post'

  require 'irb'
  binding.irb
end
