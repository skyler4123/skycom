require "rails_helper"

RSpec.feature "Companies::CalendarEvents New", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let!(:position) { create(:calendar_position, company: company, name: "Dentist") }
  let!(:procedure) do
    create(:calendar_procedure, company: company, calendar_position: position,
      name: "Tooth Extraction", duration_minutes: 60, requires_location: true)
  end
  let!(:practitioner) { create(:calendar_practitioner, company: company, calendar_position: position, name: "Dr. D") }
  let!(:location) { create(:calendar_location, company: company, name: "Surgery Room 1") }

  before do
    sign_in(owner)
    seed_client_cache!
  end

  # Selenium's fill_in types into datetime-local's segmented control and mangles
  # the value; assigning .value directly is reliable. Events are then set by
  # clicking the real submit button so the form engine still dispatches
  # form:success.
  def set_window(starts_at, ends_at)
    page.execute_script(<<~JS, starts_at, ends_at)
      const form = document.querySelector("form");
      form.querySelector('[name="calendar_event[starts_at]"]').value = arguments[0];
      form.querySelector('[name="calendar_event[ends_at]"]').value = arguments[1];
    JS
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

  scenario "renders the booking form with the resource pickers" do
    visit new_company_calendar_event_path(company)

    expect(page).to have_content("New Appointment", wait: 10)
    expect(page).to have_field("Procedure", wait: 10)
    expect(page).to have_field("Starts At", wait: 10)
    expect(page).to have_field("Ends At", wait: 10)
    expect(page).to have_field("Practitioners", visible: :all, wait: 10)
    expect(page).to have_field("Room / Location", wait: 10)
    # The pickers are populated from the `options` payload.
    expect(page).to have_selector(
      "select[name='calendar_event[calendar_procedure_id]'] option", text: "Tooth Extraction", wait: 10)
    expect(page).to have_selector(
      "select[name='practitioner_ids[]'] option", text: "Dr. D", visible: :all, wait: 10)
  end

  scenario "books an appointment" do
    visit new_company_calendar_event_path(company)

    select procedure.name, from: "Procedure"
    select practitioner.name, from: "Practitioners"
    select location.name, from: "Room / Location"
    set_window("2030-01-15T10:00", "2030-01-15T11:00")

    click_button "Book Appointment"

    # The controller reloads the appointments list on success; wait for it, then
    # assert what the server actually stored.
    expect(page).to have_content("Appointments", wait: 10)
    expect(CalendarEvent.count).to eq(1)
    event = CalendarEvent.last
    expect(event.calendar_procedure).to eq(procedure)
    expect(event.calendar_practitioners).to include(practitioner)
    expect(event.calendar_locations).to include(location)
    # The first pick becomes the lead.
    expect(event.calendar_event_practitioners.first.role).to eq("lead")
  end

  scenario "flags a double-booked room before submitting" do
    # An existing booking that already holds the room in the chosen window.
    starts = Time.zone.parse("2030-01-15T10:00")
    existing = create(:calendar_event, company: company, calendar_procedure: procedure,
      starts_at: starts, ends_at: starts + 60.minutes, status: :confirmed)
    create(:calendar_event_location, calendar_event: existing, calendar_location: location, company: company)

    visit new_company_calendar_event_path(company)

    select procedure.name, from: "Procedure"
    select location.name, from: "Room / Location"
    set_window("2030-01-15T10:30", "2030-01-15T11:30")
    click_button "Check availability"

    expect(page).to have_content("Scheduling conflict", wait: 10)
    expect(page).to have_content("already booked", wait: 10)
  end

  scenario "reports no conflict for a free window" do
    visit new_company_calendar_event_path(company)

    select procedure.name, from: "Procedure"
    select location.name, from: "Room / Location"
    set_window("2030-01-15T10:00", "2030-01-15T11:00")
    click_button "Check availability"

    expect(page).to have_no_content("Scheduling conflict", wait: 10)
  end
end
