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
    validates :item_type, presence: true
    validates :object, presence: true

    def object
      return @object if @object

      if ActiveSnapshot.config.storage_method_json?
        @object = super ? JSON.parse(super) : {}
      elsif ActiveSnapshot.config.storage_method_yaml?
        yaml_method = YAML.respond_to?(:unsafe_load) ? :unsafe_load : :load

        @object = super ? YAML.public_send(yaml_method, super) : {}
      elsif ActiveSnapshot.config.storage_method_native_json?
        @object = super
      else
        raise StandardError, "Unsupported storage_method: `#{ActiveSnapshot.config.storage_method}`"
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
