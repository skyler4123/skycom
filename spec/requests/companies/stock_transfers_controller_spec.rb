# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::StockTransfersController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "stock_transfers" }
    let(:index_class) { StockTransfer }
    let(:json_key) { "stock_transfers" }
    let(:base_json_path) { "/companies/#{company.id}/stock_transfers.json" }
    let(:record) do
      ->(company:, category:, **attrs) {
        warehouse = create(:warehouse, company: company)
        product = create(:product, company: company, name: "Product #{SecureRandom.hex(4)}")
        create(:stock_transfer, company: company, warehouse: warehouse, product: product, category: category, **attrs)
      }
    end
  end
end
