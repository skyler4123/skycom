# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::EmployeeGroups Index", type: :feature, js: true do
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

  let!(:table_config) do
    create_employee_group_table_config!(
      company: company,
      category: category,
      extra_columns: [
        { "key" => "property_string_1", "name" => "Cost Center", "visible" => true, "align" => "left", "width" => nil }
      ]
    )
  end

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
    sign_in(owner)
    seed_employee_group_client_cache!(company: company, user: owner)
  end

  scenario "displays employee groups with manager, member count, branch and dynamic columns" do
    visit company_employee_groups_path(company)

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_selector("th", text: "Name")
    expect(page).to have_selector("th", text: "Manager")
    expect(page).to have_selector("th", text: "Members")
    expect(page).to have_selector("th", text: "Cost Center")

    within("tbody tr", text: "Alpha Team") do
      expect(page).to have_content("Morgan Manager")
      expect(page).to have_content("2")
      expect(page).to have_content("Downtown")
      expect(page).to have_content("HQ")
    end
  end

  scenario "filters the table by category" do
    other_category = Seed::CategoryService.create(
      company: company,
      name: "Field Teams",
      resource_name: "employee_groups",
      properties: {}
    )
    create_employee_group_table_config!(company: company, category: other_category)
    create_employee_group!(company: company, category: other_category, name: "Field Team")
    seed_employee_group_client_cache!(company: company, user: owner)

    visit company_employee_groups_path(company, category_id: other_category.id)

    expect(page).to have_selector("tbody tr", wait: 10)
    expect(page).to have_content("Field Team")
    expect(page).not_to have_content("Alpha Team")
  end

  scenario "shows the add and edit links" do
    visit company_employee_groups_path(company)

    expect(page).to have_selector("a[href='#{new_company_employee_group_path(company)}']", wait: 10)
    expect(page).to have_selector("a[href='#{edit_company_employee_group_path(company, employee_group)}']")
  end

  scenario "renders the dynamic search input from the table config" do
    visit company_employee_groups_path(company)

    expect(page).to have_field("q", wait: 10)
  end
end
