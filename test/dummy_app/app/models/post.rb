class Post < ActiveRecord::Base
  include ActiveSnapshot

  has_snapshot_children do
    {}
  end
end
