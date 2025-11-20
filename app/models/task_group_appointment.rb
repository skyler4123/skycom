class TaskGroupAppointment < ApplicationRecord
  belongs_to :assessment
  belongs_to :appoint_from, polymorphic: true
  belongs_to :appoint_to, polymorphic: true
  belongs_to :appoint_for, polymorphic: true
end
