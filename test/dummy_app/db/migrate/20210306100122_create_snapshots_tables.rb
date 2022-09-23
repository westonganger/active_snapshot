class CreateSnapshotsTables < ActiveRecord::Migration::Current

  def change
    create_table :snapshots do |t|
      t.belongs_to :item, polymorphic: true, null: false, index: true
      t.string :identifier, unique: true, index: true
      t.belongs_to :user, polymorphic: true

      if ActiveSnapshot.config.storage_method_native_json?
        t.json :metadata
      else
        t.text :metadata
      end

      t.datetime :created_at, null: false
    end

    create_table :snapshot_items do |t|
      t.belongs_to :snapshot, null: false, index: true
      t.belongs_to :item, polymorphic: true, null: false, unique: [:snapshot_id], index: true

      if ActiveSnapshot.config.storage_method_native_json?
        t.json :object, null: false
      else
        t.text :object, null: false
      end

      t.datetime :created_at, null: false
      t.string :child_group_name
    end
  end

end
