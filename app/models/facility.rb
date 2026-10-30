# frozen_string_literal: true

# Facility — Atomic purpose: company-scoped physical space/resource (room,
# building, wing) that can be grouped, staffed, and booked by events.
#
# Why it exists: facilities are shared resources with capacity and availability
# needs; grouping and many-to-many assignments stay in atomic tables.
# How it works: belongs to company/branch/category/property mapping; facilities
# join FacilityGroup through FacilityFacilityGroupAppointment and link to
# employees/events through their appointments.
# Main associations: belongs_to :company, :category, :property_mapping
# (required), :branch (optional); has_many :facility_groups, :employees, :events
# through appointments (all dependent: :destroy).
class Facility < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    publicly_traded: 0,
    privately_held: 1
  }
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping
  has_many :facility_facility_group_appointments, dependent: :destroy
  has_many :facility_groups, through: :facility_facility_group_appointments
  has_many :employee_facility_appointments, dependent: :destroy
  has_many :employees, through: :employee_facility_appointments
  has_many :event_facility_appointments, dependent: :destroy
  has_many :events, through: :event_facility_appointments

  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }, allow_blank: true

  validates :business_type, presence: true
end
