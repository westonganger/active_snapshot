module ActiveSnapshot
  class SnapshotItem < ActiveRecord::Base
    self.table_name = "snapshot_items"

    self.belongs_to_required_by_default = true ### global config option not working, https://github.com/rails/rails/issues/27844

    if defined?(ProtectedAttributes)
      attr_accessible :object, :item_id, :item_type, :child_group_name
    end

    belongs_to :snapshot, class_name: 'ActiveSnapshot::Snapshot'
    belongs_to :item, polymorphic: true

    validates :snapshot_id, presence: true
    validates :item_id, presence: true, uniqueness: { scope: [:snapshot_id, :item_type] }
    validates :item_type, presence: true, uniqueness: { scope: [:snapshot_id, :item_id] }

    def object
      return @object if @object

      if ActiveSnapshot.config.storage_method_json?
        @object = JSON.parse(self[:object])
      elsif ActiveSnapshot.config.storage_method_yaml?
        yaml_method = "unsafe_load"

        if !YAML.respond_to?("unsafe_load")
          yaml_method = "load"
        end

        @object = YAML.send(yaml_method, self[:object])
      elsif ActiveSnapshot.config.storage_method_native_json?
        @object = self[:object]
      end
    end

    def object=(h)
      @object = nil

      if ActiveSnapshot.config.storage_method_json?
        self[:object] = h.to_json
      elsif ActiveSnapshot.config.storage_method_yaml?
        self[:object] = YAML.dump(h)
      elsif ActiveSnapshot.config.storage_method_native_json?
        self[:object] = h
      end
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
