class StockTransaction < ApplicationRecord
  attribute :metadata, :jsonb, default: {}
  attribute :currency_code, :integer, default: 840
  attribute :country_code, :integer, default: 1
  attribute :timezone, :string, default: "UTC"

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :warehouse
  belongs_to :product
  belongs_to :category
  belongs_to :property_mapping

  belongs_to :appoint_from, polymorphic: true, optional: true
  belongs_to :appoint_to, polymorphic: true, optional: true
  belongs_to :appoint_for, polymorphic: true, optional: true # Anchor document (Import/Export/Transfer)
  belongs_to :appoint_by, polymorphic: true, optional: true  # Operator identity profile

  enum :direction, { add: 0, remove: 1 }
  enum :transaction_type, { import: 0, export: 1, transfer: 2, adjustment: 3 }

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # --- Automated Stock Recalibration Callback ---
  after_create :recalibrate_stock_metrics

  private

  def recalibrate_stock_metrics
    stock = Stock.find_or_initialize_by(
      company_id: company_id,
      branch_id: branch_id,
      warehouse_id: warehouse_id,
      product_id: product_id,
      category_id: category_id,
      property_mapping_id: property_mapping_id
    )

    if add?
      stock.quantity += quantity
    elsif remove?
      stock.quantity -= quantity
    end

    stock.save!
  end
end
