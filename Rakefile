require File.expand_path(File.dirname(__FILE__) + '/lib/active_snapshot/version.rb')

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :db_prepare do
  FileUtils.rm(::Dir.glob("spec/dummy_app/db/*.sqlite3"))

  ### Instantiates Rails
  require File.expand_path("test/dummy_app/config/environment.rb", __dir__)

  migration_path = "test/dummy_app/db/migrate"

  ### Generate Migration
  require "generators/active_snapshot/install/install_generator"
  generator = ActiveSnapshot::InstallGenerator.new(migration_path: migration_path)

  f = File.join(migration_path, generator.class::MIGRATION_NAME)
  if File.exist?(f)
    FileUtils.rm(f)
  end

  generator.create_migration_file

  ### Run Migrations
  if ActiveRecord.gem_version >= Gem::Version.new("6.0.0")
    ActiveRecord::MigrationContext.new(migration_path, ActiveRecord::SchemaMigration).migrate
  elsif ActiveRecord.gem_version >= Gem::Version.new("5.2.0")
    ActiveRecord::MigrationContext.new(migration_path).migrate
  else
    ActiveRecord::Migrator.migrate(migration_path)
  end
end

task default: [:db_prepare, :test]

task :console do
  require 'active_snapshot'

  require 'test/dummy_app/app/models/post'

  require 'irb'
  binding.irb
end
