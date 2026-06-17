module OrderProcessingV1
  class FinalizeJob < ApplicationJob
    queue_as :order_finalization

    def perform(order_id)
      order = Order.find(order_id)
      return if order.workflow_status != "paid"
      return if StockExport.where(
        company_id: order.company_id,
        appoint_for_type: "Order",
        appoint_for_id: order.id
      ).exists?

      ActiveRecord::Base.transaction do
        WriteStockLedgerService.call(order: order)
        UpdateStockBalancesService.call(order: order)
        FinalizeOrderService.call(order: order)
      end
    end
  end
end
