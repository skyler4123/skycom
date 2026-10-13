require "rails_helper"

RSpec.feature "Companies::NotificationTags Edit", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:custom_tag) { NotificationTag.create!(company: company, name: "ops", description: "Ops broadcasts", business_type: :custom) }

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

  scenario "renders prefilled edit form" do
    visit edit_company_notification_tag_path(company, custom_tag)

    expect(page).to have_selector('input[name="notification_tag[name]"]', wait: 10)
    expect(find('input[name="notification_tag[name]"]').value).to eq("ops")
    expect(find('textarea[name="notification_tag[description]"]').value).to eq("Ops broadcasts")
  end

  scenario "renames tag and redirects to show page" do
    visit edit_company_notification_tag_path(company, custom_tag)
    expect(page).to have_selector('input[name="notification_tag[name]"]', wait: 10)

    fill_in "notification_tag[name]", with: "ops-updated"
    click_button "Save Changes"

    expect(page).to have_current_path(company_notification_tag_path(company, custom_tag), wait: 10)
    expect(page).to have_content("ops-updated", wait: 10)

    expect(custom_tag.reload.name).to eq("ops-updated")
  end

  scenario "deletes custom tag from edit page and redirects to index" do
    visit edit_company_notification_tag_path(company, custom_tag)
    expect(page).to have_selector('input[name="notification_tag[name]"]', wait: 10)

    click_button "Delete"

    expect(page).to have_current_path(company_notification_tags_path(company), wait: 10)
    expect(NotificationTag.where(id: custom_tag.id).count).to eq(0)
  end
end
