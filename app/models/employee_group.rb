# frozen_string_literal: true

# EmployeeGroup — Atomic purpose: company-scoped team grouping of employees with
# one manager.
#
# Why it exists: employees often share a team/crew grouping that should carry a
# manager, roles, and addresses as a unit, without duplicating per-employee
# records.
# How it works: belongs to an optional branch, the company, and an optional
# manager (an Employee, independent of the "Manager" role); employees join
# through EmployeeEmployeeGroupAppointment, and roles attach through
# EmployeeGroupRoleAppointment. Manager changes clear the members' cached manager
# lookups. Addresses/tags/categories come from concerns.
# Main associations: belongs_to :company, :category, :property_mapping (required),
# :branch and :manager (optional); has_many :employees through
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
  belongs_to :manager, class_name: "Employee", optional: true, inverse_of: :managed_employee_groups
  belongs_to :category
  belongs_to :property_mapping

  has_many :employee_employee_group_appointments, dependent: :destroy
  has_many :employees, through: :employee_employee_group_appointments

  has_many :employee_group_role_appointments, dependent: :destroy
  has_many :roles, through: :employee_group_role_appointments

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validate :manager_belongs_to_same_company

  after_save :clear_members_managers_cache, if: :saved_change_to_manager_id?

  private

  def manager_belongs_to_same_company
    return if manager.blank? || company_id.blank?
    return if manager.company_id == company_id

    errors.add(:manager, "must belong to the same company")
  end

  def clear_members_managers_cache
    employees.find_each(&:clear_managers_cache)
  end
end
