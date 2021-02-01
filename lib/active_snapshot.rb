require "active_record"
require "activerecord-import"

require "active_snapshot/version"

require "active_snapshot/models/snapshot"
require "active_snapshot/models/snapshot_item"

require "active_snapshot/concerns/snapshots_concern"

module ActiveSnapshot
  extend ActiveSupport::Concern

  included do
    include ActiveSnapshot::SnapshotsConcern
  end
end
