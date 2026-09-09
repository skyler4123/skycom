# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::StocksController search/filter", type: :request do
  let(:warehouse_cache) { Hash.new { |h, k| h[k] = create(:warehouse, company: k) } }

  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "stocks" }
    let(:index_class) { Stock }
    let(:json_key) { "stocks" }
    let(:base_json_path) { "/companies/#{company.id}/stocks.json" }
    let(:record) do
      ->(company:, category:, **attrs) {
        product = create(:product, company: company, name: "Product #{SecureRandom.hex(4)}")
        create(:stock, company: company, warehouse: warehouse_cache[company], product: product, category: category, **attrs)
      }
    end
  end
end
