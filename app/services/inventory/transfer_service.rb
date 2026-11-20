# frozen_string_literal: true

# Inventory::TransferService — the Transfer out drawer's write path. Creates a
# stock transfer document and immediately initiates it: the source units are
# held (pending) so available drops at once; the destination marks it received
# from its own Inventory console.
# Docs: docs/STOCK.md §4.3, docs/business_analysis/05-inventory.md §4
class Inventory::TransferService
  def self.transfer(company:, warehouse:, employee:, stock_id:, quantity:, destination_warehouse_id:, note: nil)
    new(company: company, warehouse: warehouse, employee: employee).transfer(
      stock_id: stock_id, quantity: quantity,
      destination_warehouse_id: destination_warehouse_id, note: note
    )
  end

  def self.receive(company:, warehouse:, employee:, transfer_id:)
    new(company: company, warehouse: warehouse, employee: employee).receive(transfer_id: transfer_id)
  end

  def initialize(company:, warehouse:, employee:)
    @company = company
    @warehouse = warehouse
    @employee = employee
  end

  def transfer(stock_id:, quantity:, destination_warehouse_id:, note: nil)
    stock = find_stock!(stock_id)
    quantity = normalize_quantity!(quantity)
    destination = find_destination!(destination_warehouse_id)
    available = available_for(stock)

    if quantity > available
      raise Inventory::Error, "Only #{available} available in #{warehouse.name}."
    end

    transfer = build_transfer(stock, quantity, destination, note)

    ActiveRecord::Base.transaction do
      transfer.save!
      transfer.stock_transfer_stock_appointments.create!(company: company, stock: stock, quantity: quantity)
      StockMovementService::Transfers::InitiateService.call(transfer: transfer, employee: employee)
    end

    {
      message: "Transfer #{transfer.code} started · #{quantity} #{item_name(stock)} held · available #{available} → #{available - quantity}",
      transfer_id: transfer.id,
      code: transfer.code
    }
  end

  def receive(transfer_id:)
    transfer = company.stock_transfers
      .where(destination_warehouse_id: warehouse.id, discarded_at: nil)
      .find(transfer_id)

    unless transfer.workflow_status_initiated?
      raise Inventory::Error, "Transfer must be in transit before it can be received."
    end

    StockMovementService::Transfers::ReceiveService.call(transfer: transfer, employee: employee)

    {
      message: "Transfer #{transfer.code} received · #{transfer.quantity.to_i} units added to #{warehouse.name}",
      transfer_id: transfer.id
    }
  end

  private

  attr_reader :company, :warehouse, :employee

  def build_transfer(stock, quantity, destination, note)
    company.stock_transfers.new(
      company: company,
      branch: stock.branch,
      warehouse: warehouse,
      destination_warehouse: destination,
      product: stock.product,
      category: stock.category,
      property_mapping: stock.property_mapping,
      code: "STKTR-#{SecureRandom.hex(4).upcase}",
      name: "Transfer to #{destination.name}",
      description: note.presence,
      quantity: quantity,
      business_type: :transfer,
      workflow_status: :pending,
      appoint_by: employee
    )
  end

  def find_stock!(stock_id)
    stock = company.stocks.where(warehouse_id: warehouse.id, discarded_at: nil).find_by(id: stock_id)
    raise Inventory::Error, "Item not found in this warehouse." if stock.blank?

    stock
  end

  def find_destination!(destination_warehouse_id)
    destination = company.warehouses.where(discarded_at: nil).find_by(id: destination_warehouse_id)
    raise Inventory::Error, "Choose a destination warehouse." if destination.blank?
    raise Inventory::Error, "Choose a different destination warehouse." if destination.id == warehouse.id

    destination
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
