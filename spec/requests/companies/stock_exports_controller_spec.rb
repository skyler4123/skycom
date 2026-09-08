# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::StockExportsController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "stock_exports" }
    let(:index_class) { StockExport }
    let(:json_key) { "stock_exports" }
    let(:base_json_path) { "/companies/#{company.id}/stock_exports.json" }
    let(:record) do
      ->(company:, category:, **attrs) {
        warehouse = create(:warehouse, company: company)
        product = create(:product, company: company, name: "Product #{SecureRandom.hex(4)}")
        create(:stock_export, company: company, warehouse: warehouse, product: product, category: category, **attrs)
      }
    end
  end
end
