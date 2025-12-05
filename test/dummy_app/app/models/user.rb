class User < ApplicationRecord

  has_many :tasks_as_requester, class_name: "Task", foreign_key: :requester_id
  has_many :tasks_as_assignee, class_name: "Task", foreign_key: :assignee_id

end
