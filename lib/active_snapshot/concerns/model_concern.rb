require "active_snapshot/namespaced_model_methods"

module ActiveSnapshot
  module ModelConcern
    extend ActiveSupport::Concern

    included do
      has_many :snapshot_versions, as: :item, class_name: 'ActiveSnapshot::Version'
    end

    def active_snapshot
      ::ActiveSnapshot::NamespacedModelMethods.new(self)
    end

  end
end
