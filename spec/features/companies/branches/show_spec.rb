require "rails_helper"

RSpec.feature "Companies::Branches Show", type: :feature, js: true do
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
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "displays branch name and description" do
    visit company_branch_path(company, branch)

    expect(page).to have_content(branch.name, wait: 10)
    expect(page).to have_content(branch.description, wait: 10)
  end

  scenario "displays branch code" do
    visit company_branch_path(company, branch)

    expect(page).to have_text(/#{Regexp.escape(branch.code)}/i, wait: 10)
  end

  scenario "displays branch phone and email" do
    visit company_branch_path(company, branch)

    expect(page).to have_content(branch.phone_number, wait: 10)
    expect(page).to have_content(branch.email, wait: 10)
  end

  scenario "has edit button linking to edit page" do
    visit company_branch_path(company, branch)

    edit_link = find("a[href*='/branches/#{branch.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "has back link to branches index" do
    visit company_branch_path(company, branch)

    back_link = find("a[href*='/companies/#{company.id}/branches']", match: :first)
    expect(back_link).to be_present
  end
end
