class Task < ApplicationRecord

  include ActiveSnapshot

  belongs_to :requester, class_name: "User"
  belongs_to :assignee, class_name: "User"

  has_snapshot_children do
    { requester: requester, assignee: assignee }
  end

end
