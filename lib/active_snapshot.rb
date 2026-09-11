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

  def self.get_deserialized_value(klass, key:, value:)
    return value if value.nil?

    begin
      if klass.respond_to?(:defined_enums) && klass.defined_enums.key?(key)
        # Snapshots created with gem versions <= 0.4.x stored enum attributes as their
        # label (e.g. "published"), newer versions store the database value. `deserialize`
        # expects the database value and would silently turn a label into the enum's
        # first value (e.g. "published".to_i => 0 => "draft"), `cast` accepts both.
        klass.attribute_types[key].cast(value)
      else
        klass.attribute_types[key].deserialize(value)
      end
    rescue ActiveRecord::Encryption::Errors::Base
      # handle columns which are changed from non-encrypted to encrypted
      value
    end
  end
end

ActiveSupport.on_load(:active_record) do
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
