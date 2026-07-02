require 'rails_helper'

RSpec.feature "OmniAuth Google Sign-In", type: :feature, js: true do
  let(:test_email) { MOCK_OAUTH_EMAIL }

  before do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: "google-mock-#{SecureRandom.hex(8)}",
      info: {
        email: test_email,
        name: "Manager One",
        first_name: "Manager",
        last_name: "One",
        image: "https://avatar.iran.liara.run/public/30"
      }
    })
  end

  after do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  scenario "user signs in with Google OAuth for the first time" do
    visit root_path

    expect(page).to have_selector('button[role="sign-in-button"]', wait: 10)
    find('button[role="sign-in-button"]', wait: 10).click

    click_button "Sign in with Google"

    expect(page).to have_selector('[data-controller="avatar"]', wait: 10)
    expect(User.find_by(email: test_email)).to be_present
  end

  scenario "existing user signs in with Google OAuth" do
    existing_user = Seed::UserService.create(
      email: test_email,
      password: "Password@1234",
      system_role: :company_employee
    )

    visit root_path

    expect(page).to have_selector('button[role="sign-in-button"]', wait: 10)
    find('button[role="sign-in-button"]', wait: 10).click

    click_button "Sign in with Google"

    expect(page).to have_selector('[data-controller="avatar"]', wait: 10)
    existing_user.reload
    expect(existing_user.provider).to eq("google_oauth2")
    expect(existing_user.uid).to be_present
  end
end
