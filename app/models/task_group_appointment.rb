class TaskGroupAppointment < ApplicationRecord
  belongs_to :task_group
  belongs_to :appoint_from, polymorphic: true
  belongs_to :appoint_to, polymorphic: true
  belongs_to :appoint_for, polymorphic: true
  belongs_to :appoint_by, polymorphic: true
end
