# frozen_string_literal: true

# Pos::CatalogService — the single payload builder for the POS catalog.
#
# Prices are server-owned cents, tax is the company's configured POS rate, and
# stock is one deterministic pile per product (main warehouse first, then
# oldest). The cap is explicit: the UI can say "Showing 50 of N" instead of
# silently hiding the rest. When a search query is present, Meilisearch supplies
# the matching ids; the DB still loads the records and prices.
module Pos
  class CatalogService
    def self.call(company:, branch:, query: nil)
      new(company: company, branch: branch, query: query).call
    end

    def initialize(company:, branch:, query: nil)
      @company = company
      @branch = branch
      @query = query.to_s.strip
    end

    def call
      products = load_products
      service_rows = services
      stocks = Pos::SellingStockResolver.for_products(
        company: @company, branch: @branch, products: products
      )

      {
        currency: @company.currency,
        tax: tax_payload,
        catalog: {
          limit: POS_CATALOG_LIMIT,
          products_total: @products_total,
          services_total: @services_total
        },
        products: products.map { |product| product_payload(product, stocks[product.id]) },
        services: service_rows.map { |service| service_payload(service) }
      }
    end

    private

    def tax_payload
      config = TaxConfig.for_company!(@company)
      {
        rate_bp: config.pos_tax_rate_bp.to_i,
        rate_percent: config.pos_tax_rate_percent,
        name: config.pos_tax_name.presence || "Tax"
      }
    end

    def load_products
      scope = @company.products.where(branch_id: @branch.id).includes(:category)
      if @query.blank?
        @products_total = scope.count
        scope.order(:name).limit(POS_CATALOG_LIMIT).to_a
      else
        ids, total = search_ids(Product)
        @products_total = total
        return [] if ids.empty?

        scope.where(id: ids).in_order_of(:id, ids).to_a
      end
    end

    def services
      return @services if defined?(@services)

      scope = @company.services.where(branch_id: @branch.id).includes(:category)
      if @query.blank?
        @services_total = scope.count
        @services = scope.order(:name).limit(POS_CATALOG_LIMIT).to_a
      else
        ids, total = search_ids(Service)
        @services_total = total
        @services = ids.empty? ? [] : scope.where(id: ids).in_order_of(:id, ids).to_a
      end
    end

    def search_ids(model)
      result = model.ms_raw_search(
        @query,
        filter: %(company_id = "#{@company.id}" AND branch_id = "#{@branch.id}"),
        limit: POS_CATALOG_LIMIT
      )
      ids = Array(result["hits"]).map { |hit| hit["id"] }
      [ ids, (result["estimatedTotalHits"] || ids.length).to_i ]
    rescue Meilisearch::Error
      # Let Companies::ApplicationController translate this to a JSON 503; a
      # silent unfiltered fallback would show the wrong catalog.
      raise
    end

    def product_payload(product, stock)
      {
        id: product.id,
        name: product.name,
        code: product.code,
        category_id: product.category_id,
        category_name: product.category&.name,
        price_cents: product.price_cents,
        price_set: !product.price_cents.nil?,
        stock_id: stock&.id,
        stock_quantity: stock ? stock.available_count : 0,
        stock_warehouse_id: stock&.warehouse_id,
        stock_warehouse_name: stock&.warehouse&.name,
        image_url: image_url(product)
      }
    end

    def service_payload(service)
      {
        id: service.id,
        name: service.name,
        code: service.code,
        category_id: service.category_id,
        category_name: service.category&.name,
        price_cents: service.price_cents,
        price_set: !service.price_cents.nil?,
        image_url: image_url(service)
      }
    end

    # Request specs have no ActiveStorage host; the image is optional, so a
    # missing URL must not take the whole catalog down.
    def image_url(record)
      record.image_attachments.first&.variant(:thumb)&.processed&.url
    rescue ArgumentError
      nil
    end
  end
end
