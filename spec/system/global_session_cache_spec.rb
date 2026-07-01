require "rails_helper"

RSpec.describe "Global Session Cache", type: :system do
  let(:user) { create(:user, system_role: :company_owner, password: "Password@1234", password_confirmation: "Password@1234") }

  after(:each) do
    Rails.global_session_cache.delete("rspec_session_test")
  end

  describe "global cache lifecycle" do
    it "writes session id to global cache on sign-in" do
      expect(user.sessions.count).to eq(0)

      visit root_path
      expect(page).to have_selector('button[role="sign-in-button"]', wait: 10)
      find('button[role="sign-in-button"]', wait: 10).click

      within 'form[role="sign-in-form"]', wait: 10 do
        find('input[name="email"]', wait: 5).set(user.email)
        find('input[name="password"]', wait: 5).set(user.password)
        click_button "Sign In"
      end

      expect(page).to have_selector('[data-controller="avatar"]', wait: 10)

      session_id = user.sessions.last.id
      expect(Rails.global_session_cache.exist?(session_id)).to be true
    end

    it "removes session id from global cache when session is destroyed" do
      session = user.sessions.create!
      expect(Rails.global_session_cache.exist?(session.id)).to be true

      session.destroy
      expect(Rails.global_session_cache.exist?(session.id)).to be false
    end
  end

  describe "global cache check in set_current_session" do
    it "rejects requests when session is missing from global cache" do
      visit root_path
      expect(page).to have_selector('button[role="sign-in-button"]', wait: 10)
      find('button[role="sign-in-button"]', wait: 10).click
      within 'form[role="sign-in-form"]', wait: 10 do
        find('input[name="email"]', wait: 5).set(user.email)
        find('input[name="password"]', wait: 5).set(user.password)
        click_button "Sign In"
      end
      expect(page).to have_selector('[data-controller="avatar"]', wait: 10)

      session_id = user.sessions.last.id
      expect(Rails.global_session_cache.exist?(session_id)).to be true

      Rails.global_session_cache.delete(session_id)

      visit root_path
      expect(page).not_to have_selector('[data-controller="avatar"]', wait: 10)
    end
  end

  describe "Rails.global_session_cache" do
    it "exists and delegates to global_cache" do
      Rails.global_session_cache.write("rspec_session_test", true, expires_in: 60)
      expect(Rails.global_session_cache.exist?("rspec_session_test")).to be true
      expect(Rails.global_session_cache.read("rspec_session_test")).to be true
    end

    it "deletes values" do
      Rails.global_session_cache.write("rspec_session_test", true, expires_in: 60)
      Rails.global_session_cache.delete("rspec_session_test")
      expect(Rails.global_session_cache.exist?("rspec_session_test")).to be false
    end
  end
end
