module ActiveSnapshot
  module SnapshotsConcern
    extend ActiveSupport::Concern

    included do
      ### We do NOT mark these as dependent: :destroy, the developer must manually destroy the snapshots or individual snapshot items
      has_many :snapshots, as: :item, class_name: 'ActiveSnapshot::Snapshot'
      has_many :snapshot_items, as: :item, class_name: 'ActiveSnapshot::SnapshotItem'
    end

    def create_snapshot!(identifier, user: nil, metadata: nil)
      snapshot = snapshots.create!({
        identifier: identifier,
        user_id: (user.id if user),
        user_type: (user.class.name if user),
        metadata: (metadata || {}),
      })

      snapshot_items = []

      snapshot_items << snapshot.build_snapshot_item(self)

      snapshot_children = self.class.has_snapshot_children

      if snapshot_children
        snapshot_children.each do |child_group_name, h|
          h[:records].each do |child_item|
            snapshot_items << snapshot.build_snapshot_item(child_item, child_group_name: child_group_name)
          end
        end
      end

      SnapshotItem.import(snapshot_items, validate: true)

      snapshot
    end

    class_methods do

      def has_snapshot_children(&block)
        if !block_given? && !defined?(@snapshot_children_proc)
          raise ArgumentError.new("Invalid `has_snapshot_children` requires block to be defined")

        elsif block_given?
          @snapshot_children_proc = block

        elsif @snapshot_children_proc
          records = @snapshot_children_proc.call

          if records.is_a?(Hash)
            records = records.with_indifferent_access
          else
            raise ArgumentError.new("Invalid `has_snapshot_children` definition. Must return a Hash")
          end

          snapshot_children = {}

          records.each do |assoc_name, opts|
            snapshot_children[assoc_name] = {}

            if opts.is_a?(Array)
              snapshot_children[assoc_name][:records] = opts

            elsif opts.is_a?(Hash)
              opts = opts.with_indifferent_access

              records = opts[:records] || opts[:record]

              if records
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

            else
              raise ArgumentError.new("Invalid `has_snapshot_children` definition. Invalid :records argument. Must be a Hash or Array")
            end

            return snapshot_children
          end
        end
      end

    end

  end
end
