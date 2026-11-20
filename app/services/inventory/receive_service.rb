# frozen_string_literal: true

# Inventory::ReceiveService — the Receive drawer's write path. Creates a
# StockImport + one atomic line, executes it through the stock movement epic
# (one `add` ledger row, on hand increases), and optionally records the put-away
# location on the stock row.
# Docs: docs/STOCK.md §4.2, docs/business_analysis/05-inventory.md §3
class Inventory::ReceiveService
  def self.post(company:, warehouse:, employee:, stock_id:, quantity:, supplier_id: nil, location: nil, note: nil)
    new(company: company, warehouse: warehouse, employee: employee).post(
      stock_id: stock_id, quantity: quantity, supplier_id: supplier_id, location: location, note: note
    )
  end

  def self.post_import(company:, warehouse:, employee:, import_id:, stock_id: nil, quantity: nil, location: nil)
    new(company: company, warehouse: warehouse, employee: employee).post_import(
      import_id: import_id, stock_id: stock_id, quantity: quantity, location: location
    )
  end

  def initialize(company:, warehouse:, employee:)
    @company = company
    @warehouse = warehouse
    @employee = employee
  end

  def post(stock_id:, quantity:, supplier_id: nil, location: nil, note: nil)
    stock = find_stock!(stock_id)
    quantity = normalize_quantity!(quantity)
    validate_stockable!(stock)
    supplier = find_supplier(supplier_id)

    old_on_hand = stock.quantity.to_i
    import = build_import(stock, quantity, supplier, location, note)

    ActiveRecord::Base.transaction do
      import.save!
      import.stock_import_stock_appointments.create!(company: company, stock: stock, quantity: quantity)
      StockMovementService::Imports::CreateService.execute!(document: import, employee: employee)
      stock.update!(property_string_1: location) if location.present?
    end

    stock.reload
    {
      message: "Received #{quantity} · #{item_name(stock)} · on hand #{old_on_hand} → #{stock.quantity}",
      import_id: import.id
    }
  end

  def post_import(import_id:, stock_id: nil, quantity: nil, location: nil)
    import = company.stock_imports.where(warehouse_id: warehouse.id, discarded_at: nil).find(import_id)
    raise Inventory::Error, "This receipt is already #{import.workflow_status}." if closed?(import)

    if import.stock_import_stock_appointments.none?
      raise Inventory::Error, "This receipt has no line items." if stock_id.blank? || quantity.blank?

      stock = find_stock!(stock_id)
      quantity = normalize_quantity!(quantity)
      validate_stockable!(stock)
      validate_line_warehouse!(stock)

      ActiveRecord::Base.transaction do
        import.stock_import_stock_appointments.create!(company: company, stock: stock, quantity: quantity)
        import.update!(product_id: import.product_id || stock.product_id, quantity: quantity)
        StockMovementService::Imports::CreateService.execute!(document: import, employee: employee)
        stock.update!(property_string_1: location) if location.present?
      end
    else
      import.stock_import_stock_appointments.includes(:stock).each do |line|
        validate_line_warehouse!(line.stock)
      end

      ActiveRecord::Base.transaction do
        StockMovementService::Imports::CreateService.execute!(document: import, employee: employee)
      end
    end

    units = import.quantity.to_i.positive? ? import.quantity.to_i : import.stock_import_stock_appointments.sum(&:quantity)
    {
      message: "Received #{units} · #{import.code}",
      import_id: import.id
    }
  end

  private

  attr_reader :company, :warehouse, :employee

  def build_import(stock, quantity, supplier, location, note)
    company.stock_imports.new(
      company: company,
      branch: stock.branch,
      warehouse: warehouse,
      product: stock.product,
      category: stock.category,
      property_mapping: stock.property_mapping,
      code: "STKIM-#{SecureRandom.hex(4).upcase}",
      name: "Receipt #{item_name(stock)}",
      description: note.presence,
      quantity: quantity,
      business_type: supplier.present? ? :purchase : :adjustment,
      workflow_status: :pending,
      appoint_from: supplier,
      appoint_by: employee,
      property_string_1: location.presence
    )
  end

  def find_stock!(stock_id)
    stock = company.stocks.where(warehouse_id: warehouse.id, discarded_at: nil).find_by(id: stock_id)
    raise Inventory::Error, "Item not found in this warehouse." if stock.blank?

    stock
  end

  def find_supplier(supplier_id)
    return nil if supplier_id.blank?

    supplier = company.suppliers.where(discarded_at: nil).find_by(id: supplier_id)
    raise Inventory::Error, "Supplier not found." if supplier.blank?

    supplier
  end

  def normalize_quantity!(quantity)
    number = Integer(quantity, exception: false)
    raise Inventory::Error, "Quantity must be a whole number greater than 0." unless number&.positive?

    number
  end

  def validate_stockable!(stock)
    raise Inventory::Error, "This item is not a stocked product." if stock.product.blank?
    raise Inventory::Error, "Service items cannot be stocked." if stock.product.service_based?
  end

  def validate_line_warehouse!(stock)
    return if stock.warehouse_id == warehouse.id

    raise Inventory::Error, "This receipt contains an item from another warehouse."
  end

  def closed?(import)
    %w[received completed cancelled failed].include?(import.workflow_status.to_s)
  end

  def item_name(stock)
    stock.name.presence || stock.product&.name.presence || stock.code.presence || "Item"
  end
end
