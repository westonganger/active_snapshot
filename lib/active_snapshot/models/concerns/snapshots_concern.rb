module ActiveSnapshot
  module SnapshotsConcern
    extend ActiveSupport::Concern

    included do
      ### We do NOT mark these as dependent: :destroy, the developer must manually destroy the snapshots or individual snapshot items
      has_many :snapshots, as: :item, class_name: 'ActiveSnapshot::Snapshot'
      has_many :snapshot_items, as: :item, class_name: 'ActiveSnapshot::SnapshotItem'
    end

    def create_snapshot!(legacy_identifier=nil, identifier: nil, user: nil, metadata: nil)
      if identifier.nil? && legacy_identifier
        identifier = legacy_identifier

        ActiveSupport::Deprecation.warn(LEGACY_POSITIONAL_ARGUMENT_WARNING)
      end

      snapshot = snapshots.create!({
        identifier: identifier,
        user_id: (user.id if user),
        user_type: (user.class.name if user),
        metadata: (metadata || {}),
      })

      snapshot_items = []
      restore_first_items = []

      snapshot_items << snapshot.build_snapshot_item(self)

      snapshot_children = self.children_to_snapshot

      if snapshot_children
        snapshot_children.each do |child_group_name, h|
          h[:records].each do |child_item|
            (h[:restore_first] ? restore_first_items : snapshot_items) << snapshot.build_snapshot_item(child_item, child_group_name: child_group_name)
          end
        end
      end

      ### Prepend restore_first items to account for potential foreign keys
      snapshot_items.unshift(*restore_first_items)

      SnapshotItem.import(snapshot_items, validate: true)

      snapshot
    end

    class_methods do

      def has_snapshot_children(&block)
        if block_given?
          @snapshot_children_proc = block
        else
          @snapshot_children_proc
        end
      end

    end

    def children_to_snapshot
      snapshot_children_proc = self.class.has_snapshot_children

      if !snapshot_children_proc
        return {}
      else
        records = self.instance_exec(&snapshot_children_proc)

        if records.is_a?(Hash)
          records = records.with_indifferent_access
        else
          raise ArgumentError.new("Invalid `has_snapshot_children` definition. Must return a Hash")
        end

        snapshot_children = {}.with_indifferent_access

        records.each do |assoc_name, opts|
          snapshot_children[assoc_name] = {}

          if opts.nil?
            ### nil is allowed value in case has_one/belongs_to is nil, etc.
            snapshot_children[assoc_name][:records] = []

          elsif opts.is_a?(ActiveRecord::Base)
            ### Support belongs_to / has_one
            snapshot_children[assoc_name][:records] = [opts]

          elsif opts.is_a?(ActiveRecord::Relation) || opts.is_a?(Array)
            snapshot_children[assoc_name][:records] = opts

          elsif opts.is_a?(Hash)
            opts = opts.with_indifferent_access

            if opts.has_key?(:records)
              records = opts[:records]
            elsif opts.has_key?(:record)
              records = opts[:record]
            end

            if records.nil?
              # Do nothing, allow nil value in case a has_one/belong_to returns nil, etc.
            elsif records
              if records.respond_to?(:to_a)
                records = records.to_a
              else
                records = [records]
              end

              snapshot_children[assoc_name][:records] = records
            else
              raise ArgumentError.new("Invalid `has_snapshot_children` definition. Must define a :records key for each child association.")
            end

            delete_method = opts[:delete_method]

            if delete_method.present? && delete_method.to_s != "default"
              if delete_method.respond_to?(:call)
                snapshot_children[assoc_name][:delete_method] = delete_method
              else
                raise ArgumentError.new("Invalid `has_snapshot_children` definition. Invalid :delete_method argument. Must be a Lambda / Proc")
              end
            end

            restore_first = opts[:restore_first]

            if restore_first.present?
              if [true, false].include? restore_first
                snapshot_children[assoc_name][:restore_first] = restore_first
              else
                raise ArgumentError.new("Invalid `has_snapshot_children` definition. Invalid :restore_first argument. Must be a Boolean.")
              end
            end
          else
            raise ArgumentError.new("Invalid `has_snapshot_children` definition. Invalid :records argument. Must be a Hash or Array")
          end
        end

        return snapshot_children
      end
    end

    LEGACY_POSITIONAL_ARGUMENT_WARNING = "Supplying the snapshots :identifier as a positional argument is now deprecated and will be removed in upcoming versions. Please supply the snapshot identifier using the :identifier keyword argument instead.".freeze

  end
end
