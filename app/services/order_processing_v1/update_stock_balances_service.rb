module OrderProcessingV1
  class UpdateStockBalancesService
    def self.call(order:)
      updated = []
      order.order_appointments.each do |oa|
        product = oa.appoint_to
        stock = Stock.find_by!(company_id: order.company_id, product_id: product.id)

        Stock.where(id: stock.id).update_all(
          [ "quantity = quantity - ?, reserved_quantity = reserved_quantity - ?", oa.quantity, oa.quantity ]
        )

        updated << stock.id
      end

      { updated: updated }
    end
  end
end
