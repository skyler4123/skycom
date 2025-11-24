class Tag < ApplicationRecord
  belongs_to :company

  has_many :tag_appointments, dependent: :destroy
  has_many :employee_groups, through: :tag_appointments, source: :appoint_to, source_type: "EmployeeGroup"
  has_many :employees, through: :tag_appointments, source: :appoint_to, source_type: "Employee"
  has_many :customer_groups, through: :tag_appointments, source: :appoint_to, source_type: "CustomerGroup"
  has_many :customers, through: :tag_appointments, source: :appoint_to, source_type: "Customer"
  has_many :service_groups, through: :tag_appointments, source: :appoint_to, source_type: "ServiceGroup"
  has_many :services, through: :tag_appointments, source: :appoint_to, source_type: "Service"
  has_many :facility_groups, through: :tag_appointments, source: :appoint_to, source_type: "FacilityGroup"
  has_many :facilities, through: :tag_appointments, source: :appoint_to, source_type: "Facility"

end
