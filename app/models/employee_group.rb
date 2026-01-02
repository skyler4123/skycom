class EmployeeGroup < ApplicationRecord
  include AddressConcern
  include TagConcern

  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true
  belongs_to :category, optional: true

  has_many :employee_group_appointments, dependent: :destroy
  has_many :employees, through: :employee_group_appointments, source: :appoint_to, source_type: "Employee"

  has_many :role_appointments, as: :appoint_to, dependent: :destroy
  has_many :roles, through: :role_appointments
end
