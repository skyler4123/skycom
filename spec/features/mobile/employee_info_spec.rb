# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Employee Info", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company) }
  let!(:employee) { company.employees.find_by(user: user).tap { |record| record.update!(branch: branch) } }

  scenario "shows employee profile details" do
    sign_in(user)
    visit mobile_employee_path

    expect(page).to have_content("Employee")
    expect(page).to have_content(employee.name)
    expect(page).to have_content(employee.email)
    expect(page).to have_content(company.name)
    expect(page).to have_content(branch.name)
    expect(page).to have_content("Account & Contact")
    expect(page).to have_content("Organization & Assignment")
    expect(page).to have_content("Work & Attendance")
    expect(page).to have_content("Sample")
  end

  scenario "does not render a working mobile profile editor" do
    sign_in(user)
    visit mobile_employee_path

    expect(page).to have_button("Edit Profile Details", disabled: true)
    expect(page).to have_content("Available on desktop")
  end

  scenario "has a back to home link" do
    sign_in(user)
    visit mobile_employee_path

    expect(page).to have_link("Back to Home", href: mobile_home_path)
    click_link "Back to Home"
    expect(page).to have_content(user.name.split.first)
  end

  scenario "signs out from the employee page" do
    sign_in(user)
    visit mobile_employee_path

    click_button "Sign Out"

    expect(page).to have_current_path(mobile_sign_in_path)
  end

  scenario "redirects to sign-in for unauthenticated user" do
    visit mobile_employee_path
    expect(page).to have_current_path(mobile_sign_in_path)
  end
end
