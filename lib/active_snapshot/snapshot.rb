module ActiveSnapshot
  class Snapshot < ActiveRecord::Base
    self.table_name = "snapshots"

    if defined?(ProtectedAttributes)
      attr_accessible :item_id, :item_type, :identifier, :user_id, :user_type
    end

    belongs_to :user, polymorphic: true
    belongs_to :item, polymorphic: true
    has_many :snapshot_items, class_name: 'ActiveSnapshot::SnapshotItem', dependent: :destroy

    validates :item_id, presence: true
    validates :item_type, presence: true
    validates :identifier, presence: true, uniqueness: { scope: [:item_id, :item_type] }
    validates :user_type, presence: true, if: :user_id

    def metadata
      @metadata ||= self[:metadata].with_indifferent_access
    end

    def build_snapshot_item(item, child_group_name: nil)
      self.snapshot_items.new({
        object: self.attributes, 
        identifier: identifier,
        item_id: item.id,
        item_type: item.class.name,
        child_group_name: child_group_name,
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
          snapshot_children.each do |child_group_name, h|
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
      reified_children_hash = {}.with_indifferent_access

      reified_parent = nil

      snapshot_items.each do |si| 
        reified_item = si.item_type.constantize.new(si.object)

        reified_item.readonly!

        key = si.child_group_name

        if key
          reified_children_hash[key] ||= []

          reified_children_hash[key] << reified_item

        elsif [self.item_id, self.item_type] == [si.item_id, si.item_type]
          reified_parent = reified_item
        end
      end

      return [reified_parent, reified_children_hash]
    end

    class ChildrenDefinitionError < ArgumentError

      def initialize(msg)
        super("Invalid `has_snapshot_children` definition. #{msg}. For example: \n\n#{EXAMPLE}").gsub("..", ".")
      end

      EXAMPLE = %Q(
        has_snapshot_children do
          ### Executed in the context of the instance / self

          ### In this example we just load the current record and all associated records fresh 
          ### from the database to take advantage of all association preloading / includes
          
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
end
