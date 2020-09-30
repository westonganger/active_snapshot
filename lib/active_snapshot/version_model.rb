module ActiveSnapshot
  class Version < ::ActiveRecord::Base
    self.table_name = "active_snapshot_versions"

    belongs_to :item, polymorphic: true
    belongs_to :parent_version, class_name: 'ActiveSnapshot::Version', optional: true
    has_many :child_versions, class_name: 'ActiveSnapshot::Version', foreign_key: :parent_version_id

    validates :item_id, presence: true
    validates :item_type, presence: true
    validates :identifier, presence: true

    def restore!
      attrs = object

      if item
        item.update!(attrs)
      else
        item_type.constantize.create!(attrs)
      end
    end

  end
end
