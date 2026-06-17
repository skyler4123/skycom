# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderProcessingV1::CheckAvailabilityService do
  describe ".call" do
    subject(:result) { described_class.call(items: items) }

    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:product) { create(:product, company: company) }
    let(:warehouse) { Seed::WarehouseService.create(company: company, branch: branch) }
    let!(:stock) do
      Stock.create!(
        warehouse: warehouse,
        product: product,
        company: company,
        quantity: 10,
        reserved_quantity: 0,
        name: "Test Stock",
        code: "STK-TEST"
      )
    end
    let(:items) { [ { stock_id: stock.id, quantity: 3 } ] }

    before { stock.send(:sync_available_counter) }

    context "when all items are available" do
      it "returns available: true" do
        expect(result).to eq({ available: true })
      end
    end

    context "with string quantity param" do
      let(:items) { [ { stock_id: stock.id, quantity: "3" } ] }

      it "returns available: true (handles .to_i)" do
        expect(result).to eq({ available: true })
      end
    end

    context "when an item has insufficient stock" do
      let(:items) { [ { stock_id: stock.id, quantity: 20 } ] }

      it "returns available: false with the failed item" do
        expect(result[:available]).to be false
        expect(result[:failed_item]).to eq(stock.id)
      end
    end
  end
end
