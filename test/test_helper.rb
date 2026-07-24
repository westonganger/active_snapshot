#$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
ENV["RAILS_ENV"] = "test"
ENV['TZ'] = "UTC"

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
require "pathname"
Pathname.new(__dir__).join("dummy_app/db").glob("*sqlite*").each(&:delete)

### Instantiates Rails
require File.expand_path("../dummy_app/config/environment.rb",  __FILE__)

require 'active_record/tasks/database_tasks'
db_config = ActiveRecord::Base.configurations.configs_for(env_name: ENV["RAILS_ENV"]).first
ActiveRecord::Tasks::DatabaseTasks.drop(db_config.configuration_hash) rescue nil
ActiveRecord::Tasks::DatabaseTasks.create(db_config.configuration_hash)
ActiveRecord::MigrationContext.new(File.expand_path("dummy_app/db/migrate/", __dir__)).migrate
ActiveRecord::Tasks::DatabaseTasks.dump_schema(db_config, :ruby)

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

require "rspec/mocks/minitest_integration"

def assert_time_match(a, b)
  format = "%d-%m-%Y %h:%M:%S.%L" ### MUST LIMIT THE MILLISECONDS TO 3 decimal places of accuracy, the rest are dropped
  assert_equal a.strftime(format), b.strftime(format)
end
