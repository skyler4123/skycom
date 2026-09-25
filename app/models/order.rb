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

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :currency, presence: true

  validates :business_type, presence: true

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
end
