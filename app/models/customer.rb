# frozen_string_literal: true

# Customer — Atomic purpose: tenant-scoped buyer/customer record that anchors
# orders, memberships, roles, addresses, and service/event links.
#
# Why it exists: the customer is the commercial counterparty for orders and
# service bookings; it can be linked to a login User or exist purely as a
# company-scoped POS customer, and it carries role/address/tag/membership
# concerns.
# How it works: belongs to company/branch/user (all optional) and required
# category/property mapping; associations go through atomic appointment tables
# for groups, roles, services, employees, and events. Orders belong directly to
# the customer.
# Main associations: belongs_to :company, :branch, :user (optional),
# :category, :property_mapping (required); has_many :orders, :customer_profiles,
# :customer_subprofiles (dependent: :destroy); has_many :customer_groups, :roles,
# :services, :employees, :events through their appointments.
class Customer < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include RoleConcern
  include AddressConcern
  include TagConcern
  include MembershipConcern
  include Customer::ImageConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    individual: 0,
    small_business: 1,
    enterprise: 2
  }
  # --- Associations ---
  belongs_to :user, optional: true
  belongs_to :company, optional: true
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :orders, dependent: :destroy
  has_many :customer_customer_group_appointments, dependent: :destroy
  has_many :customer_groups, through: :customer_customer_group_appointments

  has_many :customer_role_appointments, dependent: :destroy
  has_many :roles, through: :customer_role_appointments

  has_many :customer_service_appointments, dependent: :destroy
  has_many :services, through: :customer_service_appointments

  has_many :customer_employee_appointments, dependent: :destroy
  has_many :employees, through: :customer_employee_appointments

  has_many :customer_event_appointments, dependent: :destroy
  has_many :events, through: :customer_event_appointments
  has_many :customer_profiles, dependent: :destroy
  has_many :customer_subprofiles, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }

  validates :business_type, presence: true
end
