class CreateSnapshotsTables < ActiveRecord::Migration[6.0]

  def change
    create_table :snapshots do |t|
      t.belongs_to :item, polymorphic: true, null: false, index: true
      t.string :identifier, null: false, unique: true, index: true
      t.belongs_to :user, polymorphic: true
      t.jsonb :metadata
      t.datetime :created_at, null: false
      t.text :children_types
    end

    create_table :snapshot_items do |t|
      t.belongs_to :snapshot, null: false, index: true
      t.belongs_to :item, polymorphic: true, null: false, unique: [:snapshot_id], index: true
      t.jsonb :object, null: false
      t.datetime :created_at, null: false
      t.string :child_type
    end
  end

end
