# app/models/product.rb
class Product < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  attribute :metadata, :jsonb, default: {}
  attribute :currency_code, :integer, default: 840
  attribute :country_code, :integer, default: 1
  attribute :timezone, :string, default: "UTC"

  include TagConcern
  include OrderConcern
  include PriceConcern
  include Product::ImageConcern

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :brand, optional: true
  belongs_to :category
  belongs_to :property_mapping

  # Core Business Orders
  has_many :order_appointments, as: :appoint_to, dependent: :destroy
  has_many :orders, through: :order_appointments

  # Groupings Matrix
  has_many :product_group_appointments, dependent: :destroy, as: :appoint_to
  has_many :product_groups, through: :product_group_appointments

  # --- New Inventory Ledger Associations ---
  has_many :stocks, dependent: :destroy

  # The true atomic ledger tracking every specific movement of this item
  has_many :stock_transactions, dependent: :destroy

  # Indirectly access source documents that impacted this product's inventory levels
  has_many :stock_imports,   through: :stock_transactions, source: :appoint_for, source_type: "StockImport"
  has_many :stock_exports,   through: :stock_transactions, source: :appoint_for, source_type: "StockExport"
  has_many :stock_transfers, through: :stock_transactions, source: :appoint_for, source_type: "StockTransfer"

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  enum :business_type, {
    physical: 0,
    digital: 1,
    service_based: 2
  }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :business_type, presence: true
end
