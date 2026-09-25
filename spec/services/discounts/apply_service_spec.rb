require "rails_helper"

RSpec.describe Discounts::ApplyService do
  let(:company) { create(:company) }
  let(:customer) { create(:customer, company: company) }
  let(:employee) { create(:employee, company: company) }
  let(:group) do
    Seed::DiscountGroupService.create(company: company, name: "Summer", prefix: "SUM26",
      discount_type: :percentage, percentage: 10, campaign_status: :active)
  end
  let(:product) { create(:product, company: company) }
  let(:order) do
    Seed::OrderService.create(company: company, customer: customer, currency: :usd).tap do |o|
      OrderProductAppointment.create!(company: company, order: o, product: product,
        quantity: 2, unit_price: 50.0, total_price: 100.0)
    end
  end
  let!(:discount) { Seed::DiscountService.create(company: company, discount_group: group, code: "SUM26-TEST001") }

  def apply(code: "SUM26-TEST001", target: order)
    described_class.call(company: company, order: target, code: code, employee: employee)
  end

  it "reserves an unused code in pending state with the amount snapshot" do
    result = apply

    expect(result[:success]).to be(true)
    expect(result[:discount].reload).to be_status_pending
    expect(result[:discount].amount_cents).to eq(1_000) # 10% of 100.00
    expect(result[:discount].order_id).to eq(order.id)
    expect(result[:discount].customer_id).to eq(customer.id)
    expect(result[:discount].employee_id).to eq(employee.id)
    expect(group.reload.current_spent_cents).to eq(0) # spend only moves on consume
  end

  it "matches codes case-insensitively" do
    result = apply(code: "sum26-test001")
    expect(result[:success]).to be(true)
  end

  it "fails for an unknown code" do
    expect(apply(code: "SUM26-NOPE999")).to eq({ success: false, errors: [ "Discount code not found or already used" ] })
  end

  it "fails for a pending code (single-use reservation)" do
    discount.reserve!(order: order, employee: employee, amount_cents: 1_000)
    expect(apply).to eq({ success: false, errors: [ "Discount code not found or already used" ] })
  end

  it "fails for a used code" do
    discount.reserve!(order: order, employee: employee, amount_cents: 1_000)
    discount.consume!(invoice: create(:invoice, company: company, order: order, price_cents: 9_000))
    expect(apply).to eq({ success: false, errors: [ "Discount code not found or already used" ] })
  end

  it "fails when the campaign is paused" do
    group.update!(campaign_status: :paused)
    expect(apply).to eq({ success: false, errors: [ "Discount campaign is not active" ] })
  end

  it "fails when the campaign window has passed" do
    group.update!(start_at: 10.days.ago, end_at: 5.days.ago)
    expect(apply).to eq({ success: false, errors: [ "Discount campaign is not active" ] })
  end

  it "fails on currency mismatch" do
    euro_order = Seed::OrderService.create(company: company, customer: customer, currency: :vnd)
    OrderProductAppointment.create!(company: company, order: euro_order, product: product,
      quantity: 2, unit_price: 50.0, total_price: 100.0)

    expect(apply(target: euro_order)).to eq({ success: false, errors: [ "Campaign currency does not match the order" ] })
  end

  it "fails when the budget cannot cover the discount" do
    group.update!(total_budget_cents: 500)
    expect(apply).to eq({ success: false, errors: [ "Campaign budget exhausted" ] })
  end

  it "fails when the order has no payable subtotal" do
    bare = Seed::OrderService.create(company: company, customer: customer, currency: :usd)
    expect(apply(target: bare)).to eq({ success: false, errors: [ "Discount amount must be greater than zero" ] })
  end
end
