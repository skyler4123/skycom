# frozen_string_literal: true

require "rails_helper"

RSpec.describe StockImports::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "stock_imports" }
    let(:index_class) { StockImport }
    let(:record) do
      ->(company:, category:, **attrs) {
        warehouse = create(:warehouse, company: company)
        product = create(:product, company: company, name: "Product #{SecureRandom.hex(4)}")
        create(:stock_import, company: company, warehouse: warehouse, product: product, category: category, **attrs)
      }
    end
  end
end
