# frozen_string_literal: true

# Pos::SellingStockResolver — one answer to "which pile is this branch selling?"
#
# A branch may be served by several warehouses. POS uses one pile per product so
# the number shown, the line's stock_id, and the reserved hold are the same row.
# Priority is explicit and deterministic: main warehouse first, then oldest.
# The first warehouse in that order with sellable stock wins; when none has
# stock, the first warehouse is returned with its zero count.
module Pos
  class SellingStockResolver
    def self.for_products(company:, branch:, products:)
      new(company: company, branch: branch, products: products).call
    end

    def initialize(company:, branch:, products:)
      @company = company
      @branch = branch
      @products = Array(products)
    end

    def call
      return {} if @products.empty?

      warehouses = ordered_warehouses
      return @products.to_h { |product| [ product.id, nil ] } if warehouses.empty?

      stocks = @company.stocks
        .where(product_id: @products.map(&:id), warehouse_id: warehouses.map(&:id))
        .includes(:warehouse)
        .group_by(&:product_id)

      @products.to_h do |product|
        candidates = (stocks[product.id] || []).sort_by { |stock| warehouse_index(stock, warehouses) }
        [ product.id, candidates.find { |stock| stock.available_count.positive? } || candidates.first ]
      end
    end

    private

    def ordered_warehouses
      @branch.warehouses.to_a.sort_by do |warehouse|
        [ warehouse.business_type == "main" ? 0 : 1, warehouse.created_at, warehouse.id ]
      end
    end

    def warehouse_index(stock, warehouses)
      warehouses.index { |warehouse| warehouse.id == stock.warehouse_id } || warehouses.length
    end
  end
end
