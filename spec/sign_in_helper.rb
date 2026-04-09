module SessionHelpers
  def sign_in(user)
    visit root_path

    # === Wait for the authentication controller to fully render the signed-out state ===
    # This is the key: we wait until the button is present AND the controller has stabilized
    expect(page).to have_selector('button[role="sign-in-button"]', wait: 12)

    # Extra safety: wait until the authentication controller has finished its valueChanged cycle
    # (We can detect this by waiting for the button that has the correct data-action)
    expect(page).to have_selector(
      'button[role="sign-in-button"][data-action*="openSignInModal"]',
      wait: 10
    )

    find('button[role="sign-in-button"]').click

    # Wait for the modal (SweetAlert2 + Stimulus modal controller)
    expect(page).to have_selector('.swal2-container, form[role="sign-in-form"]', wait: 12)

    # Now interact with the form using fresh lookups
    within find('form[role="sign-in-form"]', wait: 10) do
      find('input[name="email"]', wait: 5).set(user.email)
      find('input[name="password"]', wait: 5).set(user.password)

      find('button[type="submit"]', text: /Sign In/i, wait: 5).click
    end

    # Final assertion
    expect(page).to have_selector('[role="avatar"]', wait: 15)
  end
end

RSpec.configure do |config|
  config.include SessionHelpers
end
