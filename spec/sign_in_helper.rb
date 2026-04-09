module SessionHelpers
  def sign_in(user)
    visit root_path

    page.execute_script("document.documentElement.style.setProperty('transition', 'none', 'important')")
    
    # 1. Wait for header controller to fully render signed-out state
    expect(page).to have_selector(
      'button[role="sign-in-button"][data-action*="openSignInModal"]',
      wait: 12
    )

    find('button[role="sign-in-button"]').click

    # 2. Wait for the modal form to appear
    expect(page).to have_selector('form[role="sign-in-form"]', wait: 12)

    # 3. Fill fields with fresh finds every time (safer than within for dynamic content)
    find('input[name="email"]', wait: 8).set(user.email)
    find('input[name="password"]', wait: 8).set(user.password)

    # 4. Click submit with fresh lookup right before action
    find('button[type="submit"]', text: /Sign In/i, wait: 8).click

    # 5. Wait for the modal to close and signed-in state to appear
    expect(page).to have_selector('[role="avatar"]', wait: 18)
    expect(page).to have_no_selector('form[role="sign-in-form"]', wait: 8) # optional but helpful
  end
end

RSpec.configure do |config|
  config.include SessionHelpers
end
