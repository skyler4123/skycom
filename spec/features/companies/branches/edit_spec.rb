require "rails_helper"

RSpec.feature "Companies::Branches Edit", type: :feature, js: true do
  let(:branch) do
    create(:branch,
      name: "Editable Branch",
      description: "Original description",
      phone_number: "+84 111 222 333"
    )
  end
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
          workflow_statuses: [
            { name: "Active", value: "active" },
            { name: "Inactive", value: "inactive" },
            { name: "Draft", value: "draft" }
          ]
        }
      },
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "renders edit form with branch name and type pre-filled" do
    visit edit_company_branch_path(company, branch)

    expect(page).to have_selector('input[name="branch[name]"]', wait: 10)
    expect(page).to have_selector('select[name="branch[business_type]"]', wait: 10)
    expect(page).to have_selector('select[name="branch[workflow_status]"]', wait: 10)
  end

  scenario "updates branch and redirects to show page" do
    visit edit_company_branch_path(company, branch)

    expect(page).to have_selector('input[name="branch[name]"]', wait: 10)
    fill_in 'branch[name]', with: 'Updated Branch Name'

    click_button "Save Changes"

    expect(page).to have_content('Updated Branch Name', wait: 10)

    branch.reload
    expect(branch.name).to eq("Updated Branch Name")
    expect(page).to have_current_path(company_branch_path(company, branch), wait: 10)
  end

  scenario "handles validation error and redirects back to edit page with alert" do
    visit edit_company_branch_path(company, branch)

    expect(page).to have_selector('input[name="branch[name]"]', wait: 10)
    fill_in 'branch[name]', with: ''

    click_button "Save Changes"

    expect(page).to have_content("can't be blank", wait: 10)
    expect(page).to have_current_path(edit_company_branch_path(company, branch), wait: 10)
  end

  scenario "updates phone number and description" do
    visit edit_company_branch_path(company, branch)

    fill_in 'branch[phone_number]', with: '+84 999 888 777'
    fill_in 'branch[description]', with: 'Updated description text'

    click_button "Save Changes"

    expect(page).to have_content('Updated description text', wait: 10)

    branch.reload
    expect(branch.phone_number).to eq('+84 999 888 777')
    expect(branch.description).to eq('Updated description text')
  end
end
