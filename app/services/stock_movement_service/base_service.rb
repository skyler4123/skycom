# frozen_string_literal: true

# == Purpose:
# The epic for every stock quantity movement (docs/superpowers/specs/
# 2026-09-23-stock-source-of-truth-design.md). One entry point that validates
# the floor rule, locks the Stock row, creates the StockTransaction (whose
# hardened callback applies the quantity delta), and consumes an existing
# pending hold when asked.
#
# == The write-path rule:
# Stock.quantity is mutated ONLY by StockTransaction#recalibrate_stock_metrics.
# Stock.pending (the promise/hold counter) is mutated only through the Stock
# wrapper methods (reserve_stock! / release_reserved! — docs/KREDIS.md).
# This service never writes either column directly.
#
# == Failure semantics:
# Any failure raises StockMovementService::Error (or RecordNotFound) so the
# caller's surrounding transaction rolls back document + ledger + quantity
# together. Callers (controllers/jobs) rescue the error and render 422.
#
# == Hold-aware floor (remove direction):
# - consume_hold: false → free-standing removal: quantity - pending >= qty
#   (cannot consume units promised to another order/transfer)
# - consume_hold: true  → the removal consumes an existing pending hold
#   (POS finalize, transfer receive): quantity >= qty AND pending >= qty.
#   The hold is released AFTER the ledger row is created so a callback
#   failure never desyncs Redis.
class StockMovementService::BaseService
  def self.call(stock:, quantity:, direction:, transaction_type:, document: nil,
                employee: nil, appoint_from: nil, appoint_to: nil, consume_hold: false)
    new(stock: stock, quantity: quantity, direction: direction,
        transaction_type: transaction_type, document: document, employee: employee,
        appoint_from: appoint_from, appoint_to: appoint_to,
        consume_hold: consume_hold).call
  end

  def initialize(stock:, quantity:, direction:, transaction_type:, document: nil,
                 employee: nil, appoint_from: nil, appoint_to: nil, consume_hold: false)
    @stock = stock
    @quantity = quantity.to_i
    @direction = direction.to_s
    @transaction_type = transaction_type.to_s
    @document = document
    @employee = employee
    @appoint_from = appoint_from
    @appoint_to = appoint_to
    @consume_hold = consume_hold
  end

  def call
    validate!
    apply_floor_rule!

    stock_transaction = nil
    stock.with_lock do
      stock_transaction = StockTransaction.create!(transaction_attributes)
      stock.release_reserved!(@quantity) if @consume_hold
    end

    { success: true, stock_transaction: stock_transaction }
  end

  private

  attr_reader :stock

  def validate!
    raise StockMovementService::Error, "Quantity must be greater than 0" if @quantity <= 0
    raise StockMovementService::Error, "Invalid direction" unless StockTransaction.directions.key?(@direction)
    unless StockTransaction.transaction_types.key?(@transaction_type)
      raise StockMovementService::Error, "Invalid transaction type"
    end
    if @transaction_type == "import" && @direction != "add"
      raise StockMovementService::Error, "Import transactions must be add direction"
    end
    if @transaction_type == "export" && @direction != "remove"
      raise StockMovementService::Error, "Export transactions must be remove direction"
    end
    if @consume_hold && @direction != "remove"
      raise StockMovementService::Error, "consume_hold is only valid for remove direction"
    end
  end

  def apply_floor_rule!
    stock.reload
    if @direction == "remove"
      if @consume_hold
        return if stock.quantity >= @quantity && stock.pending >= @quantity

        raise StockMovementService::Error,
              "Insufficient stock to consume hold: quantity #{stock.quantity}, pending #{stock.pending}, need #{@quantity}"
      end

      available = stock.quantity - stock.pending
      return if available >= @quantity

      raise StockMovementService::Error,
            "Insufficient stock: available #{available}, need #{@quantity}"
    end
  end

  def transaction_attributes
    {
      company_id: stock.company_id,
      branch_id: stock.branch_id,
      warehouse_id: stock.warehouse_id,
      product_id: stock.product_id,
      category_id: stock.category_id,
      property_mapping_id: stock.property_mapping_id,
      quantity: @quantity,
      direction: @direction,
      transaction_type: @transaction_type,
      appoint_for_type: @document && @document.class.name,
      appoint_for_id: @document && @document.id,
      appoint_by_type: @employee && @employee.class.name,
      appoint_by_id: @employee && @employee.id,
      appoint_from_type: @appoint_from && @appoint_from.class.name,
      appoint_from_id: @appoint_from && @appoint_from.id,
      appoint_to_type: @appoint_to && @appoint_to.class.name,
      appoint_to_id: @appoint_to && @appoint_to.id
    }
  end
end
