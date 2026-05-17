class Comment < ActiveRecord::Base
  include ActiveSnapshot

  encrypts :content

  belongs_to :post
end
