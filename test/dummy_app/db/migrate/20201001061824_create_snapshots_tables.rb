class CreateSnapshotsTables < ActiveRecord::Migration[6.0]

  # The largest text column available in all supported RDBMS is 1024^3 - 1 bytes, roughly one gibibyte.  We specify a size
  # so that MySQL will use `longtext` instead of `text`.  Otherwise, when serializing very large objects, `text` might not be big enough.
  TEXT_BYTES = 1_073_741_823

  def change
    create_table :snapshots do |t|
      t.belongs_to :item, polymorphic: true, null: false, index: true
      t.string :identifier, null: false, unique: true, index: true
      t.belongs_to :user, polymorphic: true
      t.text :metadata, limit: TEXT_BYTES
      t.datetime :created_at, null: false
    end

    create_table :snapshot_items do |t|
      t.belongs_to :snapshot, null: false, index: true
      t.belongs_to :item, polymorphic: true, null: false, unique: [:snapshot_id], index: true
      t.text :object, limit: TEXT_BYTES
      t.datetime :created_at, null: false
    end
  end

end
