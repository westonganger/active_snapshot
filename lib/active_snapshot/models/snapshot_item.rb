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

      if ActiveSnapshot.config.storage_method_serialized_json?
        # for legacy active_snapshot configurations only
        @object = self[:object] ? JSON.parse(self[:object]) : {}
      elsif ActiveSnapshot.config.storage_method_yaml?
        # for legacy active_snapshot configurations only
        yaml_method = YAML.respond_to?(:unsafe_load) ? :unsafe_load : :load

        @object = self[:object] ? YAML.public_send(yaml_method, self[:object]) : {}
      else
        @object = self[:object]
      end
    end

    def object=(h)
      @object = nil

      if ActiveSnapshot.config.storage_method_serialized_json?
        # for legacy active_snapshot configurations only
        self[:object] = h.to_json
      elsif ActiveSnapshot.config.storage_method_yaml?
        # for legacy active_snapshot configurations only
        self[:object] = YAML.dump(h)
      else
        self[:object] = h
      end
    end

    def restore_item!
      ### Add any custom logic here

      if !item
        item_klass = item_type.constantize

        self.item = item_klass.new
      end

      object.each do |k,v|
        if item.respond_to?("#{k}=")
          item[k] = v
        else
          # database column was likely dropped since the snapshot was created
        end
      end

      item.save!(validate: false, touch: false)
    end

  end
end
