require "rails_helper"

RSpec.feature "Companies::Suppliers Edit", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:supplier) do
    create(:supplier,
      company: company,
      name: "Editable Supplier",
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
        supplier: {
          business_types: [
            { name: "Manufacturer", value: "manufacturer" },
            { name: "Distributor", value: "distributor" },
            { name: "Wholesaler", value: "wholesaler" },
            { name: "Service provider", value: "service_provider" }
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

  scenario "renders edit form with supplier name and type fields" do
    visit edit_company_supplier_path(company, supplier)

    expect(page).to have_selector('input[name="supplier[name]"]', wait: 10)
    expect(page).to have_selector('select[name="supplier[business_type]"]', wait: 10)
    expect(page).to have_selector('select[name="supplier[workflow_status]"]', wait: 10)
  end

  scenario "updates supplier and redirects to show page" do
    visit edit_company_supplier_path(company, supplier)

    expect(page).to have_selector('input[name="supplier[name]"]', wait: 10)
    fill_in 'supplier[name]', with: 'Updated Supplier Name'

    click_button "Save Changes"

    expect(page).to have_current_path(company_supplier_path(company, supplier), wait: 10)
    expect(page).to have_content('Updated Supplier Name', wait: 10)

    supplier.reload
    expect(supplier.name).to eq("Updated Supplier Name")
  end

  scenario "handles validation error and redirects back to edit page with alert" do
    visit edit_company_supplier_path(company, supplier)

    expect(page).to have_selector('input[name="supplier[name]"]', wait: 10)
    fill_in 'supplier[name]', with: ''

    click_button "Save Changes"

    expect(page).to have_current_path(edit_company_supplier_path(company, supplier), wait: 10)
    expect(page).to have_content("can't be blank", wait: 10)
  end

  scenario "updates description" do
    visit edit_company_supplier_path(company, supplier)

    fill_in 'supplier[description]', with: 'Updated description text'

    click_button "Save Changes"

    expect(page).to have_current_path(company_supplier_path(company, supplier), wait: 10)
    expect(page).to have_content('Updated description text', wait: 10)

    supplier.reload
    expect(supplier.description).to eq('Updated description text')
  end
end
