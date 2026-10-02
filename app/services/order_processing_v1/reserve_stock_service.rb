# frozen_string_literal: true

# Reserves POS stock behind StockPending rows (one `pos` hold per line via
# StockPendings::HoldService — each with its own anchored `hold` ledger row).
# Any insufficient line releases ALL prior holds (via ReleaseService) and
# raises InsufficientStockError, leaving no pending rows behind.
module OrderProcessingV1
  class ReserveStockService
    def self.call(items:)
      # Heal missing counters from DB first — a hold on a missing key would
      # falsely report insufficient stock.
      items.each { |item| Stock.find(item[:stock_id]).available_count }

      reserved = []
      items.each do |item|
        stock = Stock.find(item[:stock_id])
        result = StockPendings::HoldService.call(
          company: stock.company, warehouse: stock.warehouse, stock: stock,
          quantity: item[:quantity], business_type: :pos
        )
        unless result[:success]
          reserved.each { |r| StockPendings::ReleaseService.call(stock_pending: r[:stock_pending]) }
          raise InsufficientStockError, "Insufficient stock for item #{item[:stock_id]}"
        end
        reserved << { stock: stock, qty: item[:quantity].to_i, stock_pending: result[:stock_pending] }
      end

      { success: true, reserved: reserved }
    end
  end
end
