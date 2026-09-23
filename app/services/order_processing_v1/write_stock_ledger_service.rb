# frozen_string_literal: true

# Writes the sale's stock ledger rows — through StockMovementService::BaseService,
# whose hardened StockTransaction callback is the ONLY quantity mutator
# (docs/superpowers/specs/2026-09-23-stock-source-of-truth-design.md §5).
# Each line was reserved at pay time (pending hold), so the removal consumes
# the hold (consume_hold: true): quantity -= qty, pending -= qty, Redis synced.
# The stock row is the one persisted on the order appointment at pay time;
# legacy rows fall back to branch-scoped then company-scoped resolution.
module OrderProcessingV1
  class WriteStockLedgerService
    def self.call(order:)
      count = 0

      order.order_appointments.each do |oa|
        stock = resolve_stock(order, oa)

        # Real POS flow: the pay-time reservation holds the units (consume it).
        # Legacy/seeded paid orders never reserved — fall back to a free-standing
        # removal guarded by the hold-aware floor.
        consume_hold = stock.pending >= oa.quantity

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

    def self.resolve_stock(order, oa)
      return Stock.find(oa.stock_id) if oa.stock_id.present?

      order.company.stocks.joins(:warehouse).find_by(
        product_id: oa.appoint_to_id, warehouses: { branch_id: order.branch_id }
      ) || order.company.stocks.find_by!(product_id: oa.appoint_to_id)
    end
  end
end
