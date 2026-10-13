require "rails_helper"

RSpec.feature "Companies::Roles Owner Gating", type: :feature, js: true do
  let(:company) { create(:company) }
  let!(:role) { Seed::RoleService.create(company: company, name: "Staff#{SecureRandom.hex(3)}") }
  let!(:branch) { create(:branch, company: company) }
  let!(:staff_user) { create(:user, :company_employee) }
  let!(:staff_employee) { create(:employee, company: company, branch: branch, user: staff_user) }

  def seed_cache(user, employees)
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
      { user: JSON.parse(user.to_json), companies: [ company_data ], enums: {}, employees: employees }.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "non-owner visiting the index is bounced home with an alert" do
    sign_in(staff_user)
    seed_cache(staff_user, [ JSON.parse(staff_employee.to_json) ])

    visit company_roles_path(company)

    expect(page).to have_current_path(root_path, wait: 10)
    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
  end

  scenario "non-owner visiting the show page is bounced home with an alert" do
    sign_in(staff_user)
    seed_cache(staff_user, [ JSON.parse(staff_employee.to_json) ])

    visit company_role_path(company, role)

    expect(page).to have_current_path(root_path, wait: 10)
    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
  end
end
