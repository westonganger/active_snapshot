class ModelWithAllSqliteColumnTypes < ActiveRecord::Base
  include ActiveSnapshot

  self.table_name = "model_with_all_sqlite_column_types"

  attribute :binary_field, :string
end
