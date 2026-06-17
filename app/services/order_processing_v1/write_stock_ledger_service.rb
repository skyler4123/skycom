module OrderProcessingV1
  class WriteStockLedgerService
    def self.call(order:)
      rows = order.order_appointments.map do |oa|
        product = oa.appoint_to
        stock = Stock.find_by!(company_id: order.company_id, product_id: product.id)
        {
          company_id: order.company_id,
          branch_id: order.branch_id,
          warehouse_id: stock.warehouse_id,
          product_id: product.id,
          category_id: stock.category_id,
          property_mapping_id: stock.property_mapping_id,
          quantity: oa.quantity,
          direction: StockTransaction.directions[:remove],
          transaction_type: StockTransaction.transaction_types[:export],
          appoint_for_type: "Order",
          appoint_for_id: order.id,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      StockTransaction.insert_all!(rows) if rows.any?
      { count: rows.size }
    end
  end
end
