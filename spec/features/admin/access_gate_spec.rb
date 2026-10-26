require "rails_helper"

RSpec.feature "Admin access gate", type: :feature, js: true do
  let(:admin) { create(:user, :admin) }
  let(:employee) { create(:user) }

  scenario "admin can access admin pages" do
    sign_in(admin)
    visit admin_promo_campaigns_path

    expect(page).to have_selector("table", wait: 10)
  end

  scenario "employee cannot access admin pages" do
    sign_in(employee)
    visit admin_promo_campaigns_path

    expect(page).not_to have_selector("table", wait: 2)
    expect(page).to have_current_path(root_path, wait: 10)
  end
end
