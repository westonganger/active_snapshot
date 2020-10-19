require File.expand_path(File.dirname(__FILE__) + '/lib/active_snapshot/version.rb')

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :db_prepare do
  Dir.chdir("test/dummy_app")

  #FileUtils.rm(::Dir.glob("spec/dummy_app/db/*.sqlite3"))
  
  ### Create Database
  ENV['DB'] ||= 'postgresql'

  case ENV["DB"]
  when "postgresql"
    system("createdb active_snapshot_test")
  when "mysql"
    system("mysqladmin create active_snapshot_test")
  else
    raise "Don't know how to create specified DB: #{ENV['DB']}"
  end

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

  generator.create_migration_file

  ### Run Migrations
  if ActiveRecord.gem_version >= Gem::Version.new("6.0.0")
    ActiveRecord::MigrationContext.new(migration_path, ActiveRecord::SchemaMigration).migrate
  elsif ActiveRecord.gem_version >= Gem::Version.new("5.2.0")
    ActiveRecord::MigrationContext.new(migration_path).migrate
  else
    ActiveRecord::Migrator.migrate(migration_path)
  end

  Dir.chdir(__dir__) ### Ensure switch back to current dir
end

task default: [:db_prepare, :test]

task :console do
  require 'active_snapshot'

  require 'test/dummy_app/app/models/post'

  require 'irb'
  binding.irb
end
