require "rails_helper"

RSpec.feature "Companies::Workflows Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:purchase_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "purchases") }

  let!(:workflow) do
    Seed::WorkflowService.create(
      company: company, category: purchase_category,
      name: "Standard Purchase Process", process_type: :purchase_process
    ).tap do |workflow|
      [
        { name: "Submit", position: 1 },
        { name: "Manager Approval", position: 2 },
        { name: "Buy", position: 3 },
        { name: "Complete", position: 4 }
      ].each { |attrs| Seed::WorkflowStepService.create(company: company, workflow: workflow, **attrs) }
    end
  end

  before do
    sign_in(owner)

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => [],
      "table_configs" => [],
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

  scenario "index page loads and displays workflows table" do
    visit company_workflows_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Name')
    expect(page).to have_selector('th', text: 'Code')
    expect(page).to have_selector('th', text: 'Process')
    expect(page).to have_selector('th', text: 'Category')
    expect(page).to have_selector('th', text: 'Steps')

    expect(page).to have_content('Standard Purchase Process')
    expect(page).to have_content('4')
  end

  scenario "workflow renders its bound category" do
    visit company_workflows_path(company)
    expect(page).to have_selector('table', wait: 10)

    row = find('tr', text: 'Standard Purchase Process')
    expect(row).to have_content(purchase_category.name)
  end

  scenario "edit button links to edit page for workflow" do
    visit company_workflows_path(company)
    expect(page).to have_selector('table', wait: 10)

    edit_link = find("a[href*='/workflows/#{workflow.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end
end
