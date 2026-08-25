# frozen_string_literal: true

module OrderProcessingV1
  class ReserveStockService
    def self.call(items:)
      # Heal missing counters from DB first — a decrement on a missing key
      # would falsely report insufficient stock.
      items.each { |item| Stock.find(item[:stock_id]).available_count }

      reserved = []
      items.each do |item|
        stock = Stock.find(item[:stock_id])
        unless stock.reserve_stock!(item[:quantity])
          reserved.each { |r| r[:stock].release_reserved!(r[:qty]) }
          raise InsufficientStockError, "Insufficient stock for item #{item[:stock_id]}"
        end
        reserved << { stock: stock, qty: item[:quantity].to_i }
      end

      { success: true }
    end
  end
end
