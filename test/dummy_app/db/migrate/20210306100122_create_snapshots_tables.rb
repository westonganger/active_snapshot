class CreateSnapshotsTables < ActiveRecord::Migration::Current

  def change
    create_table :snapshots do |t|
      t.belongs_to :item, polymorphic: true, null: false, index: true
      t.string :identifier, unique: true, index: true
      t.belongs_to :user, polymorphic: true
      t.text :metadata
      t.datetime :created_at, null: false
    end

    create_table :snapshot_items do |t|
      t.belongs_to :snapshot, null: false, index: true
      t.belongs_to :item, polymorphic: true, null: false, unique: [:snapshot_id], index: true
      t.text :object, null: false
      t.datetime :created_at, null: false
      t.string :child_group_name
    end
  end

end
