# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderProcessingV1::CompletePaymentService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:customer) { create(:customer, company: company) }
  let(:order) { create(:order, company: company, branch: branch, customer: customer, workflow_status: :pending) }
  let!(:invoice) do
    Invoice.create!(
      company_id: order.company_id, branch_id: order.branch_id, order_id: order.id,
      name: "Invoice for Order #{order.id}", code: "INV-#{Time.current.to_i}-#{SecureRandom.hex(3).upcase}",
      price_cents: 5000, currency: order.currency, business_type: :sales
    )
  end
  let!(:txn) do
    Transaction.create!(
      company_id: order.company_id, branch_id: order.branch_id, invoice_id: invoice.id,
      price_cents: 5000, currency: order.currency, status: :pending,
      business_type: :standard_payment, gateway_reference: "POS_#{SecureRandom.hex(8)}"
    )
  end

  it "completes a pending transaction and derives invoice payment_status" do
    expect {
      described_class.call(transaction: txn)
    }.to change { txn.reload.status }.from("pending").to("completed")
      .and change { invoice.reload.payment_status }.from("unpaid").to("paid")
  end

  it "marks invoice and order workflow_status paid and enqueues finalization" do
    allow(OrderProcessingV1::FinalizeJob).to receive(:perform_later)
    described_class.call(transaction: txn)

    expect(invoice.reload.workflow_status).to eq("paid")
    expect(order.reload.workflow_status).to eq("paid")
    expect(OrderProcessingV1::FinalizeJob).to have_received(:perform_later).with(order.id)
  end

  it "returns true once and false afterwards (idempotent)" do
    expect(described_class.call(transaction: txn)).to be(true)
    expect(described_class.call(transaction: txn.reload)).to be(false)
  end

  it "ignores failed transactions (cancelled payments)" do
    txn.update!(status: :failed)

    expect(described_class.call(transaction: txn.reload)).to be(false)
    expect(txn.reload.status).to eq("failed")
    expect(order.reload.workflow_status).to eq("pending")
  end
end
