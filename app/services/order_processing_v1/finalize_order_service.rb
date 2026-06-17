module OrderProcessingV1
  class FinalizeOrderService
    def self.call(order:)
      export_ids = []
      order.order_appointments.each do |oa|
        product = oa.appoint_to
        stock = Stock.find_by!(company_id: order.company_id, product_id: product.id)

        export = StockExport.create!(
          company_id: order.company_id,
          branch_id: order.branch_id,
          warehouse_id: stock.warehouse_id,
          product_id: product.id,
          category_id: stock.category_id,
          property_mapping_id: stock.property_mapping_id,
          quantity: oa.quantity,
          business_type: :sale,
          code: "EXP-#{Time.current.to_i}-#{SecureRandom.hex(3).upcase}",
          workflow_status: :completed,
          appoint_for_type: "Order",
          appoint_for_id: order.id
        )

        export_ids << export.id
      end

      { export_ids: export_ids }
    end
  end
end
