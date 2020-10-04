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

end
