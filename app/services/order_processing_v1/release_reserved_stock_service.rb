# frozen_string_literal: true

# Rolls back a POS reservation: restores Redis availability and consumes the
# DB pending promise for every stock-tracked line item on the order.
module OrderProcessingV1
  class ReleaseReservedStockService
    def self.call(order:)
      released = []
      order.order_product_appointments.each do |oa|
        stock = if oa.try(:stock_id).present?
          order.company.stocks.find_by(id: oa.stock_id)
        else
          order.company.stocks.joins(:warehouse).find_by(
            product_id: oa.product_id, warehouses: { branch_id: order.branch_id }
          ) || order.company.stocks.find_by(product_id: oa.product_id)
        end
        next unless stock

        stock.release_reserved!(oa.quantity)
        released << stock.id
      end
      { released: released }
    end
  end
end
