class Comment < ActiveRecord::Base
  include ActiveSnapshot

  belongs_to :post
end
