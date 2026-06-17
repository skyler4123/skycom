# frozen_string_literal: true

module OrderProcessingV1
  class CheckAvailabilityService
    def self.call(items:)
      items.each do |item|
        stock = Stock.find(item[:stock_id])
        available = available_quantity(stock)
        return { available: false, failed_item: item[:stock_id] } if available < item[:quantity].to_i
      end
      { available: true }
    end

    def self.available_quantity(stock)
      redis_key = "stock:#{stock.id}:available"
      unless Kredis.redis.exists?(redis_key)
        value = [ stock.quantity.to_i - stock.reserved_quantity.to_i, 0 ].max
        Kredis.redis.set(redis_key, value)
        return value
      end
      stock.available_counter.value
    end
  end
end
