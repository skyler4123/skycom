require "rails_helper"

RSpec.feature "Companies::Brands New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  before do
    sign_in(owner)

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    payload = {
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {
        brand: {
          business_types: [
            { name: "Manufacturer", value: "manufacturer" },
            { name: "Retailer", value: "retailer" },
            { name: "Service Provider", value: "service_provider" },
            { name: "Technology", value: "technology" }
          ],
          lifecycle_statuses: [],
          workflow_statuses: []
        }
      },
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "renders new brand form with name and type fields" do
    visit new_company_brand_path(company)

    expect(page).to have_selector('input[name="brand[name]"]', wait: 10)
    expect(page).to have_selector('select[name="brand[business_type]"]', wait: 10)
  end

  scenario "creates brand and redirects to show page" do
    visit new_company_brand_path(company)

    fill_in 'brand[name]', with: 'New Test Brand'
    select 'Manufacturer', from: 'brand[business_type]'

    click_button "Save Brand"

    expect(page).to have_content('New Test Brand', wait: 10)

    brand_record = Brand.find_by(name: "New Test Brand")
    expect(brand_record).to be_present
    expect(page).to have_current_path(company_brand_path(company, brand_record), wait: 10)
  end

  scenario "creates brand with email" do
    visit new_company_brand_path(company)

    fill_in 'brand[name]', with: 'Brand With Email'
    fill_in 'brand[email]', with: 'brand@example.com'

    click_button "Save Brand"

    expect(page).to have_content('Brand With Email', wait: 10)

    brand_record = Brand.find_by(name: "Brand With Email")
    expect(brand_record).to be_present
    expect(brand_record.email).to eq('brand@example.com')
  end
end
