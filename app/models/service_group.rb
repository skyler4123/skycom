# frozen_string_literal: true

# ServiceGroup — Atomic purpose: company-scoped grouping of services (consulting,
# maintenance, support, training).
#
# Why it exists: groups related services for browsing and lets an order reference
# a group line; it carries its own category/property schema.
# How it works: belongs to company/branch/category/property mapping; services
# join through ServiceServiceGroupAppointment, and orders can reference group
# lines through OrderServiceGroupAppointment.
# Main associations: belongs_to :company, :category, :property_mapping
# (required), :branch (optional); has_many :services through
# :service_service_group_appointments; has_many :orders through
# :order_service_group_appointments (both dependent: :destroy).
class ServiceGroup < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern

  include TagConcern
  include OrderConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    consulting: 0,
    maintenance: 1,
    support: 2,
    training: 3
  }
  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping
  has_many :service_service_group_appointments, dependent: :destroy
  has_many :services, through: :service_service_group_appointments
  has_many :order_service_group_appointments, dependent: :destroy
  has_many :orders, through: :order_service_group_appointments

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :branch_id }

  validates :business_type, presence: true

  # NOTE: duration and start_at columns were removed from schema
  # Validations kept for future reference:
  # validates :duration, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  # validates :start_at, presence: true
end
