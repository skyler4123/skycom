# frozen_string_literal: true

# Rolls back a POS reservation: restores Redis availability and consumes the
# DB pending promise for every stock-tracked line item on the order.
module OrderProcessingV1
  class ReleaseReservedStockService
    def self.call(order:)
      released = []
      order.order_appointments.each do |oa|
        stock = order.company.stocks.find_by(product_id: oa.appoint_to.id)
        next unless stock

        stock.release_reserved!(oa.quantity)
        released << stock.id
      end
      { released: released }
    end
  end
end
