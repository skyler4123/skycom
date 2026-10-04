# frozen_string_literal: true

# Confirms a StockTransfer arrival (phase 2): for each line, releases the
# initiate-time `transfer` StockPending rows (a `release` ledger row per row,
# rows move to completed), then writes the paired quantity ledgers — a
# `remove` at the source warehouse (appoint_from: transfer) and an `add` at
# the destination warehouse (dest Stock row resolved/created positively,
# appoint_to: transfer) — both with transaction_type: transfer. The source
# removal consumes a pre-migration raw residual when one is outstanding,
# else it is a free-standing removal under the hold-aware floor. Transfer
# moves initiated → received, received_at stamped. One transaction end to end.
class StockMovementService::Transfers::ReceiveService
  def self.call(transfer:, employee: nil)
    unless transfer.workflow_status_initiated?
      raise StockMovementService::Error, "Transfer must be initiated before receiving (current: #{transfer.workflow_status})"
    end

    ActiveRecord::Base.transaction do
      transfer.stock_transfer_stock_appointments.each do |line|
        stock = line.stock.reload
        result = StockPendings::ReleaseService.call(
          company: transfer.company, warehouse: stock.warehouse, stock: stock,
          quantity: line.quantity, business_type: :transfer
        )
        raise StockMovementService::Error, result[:errors].to_sentence unless result[:success]

        # Only a pre-migration raw residual (pending beyond row-backed holdings)
        # may be consumed — never another row's hold.
        stock.reload
        row_backed = stock.stock_pendings.where(workflow_status: StockPending::HOLDING_STATUSES).sum(:quantity)
        consume_hold = (stock.pending - row_backed) >= line.quantity

        StockMovementService::BaseService.call(
          stock: stock,
          quantity: line.quantity,
          direction: :remove,
          transaction_type: :transfer,
          appoint_from: transfer,
          employee: employee,
          consume_hold: consume_hold
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
    end

    { success: true, transfer: transfer }
  end
end
