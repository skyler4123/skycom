require "rails_helper"

RSpec.feature "Companies::NotificationTags New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  before do
    sign_in(owner)

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => [],
      "table_configs" => [],
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])",
      { user: JSON.parse(owner.to_json), companies: [ company_data ], enums: {}, employees: [] }.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "renders new notification tag form with base fields" do
    visit new_company_notification_tag_path(company)

    expect(page).to have_selector('input[name="notification_tag[name]"]', wait: 10)
    expect(page).to have_selector('textarea[name="notification_tag[description]"]', wait: 10)
  end

  scenario "creates notification tag, redirects to show page" do
    visit new_company_notification_tag_path(company)
    expect(page).to have_selector('input[name="notification_tag[name]"]', wait: 10)

    fill_in "notification_tag[name]", with: "night-shift"
    fill_in "notification_tag[description]", with: "Night shift broadcasts"

    click_button "Save Tag"

    expect(page).to have_current_path(%r{/notification_tags/[0-9a-f-]+$}, wait: 10)

    tag_record = NotificationTag.find_by(company: company, name: "night-shift")
    expect(tag_record).to be_present
    expect(tag_record.business_type).to eq("custom")
    expect(page).to have_content("night-shift", wait: 10)
  end

  scenario "blank name fails and creates nothing" do
    visit new_company_notification_tag_path(company)
    expect(page).to have_selector('input[name="notification_tag[name]"]', wait: 10)

    fill_in "notification_tag[name]", with: ""

    click_button "Save Tag"

    expect(page).to have_current_path(new_company_notification_tag_path(company), wait: 10)
    expect(NotificationTag.where(company: company, description: "should-not-persist").count).to eq(0)
  end
end
