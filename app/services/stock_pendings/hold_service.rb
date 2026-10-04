# frozen_string_literal: true

# Holds sellable units behind a StockPending record (docs/superpowers/specs/
# 2026-10-02-stock-pending-design.md §3.3): one transaction creates the
# holding pending (workflow_status: pending) plus exactly one `hold` ledger
# row anchored with appoint_for: pending. The ledger callback moves
# Stock.pending; floor failure rolls back the pending row too (no orphans).
# Result-hash contract: { success:, stock_pending: } | { success: false, errors: [...] }.
module StockPendings
  class HoldService
    def self.call(company:, warehouse:, stock:, quantity:, business_type: :manual, name: nil, reason: nil)
      new(
        company: company, warehouse: warehouse, stock: stock,
        quantity: quantity, business_type: business_type, name: name, reason: reason
      ).call
    end

    def initialize(company:, warehouse:, stock:, quantity:, business_type:, name:, reason:)
      @company = company
      @warehouse = warehouse
      @stock = stock
      @quantity = quantity.to_i
      @business_type = business_type
      @name = name
      @reason = reason
    end

    def call
      validate!

      pending = nil
      ActiveRecord::Base.transaction do
        pending = StockPending.create!(
          company: @company, warehouse: @warehouse, stock: @stock, product: @stock.product,
          quantity: @quantity, workflow_status: :pending, business_type: @business_type,
          name: @name, reason: @reason,
          code: "#{StockPending::CODE_PREFIX}-#{SecureRandom.hex(4).upcase}",
          status_changed_at: Time.current
        )
        StockMovementService::BaseService.call(
          stock: @stock.reload, quantity: @quantity,
          direction: :remove, transaction_type: :hold, document: pending
        )
      end

      { success: true, stock_pending: pending }
    rescue StockMovementService::Error, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      { success: false, errors: [ e.message ] }
    end

    private

    def validate!
      raise StockMovementService::Error, "Quantity must be greater than 0" if @quantity <= 0
      raise StockMovementService::Error, "Stock does not belong to this company" unless @stock.company_id == @company.id
      unless @stock.warehouse_id == @warehouse.id
        raise StockMovementService::Error, "Stock #{@stock.code} belongs to another warehouse"
      end
    end
  end
end
