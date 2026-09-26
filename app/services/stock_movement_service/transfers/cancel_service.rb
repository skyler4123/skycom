# frozen_string_literal: true

# Cancels an initiated StockTransfer: releases every line's source hold
# (pending -= qty) and marks the transfer `cancelled`. No ledger rows exist for
# an initiated transfer — nothing else to revert. Idempotent-safe: only
# initiated transfers can be cancelled.
class StockMovementService::Transfers::CancelService
  def self.call(transfer:, employee: nil)
    unless transfer.workflow_status_initiated?
      raise StockMovementService::Error, "Only initiated transfers can be cancelled (current: #{transfer.workflow_status})"
    end

    ActiveRecord::Base.transaction do
      transfer.stock_item_appointments.each do |line|
        line.stock.reload.release_reserved!(line.quantity)
      end

      transfer.update!(workflow_status: :cancelled)
    end

    { success: true, transfer: transfer }
  end
end
