# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderProcessingV1::ReleaseReservedStockService do
  let(:company) { create(:company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let(:product) { create(:product, company: company) }
  let!(:stock) do
    cat = product.category
    Stock.create!(company: company, warehouse: warehouse, product: product,
      quantity: 10, pending: 0, category: cat, property_mapping: cat.default_property_mapping)
      .tap { |s| s.send(:sync_available_counter) }
  end
  let(:branch) { create(:branch, company: company) }
  let(:customer) { create(:customer, company: company) }
  let(:order) { create(:order, company: company, branch: branch, customer: customer) }
  let!(:item) do
    OrderAppointment.create!(order: order, appoint_to: product, company: company,
      quantity: 3, unit_price: 10.0, total_price: 30.0)
  end

  before { stock.reserve_stock!(3) }

  it "releases reservations for the order's line items" do
    result = described_class.call(order: order)

    expect(result[:released]).to contain_exactly(stock.id)
    expect(stock.reload.pending).to eq(0)
    expect(stock.available_count).to eq(10)
  end
end
