# frozen_string_literal: true

# Product — Atomic purpose: company-scoped sellable/stocked item in the catalog.
#
# Why it exists: the product is the catalog identity behind order lines, stock
# rows, and supplier purchases; it carries pricing, brand, category, and dynamic
# properties without duplicating them per order.
# How it works: belongs to company/branch/brand/category/property mapping; orders
# reference products through OrderProductAppointment, product groups through
# ProductProductGroupAppointment, and stock rows point back to the product.
# Tags, images, and dynamic search come from concerns.
# Main associations: belongs_to :company, :category, :property_mapping
# (required), :branch and :brand (optional); has_many :orders, :product_groups,
# :employees through appointments; has_many :stocks, :stock_transactions
# (dependent: :destroy).
class Product < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern
  include OrderConcern
  include Product::ImageConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    physical: 0,
    digital: 1,
    service_based: 2
  }
  # money-rails integration
  monetize :price_cents,
           as: "price",
           with_model_currency: :price_currency,
           disable_validation: true

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :brand, optional: true
  belongs_to :category
  belongs_to :property_mapping

  # Core Business Orders (atomic pairwise)
  has_many :order_product_appointments, dependent: :destroy
  has_many :orders, through: :order_product_appointments

  # Groupings Matrix (atomic pairwise)
  has_many :product_product_group_appointments, dependent: :destroy
  has_many :product_groups, through: :product_product_group_appointments

  has_many :employee_product_appointments, dependent: :destroy
  has_many :employees, through: :employee_product_appointments

  # --- New Inventory Ledger Associations ---
  has_many :stocks, dependent: :destroy

  # The true atomic ledger tracking every specific movement of this item
  has_many :stock_transactions, dependent: :destroy

  # Indirectly access source documents that impacted this product's inventory levels
  has_many :stock_imports,   through: :stock_transactions, source: :appoint_for, source_type: "StockImport"
  has_many :stock_exports,   through: :stock_transactions, source: :appoint_for, source_type: "StockExport"
  has_many :stock_transfers, through: :stock_transactions, source: :appoint_for, source_type: "StockTransfer"

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :business_type, presence: true
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }

  def price_currency
    currency&.upcase || "USD"
  end
end
