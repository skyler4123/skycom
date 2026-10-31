# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dashboards::OverviewService do
  include ActiveSupport::Testing::TimeHelpers

  subject(:result) do
    described_class.call(company: company, can_view_financials: can_view_financials)
  end

  let(:can_view_financials) { true }
  let(:company) do
    create(:company,
      business_type: :retail,
      country: :us,
      currency: :usd,
      timezone: :utc,
      name: "Health Co")
  end
  let(:branch) { create(:branch, company: company, name: "Main Branch") }
  let(:warehouse) { create(:warehouse, company: company, branch: branch, name: "Central Vault") }
  let!(:order_category) { Seed::CategoryService.create(company: company, name: "In-Store Purchase", resource_name: "orders") }
  let!(:event_category) { Seed::CategoryService.create(company: company, name: "Appointment", resource_name: "events") }
  let(:customer) { create(:customer, company: company, branch: branch, name: "Acme Customer") }
  let(:product) { create(:product, company: company, name: "Fiber Cable", price: 10.0) }
  let(:service) { Seed::ServiceService.create(company: company, branch: branch, name: "Installation") }
  let(:employee) do
    create(:employee,
      company: company,
      branch: branch,
      name: "Staff One",
      lifecycle_status: :active,
      workflow_status: :confirmed)
  end
  let(:wallet) { company.company_wallet || company.create_company_wallet!(walletable: company) }

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

  describe "#call with financial visibility" do
    before do
      product.update_column(:metadata, { "cost_price_cents" => 500 })
      wallet.add_credits!(amount: 100) if wallet.main_credit_balance.zero?
      wallet.deduct_from!(balance: :main, amount: 10, description: "Dashboard usage")

      create(:stock,
        warehouse: warehouse,
        product: product,
        quantity: 4,
        pending: 0,
        workflow_status: :confirmed,
        discarded_at: nil)
      create(:stock,
        warehouse: warehouse,
        product: create(:product, company: company, name: "Healthy Product", price: 20.0),
        quantity: 20,
        pending: 0,
        workflow_status: :confirmed,
        discarded_at: nil)

      create(:purchase,
        company: company,
        branch: branch,
        warehouse: warehouse,
        name: "Pending Purchase #{SecureRandom.hex(4)}",
        workflow_status: :pending,
        skip_workflow: true,
        discarded_at: nil)
      create(:ticket,
        company: company,
        employee: employee,
        name: "Pending Ticket #{SecureRandom.hex(4)}",
        priority: :urgent,
        workflow_status: :pending,
        skip_workflow: true,
        discarded_at: nil)
      create(:attendance_request,
        company: company,
        employee: employee,
        status: :pending)

      create(:invoice,
        order: current_order,
        name: "Overdue Invoice #{SecureRandom.hex(4)}",
        payment_status: :unpaid,
        due_date: Date.yesterday,
        price_cents: 5_000)
      create(:attendance_day,
        company: company,
        employee: employee,
        attendance_date: Date.current,
        attendance_status: :present)
      create(:scheduled_shift,
        company: company,
        branch: branch,
        employee: employee,
        work_date: Date.current,
        expected_start_at: Time.zone.local(2026, 10, 15, 9, 0, 0),
        expected_end_at: Time.zone.local(2026, 10, 15, 17, 0, 0),
        status: :scheduled)
      create(:event,
        company: company,
        branch: branch,
        category: event_category,
        property_mapping: event_category.default_property_mapping,
        name: "Quarterly Review",
        start_at: Time.zone.local(2026, 10, 16, 9, 0, 0),
        end_at: Time.zone.local(2026, 10, 16, 10, 0, 0),
        workflow_status: :confirmed,
        business_type: :appointment,
        discarded_at: nil)
    end

    it "returns the company meta and permissions" do
      expect(result[:company]).to include(
        "id" => company.id,
        "name" => "Health Co",
        "currency" => "usd",
        branches_count: 1,
        active_employees_count: 2
      )
      expect(result[:company][:owner]).to include("email" => company.user.email)
      expect(result[:permissions]).to eq(can_view_financials: true)
      expect(result[:period][:key]).to eq("this_month")
    end

    it "returns financial KPIs with previous-period deltas and tracked margin" do
      expect(result[:kpis]).to include(
        revenue_cents: 5_000,
        revenue_delta_pct: 400.0,
        orders_count: 1,
        orders_delta_pct: 0.0,
        avg_order_value_cents: 5_000,
        avg_order_value_delta_pct: 400.0,
        active_customers_count: 1,
        gross_margin_pct: 50.0,
        cost_coverage_pct: 40.0,
        credits_total: 90,
        credits_debt: 0
      )
    end

    it "returns the 30-day revenue and order trend" do
      expect(result[:trend].length).to eq(30)
      expect(result[:trend].last).to include(date: "2026-10-15", revenue_cents: 0, orders_count: 0)
      oct_10 = result[:trend].find { |row| row[:date] == "2026-10-10" }
      expect(oct_10).to include(revenue_cents: 5_000, orders_count: 1)
    end

    it "returns revenue mix by order category" do
      expect(result[:revenue_mix]).to eq([
        { id: order_category.id, name: "In-Store Purchase", revenue_cents: 5_000, pct: 100.0 }
      ])
    end

    it "returns the attention list with real operational alerts" do
      expect(result[:attention][:low_stock].first).to include(
        product_name: "Fiber Cable",
        warehouse_name: "Central Vault",
        quantity: 4,
        pending: 0,
        available: 4
      )
      expect(result[:attention][:approvals]).to eq(
        purchases: 1,
        tickets: 1,
        attendance_requests: 1,
        total: 3
      )
      expect(result[:attention][:overdue_invoices].first).to include(
        name: a_string_starting_with("Overdue Invoice"),
        price_cents: 5_000
      )
      expect(result[:attention][:urgent_tickets].first).to include(
        name: a_string_starting_with("Pending Ticket"),
        priority: "urgent"
      )
    end

    it "returns recent orders with derived totals" do
      expect(result[:recent_orders].first).to include(
        id: current_order.id,
        customer_name: "Acme Customer",
        branch_name: "Main Branch",
        workflow_status: "paid",
        total_cents: 5_000
      )
    end

    it "returns top customers for the current month" do
      expect(result[:top_customers]).to eq([
        { customer_id: customer.id, name: "Acme Customer", total_spent_cents: 5_000, order_count: 1 }
      ])
    end

    it "returns today's staff pulse and upcoming events" do
      expect(result[:staff_today]).to eq(
        scheduled: 1,
        present: 1,
        half_day: 0,
        late: 0,
        absent: 0,
        missing_checkout: 0,
        attendance_rate: 100.0
      )
      expect(result[:upcoming_events].first).to include(
        name: "Quarterly Review",
        branch_name: "Main Branch"
      )
    end

    it "returns the wallet balance and this month's usage" do
      expect(result[:wallet]).to include(
        main_credit_balance: 90,
        promo_credit_balance: 0,
        debt_credit_balance: 0,
        total_credit_balance: 90,
        used_this_month: 10,
        currency: "usd",
        access_cost: 2
      )
    end
  end

  describe "#call without financial visibility" do
    let(:can_view_financials) { false }

    it "keeps operational metrics and removes money keys" do
      expect(result[:permissions]).to eq(can_view_financials: false)
      expect(result[:kpis]).to include(
        orders_count: 1,
        active_customers_count: 1,
        low_stock_count: 0,
        pending_approvals_count: 0
      )
      expect(result[:kpis]).not_to have_key(:revenue_cents)
      expect(result).not_to have_key(:wallet)
      expect(result).not_to have_key(:trend)
      expect(result).not_to have_key(:revenue_mix)
      expect(result).not_to have_key(:top_customers)
      expect(result[:recent_orders].first).to include(total_cents: nil)
      expect(result[:attention][:overdue_invoices]).to eq([])
    end
  end

  describe "#call with no data" do
    let(:company) { create(:company, business_type: :retail, name: "Empty Co") }

    before do
      company.orders.destroy_all
      company.customers.destroy_all
    end

    it "returns zero-filled operational data without inventing money" do
      expect(result[:kpis]).to include(
        revenue_cents: 0,
        orders_count: 0,
        active_customers_count: 0,
        low_stock_count: 0,
        pending_approvals_count: 0,
        gross_margin_pct: nil,
        cost_coverage_pct: nil,
        credits_total: 0
      )
      expect(result[:trend].length).to eq(30)
      expect(result[:trend].all? { |row| row[:revenue_cents].zero? && row[:orders_count].zero? }).to be(true)
      expect(result[:revenue_mix]).to eq([])
      expect(result[:recent_orders]).to eq([])
      expect(result[:top_customers]).to eq([])
      expect(result[:upcoming_events]).to eq([])
      expect(result[:wallet]).to include(main_credit_balance: 0, total_credit_balance: 0)
    end
  end
end
