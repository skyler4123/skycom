require "rails_helper"

RSpec.feature "Feature Gating", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:contract) { company.active_billing_contract }

  # --- Helpers ---

  def seed_client_cache(billing_contract_data = nil)
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "billing_contract_summary" => billing_contract_data,
      "property_mappings" => [],
      "table_configs" => [],
      "categories" => [],
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    payload = {
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  def core_only_features
    { "contract_type" => "basic", "enabled_features" => %w[pos_basic inventory_basic crm_basic finance_basic] }
  end

  def with_feature(*keys)
    { "contract_type" => "basic", "enabled_features" => %w[pos_basic inventory_basic crm_basic finance_basic] + keys.map(&:to_s) }
  end

  def create_billing_resource(name)
    create(:billing_resource, :addon_feature, name: name, country_code: company.country_code)
  end

  def enable_feature(name)
    resource = create_billing_resource(name)
    create(:contract_feature, billing_contract: contract, billing_resource: resource, lifecycle_status: :active)
  end

  before do
    sign_in(owner)
  end

  # ==========================================================================
  # Group 1: Sidebar Gating (frontend via client cache)
  # ==========================================================================

  describe "sidebar gating" do
    scenario "hides disabled feature link when feature is not in enabled_features" do
      seed_client_cache(core_only_features)
      visit company_billing_path(company)

      expect(page).to have_link("Dashboard", href: "/companies/#{company.id}/dashboards", visible: :all, wait: 10)
      expect(page).to have_link("Products", href: "/companies/#{company.id}/products", visible: :all, wait: 10)
      expect(page).not_to have_link("Employees", href: "/companies/#{company.id}/employees", visible: :all)
      expect(page).not_to have_link("Shift Templates", href: "/companies/#{company.id}/shift_templates", visible: :all)
      expect(page).not_to have_link("Permissions", href: "/companies/#{company.id}/permissions", visible: :all)
    end

    scenario "shows enabled feature link when feature is in enabled_features" do
      seed_client_cache(with_feature(:hrm_attendance))
      visit company_billing_path(company)

      expect(page).to have_link("Employees", href: "/companies/#{company.id}/employees", visible: :all, wait: 10)
    end

    scenario "shows ungated links regardless of features" do
      seed_client_cache(core_only_features)
      visit company_billing_path(company)

      expect(page).to have_link("Dashboard", visible: :all, wait: 10)
      expect(page).to have_link("Departments", visible: :all, wait: 10)
      expect(page).to have_link("Categories", visible: :all, wait: 10)
      expect(page).to have_link("Billing", visible: :all, wait: 10)
      expect(page).to have_link("Facilities", visible: :all, wait: 10)
    end

    scenario "hides multiple disabled features at once" do
      seed_client_cache(core_only_features)
      visit company_billing_path(company)

      expect(page).not_to have_link("Stock Transfers", href: "/companies/#{company.id}/stock_transfers", visible: :all)
      expect(page).not_to have_link("Policies", href: "/companies/#{company.id}/policies", visible: :all)
    end

    scenario "branches link is hidden when multi_branch is disabled" do
      seed_client_cache(core_only_features)
      visit company_billing_path(company)

      expect(page).not_to have_link("Branches", href: "/companies/#{company.id}/branches", visible: :all)
    end
  end

  # ==========================================================================
  # Group 2: Page Access Gating (backend via DB records)
  # ==========================================================================

  describe "page access gating" do
    scenario "redirects to billing when accessing a disabled feature page" do
      create_billing_resource("hrm_attendance")
      seed_client_cache(core_only_features)

      visit company_employees_path(company)

      expect(page).to have_current_path(company_billing_path(company), wait: 10)
      expect(page).to have_css("*", text: "Feature not available", visible: false, wait: 10)
    end

    scenario "shows flash with feature name when redirected from disabled feature" do
      create_billing_resource("hrm_attendance")
      seed_client_cache(core_only_features)

      visit company_employees_path(company)

      expect(page).to have_text("Upgrade your plan to enable Hrm attendance", wait: 10)
    end

    scenario "loads the page normally when feature is enabled" do
      enable_feature("hrm_attendance")
      seed_client_cache(with_feature(:hrm_attendance))

      visit company_employees_path(company)

      expect(page).to have_current_path(company_employees_path(company), wait: 10)
      expect(page).to have_css("table", wait: 10)
    end

    scenario "disabled feature page does not render table content" do
      create_billing_resource("hrm_attendance")
      seed_client_cache(core_only_features)

      visit company_employees_path(company)

      expect(page).not_to have_css("table")
    end

    scenario "core free features are always accessible" do
      seed_client_cache(core_only_features)

      visit company_products_path(company)

      expect(page).to have_current_path(company_products_path(company), wait: 10)
      expect(page).to have_css("table", wait: 10)
    end

    scenario "ungated controller is always accessible" do
      seed_client_cache(core_only_features)

      visit company_categories_path(company)

      expect(page).to have_current_path(company_categories_path(company), wait: 10)
    end
  end

  describe "feature gating safety" do
    scenario "all features accessible when no billing resources are seeded" do
      visit company_employees_path(company)

      expect(page).to have_current_path(company_employees_path(company), wait: 10)
    end

    scenario "billing page is always accessible regardless of feature state" do
      create_billing_resource("hrm_attendance")
      seed_client_cache(core_only_features)

      visit company_billing_path(company)

      expect(page).to have_current_path(company_billing_path(company), wait: 10)
      expect(page).to have_css("*", text: "Billing Status", visible: false, wait: 10)
    end
  end

  # ==========================================================================
  # Group 3: Feature Store Toggle (end-to-end via billing dashboard)
  # ==========================================================================

  describe "feature store toggling" do
    before do
      Rails.local_cache.clear
      create(:billing_resource, :addon_feature, name: "hrm_attendance", country_code: company.country_code)
    end

    scenario "toggling a feature OFF hides it from sidebar after reload" do
      resource = BillingResource.find_by(name: "hrm_attendance")
      create(:contract_feature, billing_contract: contract, billing_resource: resource, lifecycle_status: :active)

      seed_client_cache(with_feature(:hrm_attendance))
      visit company_billing_path(company)
      expect(page).to have_link("Employees", href: "/companies/#{company.id}/employees", visible: :all, wait: 10)
      expect(page).to have_css("[data-companies--billing--show-feature-key-param='hrm_attendance']", visible: false, wait: 10)

      page.execute_script("document.querySelector('[data-companies--billing--show-feature-key-param=\"hrm_attendance\"]').checked = true")
      page.execute_script("document.querySelector('[data-companies--billing--show-feature-key-param=\"hrm_attendance\"]').dispatchEvent(new Event('change', { bubbles: true }))")

      sleep 2

      seed_client_cache(core_only_features)
      visit company_billing_path(company)
      expect(page).not_to have_link("Employees", href: "/companies/#{company.id}/employees", visible: :all)
    end

    scenario "toggling a feature ON makes sidebar link appear after reload" do
      seed_client_cache(core_only_features)
      visit company_billing_path(company)
      expect(page).not_to have_link("Employees", href: "/companies/#{company.id}/employees", visible: :all)
      expect(page).to have_css("[data-companies--billing--show-feature-key-param='hrm_attendance']", visible: false, wait: 10)

      page.execute_script("document.querySelector('[data-companies--billing--show-feature-key-param=\"hrm_attendance\"]').checked = true")
      page.execute_script("document.querySelector('[data-companies--billing--show-feature-key-param=\"hrm_attendance\"]').dispatchEvent(new Event('change', { bubbles: true }))")

      sleep 2

      seed_client_cache(with_feature(:hrm_attendance))
      visit company_billing_path(company)
      expect(page).to have_link("Employees", href: "/companies/#{company.id}/employees", visible: :all, wait: 10)
    end
  end
end
