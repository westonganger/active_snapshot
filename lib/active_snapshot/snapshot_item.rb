class SnapshotItem < ActiveRecord::Base
  self.table_name = "snapshot_items"

  belongs_to :snapshot
  belongs_to :item, polymorphic: true

  validates :item_id, uniqueness: { scope: [:snapshot_id, :item_type] }
  validates :item_type, uniqueness: { scope: [:snapshot_id, :item_id] }

  def object
    @object ||= begin
      if self[:object].present?
        YAML.load(self[:object]).with_indifferent_access
      else
        {}
      end
    end
  end

  def object=(hash)
    if hash.nil? || hash.empty?
      self[:object] = nil
      @object = nil
    else
      hash = hash.with_indifferent_access
      self[:object] = hash.to_yaml
      @object = hash
    end
  end

  def restore_item!
    attrs = object

    ### Add custom logic here

    ### If using protected_attributes your going to have to add without_protection: true to both of these assign statements
    if item
      item.assign_attributes(attrs)
      item.save!(validate: false)
    else
      item_type.constantize.new(attrs).save!(validate: false)
    end
  end

end
