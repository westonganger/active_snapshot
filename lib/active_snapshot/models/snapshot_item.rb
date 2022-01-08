module ActiveSnapshot
  class SnapshotItem < ActiveRecord::Base
    self.table_name = "snapshot_items"

    if defined?(ProtectedAttributes)
      attr_accessible :object, :item_id, :item_type, :child_group_name
    end

    belongs_to :snapshot, class_name: 'ActiveSnapshot::Snapshot'
    belongs_to :item, polymorphic: true

    validates :snapshot_id, presence: true
    validates :item_id, presence: true, uniqueness: { scope: [:snapshot_id, :item_type] }
    validates :item_type, presence: true, uniqueness: { scope: [:snapshot_id, :item_id] }

    def object
      yaml_method = "unsafe_load"

      if !YAML.respond_to?("unsafe_load")
        yaml_method = "load"
      end

      @metadata ||= YAML.send(yaml_method, self[:object]).with_indifferent_access
    end

    def object=(h)
      @object = nil
      self[:object] = YAML.dump(h)
    end

    def restore_item!
      ### Add any custom logic here
      
      if !item
        item_klass = item_type.constantize

        self.item = item_klass.new
      end

      item.assign_attributes(object)

      item.save!(validate: false, touch: false)
    end

  end
end
