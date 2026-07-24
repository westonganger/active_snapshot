class ModelWithAllMysqlColumnTypes < ActiveRecord::Base
  include ActiveSnapshot

  self.table_name = "model_with_all_mysql_column_types"

  attribute :binary_field, :string
end
