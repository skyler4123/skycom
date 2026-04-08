module SessionHelpers
  def sign_in(user)
    visit root_path
    find('button[role="sign-in-button"]').click
    within 'div[data-controller="home--signin-modal"]' do
      fill_in "Email", with: user.email
      fill_in "Password", with: user.password
      click_button "Sign In"
    end
    expect(page).to have_selector('[role="avatar"]')
  end
end

RSpec.configure do |config|
  config.include SessionHelpers
end
