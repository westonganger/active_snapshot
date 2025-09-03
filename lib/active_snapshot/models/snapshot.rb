module ActiveSnapshot
  class Snapshot < ActiveRecord::Base
    self.table_name = "snapshots"

    if defined?(ProtectedAttributes)
      attr_accessible :item_id, :item_type, :identifier, :user_id, :user_type
    end

    belongs_to :user, polymorphic: true, optional: true
    belongs_to :item, polymorphic: true
    has_many :snapshot_items, class_name: 'ActiveSnapshot::SnapshotItem', dependent: :destroy

    validates :item_id, presence: true
    validates :item_type, presence: true
    validates :identifier, uniqueness: { scope: [:item_id, :item_type], allow_nil: true}
    validates :user_type, presence: true, if: :user_id

    class << self
      def build_snapshot(resource, identifier: nil, user: nil, metadata: nil)
        snapshot = resource.snapshots.build({
          identifier: identifier,
          user_id: (user.id if user),
          user_type: (user.class.name if user),
          metadata: (metadata || {}),
        })

        snapshot.build_snapshot_item(resource)

        snapshot_children = resource.children_to_snapshot

        snapshot_children&.each do |child_group_name, h|
          h[:records].each do |child_item|
            snapshot.build_snapshot_item(child_item, child_group_name: child_group_name)
          end
        end

        snapshot
      end

      def diff(from, to)
        if !from.is_a?(Snapshot)
          raise ArgumentError.new("'from' must be an ActiveSnapshot::Snapshot")
        end

        to_item_id, to_item_type = to.is_a?(Snapshot) ? [to.item_id, to.item_type] : [to.id, to.class.name]

        if from.item_id != to_item_id || from.item_type != to_item_type
          raise ArgumentError.new("Both records must reference the same item")
        end

        if to.is_a?(Snapshot) && from.created_at > to.created_at
          raise ArgumentError.new("'to' must be a newer snapshot than 'from'")
        end

        from_snapshot = from
        to_snapshot = to.is_a?(Snapshot) ? to : build_snapshot(to)

        from_snapshot_items = from_snapshot.snapshot_items
        to_snapshot_items = to_snapshot.snapshot_items

        diffs = []

        from_snapshot_items.each do |from_snapshot_item|
          to_snapshot_item = to_snapshot_items.find do |item|
            item.item_id == from_snapshot_item.item_id && item.item_type == from_snapshot_item.item_type
          end

          if to_snapshot_item.nil?
            diffs << {
              action: :destroy,
              item_id: from_snapshot_item.item_id,
              item_type: from_snapshot_item.item_type,
              changes: snapshot_item_changes(from_snapshot_item, nil)
            }
          else
            changes = snapshot_item_changes(from_snapshot_item, to_snapshot_item)

            next if changes.empty?

            diffs << {
              action: :update,
              item_id: from_snapshot_item.item_id,
              item_type: from_snapshot_item.item_type,
              changes: changes
            }
          end
        end

        to_snapshot_items.each do |to_snapshot_item|
          from_snapshot_item = from_snapshot_items.find do |item|
            item.item_id == to_snapshot_item.item_id && item.item_type == to_snapshot_item.item_type
          end

          next if from_snapshot_item.present?

          diffs << {
            action: :create,
            item_id: to_snapshot_item.item_id,
            item_type: to_snapshot_item.item_type,
            changes: snapshot_item_changes(nil, to_snapshot_item)
          }
        end

        diffs
      end

      private

      def snapshot_item_changes(from, to)
        from_object = from ? from.object : {}
        to_object = to ? to.object : {}

        keys = (from_object.keys + to_object.keys).uniq

        changes = {}

        keys.each do |key|
          from_value = from_object[key]
          to_value = to_object[key]

          next if to_value == from_value

          changes[key.to_sym] = [from_value, to_value]
        end

        changes
      end
    end

    def metadata
      return @metadata if @metadata

      if ActiveSnapshot.config.storage_method_serialized_json?
        # for legacy active_snapshot configurations only
        @metadata = JSON.parse(self[:metadata])
      elsif ActiveSnapshot.config.storage_method_yaml?
        # for legacy active_snapshot configurations only
        yaml_method = "unsafe_load"

        if !YAML.respond_to?("unsafe_load")
          yaml_method = "load"
        end

        @metadata = YAML.send(yaml_method, self[:metadata])
      else
        @metadata = self[:metadata]
      end
    end

    def metadata=(h)
      @metadata = nil

      if ActiveSnapshot.config.storage_method_serialized_json?
        # for legacy active_snapshot configurations only
        self[:metadata] = h.to_json
      elsif ActiveSnapshot.config.storage_method_yaml?
        # for legacy active_snapshot configurations only
        self[:metadata] = YAML.dump(h)
      else
        self[:metadata] = h
      end
    end

    def build_snapshot_item(instance, child_group_name: nil)
      attrs = instance.attributes

      if instance.class.defined_enums.any?
        instance.class.defined_enums.slice(*attrs.keys).each do |enum_col_name, enum_mapping|
          val = attrs.fetch(enum_col_name)
          next if val.nil?
          attrs[enum_col_name] = enum_mapping.fetch(val)
        end
      end

      self.snapshot_items.new({
        object: attrs,
        item_id: instance.id,
        item_type: instance.class.name,
        child_group_name: child_group_name,
      })
    end

    def restore!
      ActiveRecord::Base.transaction do
        ### Cache the child snapshots in a variable for re-use
        cached_snapshot_items = snapshot_items.includes(:item)

        existing_snapshot_children = item ? item.children_to_snapshot : []

        if existing_snapshot_children.any?
          children_to_keep = Set.new

          cached_snapshot_items.each do |snapshot_item|
            key = "#{snapshot_item.item_type} #{snapshot_item.item_id}"

            children_to_keep << key
          end

          ### Destroy or Detach Items not included in this Snapshot's Items
          ### We do this first in case you later decide to validate children in ItemSnapshot#restore_item! method
          existing_snapshot_children.each do |child_group_name, h|
            delete_method = h[:delete_method] || ->(child_record){ child_record.destroy! }

            h[:records].each do |child_record|
              child_record_id = child_record.send(child_record.class.send(:primary_key))

              key = "#{child_record.class.name} #{child_record_id}"

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

    def fetch_reified_items(readonly: true)
      reified_children_hash = {}.with_indifferent_access

      reified_parent = nil

      snapshot_items.each do |si|
        reified_item = si.item_type.constantize.new

        si.object.each do |k,v|
          if reified_item.respond_to?("#{k}=")
            reified_item[k] = v
          else
            # database column was likely dropped since the snapshot was created
          end
        end

        if readonly
          reified_item.readonly!
        end

        key = si.child_group_name

        if key
          reified_children_hash[key] ||= []

          reified_children_hash[key] << reified_item

        elsif self.item_id == si.item_id && (self.item_type == si.item_type || si.item_type.constantize.new.is_a?(self.item_type.constantize))
          reified_parent = reified_item
        end
      end

      return [reified_parent, reified_children_hash]
    end

  end
end
