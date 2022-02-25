class ParentWithoutChildren < ApplicationRecord
  include ActiveSnapshot

  self.table_name = "posts"
end
