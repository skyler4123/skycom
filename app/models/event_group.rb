# frozen_string_literal: true

# EventGroup — Atomic purpose: company-scoped grouping of events (general,
# clinical, hospitality, dining).
#
# Why it exists: groups related events and assigns employees as a unit; it
# carries its own category/property schema.
# How it works: belongs to company/branch/category/property mapping; employees
# join through EmployeeEventGroupAppointment; events reference the group.
# Main associations: belongs_to :company, :category, :property_mapping
# (required), :branch (optional); has_many :employees through
# :employee_event_group_appointments (dependent: :destroy).
class EventGroup < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    general: 0,
    clinical: 1,
    hospitality: 2,
    dining: 3
  }, prefix: true

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :employee_event_group_appointments, dependent: :destroy
  has_many :employees, through: :employee_event_group_appointments

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
end
