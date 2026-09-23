# frozen_string_literal: true

# Bridges a completed Purchase into the stock domain (docs/PURCHASE_WORKFLOW.md
# §8 tenet 6: purchases reach stock only through the stock services, never
# direct writes). Called from Workflows::AdvanceService when a Purchase's final
# step is approved. One transaction (the advance's):
#   1. Resolve each purchase_item_appointment → the destination warehouse's
#      Stock row (created positively when the pair has no row yet).
#   2. Build a StockImport (business_type: purchase, appoint_from: purchase,
#      workflow_status: received) with StockItemAppointment lines.
#   3. Write one `add` ledger row per line (transaction_type: import) — the
#      hardened callback increases Stock.quantity.
# Idempotent: skips when an import for this purchase already exists. Purchases
# whose items carry no product (office supplies, services) skip the bridge —
# they have no stock to land.
class StockMovementService::Purchases::CompleteService
  def self.call(purchase:, employee: nil)
    return { success: true, skipped: true } if import_exists?(purchase)

    line_items = purchase.purchase_item_appointments.includes(purchase_item: :product)
    # Nothing to land → nothing to bridge. Completing a bare purchase must not
    # be blocked by the stock layer.
    return { success: true, skipped: true, reason: "no_line_items" } if line_items.empty?

    stocked_lines = line_items.select { |item| item.purchase_item&.product.present? }
    return { success: true, skipped: true, reason: "no_stocked_items" } if stocked_lines.empty?

    import = StockImport.new(
      company: purchase.company,
      branch: purchase.branch,
      warehouse: purchase.warehouse,
      category: purchase.category,
      property_mapping: purchase.property_mapping,
      code: "STKIM-#{SecureRandom.hex(4).upcase}",
      name: "Import for #{purchase.name}",
      business_type: :purchase,
      workflow_status: :pending,
      appoint_from: purchase
    )

    stocked_lines.each do |item|
      product = item.purchase_item.product

      stock = StockMovementService::StockResolver.resolve!(
        company: purchase.company,
        warehouse: purchase.warehouse,
        product: product
      )

      import.stock_item_appointments.build(
        company: purchase.company,
        stock: stock,
        quantity: item.quantity
      )
    end

    ActiveRecord::Base.transaction do
      import.save!
      import.stock_item_appointments.each do |line|
        StockMovementService::BaseService.call(
          stock: line.stock.reload,
          quantity: line.quantity,
          direction: :add,
          transaction_type: :import,
          document: import,
          employee: employee
        )
      end
      import.update!(workflow_status: :received)
    end

    { success: true, import: import }
  end

  def self.import_exists?(purchase)
    StockImport.where(company_id: purchase.company_id, appoint_from_type: "Purchase", appoint_from_id: purchase.id).exists?
  end
end
