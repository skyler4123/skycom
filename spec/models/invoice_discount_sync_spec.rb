require "rails_helper"

RSpec.describe "Invoice discount lifecycle" do
  let(:company) { create(:company) }
  let(:customer) { create(:customer, company: company) }
  let(:employee) { create(:employee, company: company) }
  let(:group) do
    Seed::DiscountGroupService.create(company: company, name: "G", prefix: "G",
      discount_type: :percentage, percentage: 10, campaign_status: :active)
  end
  let(:order) { Seed::OrderService.create(company: company, customer: customer, currency: :usd) }
  let(:discount) { Seed::DiscountService.create(company: company, discount_group: group, code: "LIFE1") }
  let(:invoice) { create(:invoice, company: company, order: order, price_cents: 9_000) }

  it "consumes a pending discount when the invoice becomes paid" do
    discount.reserve!(order: order, employee: employee, amount_cents: 1_000)
    invoice.update!(payment_status: :paid)

    aggregate_failures do
      expect(discount.reload).to be_status_used
      expect(discount.invoice_id).to eq(invoice.id)
      expect(discount.used_at).to be_present
      expect(group.reload.current_spent_cents).to eq(1_000)
    end
  end

  it "reverts a used discount when the invoice leaves paid (refund path)" do
    discount.reserve!(order: order, employee: employee, amount_cents: 1_000)
    invoice.update!(payment_status: :paid)
    invoice.update!(payment_status: :unpaid)

    aggregate_failures do
      expect(discount.reload).to be_status_unused
      expect(discount.invoice_id).to be_nil
      expect(discount.used_at).to be_nil
      expect(group.reload.current_spent_cents).to eq(0)
    end
  end

  it "reactivates an exhausted group when the refund drops spend under the cap" do
    budgeted = Seed::DiscountGroupService.create(company: company, name: "Cap", prefix: "CAP",
      discount_type: :percentage, percentage: 10, total_budget_cents: 1_000)
    capped = Seed::DiscountService.create(company: company, discount_group: budgeted, code: "LIFE2")
    capped.reserve!(order: order, employee: employee, amount_cents: 1_000)

    invoice.update!(payment_status: :paid)
    expect(budgeted.reload).to be_campaign_status_exhausted

    invoice.update!(payment_status: :unpaid)
    expect(budgeted.reload.current_spent_cents).to eq(0)
    expect(budgeted).to be_campaign_status_active
    expect(capped.reload).to be_status_unused
  end

  it "leaves other codes untouched when the invoice changes without a status change" do
    discount.reserve!(order: order, employee: employee, amount_cents: 1_000)
    invoice.update!(name: "Renamed invoice")

    expect(discount.reload).to be_status_pending
    expect(group.reload.current_spent_cents).to eq(0)
  end
end
