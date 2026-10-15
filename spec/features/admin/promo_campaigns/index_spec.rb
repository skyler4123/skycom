require "rails_helper"

RSpec.feature "Admin::PromoCampaigns", type: :feature, js: true do
  let(:admin) { create(:user, :admin) }
  let(:company_owner) { create(:user, :company_owner) }

  let!(:campaign) { create(:promo_campaign, name: "Launch Gift") }

  scenario "admin sees campaigns table with all entries" do
    sign_in(admin)
    visit admin_promo_campaigns_path

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Launch Gift")
  end

  scenario "table shows expected columns" do
    sign_in(admin)
    visit admin_promo_campaigns_path

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_selector("th", text: "Campaign")
    expect(page).to have_selector("th", text: "Amount")
    expect(page).to have_selector("th", text: "Max Cap")
    expect(page).to have_selector("th", text: "Status")
  end

  scenario "clicking campaign name navigates to show page" do
    sign_in(admin)
    visit admin_promo_campaigns_path

    expect(page).to have_selector("table", wait: 10)
    click_link "Launch Gift", match: :first

    expect(page).to have_current_path(admin_promo_campaign_path(campaign), wait: 10)
  end

  scenario "show page displays campaign details" do
    sign_in(admin)
    visit admin_promo_campaign_path(campaign)

    expect(page).to have_content("Launch Gift", wait: 10)
    expect(page).to have_content("300")
    expect(page).to have_content(campaign.title)
    expect(page).to have_content("PREVIEW")
  end

  scenario "admin can create a campaign from new page" do
    sign_in(admin)
    visit new_admin_promo_campaign_path

    expect(page).to have_content("New Promotion Campaign", wait: 15)
    fill_in "promo_campaign[name]", with: "Holiday Bonus"
    fill_in "promo_campaign[title]", with: "Holiday gift!"
    fill_in "promo_campaign[body]", with: "Enjoy credits"
    fill_in "promo_campaign[amount]", with: "300"
    fill_in "promo_campaign[max_cap]", with: "1000"
    page.execute_script("document.querySelector('input[name=\"promo_campaign[scheduled_at]\"]').value = '2026-12-01T10:00'")
    click_button "Save Campaign"

    expect(page).to have_current_path(%r{/admin/promo_campaigns/.+}, wait: 10)
    expect(page).to have_content("Holiday Bonus", wait: 10)
  end

  scenario "non-admin user is redirected to root" do
    sign_in(company_owner)
    visit admin_promo_campaigns_path

    expect(page).to have_current_path(root_path, wait: 5)
  end
end
