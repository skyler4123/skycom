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
  include ComputedColumnsConcern
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

  # --- Computed index columns ---
  computed_column :quantity, name: "Quantity", type: :integer

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :brand, optional: true
  belongs_to :category
  belongs_to :property_mapping
  belongs_to :tax_code, optional: true
  belongs_to :default_supplier, class_name: "Supplier", optional: true

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
  has_many :product_barcodes, dependent: :destroy
  has_many :product_bundles, dependent: :destroy
  has_many :stock_lots, dependent: :destroy
  has_many :reorder_rules, dependent: :destroy
  has_many :bill_of_materials, dependent: :destroy
  has_many :production_orders, dependent: :restrict_with_error

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :business_type, presence: true
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validate :tax_code_belongs_to_company

  # One grouped query per index page — no per-record Stock query.
  def self.preload_computed_columns(records)
    return if records.empty?

    totals = Stock.where(product_id: records.map(&:id)).group(:product_id).sum(:quantity)
    records.each do |record|
      record.instance_variable_set(:@computed_quantity, totals[record.id] || 0)
    end
  end

  # Total on-hand units across all warehouses (read-only computed column).
  def quantity
    return @computed_quantity if defined?(@computed_quantity)

    stocks.sum(:quantity)
  end

  def price_currency
    currency&.upcase || "USD"
  end

  private

  def tax_code_belongs_to_company
    return if tax_code.nil? || company_id.nil?
    return if tax_code.company_id == company_id && !tax_code.discarded?

    errors.add(:tax_code, "must be an available tax code for this company")
  end
end
