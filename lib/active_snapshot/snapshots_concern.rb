module SnapshotsConcern
  extend ActiveSupport::Concern

  included do
    ### We do NOT mark these as dependent: :destroy, the developer must manually destroy the snapshots or individual snapshot items
    has_many :snapshots, as: :item, class_name: 'Snapshot'
    has_many :snapshot_items, as: :item, class_name: 'SnapshotItem' 
  end

  ### Abstract Method
  def children_to_snapshot
    raise Snapshot::ChildrenToSnapshotNotImplemented.new(self.class)
  end

  def child_delete_function
    raise Snapshot::ChildDeleteFunctionNotImplemented.new(self.class)
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
