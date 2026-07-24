class ModelWithSerializedColumns < ActiveRecord::Base
  include ActiveSnapshot

  self.table_name = "model_with_serialized_columns"

  serialize :yaml_field, coder: YAML
  serialize :json_field, coder: JSON
end
