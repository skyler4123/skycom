# frozen_string_literal: true

# Inventory::AdjustmentService — the Adjust drawer's write path. Turns a target
# "new on hand" into a delta StockAdjustment (increase/decrease), never touching
# reserved units, and stores the chosen reason.
# Docs: docs/STOCK.md §4.2, docs/business_analysis/05-inventory.md §5
class Inventory::AdjustmentService
  def self.adjust(company:, warehouse:, employee:, stock_id:, new_on_hand:, reason:, note: nil)
    new(company: company, warehouse: warehouse, employee: employee).adjust(
      stock_id: stock_id, new_on_hand: new_on_hand, reason: reason, note: note
    )
  end

  def initialize(company:, warehouse:, employee:)
    @company = company
    @warehouse = warehouse
    @employee = employee
  end

  def adjust(stock_id:, new_on_hand:, reason:, note: nil)
    stock = find_stock!(stock_id)
    target = normalize_target!(new_on_hand)
    reason = normalize_reason!(reason, note)

    if target < stock.pending.to_i
      raise Inventory::Error, "On hand cannot be less than the #{stock.pending.to_i} reserved."
    end

    delta = target - stock.quantity.to_i
    raise Inventory::Error, "New on hand must differ from the current on hand." if delta.zero?

    old_on_hand = stock.quantity.to_i
    adjustment = build_adjustment(stock, delta, reason, note)

    ActiveRecord::Base.transaction do
      adjustment.save!
      adjustment.stock_adjustment_stock_appointments.create!(
        company: company,
        stock: stock,
        quantity: delta.abs
      )
      StockMovementService::Adjustments::CreateService.execute!(document: adjustment, employee: employee)
    end

    stock.reload
    {
      message: "Adjusted #{item_name(stock)} · on hand #{old_on_hand} → #{stock.quantity} · #{reason}",
      adjustment_id: adjustment.id
    }
  end

  private

  attr_reader :company, :warehouse, :employee

  def build_adjustment(stock, delta, reason, note)
    company.stock_adjustments.new(
      company: company,
      branch: stock.branch,
      warehouse: warehouse,
      category: stock.category,
      property_mapping: stock.property_mapping,
      code: "STKAD-#{SecureRandom.hex(4).upcase}",
      name: "Adjustment #{item_name(stock)}",
      description: note.presence,
      reason: reason,
      direction: delta.positive? ? :increase : :decrease,
      workflow_status: :pending
    )
  end

  def find_stock!(stock_id)
    stock = company.stocks.where(warehouse_id: warehouse.id, discarded_at: nil).find_by(id: stock_id)
    raise Inventory::Error, "Item not found in this warehouse." if stock.blank?

    stock
  end

  def normalize_target!(new_on_hand)
    number = Integer(new_on_hand, exception: false)
    raise Inventory::Error, "New on hand must be a whole number 0 or more." unless number && number >= 0

    number
  end

  def normalize_reason!(reason, note)
    reason = reason.to_s.strip
    raise Inventory::Error, "Choose a reason." if reason.blank?
    raise Inventory::Error, "Choose a valid reason." unless STOCK_ADJUSTMENT_REASONS.include?(reason)
    raise Inventory::Error, "Add a note for Other." if reason == "Other" && note.blank?

    reason
  end

  def item_name(stock)
    stock.name.presence || stock.product&.name.presence || stock.code.presence || "Item"
  end
end
