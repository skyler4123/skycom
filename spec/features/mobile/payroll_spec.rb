require "rails_helper"

RSpec.feature "Mobile Payroll", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:employee) { company.employees.find_by(user: user) }
  let!(:payroll) do
    create(:payroll, company: company, employee: employee, month: Date.current.beginning_of_month, status: :paid)
  end

  scenario "shows payroll details" do
    sign_in(user)
    visit mobile_payroll_path

    expect(page).to have_content("Payroll")
    expect(page).to have_content(employee.name)
    expect(page).to have_content("Paid")
  end

  scenario "has back to home link" do
    sign_in(user)
    visit mobile_payroll_path

    expect(page).to have_link("Back to Home", href: mobile_home_path)
    click_link "Back to Home"
    expect(page).to have_content("Welcome, #{user.name}")
  end

  scenario "redirects to sign-in for unauthenticated user" do
    visit mobile_payroll_path
    expect(page).to have_current_path(root_path)
  end
end
