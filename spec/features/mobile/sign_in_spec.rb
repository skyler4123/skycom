require "rails_helper"

RSpec.feature "Mobile Sign In", type: :feature, js: true do
  let(:user) { create(:user) }

  scenario "renders sign-in form with email and password fields" do
    visit mobile_sign_in_path

    expect(page).to have_field("Email")
    expect(page).to have_field("Password")
    expect(page).to have_button("Sign In")
  end

  scenario "signs in with valid credentials and redirects to home" do
    visit mobile_sign_in_path

    fill_in "Email", with: user.email
    fill_in "Password", with: "Password@1234"
    click_button "Sign In"

    expect(page).to have_content("Welcome, #{user.name}")
  end

  scenario "shows error with invalid credentials" do
    visit mobile_sign_in_path

    fill_in "Email", with: user.email
    fill_in "Password", with: "wrong_password"
    click_button "Sign In"

    expect(page).to have_content("Invalid email or password")
  end

  scenario "redirects to home if already signed in" do
    sign_in(user)

    visit mobile_sign_in_path

    expect(page).to have_content("Welcome, #{user.name}")
  end

  scenario "signs out and redirects to sign-in page" do
    sign_in(user)
    visit mobile_home_path

    click_button "Sign Out"

    expect(page).to have_current_path(mobile_sign_in_path)
    expect(page).to have_content("Signed out")
  end
end
