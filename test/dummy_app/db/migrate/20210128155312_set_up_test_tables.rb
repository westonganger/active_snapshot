class SetUpTestTables < ActiveRecord::Migration::Current
  def change
    create_table :posts do |t|
      t.integer :a, :b
      t.integer :status, default: 0
      t.timestamps
    end

    create_table :comments do |t|
      t.string :content
      t.references :post
      t.timestamps
    end

    create_table :notes do |t|
      t.string :body
      t.references :post
      t.timestamps
    end

    create_table :tasks do |t|
      t.string :title
      t.references :assignee
      t.references :requester
      t.timestamps
    end

    create_table :users do |t|
      t.string :name
      t.timestamps
    end

    create_table :model_with_serialized_columns do |t|
      t.text :yaml_field
      t.text :json_field
    end

    if connection.adapter_name == "PostgreSQL"
      create_enum :some_enum, ["foo", "bar"]

      create_table :model_with_all_postgres_column_types do |t|
        t.text :text_field
        t.integer :integer_field
        t.date :date_field
        t.time :time_field
        t.timestamp :timestamp_field
        t.boolean :boolean_field
        t.binary :binary_field
        t.json :json_field
        t.jsonb :jsonb_field
        t.inet :inet_field
        t.cidr :cidr_field
        t.macaddr :mac_field
        t.uuid :uuid_field
        t.bit :bit_field, limit: 8
        t.money :money_field
        t.text :text_array_field, array: true
        t.integer :integer_array_field, array: true
        t.enum :enum_array_field, enum_type: :some_enum, array: true
        t.enum :enum_field, enum_type: :some_enum
      end
    end

    if connection.adapter_name == "Mysql2"
      create_table :model_with_all_mysql_column_types do |t|
        t.text :text_field
        t.integer :integer_field
        t.date :date_field
        t.time :time_field
        t.timestamp :timestamp_field
        t.json :json_field
        t.boolean :boolean_field
        t.binary :binary_field
        t.column :enum_field, "ENUM('foo', 'bar')"
      end
    end

    if connection.adapter_name == "SQLite"
      create_table :model_with_all_sqlite_column_types do |t|
        t.text :text_field
        t.integer :integer_field
        t.date :date_field
        t.time :time_field
        t.timestamp :timestamp_field
        t.boolean :boolean_field
        t.binary :binary_field
        t.json :json_field
      end
    end
  end
end
