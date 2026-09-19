require "rails_helper"

RSpec.feature "Companies::Workflows Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

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

  before do
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

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])",
      { user: JSON.parse(owner.to_json), companies: [ company_data ], enums: {}, employees: [] }.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "shows workflow details with ordered steps" do
    visit company_workflow_path(company, workflow)

    expect(page).to have_content('Standard Purchase Process', wait: 10)
    expect(page).to have_content('Submit', wait: 10)
    expect(page).to have_content('Manager Approval', wait: 10)
    expect(page).to have_content('Buy', wait: 10)
    expect(page).to have_content('Complete', wait: 10)
    expect(page).to have_content('Default', wait: 10)
    expect(page).to have_content('purchase process', wait: 10)
  end

  scenario "edit link points to the edit page" do
    visit company_workflow_path(company, workflow)
    expect(page).to have_content('Standard Purchase Process', wait: 10)

    expect(page).to have_link('Edit Workflow', href: edit_company_workflow_path(company, workflow), wait: 10)
  end
end
