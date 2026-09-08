# spec/services/seed/stock_service_spec.rb
require 'rails_helper'

RSpec.describe Seed::StockService do
  let(:company) { create(:company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let(:product) { create(:product, company: company) }

  describe ".create" do
    it "assigns a stocks resource category, independent from the product's category" do
      stocks_category = Category.create!(
        company: company, name: "Inventory #{SecureRandom.uuid}", resource_name: "stocks"
      )

      stock = described_class.create(warehouse: warehouse, product_id: product.id, quantity: 5)

      expect(stock.category).to eq(stocks_category)
      expect(stock.property_mapping).to eq(stocks_category.default_property_mapping)
    end

    it "falls back to the default stocks category when none is seeded" do
      stock = described_class.create(warehouse: warehouse, product_id: product.id, quantity: 5)

      expect(stock.category.resource_name).to eq("stocks")
    end
  end
end
