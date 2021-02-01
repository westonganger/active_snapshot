if defined?(ActiveRecord::Migration::Current)
  migration_klass = ActiveRecord::Migration::Current
else
  migration_klass = ActiveRecord::Migration
end

class SetUpTestTables < migration_klass

  def change
    create_table :posts do |t|
      t.integer :a, :b
    end
  end

end
