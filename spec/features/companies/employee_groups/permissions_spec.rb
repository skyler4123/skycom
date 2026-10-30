# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::EmployeeGroups Permissions", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }

  let!(:reader_role) { create(:role, company: company, name: "Reader", business_type: :support) }
  let!(:creator_role) { create(:role, company: company, name: "Creator", business_type: :support) }
  let!(:editor_role) { create(:role, company: company, name: "Editor", business_type: :management) }
  let!(:no_permission_role) { create(:role, company: company, name: "NoPermission", business_type: :support) }

  let!(:policy_read) { create_policy(resource: "EmployeeGroup", action: "read") }
  let!(:policy_create) { create_policy(resource: "EmployeeGroup", action: "create") }
  let!(:policy_update) { create_policy(resource: "EmployeeGroup", action: "update") }

  let!(:reader_read) { create_policy_appointment(role: reader_role, policy: policy_read, workflow_status: :active) }
  let!(:creator_read) { create_policy_appointment(role: creator_role, policy: policy_read, workflow_status: :active) }
  let!(:creator_create) { create_policy_appointment(role: creator_role, policy: policy_create, workflow_status: :active) }
  let!(:editor_read) { create_policy_appointment(role: editor_role, policy: policy_read, workflow_status: :active) }
  let!(:editor_update) { create_policy_appointment(role: editor_role, policy: policy_update, workflow_status: :active) }

  let!(:reader_user) { create(:user, :company_employee) }
  let!(:reader_employee) do
    create(:employee, company: company, branch: branch, user: reader_user).tap do |employee|
      create(:employee_role_appointment, company: company, employee: employee, role: reader_role)
    end
  end

  let!(:creator_user) { create(:user, :company_employee) }
  let!(:creator_employee) do
    create(:employee, company: company, branch: branch, user: creator_user).tap do |employee|
      create(:employee_role_appointment, company: company, employee: employee, role: creator_role)
    end
  end

  let!(:editor_user) { create(:user, :company_employee) }
  let!(:editor_employee) do
    create(:employee, company: company, branch: branch, user: editor_user).tap do |employee|
      create(:employee_role_appointment, company: company, employee: employee, role: editor_role)
    end
  end

  let!(:no_permission_user) { create(:user, :company_employee) }
  let!(:no_permission_employee) do
    create(:employee, company: company, branch: branch, user: no_permission_user).tap do |employee|
      create(:employee_role_appointment, company: company, employee: employee, role: no_permission_role)
    end
  end

  let!(:category) { create_employee_group_category!(company: company) }
  let!(:table_config) { create_employee_group_table_config!(company: company, category: category) }
  let!(:employee_group) do
    create_employee_group!(company: company, category: category, name: "Permission Team")
  end

  def create_policy(resource:, action:)
    Seed::PolicyService.create(
      company: company,
      branch: branch,
      name: "Can #{action} #{resource}",
      resource: resource,
      action: action,
      business_type: :operational,
      lifecycle_status: :active
    )
  end

  def create_policy_appointment(role:, policy:, workflow_status:)
    appointment = PolicyRoleAppointment.find_or_create_by!(
      company: company,
      policy: policy,
      role: role
    )
    appointment.update!(workflow_status: workflow_status)
    appointment
  end

  before do
    company.clear_permissions_cache
    [ reader_employee, creator_employee, editor_employee, no_permission_employee ].each(&:clear_permissions_cache)
  end

  scenario "reader can access the index and show pages" do
    sign_in(reader_user)
    seed_employee_group_client_cache!(company: company, user: reader_user)

    visit company_employee_groups_path(company)
    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Permission Team")

    visit company_employee_group_path(company, employee_group)
    expect(page).to have_content("Permission Team", wait: 10)
  end

  scenario "creator can access the new page" do
    sign_in(creator_user)
    seed_employee_group_client_cache!(company: company, user: creator_user)

    visit new_company_employee_group_path(company)

    expect(page).to have_selector('input[name="employee_group[name]"]', wait: 10)
  end

  scenario "editor can access the edit page" do
    sign_in(editor_user)
    seed_employee_group_client_cache!(company: company, user: editor_user)

    visit edit_company_employee_group_path(company, employee_group)

    expect(page).to have_field("employee_group[name]", with: "Permission Team", wait: 10)
  end

  scenario "employee without permission is blocked" do
    sign_in(no_permission_user)
    seed_employee_group_client_cache!(company: company, user: no_permission_user)

    visit company_employee_groups_path(company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
  end
end
