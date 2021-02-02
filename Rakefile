require File.expand_path(File.dirname(__FILE__) + '/lib/active_snapshot/version.rb')

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :db_prepare do
  Dir.chdir("test/dummy_app") do
    `createdb active_snapshot_test` rescue true

    ### Instantiates Rails
    require File.expand_path("test/dummy_app/config/environment.rb", __dir__)

    migration_path = "db/migrate"

    ### Generate Migration
    require "generators/active_snapshot/install/install_generator"

    generator = ActiveSnapshot::InstallGenerator.new

    f = File.join(migration_path, generator.class::MIGRATION_NAME)
    if File.exist?(f)
      FileUtils.rm(f)
    end

    #generator.instance_variable_set(:@migration_path, migration_path)

    silence_warnings do
      generator.create_migration_file
    end
  end ### END chdir
end

task default: [:db_prepare, :test]

task :console do
  require 'active_snapshot'

  require 'test/dummy_app/app/models/post'

  require 'irb'
  binding.irb
end
