class Post < ActiveRecord::Base
  include ActiveSnapshot

  has_many :comments

  has_snapshot_children do
    {}
  end
end
