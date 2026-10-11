# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::ProductsController search/filter", type: :request do
  let(:company) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "products") }
  let!(:table_config) do
    category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(company: company, category: category,
      property_mapping: category.default_property_mapping, resource_name: "products",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true, "search" => true },
        { "key" => "property_integer_1", "name" => "Qty", "visible" => true,
          "filter" => { "type" => "range", "active" => true, "buckets" => [ [ nil, 100 ], [ 100, nil ] ] } }
      ] })
  end

  before do
    get sign_in_for_test_path(email: company.user.email)
  end

  def index_url(params = {})
    "/companies/#{company.id}/products.json?#{ { category_id: category.id }.merge(params).to_query }"
  end

  describe "DB path (no search params)" do
    let!(:product) { create(:product, company: company, category: category, name: "NoIndex Product") }

    it "returns products without touching Meilisearch" do
      allow(Product).to receive(:ms_raw_search).and_raise("should not be called")
      get index_url

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["products"].map { |p| p["id"] }).to include(product.id)
    end
  end

  describe "Meilisearch path" do
    let(:small) { create(:product, company: company, category: category, name: "Crimson Small", property_integer_1: 50) }
    let(:large) { create(:product, company: company, category: category, name: "Crimson Large", property_integer_1: 250) }

    before do
      raise "Meilisearch not reachable. Run `docker compose up -d meilisearch`." unless
        begin
          Meilisearch::Rails.client.health["status"] == "available"
        rescue StandardError
          false
        end
      Product.ms_clear_index!
    end

    after { Product.ms_clear_index! }

    it "filters by keyword and excludes other companies" do
      other = create(:company)
      noise = create(:product, company: other, name: "Crimson Noise")
      [ small, large, noise ].each { |p| p.ms_index!(true) }

      get index_url(q: "Crimson")
      ids = JSON.parse(response.body)["products"].map { |p| p["id"] }
      expect(ids).to contain_exactly(small.id, large.id)
    end

    it "restricts results to a configured range filter" do
      [ small, large ].each { |p| p.ms_index!(true) }

      get index_url("filters" => { "property_integer_1" => ":100" })
      ids = JSON.parse(response.body)["products"].map { |p| p["id"] }
      expect(ids).to contain_exactly(small.id)
    end

    it "keeps the pagination payload shape" do
      [ small, large ].each { |p| p.ms_index!(true) }

      get index_url(q: "Crimson")
      body = JSON.parse(response.body)
      expect(body["pagination"].keys).to include("page", "count", "limit")
    end

    it "ignores unknown filter keys and falls back to the DB path" do
      product = create(:product, company: company, category: category, name: "Anything")
      get index_url("filters" => { "evil_column" => "1 OR 1" })

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["products"].map { |p| p["id"] }).to include(product.id)
    end

    it "returns 503 with errors when Meilisearch fails" do
      allow(Product).to receive(:ms_raw_search).and_raise(Meilisearch::CommunicationError, "down")

      get index_url(q: "Crimson")

      expect(response).to have_http_status(:service_unavailable)
      expect(JSON.parse(response.body)["errors"]).to include("Search is temporarily unavailable. Please try again.")
    end
  end
end

RSpec.describe "Companies::ProductsController show", type: :request do
  let(:company) { create(:company) }
  let(:product) { create(:product, company: company) }

  before do
    get sign_in_for_test_path(email: company.user.email)
  end

  it "embeds stocks of this product in the show JSON" do
    warehouse_a = create(:warehouse, company: company)
    warehouse_b = create(:warehouse, company: company)
    stock_a = Stock.create!(company: company, warehouse: warehouse_a, product: product, quantity: 12, pending: 3, name: "PRD Stock A", code: "STK-PRD-A-#{SecureRandom.hex(2).upcase}")
    stock_b = Stock.create!(company: company, warehouse: warehouse_b, product: product, quantity: 4, pending: 0, name: "PRD Stock B", code: "STK-PRD-B-#{SecureRandom.hex(2).upcase}")
    other_product = create(:product, company: company)
    other_stock = Stock.create!(company: company, warehouse: warehouse_a, product: other_product, quantity: 9, pending: 0, name: "Other PRD Stock", code: "STK-PRD-O-#{SecureRandom.hex(2).upcase}")

    get "/companies/#{company.id}/products/#{product.id}.json"

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["product"]["id"]).to eq(product.id)
    stock_ids = body["stocks"].map { |s| s["id"] }
    expect(stock_ids).to contain_exactly(stock_a.id, stock_b.id)
    expect(stock_ids).not_to include(other_stock.id)
    row_a = body["stocks"].find { |s| s["id"] == stock_a.id }
    expect(row_a["quantity"]).to eq(12)
    expect(row_a["pending"]).to eq(3)
    expect(row_a["available"]).to eq(9)
    expect(row_a["warehouse"]["id"]).to eq(warehouse_a.id)
  end
end
