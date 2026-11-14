require 'rails_helper'

RSpec.feature "Sign in forgot password link", type: :feature, js: true do
  scenario "shows a forgot password link that routes to the reset page" do
    visit sign_in_path

    expect(page).to have_selector('a', text: "Forgot your password?", wait: 10)

    click_link "Forgot your password?"

    expect(page).to have_current_path(new_identity_password_reset_path, wait: 10)
    expect(page).to have_content("Forgot your password?", wait: 10)
  end

  scenario "can request a reset email starting from the sign in page" do
    user = create(:user,
                  system_role: :company_owner,
                  email: "signin_forgot@example.com",
                  password: "Password@1234",
                  password_confirmation: "Password@1234",
                  verified: true)

    ActionMailer::Base.deliveries.clear

    visit sign_in_path
    click_link "Forgot your password?", wait: 10

    expect(page).to have_current_path(new_identity_password_reset_path, wait: 10)

    fill_in "Email", with: user.email
    click_button "Send password reset email"

    expect(page).to have_selector("p#notice", text: "Check your email for reset instructions", wait: 10)
  end
end
