require "test_helper"
require File.expand_path("../../../lib/generators/active_snapshot/install/install_generator", __dir__)

class InstallGeneratorTest < Rails::Generators::TestCase
  tests ActiveSnapshot::InstallGenerator
  destination File.expand_path("tmp", __dir__)

  setup do
    prepare_destination # cleanup the tmp directory
    run_generator
  end

  teardown do
    ### Disable during debugging
    prepare_destination # cleanup the tmp directory
  end

  def test_should_add_migration
    run_generator

    relative_path = "db/migrate/create_snapshots_tables.rb"

    assert_migration(relative_path) do |content|
      assert_match(/create_table :snapshots/, content)
      assert_match(/create_table :snapshot_items/, content)
    end

    ### Test for syntax errors in file
    require send(:migration_file_name, relative_path)
  end
end
