require 'rails_helper'

RSpec.feature "Authentication", type: :feature, js: true, retry: 5 do
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

    it "signs me in" do
      visit root_path

      # First attempt: click to open the sign-in form (modal/drawer/etc.)
      click_on "Sign In"

      # Try to find the form — Capybara will wait and retry automatically (up to ~2-5 seconds)
      begin
        sign_in_form = find('form[role="sign-in-form"]', wait: 0.2) # explicit short wait
      rescue Capybara::ElementNotFound
        # If not found/visible after waiting, click "Sign In" again (handles toggle bugs)
        click_on "Sign In"
        sign_in_form = find('form[role="sign-in-form"]') # will wait again with default timeout
      end

      within(sign_in_form) do
        fill_in "Email", with: user.email
        fill_in "Password", with: 'Password@1234'
        click_button "Sign In"
      end

      expect(page).to have_button("Sign Out")
      expect(page).to have_selector('[role="avatar"]')
    end
  end
end
