require "rails_helper"

RSpec.feature "Companies::Role Deletion", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:role) { Seed::RoleService.create(company: company, name: "Doomed#{SecureRandom.hex(3)}") }

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

  scenario "show page confirms destroy and lands on index with tag-removal flash" do
    visit company_role_path(company, role)
    expect(page).to have_content(role.name, wait: 10)

    accept_confirm do
      click_button "Delete Role"
    end

    expect(page).to have_current_path(company_roles_path(company), wait: 10)
    expect(page).to have_content("removed also", wait: 10)

    expect(Role.exists?(role.id)).to be(false)
    expect(NotificationTag.find_by(company: company, name: "All #{role.name}")).to be_nil
  end

  scenario "dismissing the confirm keeps the role" do
    visit company_role_path(company, role)
    expect(page).to have_content(role.name, wait: 10)

    dismiss_confirm do
      click_button "Delete Role"
    end

    expect(Role.exists?(role.id)).to be(true)
  end
end
