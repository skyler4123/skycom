require "rails_helper"

RSpec.feature "Companies::Brands Edit", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:brand) do
    create(:brand,
      company: company,
      name: "Editable Brand",
      description: "Original description"
    )
  end

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
          workflow_statuses: [
            { name: "Draft", value: "draft" },
            { name: "Pending", value: "pending" },
            { name: "Active", value: "active" }
          ]
        }
      },
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "renders edit form with brand name and type fields" do
    visit edit_company_brand_path(company, brand)

    expect(page).to have_selector('input[name="brand[name]"]', wait: 10)
    expect(page).to have_selector('select[name="brand[business_type]"]', wait: 10)
    expect(page).to have_selector('select[name="brand[workflow_status]"]', wait: 10)
  end

  scenario "updates brand and redirects to show page" do
    visit edit_company_brand_path(company, brand)

    expect(page).to have_selector('input[name="brand[name]"]', wait: 10)
    fill_in 'brand[name]', with: 'Updated Brand Name'

    click_button "Save Changes"

    expect(page).to have_content('Updated Brand Name', wait: 10)

    brand.reload
    expect(brand.name).to eq("Updated Brand Name")
    expect(page).to have_current_path(company_brand_path(company, brand), wait: 10)
  end

  scenario "handles validation error and redirects back to edit page with alert" do
    visit edit_company_brand_path(company, brand)

    expect(page).to have_selector('input[name="brand[name]"]', wait: 10)
    fill_in 'brand[name]', with: ''

    click_button "Save Changes"

    expect(page).to have_content("can't be blank", wait: 10)
    expect(page).to have_current_path(edit_company_brand_path(company, brand), wait: 10)
  end

  scenario "updates description" do
    visit edit_company_brand_path(company, brand)

    fill_in 'brand[description]', with: 'Updated description text'

    click_button "Save Changes"

    expect(page).to have_content('Updated description text', wait: 10)

    brand.reload
    expect(brand.description).to eq('Updated description text')
  end
end
