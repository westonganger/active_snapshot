class VolatilePost < ActiveRecord::Base
  self.table_name = "posts"

  include ActiveSnapshot
end
