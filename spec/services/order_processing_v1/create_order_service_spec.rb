# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderProcessingV1::CreateOrderService do
  describe ".call" do
    subject(:result) { described_class.call(company: company, branch: branch, items: items, customer: customer) }

    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:product) { create(:product, company: company, branch: branch) }
    let(:warehouse) { create(:warehouse, company: company) }
    let!(:stock) { create(:stock, company: company, product: product, warehouse: warehouse, quantity: 10) }
    let(:customer) { create(:customer, company: company, branch: branch) }
    let(:items) do
      [{ stock_id: stock.id, product_id: product.id, quantity: 2, unit_price: 50.00 }]
    end

    it "creates an Order with workflow_status pending" do
      expect { result }.to change(Order, :count).by(1)
      expect(Order.last.workflow_status).to eq("pending")
    end

    it "creates OrderAppointments for each item" do
      expect { result }.to change(OrderAppointment, :count).by(1)
      oa = OrderAppointment.last
      expect(oa.quantity).to eq(2)
      expect(oa.appoint_to).to eq(product)
    end

    it "returns order_id and total_price" do
      expect(result[:order_id]).to be_present
      expect(result[:total_price]).to eq(100.00)
    end
  end
end
