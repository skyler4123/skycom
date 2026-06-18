# frozen_string_literal: true

module OrderProcessingV1
  class ReserveStockService
    def self.call(items:)
      redis = Kredis.redis
      results = redis.multi do |multi|
        items.each do |item|
          multi.decrby("stock:#{item[:stock_id]}:available", item[:quantity])
        end
      end

      items.each_with_index do |item, idx|
        next unless results[idx].to_i < 0

        redis.multi do |multi|
          items.each_with_index do |rollback_item, ridx|
            next if ridx > idx
            multi.incrby("stock:#{rollback_item[:stock_id]}:available", rollback_item[:quantity])
          end
        end

        raise InsufficientStockError, "Insufficient stock for item #{item[:stock_id]}"
      end

      { success: true }
    end
  end
end
