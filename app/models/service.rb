# frozen_string_literal: true

# Service — Atomic purpose: company-scoped sellable service in the catalog.
#
# Why it exists: services are sold on orders, booked for customers/events, and
# assigned to employees; the catalog row keeps pricing and dynamic properties
# separate from each booking.
# How it works: belongs to company/branch/category/property mapping; orders,
# service groups, customers, employees, and events link through their atomic
# appointments. Pricing uses monetize (price_cents).
# Main associations: belongs_to :company, :category, :property_mapping
# (required), :branch (optional); has_many :orders, :service_groups,
# :customer_groups, :customers, :employees, :events through appointments (all
# dependent: :destroy).
class Service < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern
  include OrderConcern
  include Service::ImageConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    b2b: 0,
    b2c: 1
  }
  monetize :price_cents,
           as: "price",
           with_model_currency: :currency,
           disable_validation: true

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :order_service_appointments, dependent: :destroy
  has_many :orders, through: :order_service_appointments

  has_many :service_service_group_appointments, dependent: :destroy
  has_many :service_groups, through: :service_service_group_appointments

  has_many :customer_group_service_appointments, dependent: :destroy
  has_many :customer_groups, through: :customer_group_service_appointments

  has_many :customer_service_appointments, dependent: :destroy
  has_many :customers, through: :customer_service_appointments
  has_many :employee_service_appointments, dependent: :destroy
  has_many :employees, through: :employee_service_appointments
  has_many :event_service_appointments, dependent: :destroy
  has_many :events, through: :event_service_appointments

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }, allow_blank: true

  validates :business_type, presence: true
end
