require "rails_helper"

RSpec.feature "Companies::Events Management", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:default_category) do
    Seed::CategoryService.find_or_create_for(company: company, resource_name: "events")
  end

  let!(:event) do
    create(:event, company: company, category: default_category,
      name: "Alpha Event #{SecureRandom.hex(4)}", business_type: "procedure",
      start_at: 2.days.from_now, end_at: 2.days.from_now + 1.hour)
  end
  let!(:event2) do
    create(:event, company: company, category: default_category,
      name: "Beta Event #{SecureRandom.hex(4)}", business_type: "reservation",
      workflow_status: "pending")
  end

  let!(:default_table_config) do
    default_category.default_property_mapping.table_configs.destroy_all
    TableConfig.create!(
      company: company,
      category: default_category,
      property_mapping: default_category.default_property_mapping,
      resource_name: "events",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Event Name", "visible" => true, "align" => "left", "width" => nil },
        { "key" => "code", "name" => "Code", "visible" => true, "align" => "left", "width" => nil },
        { "key" => "business_type", "name" => "Type", "visible" => true, "align" => "center", "width" => nil },
        { "key" => "workflow_status", "name" => "Status", "visible" => true, "align" => "center", "width" => nil }
      ] }
    )
  end

  before do
    sign_in(owner)
    seed_event_client_cache(company: company, owner: owner, enums: event_enums_payload)
  end

  scenario "index page loads and displays events table" do
    visit company_events_path(company)

    expect(page).to have_selector('table', wait: 10)

    expect(page).to have_selector('th', text: 'Event Name')
    expect(page).to have_selector('th', text: 'Status')

    expect(page).to have_selector('tbody tr')
    expect(page).to have_content(event.name)
  end

  scenario "edit button links to edit page for event" do
    visit company_events_path(company)
    expect(page).to have_selector('table', wait: 10)

    edit_link = find("a[href*='/events/#{event.id}/edit']", match: :first)
    expect(edit_link).to be_present
  end

  scenario "name links to show page for event" do
    visit company_events_path(company)
    expect(page).to have_selector('table', wait: 10)

    show_link = find("a[href*='/events/#{event.id}']", match: :first)
    expect(show_link).to be_present
  end
end
