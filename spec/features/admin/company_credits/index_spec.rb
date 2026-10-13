require "rails_helper"

RSpec.feature "Admin::CompanyCredits", type: :feature, js: true do
  let(:admin) { create(:user, :admin) }
  let(:company_owner) { create(:user, :company_owner) }

  let!(:company1) { create(:company) }

  scenario "admin sees balances table with all entries" do
    sign_in(admin)
    visit admin_company_credits_path

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content(company1.name)
  end

  scenario "table shows expected columns" do
    sign_in(admin)
    visit admin_company_credits_path

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_selector("th", text: "Company")
    expect(page).to have_selector("th", text: "Main")
    expect(page).to have_selector("th", text: "Promo")
    expect(page).to have_selector("th", text: "Debt")
    expect(page).to have_selector("th", text: "Total")
  end

  scenario "Promotion button navigates to campaigns" do
    sign_in(admin)
    visit admin_company_credits_path

    expect(page).to have_selector("table", wait: 10)
    find("main a[href='#{admin_promo_campaigns_path}']").click

    expect(page).to have_current_path(admin_promo_campaigns_path, wait: 10)
  end

  scenario "non-admin user is redirected to root" do
    sign_in(company_owner)
    visit admin_company_credits_path

    expect(page).to have_current_path(root_path, wait: 5)
  end
end
