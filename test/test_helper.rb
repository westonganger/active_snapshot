#$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
ENV["RAILS_ENV"] = "test"

require "active_snapshot"

if ENV["ACTIVE_SNAPSHOT_STORAGE_METHOD"].present?
  ActiveSnapshot.config.storage_method = ENV["ACTIVE_SNAPSHOT_STORAGE_METHOD"]
end

begin
  require 'warning'

  Warning.ignore(
    %r{mail/parsers/address_lists_parser}, ### Hide mail gem warnings
  )
rescue LoadError
  # Do nothing
end

### Instantiates Rails
require File.expand_path("../dummy_app/config/environment.rb",  __FILE__)

require "rails/test_help"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
end

Rails.backtrace_cleaner.remove_silencers!

require 'minitest-spec-rails' ### for describe blocks

require 'minitest/reporters'
Minitest::Reporters.use!(
  Minitest::Reporters::DefaultReporter.new,
  ENV,
  Minitest.backtrace_filter
)

require "minitest/autorun"

# Run any available migration
if ActiveRecord.gem_version >= Gem::Version.new("6.0")
  ActiveRecord::MigrationContext.new(File.expand_path("dummy_app/db/migrate/", __dir__), ActiveRecord::SchemaMigration).migrate
elsif ActiveRecord.gem_version >= Gem::Version.new("5.2")
  ActiveRecord::MigrationContext.new(File.expand_path("dummy_app/db/migrate/", __dir__)).migrate
else
  ActiveRecord::Migrator.migrate File.expand_path("dummy_app/db/migrate/", __dir__)
end

require 'rspec/mocks'
module MinitestRSpecMocksIntegration
  include RSpec::Mocks::ExampleMethods

  def before_setup
    RSpec::Mocks.setup
    super
  end

  def after_teardown
    super
    RSpec::Mocks.verify
  ensure
    RSpec::Mocks.teardown
  end
end
Minitest::Test.send(:include, MinitestRSpecMocksIntegration)

klasses = [
  Post,
  ActiveSnapshot::Snapshot,
  ActiveSnapshot::SnapshotItem,
]

klasses.each do |klass|
  if klass.connection.adapter_name.downcase.include?("sqlite")
    ActiveRecord::Base.connection.execute("DELETE FROM #{klass.table_name};")
    ActiveRecord::Base.connection.execute("UPDATE `sqlite_sequence` SET `seq` = 0 WHERE `name` = '#{klass.table_name}';")
  else
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{klass.table_name}")
  end
end

DATA = {}.with_indifferent_access

DATA[:shared_post] = Post.find_or_create_by!(a: 1, b: 3)
DATA[:shared_post].create_snapshot!(identifier: 'v1')
DATA[:shared_post].update_columns(a: 2, b: 4)
DATA[:shared_post].create_snapshot!(identifier: 'v2')

def assert_time_match(a, b)
  format = "%d-%m-%Y %h:%M:%S.%L" ### MUST LIMIT THE MILLISECONDS TO 3 decimal places of accuracy, the rest are dropped
  assert_equal a.strftime(format), b.strftime(format)
end
