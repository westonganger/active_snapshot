require "rails/generators"
require "rails/generators/active_record"

module ActiveSnapshot
  # Basic structure to support a generator that builds a migration
  class MigrationGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    protected

    def add_migration(template, extra_options = {})
      migration_dir = File.expand_path("db/migrate")
      if self.class.migration_exists?(migration_dir, template)
        ::Kernel.warn "Migration already exists: #{template}"
      else
        migration_template(
          "#{template}.rb.erb",
          "db/migrate/#{template}.rb",
          { migration_version: migration_version }.merge(extra_options)
        )
      end
    end

    def migration_version
      "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
    end

    private

    def mysql?
      MYSQL_ADAPTERS.include?(ActiveRecord::Base.connection.class.name)
    end

    # Even modern versions of MySQL still use `latin1` as the default character
    # encoding. Many users are not aware of this, and run into trouble when they
    # try to use PaperTrail in apps that otherwise tend to use UTF-8. Postgres, by
    # comparison, uses UTF-8 except in the unusual case where the OS is configured
    # with a custom locale.
    #
    # - https://dev.mysql.com/doc/refman/5.7/en/charset-applications.html
    # - http://www.postgresql.org/docs/9.4/static/multibyte.html
    #
    # Furthermore, MySQL's original implementation of UTF-8 was flawed, and had
    # to be fixed later by introducing a new charset, `utf8mb4`.
    #
    # - https://mathiasbynens.be/notes/mysql-utf8mb4
    # - https://dev.mysql.com/doc/refman/5.5/en/charset-unicode-utf8mb4.html
    #
    def table_options
      if mysql?
        ', { options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci" }'
      else
        ""
      end
    end

    # Class names of MySQL adapters.
    # - `MysqlAdapter` - Used by gems: `mysql`, `activerecord-jdbcmysql-adapter`.
    # - `Mysql2Adapter` - Used by `mysql2` gem.
    MYSQL_ADAPTERS = [
      "ActiveRecord::ConnectionAdapters::MysqlAdapter",
      "ActiveRecord::ConnectionAdapters::Mysql2Adapter"
    ].freeze

  end
end
