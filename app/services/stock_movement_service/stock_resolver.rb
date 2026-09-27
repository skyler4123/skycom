# frozen_string_literal: true

# Resolves (or positively creates) the Stock row for a (company, warehouse,
# product) triple. Movement documents reference specific Stock rows; when the
# pair has no row yet (first delivery of a product into a warehouse) a new row
# is created with quantity 0 — creation is NOT a movement, so this never goes
# through the ledger. Every subsequent quantity change goes through
# StockMovementService::* (docs/superpowers/specs/2026-09-23-stock-source-of-truth-design.md).
class StockMovementService::StockResolver
  def self.resolve!(company:, warehouse:, product:)
    Stock.find_by(company_id: company.id, warehouse_id: warehouse.id, product_id: product.id) ||
      create_positive!(company: company, warehouse: warehouse, product: product)
  end

  def self.create_positive!(company:, warehouse:, product:)
    category = Category.find_or_create_by!(
      company: company, resource_name: "stocks"
    ) { |cat| cat.name = "Stocks" }

    Stock.create!(
      company: company,
      branch: warehouse.branch,
      warehouse: warehouse,
      product: product,
      category: category,
      property_mapping: category.default_property_mapping,
      name: product.name,
      code: "STK-#{SecureRandom.hex(4).upcase}",
      quantity: 0,
      pending: 0
    )
  end
end
