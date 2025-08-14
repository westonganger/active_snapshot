require "active_snapshot/version"
require "active_snapshot/config"

require 'active_support/lazy_load_hooks'

module ActiveSnapshot
  @@config = ActiveSnapshot::Config.new

  def self.config(&block)
    if block_given?
      block.call(@@config)
    else
      return @@config
    end
  end
end

ActiveSupport.on_load(:active_record) do
  require "active_snapshot/models/concerns/diffable"
  require "active_snapshot/models/snapshot"
  require "active_snapshot/models/snapshot_item"

  require "active_snapshot/models/concerns/snapshots_concern"

  ActiveSnapshot.module_eval do
    extend ActiveSupport::Concern

    included do
      include ActiveSnapshot::SnapshotsConcern
    end
  end
end
