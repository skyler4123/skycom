require "rails_helper"

RSpec.feature "Companies::Companies Edit", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:owner) { company.user }

  let!(:no_perm_role) { create(:role, company: company, name: "NoPerm", business_type: :support) }
  let!(:no_perm_user) { create(:user, :company_employee) }
  let!(:no_perm_employee) do
    emp = create(:employee, company: company, branch: branch, user: no_perm_user)
    create(:role_appointment, company: company, appoint_to: emp, role: no_perm_role)
    emp
  end

  before do
    company.clear_permissions_cache
  end

  scenario "owner can visit edit company page" do
    sign_in(owner)
    visit edit_company_company_path(company, company)

    expect(page).to have_selector('input[name="company[name]"]', wait: 10)
    expect(page).to have_selector('select[name="company[timezone]"]', wait: 5)
    expect(page).to have_selector('select[name="company[currency]"]', wait: 5)
  end

  scenario "owner can update company name" do
    sign_in(owner)
    visit edit_company_company_path(company, company)

    expect(page).to have_selector('input[name="company[name]"]', wait: 10)
    fill_in "company[name]", with: "Updated Company Name"

    click_button "Save Changes"

    expect(page).to have_content("Company updated successfully", wait: 10)
    expect(page).to have_current_path(company_dashboards_path(company))

    company.reload
    expect(company.name).to eq("Updated Company Name")
  end

  scenario "owner sees validation error when submitting empty name" do
    sign_in(owner)
    visit edit_company_company_path(company, company)

    expect(page).to have_selector('input[name="company[name]"]', wait: 10)
    fill_in "company[name]", with: ""

    click_button "Save Changes"

    expect(page).to have_content("Name can", wait: 10)
    expect(page).to have_current_path(edit_company_company_path(company, company))
  end

  scenario "employee without company update permission cannot access edit page" do
    company.clear_permissions_cache
    no_perm_employee.clear_permissions_cache
    no_perm_employee.reload

    expect(no_perm_employee.can?(:update, Company)).to be_falsey

    sign_in(no_perm_user)
    visit edit_company_company_path(company, company)

    expect(page).to have_content("You are not authorized to perform this action.", wait: 10)
  end

  scenario "employee without permission cannot? returns false for company update" do
    company.clear_permissions_cache
    no_perm_employee.clear_permissions_cache
    no_perm_employee.reload

    expect(no_perm_employee.can?(:update, Company)).to be_falsey
  end

  scenario "owner can? returns true for company update" do
    owner_employee = company.employees.find_by(user: owner)
    expect(owner_employee.can?(:update, Company)).to be_truthy
  end
end
