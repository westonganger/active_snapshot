module ActiveSnapshot
  module Diffable
    extend ActiveSupport::Concern

    class_methods do
      def diff(from, to)
        unless from.is_a?(Snapshot)
          raise ArgumentError, "'from' must be an ActiveSnapshot::Snapshot"
        end

        to_item_id, to_item_type = to.is_a?(Snapshot) ? [to.item_id, to.item_type] : [to.id, to.class.name]

        if from.item_id != to_item_id || from.item_type != to_item_type
          raise ArgumentError, "Both records must reference the same item"
        end

        if to.is_a?(Snapshot) && from.created_at > to.created_at
          raise ArgumentError, "'to' must be a newer snapshot than 'from'"
        end

        from_snapshot = from
        to_snapshot = to.is_a?(Snapshot) ? to : Snapshot.build_snapshot(to)

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
  end
end
