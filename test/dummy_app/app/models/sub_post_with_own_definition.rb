class SubPostWithOwnDefinition < Post
  # Ignores snapshot children definition from base class, and defines its own
  has_snapshot_children do
    { comments: comments }
  end
end
