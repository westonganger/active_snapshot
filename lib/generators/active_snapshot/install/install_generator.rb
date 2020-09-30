require "generators/active_snapshot/migration_generator"

module ActiveSnapshot
  class InstallGenerator < MigrationGenerator

    source_root File.expand_path("templates", __dir__)

    desc "Generates a migration to add a the `snapshots` and `snapshot_items` tables"

    def create_migration_file
      add_migration(
        "create_snapshots_tables",
        { table_options: table_options }
      )
    end

  end
end
