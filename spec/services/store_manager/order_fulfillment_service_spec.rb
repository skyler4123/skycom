# frozen_string_literal: true

require "rails_helper"

RSpec.describe StoreManager::OrderFulfillmentService, type: :service do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:employee) { create(:employee, company: company, branch: branch) }
  let(:customer) { create(:customer, company: company, branch: branch) }

  def order(channel: :click_collect, workflow_status: :pending, **attrs)
    create(
      :order,
      company: company,
      branch: branch,
      customer: customer,
      name: "Order #{SecureRandom.hex(6)}",
      workflow_status: workflow_status,
      fulfillment_channel: channel,
      **attrs
    ).tap { |record| record.update_columns(discarded_at: nil) }
  end

  it "marks an order ready without changing payment state" do
    record = order

    result = described_class.mark_ready(company: company, order: record)

    expect(result[:message]).to include("ready for handover")
    expect(record.reload.fulfillment_status).to eq("ready")
    expect(record.workflow_status).to eq("pending")
  end

  it "refuses handover until an invoice is paid" do
    record = order

    expect {
      described_class.hand_over(company: company, order: record)
    }.to raise_error(StoreManager::Error, "Order must be paid at POS before handover.")
    expect(record.reload.fulfillment_status).to eq("unfulfilled")
  end

  it "hands over a paid order and records the timestamp" do
    record, = create_store_invoice_order(
      company: company, branch: branch, employee: employee, channel: :click_collect
    )

    result = described_class.hand_over(company: company, order: record)

    expect(result[:message]).to include("handed over")
    expect(record.reload.fulfillment_status).to eq("handed_over")
    expect(record.handed_over_at).to be_present
  end

  it "is idempotent when the order is already ready" do
    record = order
    record.update!(fulfillment_status: :ready)

    result = described_class.mark_ready(company: company, order: record)

    expect(result[:message]).to include("already ready")
    expect(record.reload.fulfillment_status).to eq("ready")
  end

  it "rejects counter sales" do
    record = order(channel: :walk_in)

    expect {
      described_class.mark_ready(company: company, order: record)
    }.to raise_error(StoreManager::Error, "Counter sales are handed over at checkout.")
  end

  it "rejects cancelled orders" do
    record = order(workflow_status: :cancelled)

    expect {
      described_class.mark_ready(company: company, order: record)
    }.to raise_error(StoreManager::Error, "Cancelled or refunded orders cannot be fulfilled.")
  end
end
