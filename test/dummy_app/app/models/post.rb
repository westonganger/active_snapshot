class Post < ActiveRecord::Base
  include ActiveSnapshot

  has_many :comments

  has_snapshot_children do
    instance = self.class.includes(:comments).find(id)

    {
      comments: instance.comments,
    }
  end
end
