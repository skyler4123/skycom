require "rails_helper"

RSpec.describe Discounts::ReleaseService do
  let(:company) { create(:company) }
  let(:customer) { create(:customer, company: company) }
  let(:employee) { create(:employee, company: company) }
  let(:group) do
    Seed::DiscountGroupService.create(company: company, name: "G", prefix: "G",
      discount_type: :percentage, percentage: 10, campaign_status: :active)
  end
  let(:order) { Seed::OrderService.create(company: company, customer: customer, currency: :usd) }
  let(:invoice) { create(:invoice, company: company, order: order, price_cents: 9_000) }

  it "releases all pending codes bound to an order" do
    pending_a = Seed::DiscountService.create(company: company, discount_group: group, code: "RA1")
    pending_b = Seed::DiscountService.create(company: company, discount_group: group, code: "RA2")
    pending_a.reserve!(order: order, employee: employee, amount_cents: 100)
    pending_b.reserve!(order: order, employee: employee, amount_cents: 200)

    result = described_class.call(order: order)

    aggregate_failures do
      expect(result).to eq({ success: true, released: 2 })
      expect(pending_a.reload).to be_status_unused
      expect(pending_a.order_id).to be_nil
      expect(pending_b.reload).to be_status_unused
    end
  end

  it "leaves used and untouched unused codes alone" do
    used = Seed::DiscountService.create(company: company, discount_group: group, code: "RU1")
    used.reserve!(order: order, employee: employee, amount_cents: 100)
    used.consume!(invoice: invoice)

    described_class.call(order: order)

    expect(used.reload).to be_status_used
    expect(group.reload.current_spent_cents).to eq(100)
  end

  it "releases a single discount by object" do
    pending = Seed::DiscountService.create(company: company, discount_group: group, code: "RS1")
    pending.reserve!(order: order, employee: employee, amount_cents: 100)

    result = described_class.call(discount: pending)

    expect(result).to eq({ success: true, released: 1 })
    expect(pending.reload).to be_status_unused
  end

  it "releases nothing without arguments" do
    expect(described_class.call).to eq({ success: true, released: 0 })
  end
end
