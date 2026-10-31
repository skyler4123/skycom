# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Dashboards", type: :feature, js: true do
  def seed_client_cache(company:, user:, employee: nil)
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
      employees: employee ? [ JSON.parse(employee.to_json) ] : []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  context "with company health data" do
    let(:company) do
      create(:company,
        business_type: :retail,
        country: :us,
        currency: :usd,
        timezone: :utc,
        name: "Health Spec Co")
    end
    let(:owner) { company.user }
    let(:branch) { create(:branch, company: company, name: "Main Branch") }
    let(:warehouse) { create(:warehouse, company: company, branch: branch, name: "Central Vault") }
    let!(:order_category) { Seed::CategoryService.create(company: company, name: "In-Store Purchase", resource_name: "orders") }
    let!(:event_category) { Seed::CategoryService.create(company: company, name: "Appointment", resource_name: "events") }
    let!(:customer) { create(:customer, company: company, branch: branch, name: "Acme Customer") }
    let!(:product) { create(:product, company: company, name: "Fiber Cable", price: 10.0) }
    let!(:service) { Seed::ServiceService.create(company: company, branch: branch, name: "Installation") }
    let!(:employee) do
      create(:employee,
        company: company,
        branch: branch,
        name: "Staff One",
        lifecycle_status: :active,
        workflow_status: :confirmed)
    end
    let(:wallet) { company.company_wallet }

    let!(:order) do
      create(:order,
        company: company,
        name: "Health Order #{SecureRandom.hex(4)}",
        branch: branch,
        customer: customer,
        category: order_category,
        property_mapping: order_category.default_property_mapping,
        workflow_status: :paid,
        business_type: :in_store,
        created_at: Time.current,
        discarded_at: nil)
    end
    let!(:product_line) do
      create(:order_product_appointment,
        company: company,
        order: order,
        product: product,
        quantity: 2,
        unit_price: 10.0,
        total_price: 20.0,
        discarded_at: nil)
    end
    let!(:service_line) do
      create(:order_service_appointment,
        company: company,
        order: order,
        service: service,
        quantity: 1,
        unit_price: 30.0,
        total_price: 30.0,
        discarded_at: nil)
    end

    before do
      product.update_column(:metadata, { "cost_price_cents" => 500 })
      wallet.add_credits!(amount: 100)
      create(:stock,
        warehouse: warehouse,
        product: product,
        quantity: 4,
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
        name: "Urgent Ticket #{SecureRandom.hex(4)}",
        priority: :urgent,
        workflow_status: :pending,
        skip_workflow: true,
        discarded_at: nil)
      create(:attendance_request,
        company: company,
        employee: employee,
        status: :pending)
      create(:invoice,
        order: order,
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
        expected_start_at: Time.current.change(hour: 9),
        expected_end_at: Time.current.change(hour: 17),
        status: :scheduled)
      create(:event,
        company: company,
        branch: branch,
        category: event_category,
        property_mapping: event_category.default_property_mapping,
        name: "Quarterly Review",
        start_at: 1.day.from_now,
        end_at: 1.day.from_now + 1.hour,
        workflow_status: :confirmed,
        business_type: :appointment,
        discarded_at: nil)
      company.clear_permissions_cache
    end

    scenario "shows the company health dashboard for a financial user" do
      sign_in(owner)
      seed_client_cache(company: company, user: owner)
      visit company_dashboards_path(company)

      expect(page).to have_content("Company health", wait: 10)
      expect(page).to have_content(company.name, wait: 10)
      expect(page).to have_selector('[data-kpi="revenue"]', text: "$50.00", wait: 10)
      expect(page).to have_selector('[data-kpi="orders"]', text: "1", wait: 10)
      expect(page).to have_selector('[data-kpi="aov"]', text: "$50.00", wait: 10)
      expect(page).to have_selector('[data-kpi="margin"]', text: "50.0%", wait: 10)
      expect(page).to have_selector('[data-kpi="customers"]', text: "1", wait: 10)
      expect(page).to have_selector('[data-kpi="low-stock"]', text: "1", wait: 10)
      expect(page).to have_selector('[data-kpi="approvals"]', text: "3", wait: 10)
      expect(page).to have_selector('[data-kpi="credits"]', text: "100", wait: 10)
      expect(page).to have_selector('[data-dashboard-chart="trend"] svg', wait: 10)
      expect(page).to have_selector('[data-dashboard-chart="mix"] svg', wait: 10)
      expect(page).to have_selector('[data-attention="low-stock"]', text: "Fiber Cable", wait: 10)
      expect(page).to have_selector('[data-attention="low-stock"]', text: "Central Vault", wait: 10)
      expect(page).to have_selector('[data-attention="approvals"]', text: "Purchases", wait: 10)
      expect(page).to have_selector('[data-attention="overdue-invoices"]', text: "Overdue Invoice", wait: 10)
      expect(page).to have_selector('[data-attention="urgent-tickets"]', text: "Urgent Ticket", wait: 10)
      expect(page).to have_selector('[data-dashboard-section="recent-orders"]', text: "Acme Customer", wait: 10)
      expect(page).to have_selector('[data-dashboard-section="recent-orders"]', text: "$50.00", wait: 10)
      expect(page).to have_selector('[data-dashboard-section="top-customers"]', text: "Acme Customer", wait: 10)
      expect(page).to have_selector('[data-dashboard-section="staff-today"]', text: /Present/i, wait: 10)
      expect(page).to have_selector('[data-dashboard-section="events"]', text: "Quarterly Review", wait: 10)
      expect(page).to have_selector('[data-dashboard-section="wallet"]', text: "100", wait: 10)
    end

    scenario "hides financial cards for an employee without Invoice read" do
      employee_user = create(:user, :company_employee)
      viewer = create(:employee, company: company, user: employee_user, lifecycle_status: :active)
      viewer.clear_permissions_cache
      company.clear_permissions_cache
      sign_in(employee_user)
      seed_client_cache(company: company, user: employee_user, employee: viewer)

      visit company_dashboards_path(company)

      expect(page).to have_content("Company health", wait: 10)
      expect(page).not_to have_selector('[data-kpi="revenue"]')
      expect(page).not_to have_selector('[data-kpi="aov"]')
      expect(page).not_to have_selector('[data-kpi="margin"]')
      expect(page).not_to have_selector('[data-kpi="credits"]')
      expect(page).not_to have_selector('[data-dashboard-chart="trend"]')
      expect(page).not_to have_selector('[data-dashboard-chart="mix"]')
      expect(page).not_to have_selector('[data-dashboard-section="wallet"]')
      expect(page).not_to have_selector('[data-attention="overdue-invoices"]')
      expect(page).not_to have_link("Open Analytics")
      expect(page).to have_selector('[data-kpi="orders"]', wait: 10)
      expect(page).to have_selector('[data-kpi="low-stock"]', wait: 10)
      expect(page).to have_selector('[data-kpi="approvals"]', wait: 10)
      expect(page).to have_selector('[data-dashboard-section="recent-orders"]', wait: 10)
      expect(page).to have_selector('[data-dashboard-section="staff-today"]', wait: 10)
    end
  end

  context "with credit deduction edge cases" do
    let(:company) { create(:company, name: "Credit Spec Co") }
    let(:owner) { company.user }

    before do
      sign_in(owner)
      seed_client_cache(company: company, user: owner)
    end

    scenario "deducts 2 credits from main per visit and records usage" do
      company.company_wallet.add_credits!(amount: 100)

      visit company_dashboards_path(company)

      expect(page).to have_content("Company health", wait: 10)
      expect(page).to have_content(company.name, wait: 10)
      expect(company.company_wallet.reload.main_credit_balance).to eq(98)
      expect(CompanyWalletLog.last.change_type).to eq("debit")
      expect(company.credit_usage_delta).to eq(2)
    end

    scenario "deducts from promo before main" do
      company.company_wallet.add_to!(balance: :promo, amount: 5)
      company.company_wallet.add_to!(balance: :main, amount: 100)

      visit company_dashboards_path(company)

      expect(page).to have_content("Company health", wait: 10)
      expect(page).to have_content(company.name, wait: 10)
      expect(company.company_wallet.reload.promo_credit_balance).to eq(3)
      expect(company.company_wallet.reload.main_credit_balance).to eq(100)
    end

    scenario "absorbs the shortfall into debt and still renders without a warning" do
      company.company_wallet.add_credits!(amount: 1)

      visit company_dashboards_path(company)

      expect(page).to have_content("Company health", wait: 10)
      expect(page).to have_content(company.name, wait: 10)
      expect(page).not_to have_content("Insufficient credits")
      expect(company.company_wallet.reload.main_credit_balance).to eq(0)
      expect(company.company_wallet.reload.debt_credit_balance).to eq(1)
    end
  end
end
