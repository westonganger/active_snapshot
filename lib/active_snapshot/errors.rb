module ActiveSnapshot
  module Errors

    class SnapshotChildDeleteFunctionNotImplemented < NotImplementedError
      def initialize(klass)
        super("#{klass} must implement the instance method `snapshot_child_delete_item_function`. For example:\n\n#{EXAMPLE_METHOD}")
      end

      EXAMPLE_METHOD = <<~EOF
        def snapshot_child_delete_item_function(child_record)
          if ['TimeSlot', 'IpAddress'].include?(child_record.class.name)
            ### In this example, we dont want to delete these because they are not independent child records to the parent model so we just "release" them
            item.release!
          else
            item.destroy!
          end
        end
      EOF
    end

    class ChildrenToSnapshotNotImplemented < NotImplementedError
      def initialize(klass)
        super("#{klass} must implement the instance method `children_to_snapshot`. For example:\n\n#{EXAMPLE_METHOD}")
      end

      EXAMPLE_METHOD = <<~EOF
        def children_to_snapshot
          association_names = [
            "posts",
            "books",
            "address",
          ]

          ### We load the current record and all associated records fresh from the database
          instance = self.class.includes(*association_names).find(id)

          child_items = []

          association_names.each do |assoc_name|
            child_items << instance.send(assoc_name)
          end

          ### Flatten and compact the child_items array
          ### has_many associations return an ActiveRecord::Associations::CollectionProxy, so we call `to_a` on them
          child_items = child_items.flat_map{|x| x.respond_to?(:to_a) ? x.to_a : x}

          return child_items.compact
        end
      EOF
    end

  end
end
