# frozen_string_literal: true

# Rolls back a POS reservation: releases the `pos` StockPending holds (FIFO
# scope per line) for every stock-tracked line item on the order.
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

        result = StockPendings::ReleaseService.call(
          company: order.company, warehouse: stock.warehouse,
          stock: stock, quantity: oa.quantity, business_type: :pos
        )
        released << stock.id if result[:success]
      end
      { released: released }
    end
  end
end
