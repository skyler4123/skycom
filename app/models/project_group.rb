# frozen_string_literal: true

# ProjectGroup — Atomic purpose: company-scoped grouping of projects (internal,
# client-facing, R&D).
#
# Why it exists: groups related projects and assigns them to employees as a unit;
# it carries its own category/property schema.
# How it works: belongs to company, optional branch, category, and property
# mapping; employees join through EmployeeProjectGroupAppointment; projects
# reference the group.
# Main associations: belongs_to :company, :category, :property_mapping (required),
# :branch (optional); has_many :employees through
# :employee_project_group_appointments (dependent: :destroy).
class ProjectGroup < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern

  include TagConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    internal: 0,
    client_facing: 1,
    research_and_development: 2
  }
  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping
  has_many :employee_project_group_appointments, dependent: :destroy
  has_many :employees, through: :employee_project_group_appointments

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :branch_id }

  validates :business_type, presence: true
end
