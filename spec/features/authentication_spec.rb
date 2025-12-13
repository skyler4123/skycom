require 'rails_helper'

RSpec.feature "Authentication", type: :feature, js: true do
  let(:new_user_params) {
    {
      email: 'test@example.com',
      password: 'Password@1234',
      password_confirmation: 'Password@1234'
    }
  }
  let(:created_user) { User.find_by(email: new_user_params[:email]) }

  context "Sign up with normal user" do
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
end
