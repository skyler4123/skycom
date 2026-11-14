require 'rails_helper'

RSpec.feature "Sign up forgot password link", type: :feature, js: true do
  scenario "shows a forgot password link that routes to the reset page" do
    visit sign_up_path

    expect(page).to have_selector('a', text: "Forgot your password?", wait: 10)

    click_link "Forgot your password?"

    expect(page).to have_current_path(new_identity_password_reset_path, wait: 10)
    expect(page).to have_content("Forgot your password?", wait: 10)
  end
end
