# frozen_string_literal: true

# Confirms a StockTransfer arrival (phase 2): for each line, writes TWO ledger
# rows — a `remove` at the source warehouse (consuming the initiated hold via
# consume_hold: true, appoint_from: transfer) and an `add` at the destination
# warehouse (dest Stock row resolved/created positively, appoint_to: transfer) —
# both with transaction_type: transfer. The source hold is released by the base
# service AFTER its ledger row exists (callback-failure-safe). Transfer moves
# initiated → received, received_at stamped. One transaction end to end.
class StockMovementService::Transfers::ReceiveService
  def self.call(transfer:, employee: nil)
    unless transfer.workflow_status_initiated?
      raise StockMovementService::Error, "Transfer must be initiated before receiving (current: #{transfer.workflow_status})"
    end

    transfer.stock_item_appointments.each do |line|
      StockMovementService::BaseService.call(
        stock: line.stock.reload,
        quantity: line.quantity,
        direction: :remove,
        transaction_type: :transfer,
        appoint_from: transfer,
        employee: employee,
        consume_hold: true
      )

      destination_stock = StockMovementService::StockResolver.resolve!(
        company: transfer.company,
        warehouse: transfer.destination_warehouse,
        product: line.stock.product
      )

      StockMovementService::BaseService.call(
        stock: destination_stock,
        quantity: line.quantity,
        direction: :add,
        transaction_type: :transfer,
        appoint_to: transfer,
        employee: employee
      )
    end

    transfer.update!(
      workflow_status: :received,
      received_at: Time.current
    )

    { success: true, transfer: transfer }
  end
end
