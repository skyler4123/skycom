module SessionHelpers
  def sign_in(user)
    visit root_path
    sleep 0.5
    # 1. Wait for the button and click
    expect(page).to have_selector('button[role="sign-in-button"]', wait: 10)
    find('button[role="sign-in-button"]', wait: 10).click

    # 2. Use the FORM role as the anchor.
    # If the form flickers, Capybara will re-find this block.
    within 'form[role="sign-in-form"]', wait: 10 do
      # 3. Use find(...).set. This is the "magic" fix.
      # It performs a fresh DOM lookup immediately before typing.
      find('input[name="email"]', wait: 5).set(user.email)
      find('input[name="password"]', wait: 5).set(user.password)

      click_button "Sign In"
    end

    expect(page).to have_selector('[role="avatar"]', wait: 10)
  end
end

RSpec.configure do |config|
  config.include SessionHelpers
end
