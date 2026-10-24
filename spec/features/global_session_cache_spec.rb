require "rails_helper"

# Session caching uses sync_cache (local SQLite + Redis pub/sub invalidation).
# - Session create → cached in local_cache + Redis pub/sub notification.
# - Session destroy → evicted from local_cache + pub/sub notification.
# - No global (Redis) read on any request — reads hit local_cache only.
RSpec.describe "Global Session Cache", type: :feature, js: true do
  let(:user) { create(:user, system_role: :company_owner, password: "Password@1234", password_confirmation: "Password@1234") }

  describe "session lifecycle" do
    it "rejects requests when session is destroyed" do
      visit sign_in_path
      expect(page).to have_selector('form[role="sign-in-form"]', wait: 10)
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
