require "rails_helper"

RSpec.feature "Companies::Suppliers New", type: :feature, js: true do
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
        supplier: {
          business_types: [
            { name: "Manufacturer", value: "manufacturer" },
            { name: "Distributor", value: "distributor" },
            { name: "Wholesaler", value: "wholesaler" },
            { name: "Service provider", value: "service_provider" }
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

  scenario "renders new supplier form with name and type fields" do
    visit new_company_supplier_path(company)

    expect(page).to have_selector('input[name="supplier[name]"]', wait: 10)
    expect(page).to have_selector('select[name="supplier[business_type]"]', wait: 10)
  end

  scenario "creates supplier and redirects to show page" do
    visit new_company_supplier_path(company)

    fill_in 'supplier[name]', with: 'New Test Supplier'
    select 'Manufacturer', from: 'supplier[business_type]'

    click_button "Save Supplier"

    expect(page).to have_content('New Test Supplier', wait: 10)

    supplier_record = Supplier.find_by(name: "New Test Supplier")
    expect(supplier_record).to be_present
    expect(page).to have_current_path(company_supplier_path(company, supplier_record), wait: 10)
  end

  scenario "creates supplier with email" do
    visit new_company_supplier_path(company)

    fill_in 'supplier[name]', with: 'Supplier With Email'
    fill_in 'supplier[email]', with: 'supplier@example.com'

    click_button "Save Supplier"

    expect(page).to have_content('Supplier With Email', wait: 10)

    supplier_record = Supplier.find_by(name: "Supplier With Email")
    expect(supplier_record).to be_present
    expect(supplier_record.email).to eq('supplier@example.com')
  end
end
