class Post < ActiveRecord::Base
  include ActiveSnapshot

  has_many :comments
  has_many :notes

  has_snapshot_children do
    instance = self.class.includes(:comments, :notes).find(id)

    {
      comments: instance.comments,
      notes: instance.notes,
      nil_assoc: nil,
    }
  end
end
