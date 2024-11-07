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
  end

end
