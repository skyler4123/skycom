# frozen_string_literal: true

# Order — Atomic purpose: sales order header that groups chargeable line items
# (products, services, groups, subscription plans) for a customer.
#
# Why it exists: the order is the commercial document between the customer and
# the branch; line items live in atomic tables with price snapshots so the order
# total is always derived, not stored.
# How it works: belongs to company, optional branch/customer, category, and
# property mapping; line items are Order*Appointment rows. #line_items combines
# them and #line_total sums their total_price. Invoices and discounts hang off the
# order (see docs/ORDER_PROCESSING_V1.md, docs/DISCOUNTS.md).
# Main associations: belongs_to :company, :category, :property_mapping
# (required), :branch, :customer, and :salesperson (optional); has_many :invoices, :discounts,
# :order_product_appointments, :order_service_appointments,
# :order_product_group_appointments, :order_service_group_appointments,
# :order_subscription_plan_appointments, :event_order_appointments
# (dependent: :destroy); has_many :products, :services, :product_groups,
# :service_groups, :subscription_plans, :events through those appointments.
class Order < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd
  enum :business_type, {
    online: 0,
    in_store: 1,
    phone: 2
  }
  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :customer, optional: true
  belongs_to :salesperson, class_name: "Employee", optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :invoices, dependent: :destroy
  has_many :discounts, dependent: :destroy
  has_many :order_product_appointments, dependent: :destroy
  has_many :products, through: :order_product_appointments
  has_many :order_service_appointments, dependent: :destroy
  has_many :services, through: :order_service_appointments
  has_many :order_product_group_appointments, dependent: :destroy
  has_many :product_groups, through: :order_product_group_appointments
  has_many :order_service_group_appointments, dependent: :destroy
  has_many :service_groups, through: :order_service_group_appointments
  has_many :order_subscription_plan_appointments, dependent: :destroy
  has_many :subscription_plans, through: :order_subscription_plan_appointments
  has_many :event_order_appointments, dependent: :destroy
  has_many :events, through: :event_order_appointments

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :currency, presence: true

  validates :business_type, presence: true
  validate :salesperson_belongs_to_company

  # --- Methods ---
  # Combined line items across all atomic order tables (products, services,
  # product groups, service groups, subscription plans).
  def line_items
    order_product_appointments.to_a +
      order_service_appointments.to_a +
      order_product_group_appointments.to_a +
      order_service_group_appointments.to_a +
      order_subscription_plan_appointments.to_a
  end

  def line_total
    order_product_appointments.sum(:total_price) +
      order_service_appointments.sum(:total_price) +
      order_product_group_appointments.sum(:total_price) +
      order_service_group_appointments.sum(:total_price) +
      order_subscription_plan_appointments.sum(:total_price)
  end

  private

  def salesperson_belongs_to_company
    return if salesperson.nil? || company_id.nil?
    return if salesperson.company_id == company_id

    errors.add(:salesperson, "must belong to the same company")
  end
end
