require "rails_helper"

RSpec.feature "Companies::Branches New", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
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
        branch: {
          business_types: [
            { name: "Storefront", value: "storefront" },
            { name: "Warehouse", value: "warehouse" },
            { name: "Headquarters", value: "headquarters" }
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

  scenario "renders new branch form with name and type fields" do
    visit new_company_branch_path(company)

    expect(page).to have_selector('input[name="branch[name]"]', wait: 10)
    expect(page).to have_selector('select[name="branch[business_type]"]', wait: 10)
  end

  scenario "creates branch and redirects to show page" do
    visit new_company_branch_path(company)

    fill_in 'branch[name]', with: 'New Test Branch'
    select 'Warehouse', from: 'branch[business_type]'

    click_button "Save Branch"

    expect(page).to have_content('New Test Branch', wait: 10)

    branch_record = Branch.find_by(name: "New Test Branch")
    expect(branch_record).to be_present
    expect(page).to have_current_path(company_branch_path(company, branch_record), wait: 10)
  end

  scenario "creates branch with phone and email" do
    visit new_company_branch_path(company)

    fill_in 'branch[name]', with: 'Branch With Contact'
    fill_in 'branch[phone_number]', with: '+84 123 456 789'
    fill_in 'branch[email]', with: 'branch@example.com'

    click_button "Save Branch"

    expect(page).to have_content('Branch With Contact', wait: 10)

    branch_record = Branch.find_by(name: "Branch With Contact")
    expect(branch_record).to be_present
    expect(branch_record.phone_number).to eq('+84 123 456 789')
    expect(branch_record.email).to eq('branch@example.com')
  end
end
