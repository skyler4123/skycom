# frozen_string_literal: true

# Releases StockPending holds (docs/superpowers/specs/
# 2026-10-02-stock-pending-design.md §3.3). Exact mode releases one row;
# scope mode releases holding rows FIFO (oldest first, whole rows only — a
# row releases fully even past the remaining need). One transaction per row:
# exactly one `release` ledger row plus the status transition
# (release → completed, cancel → cancelled) with released_at stamped.
# Already-released rows return { success: false } without a second ledger row.
module StockPendings
  class ReleaseService
    def self.call(stock_pending: nil, stock_pending_id: nil, company: nil, warehouse: nil,
                  stock: nil, quantity: nil, target: :release, business_type: nil)
      new(
        stock_pending: stock_pending, stock_pending_id: stock_pending_id,
        company: company, warehouse: warehouse, stock: stock,
        quantity: quantity, target: target, business_type: business_type
      ).call
    end

    def initialize(stock_pending:, stock_pending_id:, company:, warehouse:, stock:, quantity:, target:, business_type:)
      @stock_pending = stock_pending
      @stock_pending_id = stock_pending_id
      @company = company
      @warehouse = warehouse
      @stock = stock
      @quantity = quantity&.to_i
      @target = target.to_s
      @business_type = business_type
    end

    def call
      return call_exact if @stock_pending || @stock_pending_id

      call_scope
    end

    private

    def call_exact
      pending = @stock_pending || StockPending.find(@stock_pending_id)
      release_row!(pending)
      { success: true, stock_pending: pending }
    rescue StockMovementService::Error, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      { success: false, errors: [ e.message ] }
    end

    def call_scope
      released = []
      freed = 0
      holdings.each do |pending|
        break if @quantity && freed >= @quantity

        release_row!(pending)
        released << pending.reload
        freed += pending.quantity
      end
      { success: true, released: released }
    rescue StockMovementService::Error, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      { success: false, errors: [ e.message ], released: released }
    end

    # Same-business_type rows first (a transfer receive should consume transfer
    # holds, not an older manual hold), then oldest-first. Whole rows only.
    def holdings
      scope = StockPending.where(
        company_id: @company.id, warehouse_id: @warehouse.id, stock_id: @stock.id,
        workflow_status: StockPending::HOLDING_STATUSES
      )
      return scope.order(:created_at) if @business_type.blank?

      preferred = StockPending.business_types[@business_type.to_s]
      scope.order(
        Arel.sql("CASE WHEN business_type = #{scope.connection.quote(preferred)} THEN 0 ELSE 1 END"),
        :created_at
      )
    end

    def release_row!(pending)
      pending.with_lock do
        pending.reload
        unless pending.holding?
          raise StockMovementService::Error, "Stock pending is already #{pending.workflow_status}"
        end

        StockMovementService::BaseService.call(
          stock: pending.stock.reload, quantity: pending.quantity,
          direction: :add, transaction_type: :release, document: pending
        )
        @target == "cancel" ? pending.cancel! : pending.release!
      end
    end
  end
end
