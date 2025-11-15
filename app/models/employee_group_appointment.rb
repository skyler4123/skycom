class EmployeeGroupAppointment < ApplicationRecord
  belongs_to :employee_group
  belongs_to :appoint_to, polymorphic: true
end
