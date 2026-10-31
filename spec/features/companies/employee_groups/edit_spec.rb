# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::EmployeeGroups Edit", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company, name: "Downtown") }
  let(:manager) { create_employee!(company: company, branch: branch, name: "Morgan Manager") }
  let(:member) { create_employee!(company: company, branch: branch, name: "Alex Member") }

  let!(:category) do
    create_employee_group_category!(
      company: company,
      properties: { property_string_1: "Cost Center" }
    )
  end

  let!(:table_config) { create_employee_group_table_config!(company: company, category: category) }

  let!(:employee_group) do
    create_employee_group!(
      company: company,
      category: category,
      branch: branch,
      manager: manager,
      members: [ member ],
      name: "Alpha Team",
      properties: { property_string_1: "HQ" }
    )
  end

  before do
    employee_group.update!(description: "Original description", email: "alpha@example.com")
    sign_in(owner)
    seed_employee_group_client_cache!(company: company, user: owner)
  end

  scenario "renders the prefilled group, manager, member and dynamic property fields" do
    visit edit_company_employee_group_path(company, employee_group)

    expect(page).to have_field("employee_group[name]", with: "Alpha Team", wait: 10)
    expect(page).to have_field("employee_group[email]", with: "alpha@example.com")
    expect(page).to have_field("employee_group[description]", with: "Original description")
    expect(page).to have_select("employee_group[manager_id]", selected: manager.name)
    expect(find("input[name='employee_group[employee_ids][]'][value='#{manager.id}']")).to be_checked
    expect(find("input[name='employee_group[employee_ids][]'][value='#{member.id}']")).to be_checked
    expect(page).to have_field("employee_group[property_string_1]", with: "HQ")
  end

  scenario "updates the group, manager and members" do
    new_manager = create_employee!(company: company, branch: branch, name: "Taylor New Manager")
    new_member = create_employee!(company: company, branch: branch, name: "Jordan New Member")
    seed_employee_group_client_cache!(company: company, user: owner)

    visit edit_company_employee_group_path(company, employee_group)

    fill_in "employee_group[name]", with: "Updated Team"
    select new_manager.name, from: "employee_group[manager_id]"
    find("input[name='employee_group[employee_ids][]'][value='#{manager.id}']").uncheck
    find("input[name='employee_group[employee_ids][]'][value='#{member.id}']").uncheck
    find("input[name='employee_group[employee_ids][]'][value='#{new_member.id}']").check
    fill_in "employee_group[property_string_1]", with: "Remote"

    click_button "Save Changes"

    expect(page).to have_content("Employee group updated successfully", wait: 10)

    employee_group.reload
    expect(employee_group.name).to eq("Updated Team")
    expect(employee_group.manager).to eq(new_manager)
    expect(employee_group.employees).to include(new_manager, new_member)
    expect(employee_group.employees).not_to include(manager)
    expect(employee_group.employees).not_to include(member)
    expect(employee_group.property_string_1).to eq("Remote")
    expect(page).to have_current_path(company_employee_group_path(company, employee_group), wait: 10)
  end

  scenario "clears the manager and all members" do
    visit edit_company_employee_group_path(company, employee_group)

    select "No manager", from: "employee_group[manager_id]"
    find("input[name='employee_group[employee_ids][]'][value='#{manager.id}']").uncheck
    find("input[name='employee_group[employee_ids][]'][value='#{member.id}']").uncheck

    click_button "Save Changes"

    expect(page).to have_content("Employee group updated successfully", wait: 10)

    employee_group.reload
    expect(employee_group.manager).to be_nil
    expect(employee_group.employees).to be_empty
  end

  scenario "rejects a duplicate group name" do
    create_employee_group!(
      company: company,
      category: category,
      name: "Taken Team",
      properties: { property_string_1: "HQ" }
    )

    visit edit_company_employee_group_path(company, employee_group)

    fill_in "employee_group[name]", with: "Taken Team"
    click_button "Save Changes"

    expect(page).to have_content("Name has already been taken", wait: 10)

    employee_group.reload
    expect(employee_group.name).to eq("Alpha Team")
  end
end
