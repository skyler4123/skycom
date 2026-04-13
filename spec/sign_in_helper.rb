module SessionHelpers
  def sign_in(user)
    # Direct hit to the backdoor
    visit sign_in_for_test_path(email: user.email)
    # Verify the message so we know the cookie was set
    expect(page).to have_content("Signed In")
  end
end

RSpec.configure do |config|
  config.include SessionHelpers
end
