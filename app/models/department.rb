# frozen_string_literal: true

# Department — Atomic purpose: company-scoped organizational unit that groups
# employees and roles.
#
# Why it exists: HR structure needs a stable unit for department-level roles and
# employee membership, separate from EmployeeGroup (which is more of a team or
# crew).
# How it works: belongs to company/category/property mapping; employees and roles
# join through DepartmentEmployeeAppointment and DepartmentRoleAppointment.
# Addresses, tags, and categories come from concerns.
# Main associations: belongs_to :company (touch), :category, :property_mapping;
# has_many :employees through :department_employee_appointments; has_many :roles
# through :department_role_appointments (both dependent: :destroy).
class Department < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include AddressConcern
  include TagConcern
  include Department::ImageConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  enum :business_type, {
    sales: 0,
    marketing: 1,
    operations: 2,
    finance: 3,
    human_resources: 4,
    information_technology: 5,
    customer_service: 6,
    research_and_development: 7,
    legal: 8,
    administrative: 9
  }, prefix: true

  # --- Associations ---
  belongs_to :company, touch: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :department_role_appointments, dependent: :destroy
  has_many :roles, through: :department_role_appointments

  has_many :department_employee_appointments, dependent: :destroy
  has_many :employees, through: :department_employee_appointments
end
