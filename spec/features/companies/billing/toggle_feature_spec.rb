# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Billing::ToggleFeature", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }
  let(:contract) { company.active_billing_contract }

  before do
    create(:billing_resource, :addon_feature,
      name: "analytics_dashboard",
      description: "Advanced analytics and reporting",
      country: company.country)

    sign_in(owner)

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
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

  scenario "shows add-on features in the catalog" do
    visit company_billing_path(company)
    expect(page).to have_css("*", text: "Advanced analytics and reporting", visible: :all, wait: 10)
  end

  scenario "toggling ON a disabled feature enables it" do
    visit company_billing_path(company)
    expect(page).to have_css("*", text: "Advanced analytics and reporting", visible: :all, wait: 10)

    row = find("tr", text: "Advanced analytics and reporting")
    within(row) do
      find("label").click
    end

    expect(page).to have_css("*", text: "Add-on Features Catalog", visible: :all, wait: 10)

    row = find("tr", text: "Advanced analytics and reporting")
    within(row) do
      expect(find('input[type="checkbox"]', visible: false)).to be_checked
    end
  end

  scenario "toggling OFF an enabled feature disables it" do
    create(:contract_feature, billing_contract: contract,
           billing_resource: BillingResource.addon_feature.find_by!(name: "analytics_dashboard"),
           lifecycle_status: :active)

    visit company_billing_path(company)
    expect(page).to have_css("*", text: "Advanced analytics and reporting", visible: :all, wait: 10)

    row = find("tr", text: "Advanced analytics and reporting")
    within(row) do
      expect(find('input[type="checkbox"]', visible: false)).to be_checked
      find("label").click
    end

    expect(page).to have_css("*", text: "Add-on Features Catalog", visible: :all, wait: 10)

    row = find("tr", text: "Advanced analytics and reporting")
    within(row) do
      expect(find('input[type="checkbox"]', visible: false)).not_to be_checked
    end
  end

  scenario "round-trip: toggle ON then OFF" do
    visit company_billing_path(company)
    expect(page).to have_css("*", text: "Advanced analytics and reporting", visible: :all, wait: 10)

    row = find("tr", text: "Advanced analytics and reporting")
    within(row) do
      find("label").click
    end
    expect(page).to have_css("*", text: "Add-on Features Catalog", visible: :all, wait: 10)

    row = find("tr", text: "Advanced analytics and reporting")
    within(row) do
      expect(find('input[type="checkbox"]', visible: false)).to be_checked
    end

    row = find("tr", text: "Advanced analytics and reporting")
    within(row) do
      find("label").click
    end
    expect(page).to have_css("*", text: "Add-on Features Catalog", visible: :all, wait: 10)

    row = find("tr", text: "Advanced analytics and reporting")
    within(row) do
      expect(find('input[type="checkbox"]', visible: false)).not_to be_checked
    end
  end
end
