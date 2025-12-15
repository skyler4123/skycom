class EmployeeGroup < ApplicationRecord
  belongs_to :company_group
  belongs_to :company, optional: true

  has_many :tag_appointments, as: :appoint_to, dependent: :destroy
  has_many :tags, through: :tag_appointments

  has_many :employee_group_appointments, dependent: :destroy
  has_many :employees, through: :employee_group_appointments, source: :appoint_to, source_type: "Employee"

  has_many :role_appointments, as: :appoint_to, dependent: :destroy
  has_many :roles, through: :role_appointments
end
