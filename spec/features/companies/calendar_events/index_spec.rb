require "rails_helper"

RSpec.feature "Companies::CalendarEvents Index", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:procedure) { create(:calendar_procedure, company: company, name: "Tooth Extraction") }
  let(:practitioner) { create(:calendar_practitioner, company: company, name: "Dr. D") }
  let(:location) { create(:calendar_location, company: company, name: "Surgery Room 1") }

  let!(:event) do
    record = create(:calendar_event, company: company, calendar_procedure: procedure,
      title: "Extraction", status: :pending)
    create(:calendar_event_practitioner, calendar_event: record, calendar_practitioner: practitioner, company: company)
    create(:calendar_event_location, calendar_event: record, calendar_location: location, company: company)
    record
  end

  before do
    sign_in(owner)
    seed_client_cache!
  end

  def seed_client_cache!
    page.execute_script("localStorage.clear()")
    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => [], "table_configs" => [], "categories" => [],
      "branches" => [], "departments" => [], "roles" => []
    )
    payload = { user: JSON.parse(owner.to_json), companies: [ company_data ], enums: {}, employees: [] }
    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "index page loads and displays the appointments table" do
    visit company_calendar_events_path(company)

    expect(page).to have_selector("table", wait: 10)
    expect(page).to have_selector("th", text: "Appointment")
    expect(page).to have_content("Extraction", wait: 10)
  end

  scenario "shows the assigned practitioner and room" do
    visit company_calendar_events_path(company)

    expect(page).to have_content("Dr. D", wait: 10)
    expect(page).to have_content("Surgery Room 1", wait: 10)
  end

  scenario "add button links to the booking form" do
    visit company_calendar_events_path(company)

    expect(page).to have_link(href: new_company_calendar_event_path(company), wait: 10)
  end

  scenario "event title links to the show page" do
    visit company_calendar_events_path(company)

    expect(page).to have_link(href: company_calendar_event_path(company, event), wait: 10)
  end

  scenario "offers a status transition for a pending booking" do
    visit company_calendar_events_path(company)

    expect(page).to have_button("Confirm", wait: 10)
  end

  scenario "searching narrows the list" do
    # Its own procedure, so the only "Extraction" on the page belongs to the
    # row that should be filtered out.
    other_procedure = create(:calendar_procedure, company: company, name: "Zaphod Whitening")
    create(:calendar_event, company: company, calendar_procedure: other_procedure, title: "Whitening")

    visit company_calendar_events_path(company)
    expect(page).to have_content("Zaphod Whitening", wait: 10)

    fill_in "Search appointments", with: "Zaphod"
    # The list reloads asynchronously, so the absence needs its own wait.
    expect(page).to have_no_content("Extraction", wait: 10)
    expect(page).to have_content("Zaphod Whitening", wait: 10)
  end

  scenario "shows an empty state when there is nothing booked" do
    CalendarEvent.destroy_all

    visit company_calendar_events_path(company)

    expect(page).to have_content("No appointments yet", wait: 10)
  end
end
