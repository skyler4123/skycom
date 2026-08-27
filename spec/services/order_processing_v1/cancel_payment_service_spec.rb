# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderProcessingV1::CancelPaymentService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:customer) { create(:customer, company: company) }
  let(:order) { create(:order, company: company, branch: branch, customer: customer, workflow_status: :pending) }
  let(:product) { create(:product, company: company) }
  let(:warehouse) { create(:warehouse, company: company) }
  let!(:stock) do
    cat = product.category
    Stock.create!(company: company, warehouse: warehouse, product: product,
      quantity: 10, pending: 0, category: cat, property_mapping: cat.default_property_mapping)
      .tap { |s| s.send(:sync_available_counter) }
  end
  let!(:item) do
    OrderAppointment.create!(order: order, appoint_to: product, company: company,
      quantity: 2, unit_price: 25.0, total_price: 50.0)
  end
  let!(:invoice) do
    Invoice.create!(company_id: order.company_id, branch_id: order.branch_id, order_id: order.id,
      name: "Invoice for Order #{order.id}", code: "INV-#{Time.current.to_i}-#{SecureRandom.hex(3).upcase}",
      price_cents: 5000, currency: order.currency, business_type: :sales)
  end
  let!(:txn) do
    Transaction.create!(company_id: order.company_id, branch_id: order.branch_id,
      invoice_id: invoice.id, price_cents: 5000, currency: order.currency,
      status: :pending, business_type: :standard_payment,
      gateway_reference: "POS_#{SecureRandom.hex(8)}")
  end

  before { stock.reserve_stock!(2) }

  it "fails a pending transaction and releases reserved stock" do
    result = described_class.call(transaction_token: txn.gateway_reference, company: company)

    expect(result).to be(true)
    expect(txn.reload.status).to eq("failed")
    expect(stock.reload.pending).to eq(0)
    expect(stock.available_count).to eq(10)
  end

  it "returns false for a non-pending transaction and touches nothing" do
    txn.update!(status: :completed)

    expect(described_class.call(transaction_token: txn.gateway_reference, company: company)).to be(false)
    expect(txn.reload.status).to eq("completed")
    expect(stock.reload.pending).to eq(2)
  end

  it "raises for an unknown token" do
    expect {
      described_class.call(transaction_token: "NOPE", company: company)
    }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
