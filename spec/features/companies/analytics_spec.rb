require "rails_helper"

RSpec.feature "Analytics Dashboard", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:contract) { company.active_billing_contract }
  let(:branch) { create(:branch, company: company) }

  def seed_client_cache(billing_contract_data = nil)
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "billing_contract_summary" => billing_contract_data,
      "property_mappings" => [],
      "table_configs" => [],
      "categories" => [],
      "branches" => [ JSON.parse(branch.to_json) ],
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

  def with_analytics
    { "contract_type" => "basic", "enabled_features" => %w[pos_basic inventory_basic crm_basic finance_basic analytics_dashboard] }
  end

  def without_analytics
    { "contract_type" => "basic", "enabled_features" => %w[pos_basic inventory_basic crm_basic finance_basic] }
  end

  before do
    sign_in(owner)
  end

  describe "sidebar link" do
    scenario "is hidden when analytics_dashboard feature is not enabled" do
      seed_client_cache(without_analytics)
      visit company_billing_path(company)

      expect(page).not_to have_link("Analytics", href: /analytics/, visible: :all)
    end

    scenario "is visible when analytics_dashboard feature is enabled" do
      seed_client_cache(with_analytics)
      visit company_billing_path(company)

      expect(page).to have_link("Analytics", href: /analytics/, visible: :all, wait: 10)
    end
  end

  describe "page load" do
    scenario "loads the analytics page with summary cards" do
      seed_client_cache(with_analytics)
      visit company_analytics_path(company)

      expect(page).to have_content("Analytics", wait: 10)
      expect(page).to have_content("Revenue")
      expect(page).to have_content("Orders")
    end

    scenario "shows period selector" do
      seed_client_cache(with_analytics)
      visit company_analytics_path(company)

      expect(page).to have_selector("select", wait: 10)
    end
  end
end
