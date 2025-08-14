module ActiveSnapshot
  module Diffable
    extend ActiveSupport::Concern

    class_methods do
      def diff(from:, to:)
        if !from.is_a?(ActiveSnapshot::Snapshot) && !to.is_a?(ActiveSnapshot::Snapshot)
          raise ArgumentError, "At least one of 'from' or 'to' must be an ActiveSnapshot::Snapshot"
        end

        from_item_id, from_item_type = from.is_a?(ActiveSnapshot::Snapshot) ? [from.item_id, from.item_type] : [from.id, from.class.name]
        to_item_id, to_item_type = to.is_a?(ActiveSnapshot::Snapshot) ? [to.item_id, to.item_type] : [to.id, to.class.name]

        if from_item_id != to_item_id || from_item_type != to_item_type
          raise ArgumentError, "Both 'from' and 'to' must reference the same item (item_id and item_type must match)"
        end

        from_snapshot = from.is_a?(ActiveSnapshot::Snapshot) ? from : from.send(:build_snapshot)
        to_snapshot = to.is_a?(ActiveSnapshot::Snapshot) ? to : to.send(:build_snapshot)

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
              changes: item_changes(from: from_snapshot_item, to: nil)
            }
          else
            changes = item_changes(from: from_snapshot_item, to: to_snapshot_item)

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
            changes: item_changes(from: nil, to: to_snapshot_item)
          }
        end

        diffs
      end

      def item_changes(from:, to:)
        from_object = from ? from.object : {}
        to_object = to ? to.object : {}

        keys = (from_object.keys + to_object.keys).uniq

        changes = {}

        keys.each do |key|
          from_value = from_object[key]
          to_value = to_object[key]

          next if to_value == from_value

          changes[key.to_sym] = {
            from: from_value,
            to: to_value
          }
        end

        changes
      end

    end
  end
end
