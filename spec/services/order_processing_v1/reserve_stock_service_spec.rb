# frozen_string_literal: true

require "rails_helper"

Rails.root.join("app/services/order_processing_v1.rb").then { |f| require f if File.exist?(f) }

RSpec.describe OrderProcessingV1::ReserveStockService do
  describe ".call" do
    let(:company) { create(:company) }
    let(:product) { create(:product, company: company) }
    let(:warehouse) { create(:warehouse, company: company) }
    let(:stock) do
      category = product.category
      property_mapping = category.default_property_mapping
      Stock.create!(
        company: company,
        warehouse: warehouse,
        product: product,
        quantity: 5,
        pending: 0,
        category: category,
        property_mapping: property_mapping
      )
    end
    let(:items) { [ { stock_id: stock.id, quantity: 2 } ] }

    context "when stock is sufficient" do
      it "decrements the Redis counter and returns success" do
        result = described_class.call(items: items)
        expect(result[:success]).to be true
        expect(stock.available_counter.value).to eq(3)
      end

      it "returns the reservation list so callers can roll back later" do
        result = described_class.call(items: items)

        expect(result[:reserved].length).to eq(1)
        expect(result[:reserved].first[:qty]).to eq(2)
        expect(result[:reserved].first[:stock].id).to eq(stock.id)
      end

      it "promises the units in DB by incrementing pending" do
        described_class.call(items: items)
        expect(stock.reload.pending).to eq(2)
      end
    end

    context "with string quantity param" do
      let(:items) { [ { stock_id: stock.id, quantity: "2" } ] }

      it "decrements the Redis counter" do
        described_class.call(items: items)
        expect(stock.available_counter.value).to eq(3)
      end
    end

    context "when stock runs out" do
      let(:items) { [ { stock_id: stock.id, quantity: 10 } ] }

      it "rolls back and raises InsufficientStockError" do
        expect { described_class.call(items: items) }
          .to raise_error(OrderProcessingV1::InsufficientStockError)
        expect(stock.available_counter.value).to eq(5)
      end
    end

    context "when the Redis counter is missing" do
      before { Kredis.redis.del("stock:#{stock.id}:available") }

      it "heals from DB before reserving and returns success" do
        result = described_class.call(items: items)
        expect(result[:success]).to be true
        expect(stock.available_counter.value).to eq(3)
      end
    end
  end
end
