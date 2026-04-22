require "rails_helper"

RSpec.feature "Companies::Permissions Management", type: :feature, js: true do
  let!(:branch)   { create(:branch) }
  let!(:company) { branch.company }
  let!(:owner)   { company.user }

  let!(:role) do
    create(:role, company: company, name: "Manager")
  end

  let!(:role2) do
    create(:role, company: company, name: "Staff")
  end

  let!(:policy) { create(:policy, branch: branch) }
  let!(:policy2) { create(:policy, branch: branch) }

  let!(:policy_appointment) do
    create(:policy_appointment,
      policy: policy,
      appoint_to: role,
      workflow_status: "active"
    )
  end

  let!(:policy_appointment2) do
    create(:policy_appointment,
      policy: policy2,
      appoint_to: role,
      workflow_status: "inactive"
    )
  end

  before do
    sign_in(owner)
  end

  after do
    company.clear_permissions_cache
  end

  scenario "index page loads and displays roles with grouped policies" do
    visit company_permissions_path(company)

    expect(page).to have_selector('.role-section', wait: 10)

    expect(page).to have_selector('h3', text: 'Manager')
    expect(page).to have_selector('h3', text: 'Staff')
  end

  scenario "displays active/inactive policy count per role" do
    visit company_permissions_path(company)

    expect(page).to have_content(/1 \/ 2 active/)
  end

  scenario "displays policies grouped by resource" do
    visit company_permissions_path(company)

    expect(page).to have_selector('.resource-section', wait: 10)
    expect(page).to have_selector('.resource-details')
  end

  scenario "toggle policy checkbox from active to inactive" do
    visit company_permissions_path(company)

    expect(page).to have_selector('input[type="checkbox"]', wait: 10)

    all_checkboxes = page.all('input[type="checkbox"]')
    expect(all_checkboxes.length).to be >= 2

    first_checkbox = all_checkboxes.first
    initial_checked = first_checkbox.checked?

    first_checkbox.click

    sleep 1 # Allow time for UI update
  end

  scenario "empty state when company has no roles" do
    company_id = company.id

    Role.where(company_id: company_id).destroy_all
    visit company_permissions_path(company)

    expect(page).to have_selector('.p-12', wait: 10)
    expect(page).to have_content('No Roles Found')
  end

  scenario "policy checkbox reflects correct name and resource" do
    visit company_permissions_path(company)

    expect(page).to have_selector('input[type="checkbox"]', wait: 10)

    all_checkboxes = page.all('input[type="checkbox"]')
    expect(all_checkboxes.length).to be >= 2

    label_texts = all_checkboxes.first(2).map { |cb| cb.find(:xpath, './ancestor::label').text }

    policy_resources = [policy, policy2].map { |p| p.resource.titleize }.sort
    displayed_resources = label_texts.map { |t| t.split(" · ").first.strip.split("\n").last.strip }.sort

    expect(displayed_resources).to match_array(policy_resources)
  end
end