require "lib/generators/active_snapshot/migration_generator"

module ActiveSnapshot
  class InstallGenerator < MigrationGenerator

    source_root File.expand_path("templates", __dir__)

    desc "Generates a migration to add an active_snapshot_versions table"

    def create_migration_file
      add_migration(
        "create_active_snapshot_versions",
        { table_options: table_options }
      )
    end

  end
end
