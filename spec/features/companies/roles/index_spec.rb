require "rails_helper"

RSpec.feature "Companies::Roles Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:role) { Seed::RoleService.create(company: company, name: "Seller#{SecureRandom.hex(3)}") }

  before do
    sign_in(owner)

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => [],
      "table_configs" => [],
      "categories" => [],
      "branches" => [],
      "departments" => [],
      "roles" => company.roles.reset.map { |r| JSON.parse(r.to_json) }
    )

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])",
      { user: JSON.parse(owner.to_json), companies: [ company_data ], enums: {}, employees: [] }.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "index page loads and displays roles table with paired tags" do
    visit company_roles_path(company)

    expect(page).to have_selector("table", wait: 10)

    expect(page).to have_selector("th", text: "Name")
    expect(page).to have_selector("th", text: "Notification Tag")

    expect(page).to have_content(role.name)
    expect(page).to have_content("All #{role.name}")
  end

  scenario "owner row renders without edit actions" do
    visit company_roles_path(company)
    expect(page).to have_selector("table", wait: 10)

    owner_row = find("a", text: /\Aowner\z/).find(:xpath, "./ancestor::tr")
    expect(owner_row).to have_no_selector("a[href*='/edit']")
  end

  scenario "role row links to show and edit pages" do
    visit company_roles_path(company)
    expect(page).to have_selector("table", wait: 10)

    expect(page).to have_selector("a[href*='/roles/#{role.id}']", minimum: 1)
    expect(page).to have_selector("a[href*='/roles/#{role.id}/edit']", minimum: 1)
  end
end
