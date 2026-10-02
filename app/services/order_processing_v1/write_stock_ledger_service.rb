# frozen_string_literal: true

# Writes the sale's stock ledger rows — through StockMovementService::BaseService,
# whose hardened StockTransaction callback is the ONLY quantity mutator
# (docs/superpowers/specs/2026-09-23-stock-source-of-truth-design.md §5).
# Each line was held at pay time behind a `pos` StockPending, so finalize writes
# TWO rows per line: the pending `release` (via ReleaseService scope) plus the
# quantity `remove` (transaction_type: export). A pay-persisted line
# (stock_id present) proves its hold — a missing hold fails fast instead of
# silently overselling. Legacy lines (no stock_id) keep the old heuristic:
# consume a raw residual hold when one is outstanding, else free removal.
module OrderProcessingV1
  class WriteStockLedgerService
    def self.call(order:)
      count = 0

      order.order_product_appointments.each do |oa|
        stock = resolve_stock(order, oa)
        consume_hold = release_line_hold(order, oa, stock)

        StockMovementService::BaseService.call(
          stock: stock.reload,
          quantity: oa.quantity,
          direction: :remove,
          transaction_type: :export,
          document: order,
          consume_hold: consume_hold
        )

        count += 1
      end

      { count: count }
    end

    # Releases the line's pay-time hold through its StockPending rows.
    # Returns whether the quantity removal may consume a raw residual hold
    # (legacy lines only — pay-persisted lines already released theirs).
    def self.release_line_hold(order, oa, stock)
      result = StockPendings::ReleaseService.call(
        company: order.company, warehouse: stock.warehouse,
        stock: stock, quantity: oa.quantity
      )
      raise StockMovementService::Error, result[:errors].to_sentence unless result[:success]

      if oa.try(:stock_id).present?
        freed = (result[:released] || []).sum(&:quantity)
        if freed < oa.quantity.to_i
          raise StockMovementService::Error,
                "Insufficient stock to consume hold: pending #{stock.reload.pending}, need #{oa.quantity}"
        end
        return false
      end

      stock.reload.pending >= oa.quantity.to_i
    end

    def self.resolve_stock(order, oa)
      return Stock.find(oa.stock_id) if oa.try(:stock_id).present?

      order.company.stocks.joins(:warehouse).find_by(
        product_id: oa.product_id, warehouses: { branch_id: order.branch_id }
      ) || order.company.stocks.find_by!(product_id: oa.product_id)
    end
  end
end
