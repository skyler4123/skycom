# frozen_string_literal: true

# EmployeeProfile — Atomic purpose: named sub-record under one Employee that holds
# profile-specific data and its own dynamic schema.
#
# Why it exists: one employee can have multiple profiles (e.g. per position or
# contract) without adding columns to Employee; profiles own subprofiles and use
# the category/property mapping pattern (see docs/PROFILE_SUBPROFILE.md).
# How it works: belongs to an employee and company; discard cascades to kept
# subprofiles; validates that the employee belongs to the same company.
# Main associations: belongs_to :company, :employee, :category,
# :property_mapping (required), :branch (optional); has_many
# :employee_subprofiles (dependent: :destroy).
class EmployeeProfile < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern
  include Discard::Model
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    general: 0,
    special: 1
  }

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :employee
  belongs_to :category
  belongs_to :property_mapping

  has_many :employee_subprofiles, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :employee_id }, length: { maximum: 255 }
  validates :code, uniqueness: { scope: :company_id }, allow_blank: true
  validates :description, length: { maximum: 5000 }, allow_blank: true

  validates :business_type, presence: true
  validate :employee_belongs_to_company

  before_discard :discard_subprofiles

  private

  def employee_belongs_to_company
    return if employee.nil? || company_id.blank?

    if employee.company_id != company_id
      errors.add(:employee, "must belong to the same company")
    end
  end

  def discard_subprofiles
    employee_subprofiles.kept.find_each(&:discard!)
  end
end
