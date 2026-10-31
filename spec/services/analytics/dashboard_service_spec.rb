# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::DashboardService do
  include ActiveSupport::Testing::TimeHelpers

  subject(:result) { described_class.call(company: company, period: period) }

  let(:company) do
    create(:company,
      business_type: :retail,
      country: :us,
      currency: :usd,
      timezone: :utc,
      name: "Analytics Co")
  end
  let(:branch) { create(:branch, company: company, name: "Main Branch") }
  let(:warehouse) { create(:warehouse, company: company, branch: branch, name: "Central Vault") }
  let!(:order_category) { Seed::CategoryService.create(company: company, name: "In-Store Purchase", resource_name: "orders") }
  let(:customer) { create(:customer, company: company, branch: branch, name: "Analytics Customer") }
  let(:product) { create(:product, company: company, name: "Fiber Cable", price: 10.0) }
  let(:healthy_product) { create(:product, company: company, name: "Healthy Product", price: 20.0) }
  let(:service) { Seed::ServiceService.create(company: company, branch: branch, name: "Installation") }
  let(:employee) do
    create(:employee,
      company: company,
      branch: branch,
      name: "Staff One",
      lifecycle_status: :active,
      workflow_status: :confirmed)
  end
  let(:period) { "this_month" }

  let!(:current_order) do
    create(:order,
      company: company,
      name: "Current Order #{SecureRandom.hex(4)}",
      branch: branch,
      customer: customer,
      category: order_category,
      property_mapping: order_category.default_property_mapping,
      workflow_status: :paid,
      business_type: :in_store,
      created_at: Time.zone.local(2026, 10, 10, 10, 0, 0),
      discarded_at: nil)
  end
  let!(:previous_order) do
    create(:order,
      company: company,
      name: "Previous Order #{SecureRandom.hex(4)}",
      branch: branch,
      customer: customer,
      category: order_category,
      property_mapping: order_category.default_property_mapping,
      workflow_status: :paid,
      business_type: :in_store,
      created_at: Time.zone.local(2026, 9, 10, 10, 0, 0),
      discarded_at: nil)
  end
  let!(:product_line) do
    create(:order_product_appointment,
      company: company,
      order: current_order,
      product: product,
      quantity: 2,
      unit_price: 10.0,
      total_price: 20.0,
      discarded_at: nil)
  end
  let!(:service_line) do
    create(:order_service_appointment,
      company: company,
      order: current_order,
      service: service,
      quantity: 1,
      unit_price: 30.0,
      total_price: 30.0,
      discarded_at: nil)
  end
  let!(:previous_line) do
    create(:order_product_appointment,
      company: company,
      order: previous_order,
      product: product,
      quantity: 1,
      unit_price: 10.0,
      total_price: 10.0,
      discarded_at: nil)
  end

  around do |example|
    travel_to(Time.zone.local(2026, 10, 15, 12, 0, 0)) { example.run }
  end

  before do
    product.update_column(:metadata, { "cost_price_cents" => 500 })
    healthy_product.update_column(:metadata, {})
    create(:stock,
      warehouse: warehouse,
      product: product,
      quantity: 14,
      pending: 0,
      workflow_status: :confirmed,
      discarded_at: nil)
    create(:stock,
      warehouse: warehouse,
      product: healthy_product,
      quantity: 20,
      pending: 0,
      workflow_status: :confirmed,
      discarded_at: nil)
    StockTransaction.create!(
      company: company,
      warehouse: warehouse,
      product: product,
      category: product.category,
      property_mapping: product.property_mapping,
      direction: :remove,
      transaction_type: :export,
      quantity: 10,
      created_at: Time.zone.local(2026, 10, 12, 10, 0, 0)
    )
    AttendanceMonth.create!(
      company: company,
      branch: branch,
      employee: employee,
      month: Date.new(2026, 10, 1),
      total_work_minutes: 9_600,
      total_overtime_minutes: 60,
      total_present_days: 20,
      total_absent_days: 2
    )
  end

  describe "#call" do
    it "returns the selected period and its previous comparison window" do
      expect(result[:period]).to include(
        key: "this_month",
        start: Time.zone.local(2026, 10, 1),
        end: Time.zone.local(2026, 10, 15, 12, 0, 0),
        previous_start: Time.zone.local(2026, 9, 1)
      )
      expect(result[:period][:previous_end]).to be_within(1.second).of(Time.zone.local(2026, 9, 30, 23, 59, 59))
    end

    it "returns financial summary metrics with deltas" do
      expect(result[:summary]).to include(
        total_revenue_cents: 5_000,
        previous_total_revenue_cents: 1_000,
        revenue_delta_pct: 400.0,
        total_orders: 1,
        previous_total_orders: 1,
        orders_delta_pct: 0.0,
        avg_order_value_cents: 5_000,
        previous_avg_order_value_cents: 1_000,
        avg_order_value_delta_pct: 400.0,
        active_customers: 1,
        previous_active_customers: 1,
        active_customers_delta_pct: 0.0,
        new_customers: 1,
        gross_profit_cents: 1_000,
        gross_margin_pct: 50.0,
        previous_gross_margin_pct: 50.0,
        gross_margin_delta_pp: 0.0,
        cost_coverage_pct: 40.0,
        revenue_per_worked_hour_cents: 31,
        low_stock_count: 1,
        inventory_days_of_cover: 6.0,
        currency: "usd"
      )
    end

    it "returns the monthly revenue, tracked cost, and margin series" do
      expect(result[:profit_margins]).to include(overall_margin_pct: 50.0, cost_coverage_pct: 40.0)
      expect(result[:profit_margins][:by_month]).to eq([
        { month: "2026-10", revenue_cents: 5_000, cost_cents: 1_000, margin_pct: 50.0 }
      ])
    end

    it "returns revenue mix by order category and branch" do
      expect(result[:revenue_mix][:by_category].first).to include(
        id: order_category.id,
        name: "In-Store Purchase",
        revenue_cents: 5_000,
        pct: 100.0
      )
      expect(result[:revenue_mix][:by_branch].first).to include(
        id: branch.id,
        name: "Main Branch",
        revenue_cents: 5_000,
        pct: 100.0
      )
    end

    it "returns top products and services with real cost coverage" do
      expect(result[:top_items][:products].first).to include(
        product_id: product.id,
        name: "Fiber Cable",
        quantity: 2,
        revenue_cents: 2_000,
        cost_cents: 1_000,
        margin_pct: 50.0
      )
      expect(result[:top_items][:services].first).to include(
        service_id: service.id,
        name: "Installation",
        quantity: 1,
        revenue_cents: 3_000
      )
    end

    it "returns inventory velocity, days of cover, and stock value" do
      velocity = result[:inventory_velocity]
      expect(velocity[:low_stock_count]).to eq(1)
      expect(velocity[:low_stock_items].first).to include(
        product_name: "Fiber Cable",
        warehouse_name: "Central Vault",
        quantity: 4,
        available: 4
      )
      expect(velocity[:by_product].first).to include(
        product_id: product.id,
        name: "Fiber Cable",
        quantity: 4,
        available: 4,
        units_sold: 10,
        turnover_rate: 2.5,
        days_of_cover: 6.0,
        revenue_cents: 2_000,
        cost_cents: 1_000,
        margin_pct: 50.0
      )
      expect(velocity[:stock_value_cost_cents]).to eq(2_000)
      expect(velocity[:stock_value_retail_cents]).to eq(44_000)
    end

    it "returns workforce totals and per-employee attendance" do
      performance = result[:staff_performance]
      expect(performance[:totals]).to eq(
        employees_count: 1,
        total_hours: 160.0,
        overtime_hours: 1.0,
        absent_days: 2,
        average_attendance_rate: 90.9
      )
      expect(performance[:by_employee].first).to include(
        employee_id: employee.id,
        name: "Staff One",
        total_hours: 160.0,
        overtime_hours: 1.0,
        absent_days: 2,
        attendance_rate: 90.9
      )
    end

    it "returns CLV, new customers, and the returning-customer rate" do
      expect(result[:customer_clv][:by_customer].first).to include(
        customer_id: customer.id,
        name: "Analytics Customer",
        total_spent_cents: 6_000,
        order_count: 2,
        avg_order_value_cents: 3_000
      )
      expect(result[:customer_clv][:new_customers]).to eq(1)
      expect(result[:customer_clv][:repeat_customer_rate]).to eq(100.0)
    end

    it "returns a real cohort retention row from the first paid order" do
      expect(result[:cohorts]).to eq([
        { cohort: "2026-09", new_customers: 1, retention: [ 100.0, 100.0, nil, nil, nil, nil ] }
      ])
    end
  end

  context "with no data" do
    let(:company) { create(:company, business_type: :retail, name: "Empty Analytics Co") }

    before do
      StockTransaction.where(company: company).delete_all
      company.stocks.destroy_all
      company.attendance_months.destroy_all
      company.orders.destroy_all
      company.customers.destroy_all
    end

    it "returns zero-filled metrics and nil where no baseline exists" do
      expect(result[:summary]).to include(
        total_revenue_cents: 0,
        total_orders: 0,
        active_customers: 0,
        new_customers: 0,
        gross_profit_cents: 0,
        gross_margin_pct: nil,
        cost_coverage_pct: nil,
        revenue_per_worked_hour_cents: nil,
        inventory_days_of_cover: nil,
        low_stock_count: 0
      )
      expect(result[:profit_margins][:by_month]).to eq([])
      expect(result[:revenue_mix][:by_category]).to eq([])
      expect(result[:revenue_mix][:by_branch]).to eq([])
      expect(result[:top_items]).to eq(products: [], services: [])
      expect(result[:inventory_velocity][:by_product]).to eq([])
      expect(result[:staff_performance][:by_employee]).to eq([])
      expect(result[:customer_clv][:by_customer]).to eq([])
      expect(result[:cohorts]).to eq([])
    end
  end

  context "with period filter" do
    let(:period) { "last_month" }

    it "supports last_month" do
      expect(result).to have_key(:summary)
      expect(result[:period][:key]).to eq("last_month")
    end

    context "with last_6_months" do
      let(:period) { "last_6_months" }

      it "supports last_6_months" do
        expect(result).to have_key(:profit_margins)
        expect(result[:period][:key]).to eq("last_6_months")
      end
    end

    context "with this_year" do
      let(:period) { "this_year" }

      it "supports this_year" do
        expect(result).to have_key(:summary)
        expect(result[:period][:key]).to eq("this_year")
      end
    end
  end
end
