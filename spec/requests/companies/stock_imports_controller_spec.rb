# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::StockImportsController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "stock_imports" }
    let(:index_class) { StockImport }
    let(:json_key) { "stock_imports" }
    let(:base_json_path) { "/companies/#{company.id}/stock_imports.json" }
    let(:record) do
      ->(company:, category:, **attrs) {
        warehouse = create(:warehouse, company: company)
        product = create(:product, company: company, name: "Product #{SecureRandom.hex(4)}")
        create(:stock_import, company: company, warehouse: warehouse, product: product, category: category, **attrs)
      }
    end
  end
end
