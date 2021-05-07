class Note < ActiveRecord::Base
  include ActiveSnapshot

  belongs_to :post
end
