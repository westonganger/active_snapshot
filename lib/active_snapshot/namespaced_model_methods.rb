module ActiveSnapshot
  class NamespacedModelMethods

    def initialize(instance)
      @instance = instance
    end

    def create_snapshot!(identifier, child_records: [], metadata: {})
      parent_version = @instance.create_version!({identifier: identifier, metadata: metadata})

      @instance.child_records.each do |item|
        item.create_version!(identifier: identifier, parent_version_id: parent_version.id, metadata: metadata)
      end

      parent_version
    end

    def restore_snapshot!(parent_version) 
      ActiveRecord::Base.transaction do
        parent_version.restore!

        parent_version.child_versions.each do |version|
          version.restore!
        end

        @instance.reload
        @instance
      end
    end

    def create_version!(identifier:, parent_version_id: nil, metadata: {})
      @instance.snapshots.create!({
        object: @instance.attributes, 
        identifier: identifier,
        parent_version_id: parent_version_id,
        metadata: metadata,
      })
    end

    def destroy_snapshot!(parent_version)
      parent_version.child_versions.destroy_all
      parent_version.destroy
    end

  end
end
