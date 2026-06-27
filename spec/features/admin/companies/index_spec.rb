require "rails_helper"

RSpec.feature "Admin::Companies", type: :feature, js: true do
  let(:admin) { create(:user, :admin) }

  let(:company_owner) { create(:user, :company_owner) }

  let!(:company1) { create(:company) }

  let!(:company2) do
    c = create(:company)
    c.update!(name: "Second Corp", code: "SEC-002", email: "second@example.com")
    c
  end

  scenario "admin sees companies table with all entries" do
    sign_in(admin)
    visit admin_companies_path

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content(company1.name)
    expect(page).to have_content("Second Corp")
    expect(page).to have_content("second@example.com")
  end

  scenario "table shows expected columns" do
    sign_in(admin)
    visit admin_companies_path

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_selector("th", text: "Company Name")
    expect(page).to have_selector("th", text: "Code")
    expect(page).to have_selector("th", text: "Type")
    expect(page).to have_selector("th", text: "Email")
    expect(page).to have_selector("th", text: "Phone")
    expect(page).to have_selector("th", text: "Owner")
    expect(page).to have_selector("th", text: "Status")
    expect(page).to have_selector("th", text: "Created")
  end

  scenario "clicking company name navigates to show page" do
    sign_in(admin)
    visit admin_companies_path

    expect(page).to have_selector("table", wait: 10)
    click_link company1.name, match: :first

    expect(page).to have_current_path(admin_company_path(company1), wait: 10)
  end

  scenario "show page displays company details" do
    sign_in(admin)
    visit admin_company_path(company1)

    expect(page).to have_content(company1.name, wait: 10)
    expect(page).to have_content("Back to Companies")
    expect(page).to have_content(company1.user.name)
    expect(page).to have_content(company1.user.email)
  end

  scenario "non-admin user is redirected to root" do
    sign_in(company_owner)
    visit admin_companies_path

    expect(page).to have_current_path(root_path, wait: 5)
  end
end
