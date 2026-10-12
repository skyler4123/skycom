require "rails_helper"

RSpec.feature "Companies::NotificationTags Show", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:custom_tag) { NotificationTag.create!(company: company, name: "ops", description: "Ops broadcasts", business_type: :custom) }
  let!(:system_tag) { NotificationTag.create!(company: company, name: "All Company", description: "Broadcasts to everyone", business_type: :system) }

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

  scenario "shows custom tag details with edit and delete actions" do
    visit company_notification_tag_path(company, custom_tag)

    expect(page).to have_content("ops", wait: 10)
    expect(page).to have_content("Ops broadcasts", wait: 10)

    expect(page).to have_link("Edit Tag", href: edit_company_notification_tag_path(company, custom_tag), wait: 10)
    expect(page).to have_button("Delete", wait: 10)
  end

  scenario "system tag shows no edit or delete actions" do
    visit company_notification_tag_path(company, system_tag)

    expect(page).to have_content("All Company", wait: 10)

    expect(page).to have_no_link("Edit Tag")
    expect(page).to have_no_button("Delete")
  end
end
