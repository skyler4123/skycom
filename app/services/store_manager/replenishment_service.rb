# frozen_string_literal: true

# StoreManager::ReplenishmentService — one low shelf row becomes one real
# document.
#
# Reuse first: an open transfer for the same product → destination, or an open
# purchase for the same product → warehouse, is returned instead of creating a
# second document. Otherwise a transfer is started from the supplying warehouse
# when it has stock; with no warehouse stock it creates the same purchase draft
# the Inventory console uses.
#
# Docs: docs/STOCK.md, docs/business_analysis/06-store-manager.md
class StoreManager::ReplenishmentService
  OPEN_TRANSFER_STATUSES = %w[pending initiated].freeze
  CLOSED_PURCHASE_STATUSES = %w[completed cancelled failed refunded].freeze

  def self.call(company:, branch:, employee:, stock_id:, quantity: nil, supplier_id: nil)
    new(company: company, branch: branch, employee: employee).call(
      stock_id: stock_id, quantity: quantity, supplier_id: supplier_id
    )
  end

  def initialize(company:, branch:, employee:)
    @company = company
    @branch = branch
    @employee = employee
  end

  def call(stock_id:, quantity: nil, supplier_id: nil)
    stock = find_stock!(stock_id)
    shortfall = shortfall_for(stock)
    raise StoreManager::Error, "This item is not below its reorder point." unless shortfall.positive?

    stock.with_lock do
      existing = existing_document(stock)
      return existing_result(existing, stock) if existing.present?

      source = source_stock(stock)
      if source.present?
        create_transfer(stock, source, shortfall, quantity)
      else
        create_purchase(stock, shortfall, quantity, supplier_id)
      end
    end
  end

  private

  attr_reader :company, :branch, :employee

  def find_stock!(stock_id)
    stock = company.stocks
      .includes(:product, :warehouse)
      .find_by(id: stock_id, discarded_at: nil)
    raise StoreManager::Error, "Item not found at this branch." if stock.blank?

    branch_match = stock.branch_id == branch.id || stock.warehouse&.branch_id == branch.id
    raise StoreManager::Error, "Item not found at this branch." unless branch_match

    stock
  end

  def reorder_point_for(stock)
    rule = ReorderRule.where(
      company_id: company.id,
      product_id: stock.product_id,
      warehouse_id: stock.warehouse_id,
      is_active: true,
      discarded_at: nil
    ).first

    rule.present? ? rule.min_quantity.to_i + rule.safety_stock.to_i : LOW_STOCK_THRESHOLD
  end

  def available_for(stock)
    [ stock.quantity.to_i - stock.pending.to_i, 0 ].max
  end

  def shortfall_for(stock)
    reorder_point_for(stock) - available_for(stock)
  end

  def source_stock(stock)
    candidates = company.stocks
      .where(product_id: stock.product_id, discarded_at: nil)
      .where.not(warehouse_id: stock.warehouse_id)
      .includes(:warehouse)
    source = candidates.max_by { |candidate| available_for(candidate) }
    source if source && available_for(source).positive?
  end

  def existing_document(stock)
    transfer = company.stock_transfers
      .where(product_id: stock.product_id, destination_warehouse_id: stock.warehouse_id, discarded_at: nil)
      .where(workflow_status: OPEN_TRANSFER_STATUSES)
      .order(created_at: :desc)
      .first
    return transfer_document(transfer, existing: true) if transfer.present?

    purchase = company.purchases
      .joins(:purchase_items)
      .where(purchases: { warehouse_id: stock.warehouse_id, discarded_at: nil })
      .where.not(purchases: { workflow_status: CLOSED_PURCHASE_STATUSES })
      .where(purchase_items: { product_id: stock.product_id })
      .order(Arel.sql("purchases.created_at DESC"))
      .first
    return purchase_document(purchase, existing: true) if purchase.present?

    nil
  end

  def create_transfer(stock, source, shortfall, quantity)
    source_available = available_for(source)
    requested = normalize_quantity!(quantity.presence || [ shortfall, source_available ].min)
    result = Inventory::TransferService.transfer(
      company: company,
      warehouse: source.warehouse,
      employee: employee,
      stock_id: source.id,
      quantity: requested,
      destination_warehouse_id: stock.warehouse_id,
      note: "Store Manager replenishment for #{stock.code}"
    )

    {
      message: result[:message],
      existing: false,
      document: {
        type: "transfer",
        id: result[:transfer_id],
        code: result[:code],
        path: "/companies/#{company.id}/stock_transfers/#{result[:transfer_id]}"
      }
    }
  end

  def create_purchase(stock, shortfall, quantity, supplier_id)
    requested = normalize_quantity!(quantity.presence || shortfall)
    result = Inventory::ReorderService.create(
      company: company,
      warehouse: stock.warehouse,
      employee: employee,
      stock_id: stock.id,
      supplier_id: supplier_id,
      quantity: requested
    )

    {
      message: result[:message],
      existing: result[:existing] == true,
      document: {
        type: "purchase",
        id: result.dig(:purchase, :id),
        code: result.dig(:purchase, :code),
        path: result.dig(:purchase, :path)
      }
    }
  end

  def existing_result(document, stock)
    type = document[:type]
    {
      message: "#{type == 'transfer' ? 'Transfer' : 'Purchase'} #{document[:code]} is already open for #{stock.name}.",
      existing: true,
      document: document
    }
  end

  def transfer_document(transfer, existing:)
    {
      type: "transfer",
      id: transfer.id,
      code: transfer.code,
      path: "/companies/#{company.id}/stock_transfers/#{transfer.id}",
      existing: existing
    }
  end

  def purchase_document(purchase, existing:)
    {
      type: "purchase",
      id: purchase.id,
      code: purchase.code,
      path: "/companies/#{company.id}/purchases/#{purchase.id}",
      existing: existing
    }
  end

  def normalize_quantity!(quantity)
    number = Integer(quantity, exception: false)
    raise StoreManager::Error, "Quantity must be a whole number greater than 0." unless number&.positive?

    number
  end
end
