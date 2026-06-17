# frozen_string_literal: true

module OrderProcessingV1
  class CheckAvailabilityService
    def self.call(items:)
      items.each do |item|
        stock = Stock.find(item[:stock_id])
        available = stock.available_counter.value
        return { available: false, failed_item: item[:stock_id] } if available < item[:quantity]
      end
      { available: true }
    end
  end
end
