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

    it "signs me in" do
      visit root_path

      click_on "Sign Up"

      within('form[role="Sign Up Form"]') do
        fill_in "Email", with: new_user_params[:email]
        fill_in "Password", with: new_user_params[:password]
        fill_in "Password confirmation", with: new_user_params[:password_confirmation]
        click_button "Sign Up"
      end

      expect(page).to have_button("Sign Out")
      expect(page).to have_selector('[role="avatar"]')
      expect(created_user).to be_truthy
    end
  end

  describe "Sign in with normal user" do
    let(:user) { create(:user) }
    it "signs me in" do
      debugger
      visit root_path

      click_on "Sign In"

      within('form[role="Sign In Form"]') do
        fill_in "Email", with: user.email
        fill_in "Password", with: 'Password@1234'
        click_button "Sign In"
      end

      expect(page).to have_button("Sign Out")
      expect(page).to have_selector('[role="avatar"]')
    end
  end
end
