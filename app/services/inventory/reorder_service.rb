# frozen_string_literal: true

# Inventory::ReorderService — turns a Low/Out stock row into a real purchase
# draft. One open purchase per product per warehouse: a second press returns the
# existing purchase instead of creating another.
# Docs: docs/PURCHASE_WORKFLOW.md, docs/business_analysis/05-inventory.md §6
class Inventory::ReorderService
  def self.create(company:, warehouse:, employee:, stock_id:, supplier_id: nil, quantity: nil)
    new(company: company, warehouse: warehouse, employee: employee).create(
      stock_id: stock_id, supplier_id: supplier_id, quantity: quantity
    )
  end

  def initialize(company:, warehouse:, employee:)
    @company = company
    @warehouse = warehouse
    @employee = employee
  end

  def create(stock_id:, supplier_id: nil, quantity: nil)
    stock = find_stock!(stock_id)
    reorder_point = reorder_point_for(stock)
    available = available_for(stock)
    shortfall = reorder_point - available
    raise Inventory::Error, "This item is not below its reorder point." unless shortfall.positive?

    quantity = normalize_quantity!(quantity.presence || shortfall)
    supplier = resolve_supplier!(stock.product, supplier_id)

    existing = open_purchase_for(stock.product)
    return existing_result(existing) if existing.present?

    purchase = nil
    stock.with_lock do
      existing = open_purchase_for(stock.product)
      return existing_result(existing) if existing.present?

      purchase = create_purchase(stock, quantity, supplier, shortfall)
    end

    {
      message: "Purchase #{purchase.code} drafted · #{quantity} × #{item_name(stock)}",
      purchase: purchase_payload(purchase)
    }
  end

  private

  attr_reader :company, :warehouse, :employee

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

  def reorder_point_for(stock)
    rule = ReorderRule.where(
      company_id: company.id,
      product_id: stock.product_id,
      warehouse_id: warehouse.id,
      is_active: true,
      discarded_at: nil
    ).first

    rule.present? ? rule.min_quantity.to_i + rule.safety_stock.to_i : LOW_STOCK_THRESHOLD
  end

  def resolve_supplier!(product, supplier_id)
    if supplier_id.present?
      supplier = company.suppliers.where(discarded_at: nil).find_by(id: supplier_id)
      raise Inventory::Error, "Supplier not found." if supplier.blank?

      return supplier
    end

    product.default_supplier ||
      raise(Inventory::Error, "Choose a supplier for this purchase.")
  end

  def open_purchase_for(product)
    closed_statuses = Purchase.workflow_statuses.values_at("completed", "cancelled", "failed", "refunded")

    PurchasePurchaseItemAppointment
      .joins(:purchase, :purchase_item)
      .where(purchases: {
        company_id: company.id,
        warehouse_id: warehouse.id,
        discarded_at: nil
      })
      .where.not(purchases: { workflow_status: closed_statuses })
      .where(purchase_items: { product_id: product.id })
      .includes(:purchase)
      .order(Arel.sql("purchases.created_at DESC"))
      .first
      &.purchase
  end

  def create_purchase(stock, quantity, supplier, shortfall)
    product = stock.product
    purchase_category = company.categories.find_by(resource_name: "purchases") || stock.category
    purchase_mapping = purchase_category&.default_property_mapping || stock.property_mapping
    raise Inventory::Error, "Purchasing is not configured for this company." if purchase_category.blank? || purchase_mapping.blank?

    purchase_item = find_or_create_purchase_item(product, purchase_category)
    unit_price = product.price&.to_f || 0

    purchase = company.purchases.new(
      company: company,
      branch: warehouse.branch,
      warehouse: warehouse,
      supplier: supplier,
      category: purchase_category,
      property_mapping: purchase_mapping,
      code: "PUR-#{SecureRandom.hex(4).upcase}",
      name: purchase_name(product),
      description: "Reorder from Inventory · #{stock.code} · short by #{shortfall}",
      business_type: :stock_reorder,
      currency: company.currency || "usd"
    )
    purchase.created_by_employee = employee
    purchase.save!

    purchase.purchase_purchase_item_appointments.create!(
      company: company,
      purchase_item: purchase_item,
      quantity: quantity,
      unit_price: unit_price,
      total_price: quantity * unit_price
    )

    purchase
  end

  def find_or_create_purchase_item(product, purchase_category)
    existing = company.purchase_items.find_by(product_id: product.id)
    return existing if existing.present?

    item_category = company.categories.find_by(resource_name: "purchase_items") || purchase_category
    item_mapping = item_category&.default_property_mapping || product.property_mapping
    raise Inventory::Error, "Purchasing is not configured for this company." if item_category.blank? || item_mapping.blank?

    company.purchase_items.create!(
      company: company,
      product: product,
      category: item_category,
      property_mapping: item_mapping,
      name: unique_purchase_item_name(product),
      unit: "piece",
      estimated_unit_price: product.price&.to_f
    )
  end

  def unique_purchase_item_name(product)
    base = product.name.presence || "Item #{product.code.presence || product.id.to_s.first(6)}"
    candidate = base
    2.upto(20) do |index|
      break unless company.purchase_items.exists?(name: candidate)

      candidate = "#{base} (#{index})"
    end
    candidate
  end

  def purchase_name(product)
    base = "Reorder #{product.name.presence || product.code}".strip
    suffix = " · #{Date.current.iso8601} · #{SecureRandom.hex(2).upcase}"
    base.first(255 - suffix.length) + suffix
  end

  def existing_result(purchase)
    {
      message: "Purchase #{purchase.code} is already open.",
      purchase: purchase_payload(purchase),
      existing: true
    }
  end

  def purchase_payload(purchase)
    {
      id: purchase.id,
      code: purchase.code,
      path: "/companies/#{company.id}/purchases/#{purchase.id}",
      workflow_status: purchase.workflow_status
    }
  end

  def item_name(stock)
    stock.name.presence || stock.product&.name.presence || stock.code.presence || "Item"
  end
end
