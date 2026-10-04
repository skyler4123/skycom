require "rails_helper"

RSpec.feature "Companies::Events New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:default_category) do
    Seed::CategoryService.find_or_create_for(company: company, resource_name: "events")
  end

  before do
    sign_in(owner)
    seed_event_client_cache(company: company, owner: owner, enums: event_enums_payload)
  end

  scenario "renders new event form with name and time fields" do
    visit new_company_event_path(company)

    expect(page).to have_selector('input[name="event[name]"]', wait: 10)
    expect(page).to have_selector('select[name="event[business_type]"]', wait: 10)
    expect(page).to have_selector('input[name="event[start_at]"]', wait: 10)
    expect(page).to have_selector('input[name="event[end_at]"]', wait: 10)
  end

  scenario "creates event and redirects to show page" do
    visit new_company_event_path(company)

    fill_in 'event[name]', with: 'New Test Event'
    page.execute_script("document.querySelector('select[name=\"event[business_type]\"]').value = 'procedure'")

    click_button "Save Event"

    expect(page).to have_current_path(company_event_path(company, Event.find_by(name: "New Test Event")), wait: 10)
    expect(page).to have_content('New Test Event', wait: 10)

    expect(Event.find_by(name: "New Test Event")).to be_present
  end
end
