require 'rails_helper'

RSpec.feature "Homepage", type: :feature, js: true do
  describe "Sign in with normal user" do
    let(:user) { create(:user, password: 'Password@1234', password_confirmation: 'Password@1234') }

    it "signs me in" do
      sign_in(user)
      expect(page).to have_current_path("/")
    end
  end
end
