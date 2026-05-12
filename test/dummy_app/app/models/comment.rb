class Comment < ActiveRecord::Base
  include ActiveSnapshot

  if ActiveRecord::VERSION::MAJOR >= 7
    encrypts :content
  end

  belongs_to :post
end
