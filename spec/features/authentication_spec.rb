require 'rails_helper'

RSpec.feature "Authentication", type: :feature, js: true do
  describe "Sign up with normal user" do
    let(:new_user_params) {
      {
        email: 'test@example.com',
        password: 'Password@1234',
        password_confirmation: 'Password@1234'
      }
    }
    let(:created_user) { User.find_by(email: new_user_params[:email]) }

    it "successfully signs up and signs me in" do
      visit root_path

      # First click to open the sign-up form/modal
      click_on "Sign Up"

      # Wait for the form to appear; if not found/visible, click again (handles flaky toggle/modal)
      begin
        sign_up_form = find('form[role="sign-up-form"]', wait: 0.2)
      rescue Capybara::ElementNotFound
        # Second attempt: click again in case the first one didn't fully trigger the modal/drawer
        click_on "Sign Up"
        sign_up_form = find('form[role="sign-up-form"]') # uses default wait time
      end

      within(sign_up_form) do
        fill_in "Email", with: new_user_params[:email]
        fill_in "Password", with: new_user_params[:password]
        fill_in "Password confirmation", with: new_user_params[:password_confirmation]
        click_button "Sign Up"
      end

      # Assertions
      expect(page).to have_button("Sign Out")
      expect(page).to have_selector('[role="avatar"]')
      expect(created_user).to be_present # more idiomatic than be_truthy for ActiveRecord objects
    end
  end

  describe "Sign in with normal user" do
    let(:user) { create(:user, password: 'Password@1234', password_confirmation: 'Password@1234') }
    let!(:before_session_count) { user.sessions.count }
    
    it "signs me in", retry: 3, retry_wait: 10 do
      sign_in(user)

      expect(page).to have_button("Sign Out")
      expect(page).to have_selector('[role="avatar"]')
      expect(user.sessions.count - before_session_count).to equal 1
    end
  end
end
