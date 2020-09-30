class ParentModel < ApplicationRecord

  has_many :child_models

  def children_to_snapshot
    association_names = [
      "child_models",
    ]

    ### We load the current record and all associated records fresh from the database
    instance = self.class.includes(*association_names).find(id)

    child_items = [] 

    association_names.each do |assoc_name|
      child_items << instance.send(assoc_name)
    end

    child_items = child_items.flat_map{|x| x.respond_to?(:to_a) ? x.to_a : x}

    return child_items.compact
  end

  def snapshot_child_delete_function(child_record)
    child_record.destroy!
  end

end
