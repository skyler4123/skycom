# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Employee Info", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company) }
  let(:manager) { create(:employee, company: company, branch: branch, name: "Morgan Manager") }
  let!(:employee) do
    company.employees.find_by(user: user).tap do |record|
      record.update!(branch: branch, expiration_date: Date.new(2026, 11, 30))
    end
  end
  let!(:employee_group) { create(:employee_group, company: company, branch: branch, manager: manager, name: "Clinical Team") }
  let!(:appointment) do
    create(:employee_employee_group_appointment, company: company, employee: employee, employee_group: employee_group)
  end

  scenario "shows employee profile details" do
    sign_in(user)
    visit mobile_company_employee_path(company)

    expect(page).to have_content("Employee")
    expect(page).to have_content(employee.name)
    expect(page).to have_content(employee.email)
    expect(page).to have_content(company.name)
    expect(page).to have_content(branch.name)
    expect(page).to have_content("Account & Contact")
    expect(page).to have_content("Organization & Assignment")
    expect(page).to have_content("Work & Attendance")
    expect(page).to have_content("Morgan Manager")
    expect(page).to have_content("30 November 2026")
    expect(page).not_to have_content("Sample")
  end

  scenario "shows every group manager" do
    second_manager = create(:employee, company: company, branch: branch, name: "Taylor Manager")
    second_group = create(:employee_group, company: company, branch: branch, manager: second_manager, name: "Surgical Team")
    create(
      :employee_employee_group_appointment,
      company: company,
      employee: employee,
      employee_group: second_group
    )

    sign_in(user)
    visit mobile_company_employee_path(company)

    expect(page).to have_content("Morgan Manager")
    expect(page).to have_content("Taylor Manager")
  end

  scenario "does not render a working mobile profile editor" do
    sign_in(user)
    visit mobile_company_employee_path(company)

    expect(page).to have_button("Edit Profile Details", disabled: true)
    expect(page).to have_content("Available on desktop")
  end

  scenario "has a back to home link" do
    sign_in(user)
    visit mobile_company_employee_path(company)

    expect(page).to have_link("Back to Home", href: mobile_company_home_path(company))
    click_link "Back to Home"
    expect(page).to have_content(user.name.split.first)
  end

  scenario "signs out from the employee page" do
    sign_in(user)
    visit mobile_company_employee_path(company)

    click_button "Sign Out"

    expect(page).to have_current_path(mobile_sign_in_path)
  end

  scenario "redirects to sign-in for unauthenticated user" do
    visit mobile_company_employee_path(company)
    expect(page).to have_current_path(mobile_sign_in_path)
  end

  scenario "redirects an unauthorized employee to home" do
    unauthorized_user = create(:user)
    create(:employee, user: unauthorized_user, company: company)

    sign_in(unauthorized_user)
    visit mobile_company_employee_path(company)

    expect(page).to have_current_path(mobile_company_home_path(company))
    expect(page).to have_content("not authorized")
  end
end
