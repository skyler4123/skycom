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
      # visit sign_up_path
      # fill_in 'email', with: params[:email]
      # fill_in 'password', with: params[:password]
      # fill_in 'password_confirmation', with: params[:password_confirmation]
      # fill_in 'name', with: params[:name]
      # # select params[:education_role], from: 'education_role'
      # submit_button = find('input[type="submit"]')
      # submit_button.click
      # expect(page).to have_current_path('/')
      # expect(created_user).to be_truthy
      # expect(page).to have_content(SIGN_UP_SUCCESS_MESSAGE)
      visit root_path
      sleep 10
    end
  end
end
