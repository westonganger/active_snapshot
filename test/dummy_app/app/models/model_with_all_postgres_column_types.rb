class ModelWithAllPostgresColumnTypes < ActiveRecord::Base
  include ActiveSnapshot

  self.table_name = "model_with_all_postgres_column_types"
end
