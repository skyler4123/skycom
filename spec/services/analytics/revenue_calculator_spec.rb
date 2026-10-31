# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::RevenueCalculator do
  subject(:calculator) { described_class.new(company: company, orders: paid_orders) }

  let(:company) do
    create(:company,
      business_type: :retail,
      country: :us,
      currency: :usd,
      timezone: :utc,
      name: "Revenue Calc Co")
  end
  let(:branch_a) { create(:branch, company: company, name: "Main Branch") }
  let(:branch_b) { create(:branch, company: company, name: "Second Branch") }
  let!(:category_a) { Seed::CategoryService.create(company: company, name: "In-Store Purchase", resource_name: "orders") }
  let!(:category_b) { Seed::CategoryService.create(company: company, name: "Online Order", resource_name: "orders") }
  let(:customer_a) { create(:customer, company: company, branch: branch_a, name: "Customer A") }
  let(:customer_b) { create(:customer, company: company, branch: branch_a, name: "Customer B") }
  let(:product_a) { create(:product, company: company, name: "Product A", price: 10.0) }
  let(:product_b) { create(:product, company: company, name: "Product B", price: 20.0) }
  let(:service_a) { Seed::ServiceService.create(company: company, branch: branch_a, name: "Service A") }

  let!(:order_a) do
    create(:order,
      company: company,
      name: "Order A #{SecureRandom.hex(4)}",
      branch: branch_a,
      customer: customer_a,
      category: category_a,
      property_mapping: category_a.default_property_mapping,
      workflow_status: :paid,
      business_type: :in_store,
      created_at: Time.zone.local(2026, 10, 10, 10, 0, 0),
      discarded_at: nil)
  end

  let!(:order_b) do
    create(:order,
      company: company,
      name: "Order B #{SecureRandom.hex(4)}",
      branch: branch_b,
      customer: customer_b,
      category: category_b,
      property_mapping: category_b.default_property_mapping,
      workflow_status: :paid,
      business_type: :online,
      created_at: Time.zone.local(2026, 10, 15, 10, 0, 0),
      discarded_at: nil)
  end

  let!(:product_a_line) do
    create(:order_product_appointment,
      company: company,
      order: order_a,
      product: product_a,
      quantity: 2,
      unit_price: 10.0,
      total_price: 20.0,
      discarded_at: nil)
  end

  let!(:product_b_line_a) do
    create(:order_product_appointment,
      company: company,
      order: order_a,
      product: product_b,
      quantity: 1,
      unit_price: 20.0,
      total_price: 20.0,
      discarded_at: nil)
  end

  let!(:product_b_line_b) do
    create(:order_product_appointment,
      company: company,
      order: order_b,
      product: product_b,
      quantity: 3,
      unit_price: 20.0,
      total_price: 60.0,
      discarded_at: nil)
  end

  let!(:service_line) do
    create(:order_service_appointment,
      company: company,
      order: order_a,
      service: service_a,
      quantity: 1,
      unit_price: 30.0,
      total_price: 30.0,
      discarded_at: nil)
  end

  let(:paid_orders) { company.orders.where(workflow_status: :paid, discarded_at: nil) }

  before do
    product_a.update_column(:metadata, { "cost_price_cents" => 500 })
    product_b.update_column(:metadata, {})
  end

  describe "#total_cents" do
    it "sums every order appointment line in minor units" do
      expect(calculator.total_cents).to eq(13_000)
    end
  end

  describe "gross margin" do
    it "uses only product lines with a known cost" do
      expect(calculator.product_revenue_cents).to eq(10_000)
      expect(calculator.covered_revenue_cents).to eq(2_000)
      expect(calculator.covered_cost_cents).to eq(1_000)
      expect(calculator.covered_profit_cents).to eq(1_000)
      expect(calculator.margin_pct).to eq(50.0)
      expect(calculator.coverage_pct).to eq(15.4)
    end

    it "returns nil margin and coverage when there is no revenue" do
      empty_calculator = described_class.new(company: company, orders: company.orders.none)

      expect(empty_calculator.total_cents).to eq(0)
      expect(empty_calculator.margin_pct).to be_nil
      expect(empty_calculator.coverage_pct).to be_nil
    end
  end

  describe "#by_month" do
    it "returns revenue and tracked cost grouped by order month" do
      expect(calculator.by_month).to eq([
        { month: "2026-10", revenue_cents: 13_000, cost_cents: 1_000, margin_pct: 50.0 }
      ])
    end
  end

  describe "#by_order_category" do
    it "groups revenue by the order category" do
      result = calculator.by_order_category

      expect(result.map { |row| [ row[:id], row[:name], row[:revenue_cents] ] }).to contain_exactly(
        [ category_a.id, "In-Store Purchase", 7_000 ],
        [ category_b.id, "Online Order", 6_000 ]
      )
    end
  end

  describe "#by_branch" do
    it "groups revenue by branch and preserves unassigned orders" do
      result = calculator.by_branch

      expect(result.map { |row| [ row[:id], row[:name], row[:revenue_cents] ] }).to contain_exactly(
        [ branch_a.id, "Main Branch", 7_000 ],
        [ branch_b.id, "Second Branch", 6_000 ]
      )
    end
  end

  describe "#by_day" do
    it "groups revenue by order date" do
      expect(calculator.by_day).to eq(
        Date.new(2026, 10, 10) => 7_000,
        Date.new(2026, 10, 15) => 6_000
      )
    end
  end

  describe "#order_totals" do
    it "returns each order's revenue" do
      expect(calculator.order_totals).to eq(
        order_a.id => 7_000,
        order_b.id => 6_000
      )
    end
  end

  describe "catalog totals" do
    it "ranks products by revenue and keeps unknown costs nil" do
      expect(calculator.product_totals).to eq([
        { product_id: product_b.id, name: "Product B", quantity: 4, revenue_cents: 8_000, cost_cents: nil, margin_pct: nil },
        { product_id: product_a.id, name: "Product A", quantity: 2, revenue_cents: 2_000, cost_cents: 1_000, margin_pct: 50.0 }
      ])
      expect(calculator.top_products(limit: 1).first[:name]).to eq("Product B")
    end

    it "ranks services by revenue without inventing a cost" do
      expect(calculator.service_totals).to eq([
        { service_id: service_a.id, name: "Service A", quantity: 1, revenue_cents: 3_000 }
      ])
    end
  end

  context "with a VND company" do
    let(:company) do
      create(:company,
        business_type: :retail,
        country: :vn,
        currency: :vnd,
        timezone: :plus_7,
        name: "VND Revenue Co")
    end
    let(:paid_orders) { company.orders.where(id: vnd_order.id) }
    let!(:vnd_category) { Seed::CategoryService.create(company: company, name: "VND Sales", resource_name: "orders") }
    let(:vnd_customer) { create(:customer, company: company, name: "VND Customer") }
    let!(:vnd_order) do
      create(:order,
        company: company,
        name: "VND Order #{SecureRandom.hex(4)}",
        customer: vnd_customer,
        category: vnd_category,
        property_mapping: vnd_category.default_property_mapping,
        workflow_status: :paid,
        created_at: Time.zone.local(2026, 10, 10, 10, 0, 0),
        discarded_at: nil)
    end
    let!(:vnd_product) { create(:product, company: company, name: "VND Product", price: 100_000) }

    it "treats line-item totals as whole VND, not cents" do
      create(:order_product_appointment,
        company: company,
        order: vnd_order,
        product: vnd_product,
        quantity: 1,
        unit_price: 100_000,
        total_price: 100_000,
        discarded_at: nil)

      expect(calculator.total_cents).to eq(100_000)
    end
  end
end
