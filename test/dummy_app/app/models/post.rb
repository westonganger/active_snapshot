class Post < ActiveRecord::Base
  include SnapshotsConcern

  has_snapshot_children do
    {}
  end
end
