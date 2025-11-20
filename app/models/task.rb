class Task < ApplicationRecord
  belongs_to :company
  belongs_to :task_group
end
