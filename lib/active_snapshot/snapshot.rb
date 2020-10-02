class Snapshot < ActiveRecord::Base
  self.table_name = "snapshots"

  belongs_to :user, polymorphic: true
  belongs_to :item, polymorphic: true
  has_many :snapshot_items, dependent: :destroy

  validates :item_id, presence: true
  validates :item_type, presence: true
  validates :identifier, presence: true, uniqueness: { scope: [:item_id, :item_type] }

  def metadata
    @metadata ||= begin
      if self[:metadata].present?
        YAML.load(self[:metadata]).with_indifferent_access
      end
    end
  end

  def metadata=(hash)
    hash ||= {}
    hash = hash.with_indifferent_access
    self[:metadata] = hash.to_yaml
    @metadata = hash
  end

  def create_snapshot_item!(item)
    snapshot_items.create!({
      object: self.attributes, 
      identifier: identifier,
      parent_version_id: id,
      item_id: item.id,
      item_type: item.class.name,
    })
  end

  def restore!
    ActiveRecord::Base.transaction do
      ### Cache the child snapshots in a variable for re-use
      cached_snapshot_items = snapshot_items.includes(:item)

      children_to_keep = Set.new

      cached_snapshot_items.each do |snapshot_item|
        key = "#{snapshot_item.item_type} #{snapshot_item.item_id}"
        children_to_keep << key
      end

      ### Destroy or Detach Items not included in this Snapshot's Items
      ### We do this first in case you decide to validate children in ItemSnapshot#restore_item! method
      children_to_snapshot.each do |child_record|
        key = "#{child_record.class.name} #{child_record.id}"
        if !children_to_keep.include?(key)
          item.snapshot_child_delete_function(child_record)
        end
      end

      ### Create or Update Items from Snapshot Items
      cached_snapshot_items.each do |snapshot|
        snapshot.restore_item!
      end

      return true
    end
  end

  class ChildDeleteFunctionNotImplemented < NotImplementedError
    def initialize(klass)
      super("#{klass} must implement the instance method `snapshot_child_delete_item_function`. For example:\n\n#{EXAMPLE_METHOD}")
    end

    EXAMPLE_METHOD = %Q(
      def snapshot_child_delete_item_function(child_record)
        if ['TimeSlot', 'IpAddress'].include?(child_record.class.name)
          ### In this example, we dont want to delete these because they are not independent child records to the parent model so we just "release" them
          item.release!
        else
          item.destroy!
        end
      end
    ).strip.freeze
  end

  class ChildrenToSnapshotNotImplemented < NotImplementedError
    def initialize(klass)
      super("#{klass} must implement the instance method `children_to_snapshot`. For example:\n\n#{EXAMPLE_METHOD}")
    end

    EXAMPLE_METHOD = %Q(
      def children_to_snapshot
        association_names = [
          "posts",
          "books",
          "address",
        ]

        ### We load the current record and all associated records fresh from the database
        instance = self.class.includes(*association_names).find(id)

        child_items = []

        association_names.each do |assoc_name|
          child_items << instance.send(assoc_name)
        end

        ### Flatten and compact the child_items array
        ### has_many associations return an ActiveRecord::Associations::CollectionProxy, so we call `to_a` on them
        child_items = child_items.flat_map{|x| x.respond_to?(:to_a) ? x.to_a : x}

        return child_items.compact
      end
    ).strip.freeze
  end

end
