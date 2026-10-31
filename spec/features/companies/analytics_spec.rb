# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Analytics Dashboard", type: :feature, js: true do
  def seed_client_cache(company:, user:)
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => company.branches.reset.map { |b| JSON.parse(b.to_json) },
      "departments" => [],
      "roles" => []
    )

    payload = {
      user: JSON.parse(user.to_json),
      companies: [ company_data ],
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  let(:company) do
    create(:company,
      business_type: :retail,
      country: :us,
      currency: :usd,
      timezone: :utc,
      name: "Analytics Spec Co")
  end
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company, name: "Main Branch") }
  let(:warehouse) { create(:warehouse, company: company, branch: branch, name: "Central Vault") }
  let!(:order_category) { Seed::CategoryService.create(company: company, name: "In-Store Purchase", resource_name: "orders") }
  let!(:customer) { create(:customer, company: company, branch: branch, name: "Analytics Customer") }
  let!(:product) { create(:product, company: company, name: "Fiber Cable", price: 10.0) }
  let!(:healthy_product) { create(:product, company: company, name: "Healthy Product", price: 20.0) }
  let!(:service) { Seed::ServiceService.create(company: company, branch: branch, name: "Installation") }
  let!(:employee) do
    create(:employee,
      company: company,
      branch: branch,
      name: "Staff One",
      lifecycle_status: :active,
      workflow_status: :confirmed)
  end

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
      created_at: Time.current,
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
      created_at: 1.month.ago,
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
      created_at: Time.current
    )
    AttendanceMonth.create!(
      company: company,
      branch: branch,
      employee: employee,
      month: Date.current.beginning_of_month,
      total_work_minutes: 9_600,
      total_overtime_minutes: 60,
      total_present_days: 20,
      total_absent_days: 2
    )

    sign_in(owner)
    seed_client_cache(company: company, user: owner)
  end

  scenario "shows the executive analysis dashboard" do
    visit company_analytics_path(company)

    expect(page).to have_content("Executive analysis", wait: 10)
    expect(page).to have_selector('select[name="period"]', wait: 10)
    expect(page).to have_selector('[data-analytics-metric="revenue"]', text: "$50.00", wait: 10)
    expect(page).to have_selector('[data-analytics-metric="gross-profit"]', text: "$10.00", wait: 10)
    expect(page).to have_selector('[data-analytics-metric="gross-margin"]', text: "50.0%", wait: 10)
    expect(page).to have_selector('[data-analytics-metric="customer-economics"]', text: "$50.00", wait: 10)
    expect(page).to have_selector('[data-analytics-metric="inventory-velocity"]', text: "2.5", wait: 10)
    expect(page).to have_selector('[data-analytics-metric="orders"]', text: "1", wait: 10)
    expect(page).to have_selector('[data-analytics-metric="new-customers"]', text: "1", wait: 10)
    expect(page).to have_selector('[data-analytics-metric="revenue-per-hour"]', text: "$0.31", wait: 10)
    expect(page).to have_selector('[data-analytics-metric="low-stock"]', text: "1", wait: 10)
    expect(page).to have_selector('[data-analytics-chart="margin"] svg', wait: 10)
    expect(page).to have_selector('[data-analytics-section="revenue-mix"]', text: "In-Store Purchase", wait: 10)
    expect(page).to have_selector('[data-analytics-section="revenue-mix"]', text: "Main Branch", wait: 10)
    expect(page).to have_selector('[data-analytics-section="top-items"]', text: "Fiber Cable", wait: 10)
    expect(page).to have_selector('[data-analytics-section="top-items"]', text: "Installation", wait: 10)
    expect(page).to have_selector('[data-analytics-section="cohorts"]', text: 1.month.ago.strftime("%b %Y"), wait: 10)
    expect(page).to have_selector('[data-analytics-section="inventory"]', text: "Fiber Cable", wait: 10)
    expect(page).to have_selector('[data-analytics-section="workforce"]', text: "90.9%", wait: 10)
  end

  scenario "switches the reporting period" do
    visit company_analytics_path(company)

    expect(page).to have_selector('[data-analytics-metric="revenue"]', text: "$50.00", wait: 10)
    select "Last Month", from: "period"

    expect(page).to have_selector('[data-analytics-metric="revenue"]', text: "$10.00", wait: 10)
  end
end
