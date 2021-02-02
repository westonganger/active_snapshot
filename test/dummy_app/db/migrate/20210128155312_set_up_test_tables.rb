class SetUpTestTables < ActiveRecord::Migration::Current

  def change
    create_table :posts do |t|
      t.integer :a, :b
    end
  end

end
