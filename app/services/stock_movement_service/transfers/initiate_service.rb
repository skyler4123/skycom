# frozen_string_literal: true

# Initiates a StockTransfer (two-phase, docs/superpowers/specs/
# 2026-09-23-stock-source-of-truth-design.md §3.5):
# Phase 1 — holds the source units behind one `transfer` StockPending per
# line (each with its own anchored `hold` ledger row; the units stay on the
# shelf but disappear from POS availability). Any insufficient line releases
# ALL prior holds (healing Redis) and raises — the transfer stays uninitiated
# with no pending rows left behind. The transfer moves to `initiated`.
class StockMovementService::Transfers::InitiateService
  def self.call(transfer:, employee: nil)
    raise StockMovementService::Error, "Transfer has no stock lines" if transfer.stock_transfer_stock_appointments.empty?
    unless transfer.workflow_status_draft? || transfer.workflow_status_pending?
      raise StockMovementService::Error, "Transfer is already #{transfer.workflow_status}"
    end

    reserved = []

    ActiveRecord::Base.transaction do
      transfer.stock_transfer_stock_appointments.each do |line|
        stock = line.stock.reload
        result = StockPendings::HoldService.call(
          company: transfer.company, warehouse: stock.warehouse, stock: stock,
          quantity: line.quantity, business_type: :transfer, name: transfer.code
        )
        unless result[:success]
          raise StockMovementService::Error,
                "Insufficient stock to initiate transfer for #{stock.product.name}"
        end

        reserved << result[:stock_pending]
      end

      transfer.update!(
        workflow_status: :initiated,
        initiated_at: Time.current
      )
    rescue StockMovementService::Error
      reserved.each { |pending| StockPendings::ReleaseService.call(stock_pending: pending) }
      raise
    end

    { success: true, transfer: transfer }
  end
end
