module SnapshotsConcern
  extend ActiveSupport::Concern

  included do
    has_many :snapshots, as: :item, class_name: 'Snapshot', dependent: :destroy
    has_many :snapshot_items, as: :item, class_name: 'SnapshotItem' ### Do NOT add dependent: :destroy, this will break restore functionality
  end

  ### Abstract Method
  def children_to_snapshot
    raise ActiveSnapshot::Errors::ChildrenToSnapshotNotImplemented.new(self.class)
  end

  def child_delete_function
    raise ActiveSnapshot::Errors::ChildDeleteFunctionNotImplemented.new(self.class)
  end

  def create_snapshot!(identifier, user: nil, metadata: nil)
    snapshot = snapshots.create!({
      identifier: identifier,
      user_id: (user.id if user),
      user_type: (user.class.name if user),
      metadata: (metadata || {}),
    })

    snapshot_items = []

    snapshot_item << snapshot.build_snapshot_item!(self)

    self.children_to_snapshot.each do |child_item|
      snapshot_items << snapshot.create_snapshot_item!(child_item)
    end

    SnapshotItem.import(snapshot_items, validate: true)

    snapshot
  end

end

ActiveSupport.on_load(:active_record) do
  include SnapshotsConcern
end
