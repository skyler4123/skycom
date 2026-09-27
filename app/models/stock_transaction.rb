# StockTransaction — Atomic purpose: the stock ledger row and SINGLE quantity
# mutator. Its after_create callback (recalibrate_stock_metrics, with_lock +
# floor check) is the only writer of Stock.quantity; a missing Stock row or
# negative result raises and rolls back the whole movement.
class StockTransaction < ApplicationRecord
  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  enum :direction, { add: 0, remove: 1 }
  enum :transaction_type, { import: 0, export: 1, transfer: 2, adjustment: 3 }
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

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # --- Automated Stock Recalibration Callback ---
  # The SINGLE quantity mutator for the stock domain (docs/KREDIS.md,
  # docs/superpowers/specs/2026-09-23-stock-source-of-truth-design.md).
  # Raises on floor violation so the caller's transaction rolls back the
  # ledger row together with any document state.
  after_create :recalibrate_stock_metrics

  private

  def recalibrate_stock_metrics
    # Identity = warehouse + product (the stocks uniqueness scope). category_id/
    # property_mapping_id must NOT be lookup keys: stocks live in their own category
    # taxonomy, and a ledger row may carry a different document category.
    # The row must already exist — callers resolve/create it positively; a missing
    # row is a programming error, never a silent zero-quantity lazy creation.
    stock = Stock.find_by!(company_id: company_id, warehouse_id: warehouse_id, product_id: product_id)

    stock.with_lock do
      delta = add? ? quantity : -quantity
      new_quantity = stock.quantity + delta
      if new_quantity.negative?
        raise StockMovementService::Error,
              "Insufficient stock: quantity #{stock.quantity}, movement #{delta}"
      end

      stock.quantity = new_quantity
      stock.save! # after_save syncs the Redis available counter
    end
  end
end
