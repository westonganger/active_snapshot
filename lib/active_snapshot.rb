require "active_snapshot/version"

require "active_record"

require "active_snapshot/version_model"
require "active_snapshot/model_concern"

module ActiveSnapshot
  class Error < StandardError; end
end

ActiveSupport.on_load(:active_record) do
  include ActiveSnapshot::ModelConcern
end
