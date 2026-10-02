require "rails_helper"

RSpec.feature "Companies::Calendar Board", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }

  let!(:default_category) do
    Seed::CategoryService.find_or_create_for(company: company, resource_name: "events")
  end

  let!(:event) do
    create(:event, company: company, category: default_category,
      name: "Board Event #{SecureRandom.hex(4)}",
      start_at: 2.days.from_now.change(hour: 10), end_at: 2.days.from_now.change(hour: 11))
  end

  before do
    sign_in(owner)
    seed_event_client_cache(company: company, owner: owner, enums: event_enums_payload)
  end

  scenario "board loads with month view and event chips" do
    visit company_calendar_path(company)

    expect(page).to have_content(event.name, wait: 10)
    expect(page).to have_button("Month")
    expect(page).to have_button("Week")
    expect(page).to have_button("Day")
  end

  scenario "switching to week view keeps event chips" do
    visit company_calendar_path(company)
    expect(page).to have_content(event.name, wait: 10)

    click_button "Week"

    expect(page).to have_content(event.name, wait: 10)
  end

  scenario "clicking a day opens the create modal with prefilled times" do
    visit company_calendar_path(company)
    expect(page).to have_content(event.name, wait: 10)

    day_cell = find("[data-date]", match: :first)
    day_cell.click

    expect(page).to have_selector('input[name="event[name]"]', wait: 10)
    start_value = page.find('input[name="event[start_at]"]').value
    expect(start_value).to be_present
  end
end
