class StockTransferStockAppointment < ApplicationRecord
  # Stock transfer line — atomic row binding a StockTransfer to one exact source
  # Stock row.
  #
  # Why it exists: quantity truth lives on the line (stock + quantity), not on
  # the document header; the source row is exact so holds and ledger rows never
  # guess a warehouse.
  # How to use: built on the transfer document at creation; initiate holds each
  # line's stock, receive writes remove@source (consuming the hold) + add@dest.
  # How it works: concrete FKs to company/stock_transfer/stock; company_id
  # derives from either side via SetDefaultCompanyConcern.
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :stock_transfer
  belongs_to :stock

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
end
