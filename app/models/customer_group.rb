# frozen_string_literal: true

# CustomerGroup — Atomic purpose: company-scoped customer segment (VIP,
# wholesale, retail, new customers) used for roles, pricing, and service access.
#
# Why it exists: groups customers for shared roles, services, and addresses
# without per-customer rows; it is the customer-side counterpart of EmployeeGroup.
# How it works: belongs to company/branch (optional) and required category/
# property mapping; customers join through CustomerCustomerGroupAppointment,
# roles through CustomerGroupRoleAppointment, and services through
# CustomerGroupServiceAppointment.
# Main associations: belongs_to :company, :category, :property_mapping
# (required), :branch (optional); has_many :customers, :roles, :services through
# their appointments (dependent: :destroy).
class CustomerGroup < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include AddressConcern
  include TagConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    vip: 0,
    wholesale: 1,
    retail: 2,
    new_customers: 3
  }
  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :customer_customer_group_appointments, dependent: :destroy
  has_many :customers, through: :customer_customer_group_appointments
  has_many :customer_group_service_appointments, dependent: :destroy
  has_many :services, through: :customer_group_service_appointments

  has_many :customer_group_role_appointments, dependent: :destroy
  has_many :roles, through: :customer_group_role_appointments

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :branch_id }

  validates :business_type, presence: true
end
