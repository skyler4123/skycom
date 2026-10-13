require "rails_helper"

RSpec.feature "Companies::NotificationTags Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:custom_tag) { NotificationTag.create!(company: company, name: "ops", description: "Ops broadcasts", business_type: :custom) }
  let!(:system_tag) { NotificationTag.create!(company: company, name: "All Employees", description: "Broadcasts to everyone", business_type: :system) }

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

  scenario "index page loads and displays notification tags table" do
    visit company_notification_tags_path(company)

    expect(page).to have_selector("table", wait: 10)

    expect(page).to have_selector("th", text: "Name")
    expect(page).to have_selector("th", text: "Description")
    expect(page).to have_selector("th", text: "Type")

    expect(page).to have_content("ops")
  end

  scenario "system tags render without edit or delete actions" do
    visit company_notification_tags_path(company)
    expect(page).to have_selector("table", wait: 10)

    system_row = find("tr", text: "All Employees")
    expect(system_row).to have_no_selector("a[href*='/edit']")
    expect(system_row).to have_no_button("Delete")
  end

  scenario "custom tag row links to show and edit pages" do
    visit company_notification_tags_path(company)
    expect(page).to have_selector("table", wait: 10)

    expect(page).to have_selector("a[href*='/notification_tags/#{custom_tag.id}']", minimum: 1)
    expect(page).to have_selector("a[href*='/notification_tags/#{custom_tag.id}/edit']", minimum: 1)
  end
end
