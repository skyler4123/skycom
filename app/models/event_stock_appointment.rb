class EventStockAppointment < ApplicationRecord
  # Requirement row binding an Event to the Stock it needs.
  #
  # Why it exists: captures how many units of a SKU an event needs
  # (quantity) without moving any inventory — the row never writes
  # Stock.quantity/pending (STOCK.md Tenet 1: only the StockTransaction
  # callback mutates). Holds, when the category's EventConfig asks for them,
  # go through StockPendings::HoldService as :event StockPending rows.
  # How to use: created with the event (or added on update); read via
  # event.event_stock_appointments. Never edit quantity after holds exist —
  # reconcile through the event update flow instead.
  # How it works: concrete FKs to company/event/stock; company_id derives
  # from either side via SetDefaultCompanyConcern.
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :event
  belongs_to :stock

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
