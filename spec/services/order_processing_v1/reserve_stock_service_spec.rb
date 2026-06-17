# frozen_string_literal: true

require "rails_helper"

# Ensure the root module file is loaded (defines InsufficientStockError)
OrderProcessingV1

RSpec.describe OrderProcessingV1::ReserveStockService do
  describe ".call" do
    let(:company) { create(:company) }
    let(:product) { create(:product, company: company) }
    let(:warehouse) { create(:warehouse, company: company) }
    let(:stock) do
      category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "stocks")
      property_mapping = category.property_mapping
      Stock.create!(
        company: company,
        warehouse: warehouse,
        product: product,
        quantity: 5,
        reserved_quantity: 0,
        category: category,
        property_mapping: property_mapping
      )
    end
    let(:items) { [{ stock_id: stock.id, quantity: 2 }] }

    context "when stock is sufficient" do
      it "decrements the Redis counter and returns success" do
        result = described_class.call(items: items)
        expect(result[:success]).to be true
        expect(stock.available_counter.value).to eq(3)
      end
    end

    context "when stock runs out" do
      let(:items) { [{ stock_id: stock.id, quantity: 10 }] }

      it "rolls back and raises InsufficientStockError" do
        expect { described_class.call(items: items) }
          .to raise_error(OrderProcessingV1::InsufficientStockError)
        expect(stock.available_counter.value).to eq(5)
      end
    end
  end
end
