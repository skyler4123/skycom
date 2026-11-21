# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderProcessingV1::CancelOrderService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:customer) { create(:customer, company: company) }
  let(:order) do
    create(:order, company: company, branch: branch, customer: customer,
      workflow_status: :pending, currency: :usd)
  end

  it "marks a pending order cancelled and releases its pending discount" do
    group = Seed::DiscountGroupService.create(company: company, name: "Cancel Discounts",
      prefix: "CAN", discount_type: :percentage, percentage: 10, campaign_status: :active)
    discount = Seed::DiscountService.create(company: company, discount_group: group, code: "CAN-1")
    discount.reserve!(order: order, employee: nil, amount_cents: 500)

    result = described_class.call(order: order, company: company)

    expect(result[:success]).to be(true)
    expect(order.reload.workflow_status).to eq("cancelled")
    expect(discount.reload).to be_status_unused
  end

  it "refuses a paid order" do
    order.update!(workflow_status: :paid)

    result = described_class.call(order: order, company: company)

    expect(result[:success]).to be(false)
    expect(result[:errors]).to include("Paid orders cannot be voided here")
    expect(order.reload.workflow_status).to eq("paid")
  end

  it "is idempotent for an already-cancelled order" do
    order.update!(workflow_status: :cancelled)

    result = described_class.call(order: order, company: company)

    expect(result[:success]).to be(true)
    expect(order.reload.workflow_status).to eq("cancelled")
  end
end
