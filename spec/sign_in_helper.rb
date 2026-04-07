module SessionHelpers
  def sign_in(user)
    visit root_path

    # 1. Click the button that opens the Stimulus modal
    # We use the 'role' attribute since it's unique and stable
    find('button[role="sign-in-button"]').click

    # 2. Wait for the modal to appear and fill in the fields
    # Capybara will automatically wait for these to be visible
    within 'div[data-controller="home--signin-modal"]' do # Adjust selector if your modal has a different ID/Class
      fill_in "Email", with: user.email
      fill_in "Password", with: user.password
      click_button "Sign In"
    end

    # 3. Assertions
    # Note: Since you are using a Shell + JSON architecture,
    # ensure your 'notification' controller has rendered the message.
    # expect(page).to have_content("Signed in successfully", wait: 5)
    # expect(page).to have_link("Sign Out")

    # Matching your specific role selector
    # expect(page).to have_selector('[role="avatar"]')
  end
end

RSpec.configure do |config|
  config.include SessionHelpers
end
