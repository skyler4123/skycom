module SessionHelpers
  def sign_in(user)
      visit sign_in_path
      
      fill_in "Email", with: user.email
      fill_in "Password", with: user.password
      click_button "Sign in"
      
      expect(page).to have_content("Signed in successfully")
      expect(page).to have_link("Sign Out")
      expect(page).to have_selector('[role="avatar"]')
  end
end

RSpec.configure do |config|
  config.include SessionHelpers
end
