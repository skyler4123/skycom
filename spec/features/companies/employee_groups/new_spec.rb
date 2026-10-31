# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::EmployeeGroups New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company, name: "Downtown") }
  let!(:manager) { create_employee!(company: company, branch: branch, name: "Morgan Manager") }
  let!(:member) { create_employee!(company: company, branch: branch, name: "Alex Member") }

  let!(:category) do
    create_employee_group_category!(
      company: company,
      properties: { property_string_1: "Cost Center" }
    )
  end

  let!(:table_config) { create_employee_group_table_config!(company: company, category: category) }

  before do
    sign_in(owner)
    seed_employee_group_client_cache!(company: company, user: owner)
  end

  def visit_new_form
    visit new_company_employee_group_path(company, category_id: category.id)
    expect(page).to have_selector('input[name="employee_group[name]"]', wait: 10)
  end

  def fill_core_fields(name:)
    fill_in "employee_group[name]", with: name
    fill_in "employee_group[email]", with: "team@example.com"
    fill_in "employee_group[description]", with: "A team description"
    fill_in "employee_group[property_string_1]", with: "HQ"
  end

  scenario "renders the category, manager, branch, employee and dynamic property fields" do
    visit_new_form

    expect(page).to have_selector('select[name="employee_group[category_id]"]')
    expect(page).to have_selector('select[name="employee_group[branch_id]"]')
    expect(page).to have_selector('select[name="employee_group[manager_id]"]')
    expect(page).to have_selector("input[name='employee_group[employee_ids][]'][value='#{manager.id}']")
    expect(page).to have_selector("input[name='employee_group[employee_ids][]'][value='#{member.id}']")
    expect(page).to have_selector('input[name="employee_group[property_string_1]"]')
  end

  scenario "creates a group with a manager and employees, auto-enrolling the manager" do
    visit_new_form

    fill_core_fields(name: "Alpha Team")
    select branch.name, from: "employee_group[branch_id]"
    select manager.name, from: "employee_group[manager_id]"
    find("input[name='employee_group[employee_ids][]'][value='#{member.id}']").check

    click_button "Save Employee Group"

    expect(page).to have_content("Employee group created successfully", wait: 10)
    expect(page).to have_content("Alpha Team")

    group = EmployeeGroup.find_by!(name: "Alpha Team")
    expect(page).to have_current_path(company_employee_group_path(company, group), wait: 10)
    expect(group.manager).to eq(manager)
    expect(group.branch).to eq(branch)
    expect(group.employees).to include(manager, member)
    expect(group.property_string_1).to eq("HQ")
  end

  scenario "auto-enrolls the manager even when the manager checkbox is unchecked" do
    visit_new_form

    fill_core_fields(name: "Beta Team")
    select manager.name, from: "employee_group[manager_id]"

    manager_checkbox = find("input[name='employee_group[employee_ids][]'][value='#{manager.id}']")
    manager_checkbox.uncheck

    click_button "Save Employee Group"

    expect(page).to have_content("Employee group created successfully", wait: 10)

    group = EmployeeGroup.find_by!(name: "Beta Team")
    expect(group.employees).to include(manager)
  end

  scenario "creates a group without a manager" do
    visit_new_form

    fill_core_fields(name: "No Manager Team")
    find("input[name='employee_group[employee_ids][]'][value='#{member.id}']").check

    click_button "Save Employee Group"

    expect(page).to have_content("Employee group created successfully", wait: 10)

    group = EmployeeGroup.find_by!(name: "No Manager Team")
    expect(group.manager).to be_nil
    expect(group.employees).to include(member)
  end

  scenario "rejects a duplicate group name" do
    create_employee_group!(
      company: company,
      category: category,
      name: "Duplicate Team",
      manager: manager,
      properties: { property_string_1: "HQ" }
    )

    visit_new_form
    fill_core_fields(name: "Duplicate Team")

    click_button "Save Employee Group"

    expect(page).to have_content("Name has already been taken", wait: 10)
    expect(page).to have_current_path(new_company_employee_group_path(company), wait: 10)
    expect(EmployeeGroup.where(company: company, name: "Duplicate Team").count).to eq(1)
  end
end
