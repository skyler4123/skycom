require "rails_helper"

RSpec.feature "Mobile Employee Info", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company) }
  let!(:employee) { create(:employee, user: user, company: company, branch: branch) }

  let(:displayed_employee) { user.employees.first }

  scenario "shows employee details" do
    sign_in(user)
    visit mobile_employee_path

    expect(page).to have_content("Employee Info")
    expect(page).to have_content(displayed_employee.name)
    expect(page).to have_content(displayed_employee.email)
    expect(page).to have_content(company.name)
  end

  scenario "has back to home link" do
    sign_in(user)
    visit mobile_employee_path

    expect(page).to have_link("Back to Home", href: mobile_home_path)
    click_link "Back to Home"
    expect(page).to have_content("Welcome, #{user.name}")
  end

  scenario "redirects to sign-in for unauthenticated user" do
    visit mobile_employee_path
    expect(page).to have_current_path(root_path)
  end
end
