require "rails_helper"

RSpec.feature "Mobile Home", type: :feature, js: true do
  let(:user) { create(:user) }

  scenario "shows welcome message for signed-in user" do
    sign_in(user)
    visit mobile_home_path

    expect(page).to have_content("Welcome, #{user.name}")
    expect(page).to have_content("You are signed in")
  end

  scenario "has employee info link" do
    sign_in(user)
    visit mobile_home_path

    expect(page).to have_link("Employee Info", href: mobile_employee_path)
  end

  scenario "has check in button" do
    sign_in(user)
    visit mobile_home_path

    expect(page).to have_button("Check In")
  end

  scenario "redirects to sign-in for unauthenticated user" do
    visit mobile_home_path

    expect(page).to have_current_path(root_path)
  end
end
