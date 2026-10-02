# frozen_string_literal: true

# Cancels an initiated StockTransfer: releases every line's source hold
# through its `transfer` StockPending rows (cancelled, with `release` ledger
# rows) and marks the transfer `cancelled`. Pre-migration raw residuals
# (holds with no pending rows) are released via the wrapper fallback.
# Idempotent-safe: only initiated transfers can be cancelled.
class StockMovementService::Transfers::CancelService
  def self.call(transfer:, employee: nil)
    unless transfer.workflow_status_initiated?
      raise StockMovementService::Error, "Only initiated transfers can be cancelled (current: #{transfer.workflow_status})"
    end

    ActiveRecord::Base.transaction do
      transfer.stock_transfer_stock_appointments.each do |line|
        stock = line.stock.reload
        result = StockPendings::ReleaseService.call(
          company: transfer.company, warehouse: stock.warehouse, stock: stock,
          quantity: line.quantity, target: :cancel
        )
        raise StockMovementService::Error, result[:errors].to_sentence unless result[:success]

        release_raw_residual!(stock, line.quantity)
      end

      transfer.update!(workflow_status: :cancelled)
    end

    { success: true, transfer: transfer }
  end

  # Pre-migration holds have no StockPending rows: anything in `pending`
  # beyond row-backed holdings is a legacy raw hold for this line.
  def self.release_raw_residual!(stock, quantity)
    row_backed = stock.stock_pendings.where(workflow_status: StockPending::HOLDING_STATUSES).sum(:quantity)
    raw = stock.reload.pending - row_backed
    stock.release_reserved!([ raw, quantity ].min) if raw.positive?
  end
end
