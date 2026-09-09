# frozen_string_literal: true

require "rails_helper"

RSpec.describe StockTransfers::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "stock_transfers" }
    let(:index_class) { StockTransfer }
    let(:record) do
      ->(company:, category:, **attrs) {
        warehouse = create(:warehouse, company: company)
        product = create(:product, company: company, name: "Product #{SecureRandom.hex(4)}")
        create(:stock_transfer, company: company, warehouse: warehouse, product: product, category: category, **attrs)
      }
    end
  end
end
