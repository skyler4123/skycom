require "rails_helper"

RSpec.feature "Companies::Brands Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:brand) { create(:brand, company: company, name: "Test Brand", description: "A test brand description") }

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
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "displays brand name and description" do
    visit company_brand_path(company, brand)

    expect(page).to have_content(brand.name, wait: 10)
    expect(page).to have_content(brand.description, wait: 10)
  end

  scenario "displays brand code" do
    visit company_brand_path(company, brand)

    expect(page).to have_text(/#{Regexp.escape(brand.code)}/i, wait: 10)
  end

  scenario "has edit button linking to edit page" do
    visit company_brand_path(company, brand)

    edit_link = find("a[href*='/brands/#{brand.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "has back link to brands index" do
    visit company_brand_path(company, brand)

    back_link = find("a[href*='/companies/#{company.id}/brands']", match: :first)
    expect(back_link).to be_present
  end
end
