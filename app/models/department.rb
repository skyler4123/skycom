class Department < ApplicationRecord
  include AddressConcern
  include TagConcern

  # --- Associations ---
  belongs_to :company
  belongs_to :category, optional: true

  has_many :role_appointments, as: :appoint_to, dependent: :destroy
  has_many :roles, through: :role_appointments

  has_many :department_appointments, dependent: :destroy
  has_many :employees, through: :department_appointments, source: :appoint_to, source_type: "Employee"
end
