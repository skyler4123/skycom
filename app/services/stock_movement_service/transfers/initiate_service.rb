# frozen_string_literal: true

# Initiates a StockTransfer (two-phase, docs/superpowers/specs/
# 2026-09-23-stock-source-of-truth-design.md §3.5):
# Phase 1 — holds the source units: each line's source Stock row gets
# `pending += qty` via Stock#reserve_stock! (no ledger rows, no quantity change;
# the units stay on the shelf but disappear from POS availability). Any
# insufficient line rolls back ALL prior holds (same pattern as
# OrderProcessingV1::ReserveStockService). The transfer moves to `initiated`.
class StockMovementService::Transfers::InitiateService
  def self.call(transfer:, employee: nil)
    raise StockMovementService::Error, "Transfer has no stock lines" if transfer.stock_item_appointments.empty?
    unless transfer.workflow_status_draft? || transfer.workflow_status_pending?
      raise StockMovementService::Error, "Transfer is already #{transfer.workflow_status}"
    end

    reserved = []

    ActiveRecord::Base.transaction do
      transfer.stock_item_appointments.each do |line|
        stock = line.stock.reload
        unless stock.reserve_stock!(line.quantity)
          raise StockMovementService::Error,
                "Insufficient stock to initiate transfer for #{stock.product.name}"
        end

        reserved << [ stock, line.quantity ]
      end

      transfer.update!(
        workflow_status: :initiated,
        initiated_at: Time.current
      )
    rescue StockMovementService::Error
      reserved.each { |stock, qty| stock.release_reserved!(qty) }
      raise
    end

    { success: true, transfer: transfer }
  end
end
