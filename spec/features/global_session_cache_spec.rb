require "rails_helper"

# Session caching uses sync_cache (local SQLite + Redis pub/sub invalidation).
# - Session create → cached in local_cache + Redis pub/sub notification.
# - Session destroy → evicted from local_cache + pub/sub notification.
# - No global (Redis) read on any request — reads hit local_cache only.
RSpec.describe "Global Session Cache", type: :feature, js: true do
  let(:user) { create(:user, system_role: :company_owner, password: "Password@1234", password_confirmation: "Password@1234") }

  describe "sync_cache session lifecycle" do
    it "caches session in sync_cache on sign-in and evicts on destroy" do
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
      expect(Rails.sync_cache.read("sessions_#{session_id}")).not_to be_nil

      user.sessions.last.destroy
      expect(Rails.sync_cache.read("sessions_#{session_id}")).to be_nil
    end

    it "rejects requests when session is destroyed" do
      visit root_path
      expect(page).to have_selector('button[role="sign-in-button"]', wait: 10)
      find('button[role="sign-in-button"]', wait: 10).click
      within 'form[role="sign-in-form"]', wait: 10 do
        find('input[name="email"]', wait: 5).set(user.email)
        find('input[name="password"]', wait: 5).set(user.password)
        click_button "Sign In"
      end
      expect(page).to have_selector('[data-controller="avatar"]', wait: 10)

      user.sessions.last.destroy

      visit root_path
      expect(page).not_to have_selector('[data-controller="avatar"]', wait: 10)
    end
  end
end
