require "rails_helper"

RSpec.feature "Companies::Workflows Edit", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:default_workflow) do
    Seed::WorkflowService.create(
      company: company, name: "Standard Purchase Process",
      process_type: :purchase_process, is_default: true
    ).tap do |workflow|
      [
        { name: "Submit", position: 1 },
        { name: "Manager Approval", position: 2 }
      ].each { |attrs| Seed::WorkflowStepService.create(company: company, workflow: workflow, **attrs) }
    end
  end

  let!(:workflow) do
    Seed::WorkflowService.create(
      company: company, name: "Custom Purchase Process",
      process_type: :purchase_process
    ).tap do |workflow|
      Seed::WorkflowStepService.create(company: company, workflow: workflow, name: "Submit", position: 1)
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

  scenario "renders prefilled edit form with existing steps" do
    visit edit_company_workflow_path(company, workflow)

    expect(page).to have_selector('input[name="workflow[name]"]', wait: 10)
    expect(find('input[name="workflow[name]"]').value).to eq('Custom Purchase Process')
    expect(page).to have_selector('input[name="workflow[workflow_steps_attributes][0][name]"]', wait: 10)
    expect(find('input[name="workflow[workflow_steps_attributes][0][name]"]').value).to eq('Submit')
  end

  scenario "renames workflow and step, appends a new step" do
    visit edit_company_workflow_path(company, workflow)
    expect(page).to have_selector('input[name="workflow[name]"]', wait: 10)

    fill_in 'workflow[name]', with: 'Custom Purchase Process v2'
    fill_in 'workflow[workflow_steps_attributes][0][name]', with: 'Submit Request'
    click_button "Add Step"
    fill_in 'workflow[workflow_steps_attributes][1][name]', with: 'Approve'
    click_button "Save Changes"

    expect(page).to have_current_path(company_workflow_path(company, workflow), wait: 10)
    expect(page).to have_content('Custom Purchase Process v2', wait: 10)

    expect(workflow.reload.name).to eq('Custom Purchase Process v2')
    expect(workflow.workflow_steps.order(:position).map(&:name)).to eq([ 'Submit Request', 'Approve' ])
  end

  scenario "making a workflow default demotes the previous default" do
    visit edit_company_workflow_path(company, workflow)
    expect(page).to have_selector('input[name="workflow[name]"]', wait: 10)

    find('input[name="workflow[is_default]"]').check
    click_button "Save Changes"

    expect(page).to have_current_path(company_workflow_path(company, workflow), wait: 10)

    expect(workflow.reload.is_default).to be true
    expect(default_workflow.reload.is_default).to be false
  end
end
