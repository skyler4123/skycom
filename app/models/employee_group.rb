# frozen_string_literal: true

# EmployeeGroup — Atomic purpose: company-scoped grouping of employees for
# organization, role assignment, and permissions.
#
# Why it exists: employees often share a team/crew/position grouping that should
# carry roles and addresses as a unit, without duplicating per-employee records.
# How it works: belongs to an optional branch and the company; employees join
# through EmployeeEmployeeGroupAppointment, and roles attach through
# EmployeeGroupRoleAppointment. Addresses/tags/categories come from concerns.
# Main associations: belongs_to :company, :category, :property_mapping (required),
# :branch (optional); has_many :employees through
# :employee_employee_group_appointments; has_many :roles through
# :employee_group_role_appointments.
class EmployeeGroup < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include AddressConcern
  include TagConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :employee_employee_group_appointments, dependent: :destroy
  has_many :employees, through: :employee_employee_group_appointments

  has_many :employee_group_role_appointments, dependent: :destroy
  has_many :roles, through: :employee_group_role_appointments

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
end
