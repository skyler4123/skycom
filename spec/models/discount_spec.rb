require "rails_helper"

RSpec.describe Discount do
  let(:company) { create(:company) }
  let(:group) do
    Seed::DiscountGroupService.create(company: company, name: "G1", prefix: "G1",
      discount_type: :percentage, percentage: 10, max_amount_cents: 2_000)
  end
  let(:customer) { create(:customer, company: company) }
  let(:order) { Seed::OrderService.create(company: company, customer: customer) }
  let(:employee) { create(:employee, company: company) }

  describe "validations" do
    it "scopes code uniqueness to company" do
      Seed::DiscountService.create(company: company, discount_group: group, code: "ABC123")

      other_company = create(:company)
      other_group = Seed::DiscountGroupService.create(company: other_company, name: "G2", prefix: "G2",
        discount_type: :fixed_amount, amount_cents: 100)
      expect(Seed::DiscountService.new(company: other_company, discount_group: other_group, code: "ABC123"))
        .to be_valid
    end

    it "rejects cross-company group" do
      other = create(:company)
      other_group = Seed::DiscountGroupService.create(company: other, name: "G3", prefix: "G3",
        discount_type: :fixed_amount, amount_cents: 100)
      discount = Seed::DiscountService.new(company: company, discount_group: other_group, code: "X1")
      expect(discount).not_to be_valid
    end

    it "rejects negative amount snapshot" do
      discount = Seed::DiscountService.new(company: company, discount_group: group, code: "N1", amount_cents: -5)
      expect(discount).not_to be_valid
    end
  end

  describe "#compute_amount_cents" do
    let(:discount) { Seed::DiscountService.create(company: company, discount_group: group, code: "C1") }

    it "caps fixed_amount at the subtotal" do
      discount.discount_group.update!(discount_type: :fixed_amount, amount_cents: 5_000)
      expect(discount.compute_amount_cents(3_000)).to eq(3_000)
      expect(discount.compute_amount_cents(50_000)).to eq(5_000)
    end

    it "applies percentage and honors max_amount_cents" do
      expect(discount.compute_amount_cents(10_000)).to eq(1_000)
      expect(discount.compute_amount_cents(500_000)).to eq(2_000)
    end

    it "is uncapped for percentage without max_amount_cents" do
      discount.discount_group.update!(max_amount_cents: nil)
      expect(discount.compute_amount_cents(500_000)).to eq(50_000)
    end
  end

  describe "state transitions" do
    let(:discount) { Seed::DiscountService.create(company: company, discount_group: group, code: "T1") }

    it "reserve binds the code to the order in pending state" do
      discount.reserve!(order: order, employee: employee, amount_cents: 1_000)
      expect(discount.reload).to be_status_pending
      expect(discount.order_id).to eq(order.id)
      expect(discount.customer_id).to eq(customer.id)
      expect(discount.employee_id).to eq(employee.id)
      expect(discount.amount_cents).to eq(1_000)
      expect(discount.invoice_id).to be_nil
    end

    it "consume marks used, records the invoice and increments the group budget" do
      discount.reserve!(order: order, employee: employee, amount_cents: 1_000)
      invoice = create(:invoice, company: company, order: order, price_cents: 9_000)

      discount.consume!(invoice: invoice)

      expect(discount.reload).to be_status_used
      expect(discount.invoice_id).to eq(invoice.id)
      expect(discount.used_at).to be_present
      expect(group.reload.current_spent_cents).to eq(1_000)
    end

    it "release resets a pending code to the pool and clears bindings" do
      discount.reserve!(order: order, employee: employee, amount_cents: 500)
      expect(discount.release!).to be(true)

      discount.reload
      expect(discount).to be_status_unused
      expect(discount.order_id).to be_nil
      expect(discount.customer_id).to be_nil
      expect(discount.employee_id).to be_nil
      expect(discount.amount_cents).to be_nil
      expect(group.reload.current_spent_cents).to eq(0)
    end

    it "release refuses used codes" do
      discount.reserve!(order: order, employee: employee, amount_cents: 500)
      invoice = create(:invoice, company: company, order: order, price_cents: 4_500)
      discount.consume!(invoice: invoice)

      expect(discount.release!).to be(false)
      expect(discount.reload).to be_status_used
    end

    it "revert refunds the budget (reactivating an exhausted group) and returns the code to the pool" do
      budgeted = Seed::DiscountGroupService.create(company: company, name: "Capped", prefix: "CAP",
        discount_type: :percentage, percentage: 10, total_budget_cents: 1_000)
      capped = Seed::DiscountService.create(company: company, discount_group: budgeted, code: "R1")
      capped.reserve!(order: order, employee: employee, amount_cents: 1_000)

      invoice = create(:invoice, company: company, order: order, price_cents: 9_000)
      capped.consume!(invoice: invoice)
      expect(budgeted.reload).to be_campaign_status_exhausted

      expect(capped.revert!).to be(true)
      capped.reload
      expect(capped).to be_status_unused
      expect(capped.invoice_id).to be_nil
      expect(capped.used_at).to be_nil
      expect(budgeted.reload.current_spent_cents).to eq(0)
      expect(budgeted).to be_campaign_status_active
    end

    it "revert refuses unused codes" do
      expect(discount.revert!).to be(false)
    end
  end
end
