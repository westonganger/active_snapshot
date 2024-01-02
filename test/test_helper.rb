#$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
ENV["RAILS_ENV"] = "test"

require "active_support/all"

ActiveSupport.on_load(:active_record) do
  ### To ensure belongs_to :optional validation errors are being caught properly, otherwise they are ignored for some reason
  ### https://github.com/rails/rails/issues/23589#issuecomment-323761201
  ActiveRecord::Base.belongs_to_required_by_default = true
end

require "active_snapshot"

if ENV["ACTIVE_SNAPSHOT_STORAGE_METHOD"].present?
  ActiveSnapshot.config.storage_method = ENV["ACTIVE_SNAPSHOT_STORAGE_METHOD"]
end

require 'warning'

Warning.ignore(
  %r{mail/parsers/address_lists_parser}, ### Hide mail gem warnings
)

### Delete the database completely before starting
FileUtils.rm(
  File.expand_path("../dummy_app/db/*sqlite*",  __FILE__),
  force: true,
)

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

DATA = {}.with_indifferent_access

DATA[:shared_post] = Post.create!(a: 1, b: 3)
DATA[:shared_post].create_snapshot!(identifier: 'v1')
DATA[:shared_post].update_columns(a: 2, b: 4)
DATA[:shared_post].create_snapshot!(identifier: 'v2')

def assert_time_match(a, b)
  format = "%d-%m-%Y %h:%M:%S.%L" ### MUST LIMIT THE MILLISECONDS TO 3 decimal places of accuracy, the rest are dropped
  assert_equal a.strftime(format), b.strftime(format)
end
