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
      visit sign_up_path
      sign_up_form = find('form[role="sign-up-form"]', wait: 10)
      expect(page).to have_selector('form[role="sign-up-form"]', visible: true)

      within(sign_up_form) do
        fill_in "Email", with: new_user_params[:email]
        fill_in "Password", with: new_user_params[:password]
        fill_in "Password confirmation", with: new_user_params[:password_confirmation]
        click_button "Sign Up"
      end

      # Assertions
      expect(page).to have_selector('[data-controller="avatar"]', wait: 10)
      expect(created_user).to be_present # more idiomatic than be_truthy for ActiveRecord objects
    end

    it "prefills email from the homepage CTA" do
      visit sign_up_path(email: "founder@example.com")

      expect(page).to have_field("Email", with: "founder@example.com", wait: 10)
    end
  end

  describe "Sign in with normal user" do
    let(:user) { create(:user, system_role: :company_owner, password: 'Password@1234', password_confirmation: 'Password@1234') }
    let!(:before_session_count) { user.sessions.count }

    it "signs me in", retry: 3, retry_wait: 10 do
      visit sign_in_path

      # Use the FORM role as the anchor.
      within 'form[role="sign-in-form"]', wait: 10 do
        # Use find(...).set — performs a fresh DOM lookup immediately before typing.
        find('input[name="email"]', wait: 5).set(user.email)
        find('input[name="password"]', wait: 5).set(user.password)

        click_button "Sign In"
      end

      expect(page).to have_selector('[data-controller="avatar"]', wait: 10)
      expect(user.sessions.count - before_session_count).to equal 1
    end
  end

  describe "Already signed in" do
    let(:user) { create(:user, system_role: :company_owner, password: 'Password@1234', password_confirmation: 'Password@1234') }

    before do
      sign_in(user)
    end

    it "redirects away from the sign-in page" do
      visit sign_in_path

      expect(page).to have_current_path(root_path, wait: 10)
    end

    it "redirects away from the sign-up page" do
      visit sign_up_path

      expect(page).to have_current_path(root_path, wait: 10)
    end
  end
end
