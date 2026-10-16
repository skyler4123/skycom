# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Dynamic sidebar editor", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }
  let!(:dynamic_setting) do
    CompanySetting.create!(
      company: company, name: "Company Quick Links", business_type: :sidebar_groups,
      workflow_status: :active,
      sidebar_groups: []
    )
  end

  before do
    sign_in(owner)
    seed_client_cache!
    page.execute_script("localStorage.setItem('open-cache-sidebar', 'sidebar')")
  end

  def seed_client_cache!(cache_user = owner)
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "company_settings" => company.company_settings.reset.map { |s| JSON.parse(s.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    payload = {
      user: JSON.parse(cache_user.to_json),
      companies: [ company_data ],
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "owner creates a custom group with an item and it appears in the sidebar" do
    visit company_company_settings_path(company)

    expect(page).to have_content("Company Quick Links", wait: 10)

    click_button "Add Group", match: :first
    fill_in "Group name", match: :first, with: "My Links"

    click_button "Add Sidebar Item", match: :first
    fill_in "Item name", match: :first, with: "Pending Orders"
    fill_in "Item URL", match: :first, with: "/pending?workflow_status=pending"

    click_button "Save Changes", match: :first

    expect(page).to have_content("Company setting updated successfully", wait: 10)
    within("aside", visible: :all) do
      expect(page).to have_selector("details[data-sidebar-group^='custom_']", visible: :all, wait: 10)
      expect(page).to have_link("Pending Orders", href: "/pending?workflow_status=pending", visible: :all, wait: 10)
    end
    expect(dynamic_setting.reload.sidebar_groups.first["name"]).to eq("My Links")
  end

  scenario "non-owner with update grant cannot update Quick Links" do
    manager_role = Seed::RoleService.create(company: company, name: "SettingsManager#{SecureRandom.hex(3)}")
    manager_user = create(:user)
    manager_employee = create(:employee, company: company, branch: branch, user: manager_user)
    create(:employee_role_appointment, company: company, employee: manager_employee, role: manager_role)

    %w[read update].each do |action|
      policy = Seed::PolicyService.create(
        company: company, name: "Can #{action} CompanySetting",
        resource: "CompanySetting", action: action,
        business_type: :operational, lifecycle_status: :active
      )
      PolicyRoleAppointment.create!(company: company, policy: policy,
        role: manager_role, workflow_status: :active)
    end
    manager_employee.clear_permissions_cache
    company.clear_permissions_cache
    manager_employee.reload

    sign_in(manager_user)
    seed_client_cache!(manager_user)
    page.execute_script("localStorage.setItem('open-cache-sidebar', 'sidebar')")

    visit company_company_settings_path(company)

    expect(page).to have_content("Company Quick Links", wait: 10)

    click_button "Add Group", match: :first
    fill_in "Group name", match: :first, with: "Hacked Links"

    click_button "Add Sidebar Item", match: :first
    fill_in "Item name", match: :first, with: "Hacked Item"
    fill_in "Item URL", match: :first, with: "/hacked"

    click_button "Save Changes", match: :first

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
    expect(dynamic_setting.reload.sidebar_groups).to eq([])
  end
end
