# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::EmployeeGroups Show", type: :feature, js: true do
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
    employee_group.update!(description: "The alpha team description", email: "team@example.com")
    sign_in(owner)
    seed_employee_group_client_cache!(company: company, user: owner)
  end

  scenario "displays the group details, manager, members and dynamic properties" do
    visit company_employee_group_path(company, employee_group)

    expect(page).to have_content("Alpha Team", wait: 10)
    expect(page).to have_content("The alpha team description")
    expect(page).to have_content("team@example.com")
    expect(page).to have_content("Downtown")
    expect(page).to have_content("Morgan Manager")
    expect(page).to have_content("Alex Member")
    expect(page).to have_content("Cost Center")
    expect(page).to have_content("HQ")
  end

  scenario "links managers and members to their employee pages" do
    visit company_employee_group_path(company, employee_group)

    expect(page).to have_link(manager.name, href: company_employee_path(company, manager), wait: 10)
    expect(page).to have_link(member.name, href: company_employee_path(company, member))
  end

  scenario "has edit and back links" do
    visit company_employee_group_path(company, employee_group)

    expect(page).to have_selector("a[href='#{edit_company_employee_group_path(company, employee_group)}']", wait: 10)
    expect(page).to have_selector("a[href='#{company_employee_groups_path(company)}']")
  end
end
