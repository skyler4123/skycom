require "rails_helper"

RSpec.feature "Companies::Suppliers Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:supplier) do
    create(:supplier, company: company, name: "Test Supplier", description: "A test supplier description")
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
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "displays supplier name and description" do
    visit company_supplier_path(company, supplier)

    expect(page).to have_content(supplier.name, wait: 10)
    expect(page).to have_content(supplier.description, wait: 10)
  end

  scenario "displays supplier code" do
    visit company_supplier_path(company, supplier)

    expect(page).to have_text(/#{Regexp.escape(supplier.code)}/i, wait: 10)
  end

  scenario "has edit button linking to edit page" do
    visit company_supplier_path(company, supplier)

    edit_link = find("a[href*='/suppliers/#{supplier.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "has back link to suppliers index" do
    visit company_supplier_path(company, supplier)

    back_link = find("a[href*='/companies/#{company.id}/suppliers']", match: :first)
    expect(back_link).to be_present
  end
end
