require "rails_helper"

RSpec.feature "Companies::Calendars Index", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:procedure) { create(:calendar_procedure, company: company) }

  # Mid-month at 10:00 local. A boundary slot (1st / last day, midnight) is a
  # poor fixture here because the grid builds its range from the BROWSER's
  # timezone; the month-edge behaviour is covered by the request spec instead.
  let(:slot) { Date.current.in_time_zone.change(month: Date.current.month, day: 15, hour: 10, min: 0) }

  let!(:event) do
    create(:calendar_event, company: company, calendar_procedure: procedure,
      title: "Tooth Extraction", starts_at: slot, ends_at: slot + 60.minutes, status: :confirmed)
  end

  before do
    sign_in(owner)
    seed_client_cache!
  end

  def seed_client_cache!
    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => [],
      "table_configs" => [],
      "categories" => [],
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    payload = {
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "renders the board with the calendar grid" do
    visit company_calendars_path(company)

    expect(page).to have_content("Calendar Board", wait: 10)
    # The shared `calendar` Stimulus controller is mounted with the board's own
    # range endpoint as its api-url.
    expect(page).to have_selector("[data-controller='calendar']", wait: 10)
    expect(page).to have_selector("[data-calendar-api-url-value]", wait: 10)
  end

  scenario "draws the seeded booking on the grid" do
    visit company_calendars_path(company)

    expect(page).to have_content("Tooth Extraction", wait: 15)
  end

  scenario "offers view switchers and navigation" do
    visit company_calendars_path(company)

    within("[data-controller='calendar']", visible: :all) do
      expect(page).to have_button("Month", wait: 10)
      expect(page).to have_button("Week", visible: :all)
      expect(page).to have_button("Day", visible: :all)
    end
  end

  scenario "links to the booking form" do
    visit company_calendars_path(company)

    expect(page).to have_link(href: new_company_calendar_event_path(company), wait: 10)
  end

  scenario "hides a cancelled booking from the grid" do
    event.update!(status: :cancelled)

    visit company_calendars_path(company)

    expect(page).to have_selector("[data-controller='calendar']", wait: 10)
    expect(page).to have_no_content("Tooth Extraction")
  end
end
