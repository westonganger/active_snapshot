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

  def build_snapshot_item(item, child_type: nil)
    snapshot_items.new({
      object: self.attributes, 
      identifier: identifier,
      parent_version_id: id,
      item_id: item.id,
      item_type: item.class.name,
      child_type: child_type,
    })
  end

  def restore!
    ActiveRecord::Base.transaction do
      ### Cache the child snapshots in a variable for re-use
      cached_snapshot_items = snapshot_items.includes(:item)

      snapshot_children = item.class.has_snapshot_children

      if snapshot_children
        children_to_keep = Set.new

        cached_snapshot_items.each do |snapshot_item|
          key = "#{snapshot_item.item_type} #{snapshot_item.item_id}"
          children_to_keep << key
        end

        ### Destroy or Detach Items not included in this Snapshot's Items
        ### We do this first in case you later decide to validate children in ItemSnapshot#restore_item! method
        snapshot_children.each do |child_type, h|
          delete_method = h[:delete_method] || ->(child_record){ child_record.destroy! }

          h[:records].each do |child_record|
            key = "#{child_record.class.name} #{child_record.id}"

            if children_to_keep.exclude?(key)
              delete_method.call(child_record)
            end
          end
        end
      end

      ### Create or Update Items from Snapshot Items
      cached_snapshot_items.each do |snapshot_item|
        snapshot_item.restore_item!
      end
    end

    return true
  end

  def fetch_reified_items
    snapshot_items.map{|x| x.item_type.constantize.new(x.object); x.readonly!; x}
  end

  class ChildrenDefinitionError < ArgumentError
    def initialize(msg)
      super("Invalid `has_snapshot_children` definition. #{msg}. For example: \n\n#{EXAMPLE}")
    end

    EXAMPLE = %Q(
      has_snapshot_children do
        ### Executed in the context of the instance / self

        ### In this example we just load the current record and all associated records fresh from the database
        instance = self.class.includes(:comments, :ip_address).find(id)
        
        {
          comments: instance.comments,
          tags: {
            records: instance.tags
          },
          ip_address: {
            record: instance.ip_address,
            delete_method: ->(item){ item.release! }
          }
        }
      end
    ).strip.freeze
  end

end
