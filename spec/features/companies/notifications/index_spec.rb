require "rails_helper"

RSpec.feature "Companies::Notifications Index", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:owner_employee) { company.employees.find_by(business_type: "owner") }
  let!(:tag) { NotificationTag.create!(company: company, name: "ops") }

  before do
    EmployeeNotificationTagAppointment.create!(employee: owner_employee, notification_tag: tag)
    Notifications::CreateService.call(company: company, title: "Server rebooted", tag_ids: [ tag.id ])

    sign_in(owner)

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
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

  scenario "bell shows unread count and clears after mark all" do
    visit company_notifications_path(company)

    expect(page).to have_selector("[data-bell-badge]", text: "1", wait: 10)
    click_button "Mark all as read"
    expect(page).to have_selector("[data-bell-badge]", text: "0", wait: 10)
  end

  scenario "index lists notification rows" do
    visit company_notifications_path(company)

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_content("Server rebooted", wait: 10)
  end
end
