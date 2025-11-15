class Tag < ApplicationRecord
  belongs_to :company

  has_many :tag_appointments, dependent: :destroy
  has_many :employee_groups, through: :tag_appointments, source: :appoint_to, source_type: "EmployeeGroup"
  has_many :employees, through: :tag_appointments, source: :appoint_to, source_type: "Employee"

end
