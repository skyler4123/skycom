class StockImportStockAppointment < ApplicationRecord
  # Stock import line — atomic row binding a StockImport to one exact Stock row.
  #
  # Why it exists: quantity truth lives on the line (stock + quantity), not on
  # the document header, so multi-line documents stay exact per warehouse+product.
  # How to use: built on the import document, then executed by
  # StockMovementService::Imports::CreateService (one add ledger row per line).
  # How it works: concrete FKs to company/stock_import/stock; company_id derives
  # from either side via SetDefaultCompanyConcern.
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :stock_import
  belongs_to :stock

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
end
