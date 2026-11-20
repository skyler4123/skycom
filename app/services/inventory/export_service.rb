# frozen_string_literal: true

# Inventory::ExportService — the "Leaving the company" branch of the Transfer
# out drawer. One-shot StockExport: the source on hand drops, nothing arrives
# anywhere else. A reference note is mandatory because the goods leave without
# a destination warehouse.
# Docs: docs/STOCK.md §4.2, docs/business_analysis/05-inventory.md §4.3
class Inventory::ExportService
  def self.export(company:, warehouse:, employee:, stock_id:, quantity:, reference:, note: nil)
    new(company: company, warehouse: warehouse, employee: employee).export(
      stock_id: stock_id, quantity: quantity, reference: reference, note: note
    )
  end

  def initialize(company:, warehouse:, employee:)
    @company = company
    @warehouse = warehouse
    @employee = employee
  end

  def export(stock_id:, quantity:, reference:, note: nil)
    stock = find_stock!(stock_id)
    quantity = normalize_quantity!(quantity)
    reference = reference.to_s.strip
    raise Inventory::Error, "Enter a reference for this export." if reference.blank?

    available = available_for(stock)
    raise Inventory::Error, "Only #{available} available in #{warehouse.name}." if quantity > available

    old_on_hand = stock.quantity.to_i
    export = build_export(stock, quantity, reference, note)

    ActiveRecord::Base.transaction do
      export.save!
      export.stock_export_stock_appointments.create!(company: company, stock: stock, quantity: quantity)
      StockMovementService::Exports::CreateService.execute!(document: export, employee: employee)
    end

    stock.reload
    {
      message: "Exported #{quantity} · #{item_name(stock)} · on hand #{old_on_hand} → #{stock.quantity} · #{reference}",
      export_id: export.id,
      code: export.code
    }
  end

  private

  attr_reader :company, :warehouse, :employee

  def build_export(stock, quantity, reference, note)
    company.stock_exports.new(
      company: company,
      branch: stock.branch,
      warehouse: warehouse,
      product: stock.product,
      category: stock.category,
      property_mapping: stock.property_mapping,
      code: "STKEX-#{SecureRandom.hex(4).upcase}",
      name: reference,
      description: note.presence,
      quantity: quantity,
      business_type: :adjustment,
      workflow_status: :pending,
      appoint_by: employee
    )
  end

  def find_stock!(stock_id)
    stock = company.stocks.where(warehouse_id: warehouse.id, discarded_at: nil).find_by(id: stock_id)
    raise Inventory::Error, "Item not found in this warehouse." if stock.blank?

    stock
  end

  def normalize_quantity!(quantity)
    number = Integer(quantity, exception: false)
    raise Inventory::Error, "Quantity must be a whole number greater than 0." unless number&.positive?

    number
  end

  def available_for(stock)
    [ stock.quantity.to_i - stock.pending.to_i, 0 ].max
  end

  def item_name(stock)
    stock.name.presence || stock.product&.name.presence || stock.code.presence || "Item"
  end
end
