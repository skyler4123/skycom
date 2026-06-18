require "rails_helper"

RSpec.feature "Companies::Invoices Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:customer) do
    Seed::CustomerService.create(company: company, name: "Test Customer")
  end
  let(:order) do
    Seed::OrderService.create(company: company, customer: customer, name: "Test Order for Invoice")
  end

  let!(:default_category) do
    Seed::CategoryService.find_or_create_for(company: company, resource_name: "invoices")
  end

  let!(:invoice) do
    Seed::InvoiceService.create(
      order: order,
      name: "Test Invoice 1",
      business_type: "sales",
      workflow_status: "draft"
    )
  end

  let!(:invoice2) do
    Seed::InvoiceService.create(
      order: order,
      name: "Test Invoice 2",
      business_type: "service",
      workflow_status: "pending"
    )
  end

  let!(:default_table_config) do
    TableConfig.create!(
      company: company,
      category: default_category,
      property_mapping: default_category.default_property_mapping,
      resource_name: "invoices",
      columns_metadata: [
        { "key" => "name", "label" => "Invoice Name", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "code", "label" => "Code", "visible" => true, "sortable" => true, "align" => "left", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} },
        { "key" => "workflow_status", "label" => "Status", "visible" => true, "sortable" => true, "align" => "center", "pinned" => nil, "width" => nil, "roles" => [], "is_virtual" => false, "render_config" => {} }
      ]
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
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "index page loads and displays invoices table" do
    visit company_invoices_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Invoice Name')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content(invoice.name)
  end

  scenario "edit button links to edit page for invoice" do
    visit company_invoices_path(company)
    expect(page).to have_selector('table', wait: 10)

    edit_link = find("a[href*='/invoices/#{invoice.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "name link goes to show page" do
    visit company_invoices_path(company)
    expect(page).to have_selector('table', wait: 10)

    name_link = find("a[href*='/invoices/#{invoice.id}']", match: :first)
    expect(name_link).to be_present
  end

  scenario "displays invoice workflow status as badge" do
    visit company_invoices_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('span.rounded-full', wait: 10)
  end
end
