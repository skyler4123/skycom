require "rails_helper"

RSpec.feature "Companies::Workflows New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

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

  scenario "renders new workflow form with base fields" do
    visit new_company_workflow_path(company)

    expect(page).to have_selector('input[name="workflow[name]"]', wait: 10)
    expect(page).to have_selector('select[name="workflow[process_type]"]', wait: 10)
    expect(page).to have_selector('input[name="workflow[is_default]"]', wait: 10)
    expect(page).to have_selector('textarea[name="workflow[description]"]', wait: 10)
  end

  scenario "add step renders an indexed step row" do
    visit new_company_workflow_path(company)
    expect(page).to have_selector('input[name="workflow[name]"]', wait: 10)

    click_button "Add Step"

    expect(page).to have_selector('input[name="workflow[workflow_steps_attributes][0][name]"]', wait: 10)

    click_button "Add Step"

    expect(page).to have_selector('input[name="workflow[workflow_steps_attributes][1][name]"]', wait: 10)
  end

  scenario "creates workflow with steps and redirects to show page" do
    visit new_company_workflow_path(company)
    expect(page).to have_selector('input[name="workflow[name]"]', wait: 10)

    fill_in 'workflow[name]', with: 'Expedited Purchase'
    click_button "Add Step"
    fill_in 'workflow[workflow_steps_attributes][0][name]', with: 'Submit'
    click_button "Add Step"
    fill_in 'workflow[workflow_steps_attributes][1][name]', with: 'Approve'

    click_button "Save Workflow"

    expect(page).to have_current_path(/\/workflows\/[0-9a-f-]+$/, wait: 10)

    workflow_record = Workflow.find_by(name: 'Expedited Purchase')
    expect(workflow_record).to be_present
    expect(page).to have_content('Expedited Purchase', wait: 10)

    expect(workflow_record.workflow_steps.order(:position).map(&:name)).to eq([ 'Submit', 'Approve' ])
  end
end
