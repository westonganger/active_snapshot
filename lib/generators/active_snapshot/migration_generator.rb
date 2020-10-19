require "rails/generators"
require "rails/generators/active_record"

module ActiveSnapshot
  # Basic structure to support a generator that builds a migration
  class MigrationGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    def self.next_migration_number(dirname)
      ::ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    protected

    def add_migration(template_name, opts = {})
      @template_name = template_name

      @migration_path ||= "db/migrate"

      if self.class.migration_exists?(@migration_path, template_name)
        Kernel.warn "Migration already exists: #{template_name}"
      else
        migration_template(
          "#{template_name}.rb.erb",
          File.join(@migration_path, "#{template_name}.rb"),
          { 
            migration_version: migration_version, 
          }.merge(opts)
        )
      end
    end

    def migration_version
      "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
    end

    def migration_name
      @template_name.titleize.gsub(' ', '')
    end

    private

    MYSQL_ADAPTERS = [
      "ActiveRecord::ConnectionAdapters::MysqlAdapter", # Used by gems: `mysql`, `activerecord-jdbcmysql-adapter`.
      "ActiveRecord::ConnectionAdapters::Mysql2Adapter", # Used by `mysql2` gem.
    ].freeze

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

  end
end
