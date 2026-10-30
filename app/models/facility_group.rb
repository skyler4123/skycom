# frozen_string_literal: true

# FacilityGroup — Atomic purpose: company-scoped grouping of facilities
# (building, floor, wing).
#
# Why it exists: groups spaces for browsing and assignment; it carries its own
# category/property schema.
# How it works: belongs to company/branch/category/property mapping; facilities
# join through FacilityFacilityGroupAppointment.
# Main associations: belongs_to :company, :category, :property_mapping
# (required), :branch (optional); has_many :facilities through
# :facility_facility_group_appointments (dependent: :destroy).
class FacilityGroup < ApplicationRecord
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
    building: 0,
    floor: 1,
    wing: 2
  }
  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping
  has_many :facility_facility_group_appointments, dependent: :destroy
  has_many :facilities, through: :facility_facility_group_appointments

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :branch_id }

  validates :business_type, presence: true
end
