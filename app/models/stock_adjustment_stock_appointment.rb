class StockAdjustmentStockAppointment < ApplicationRecord
  # Stock adjustment line — atomic row binding a StockAdjustment to one exact
  # Stock row.
  #
  # Why it exists: quantity truth lives on the line (stock + quantity), not on
  # the document header, so stock-take corrections stay exact per
  # warehouse+product.
  # How to use: built on the adjustment document, then executed by
  # StockMovementService::Adjustments::CreateService (add on increase, remove
  # on decrease, one ledger row per line).
  # How it works: concrete FKs to company/stock_adjustment/stock; company_id
  # derives from either side via SetDefaultCompanyConcern.
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :stock_adjustment
  belongs_to :stock

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
end
