require "rails_helper"

RSpec.feature "Companies::Purchases Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  # rails_helper disables company init (Company.skip_init) — seed explicitly.
  let!(:workflow) do
    Seed::WorkflowService.create(
      company: company, name: "Standard Purchase Process",
      process_type: :purchase_process, is_default: true
    ).tap do |workflow|
      [
        { name: "Submit", position: 1 },
        { name: "Manager Approval", position: 2 },
        { name: "Buy", position: 3 },
        { name: "Complete", position: 4 }
      ].each { |attrs| Seed::WorkflowStepService.create(company: company, workflow: workflow, **attrs) }
    end
  end

  let!(:default_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "purchases") }
  let!(:purchase) { create(:purchase, company: company, name: "Pens restock") }

  let!(:default_table_config) do
    default_category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(
      company: company,
      category: default_category,
      property_mapping: default_category.default_property_mapping,
      resource_name: "purchases",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true, "align" => "left", "width" => nil },
        { "key" => "code", "name" => "Code", "visible" => true, "align" => "left", "width" => nil },
        { "key" => "workflow_status", "name" => "Status", "visible" => true, "align" => "center", "width" => nil },
        { "key" => "needed_by", "name" => "Needed By", "visible" => true, "align" => "center", "width" => nil }
      ] }
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

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])",
      { user: JSON.parse(owner.to_json), companies: [ company_data ], enums: {}, employees: [] }.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "index page loads and displays purchases table" do
    visit company_purchases_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Name')
    expect(page).to have_selector('th', text: 'Code')
    expect(page).to have_selector('th', text: 'Status')
    expect(page).to have_selector('th', text: 'Needed By')

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content('Pens restock')
  end

  scenario "edit button links to edit page for purchase" do
    visit company_purchases_path(company)
    expect(page).to have_selector('table', wait: 10)

    edit_link = find("a[href*='/purchases/#{purchase.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "workflow status renders as badge" do
    visit company_purchases_path(company)
    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('span.rounded-full', wait: 10)
  end

  scenario "filter by category updates URL and filters table" do
    category = Seed::CategoryService.create(company: company, name: "Test Purchase Category", resource_name: "purchases")
    purchase.update!(category: category, property_mapping: category.default_property_mapping)
    visit company_purchases_path(company)
    expect(page).to have_selector('table', wait: 10)

    select(category.name, from: 'category_id')
    click_button "Search"

    expect(page).to have_current_path(/category_id=#{category.id}/)
    expect(page).to have_selector('tbody tr', wait: 10)
  end
end
