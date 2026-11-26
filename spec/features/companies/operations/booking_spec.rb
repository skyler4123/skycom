# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Operations::Booking", type: :feature, js: true do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :education).tap(&:save!) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company, timezone: :utc, name: "Downtown Branch") }
  let(:operation_record) { create(:operation, company: company, branch: branch, operation_type: :booking) }
  let(:booking_path) { "/companies/#{company.id}/operations/booking/#{operation_record.id}?branch_id=#{branch.id}" }
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }

  let(:office_category) { Seed::CategoryService.create(company: company, name: "Office Space", resource_name: "facilities") }
  let(:storage_category) { Seed::CategoryService.create(company: company, name: "Storage Room", resource_name: "facilities") }
  let(:retail_category) { Seed::CategoryService.create(company: company, name: "Retail Floor", resource_name: "facilities") }
  let!(:empty_category) { Seed::CategoryService.create(company: company, name: "Parking Area", resource_name: "facilities") }

  let!(:office) do
    create(:facility, company: company, branch: branch, name: "Boardroom Orion", category: office_category,
      property_mapping: office_category.default_property_mapping, property_integer_1: 16)
  end
  let!(:store) do
    create(:facility, company: company, branch: branch, name: "Storage 3", category: storage_category,
      property_mapping: storage_category.default_property_mapping)
  end
  let!(:retail) do
    create(:facility, company: company, branch: branch, name: "Retail Floor 1", category: retail_category,
      property_mapping: retail_category.default_property_mapping)
  end
  let!(:host) { create(:employee, company: company, branch: branch, name: "Marcus Sterling") }
  let(:customer) { create(:customer, company: company, name: "Vanguard Capital") }

  def create_booking(name:, facility:, start_time:, end_time:, workflow_status: :confirmed, host: nil, customer: nil)
    event = create(:event, company: company, branch: branch, category: event_category,
      name: name, code: "BKG-#{SecureRandom.hex(3).upcase}",
      start_at: LocalTime.parse(LocalTime.today(branch), start_time, branch),
      end_at: LocalTime.parse(LocalTime.today(branch), end_time, branch),
      workflow_status: workflow_status)
    EventFacilityAppointment.create!(company: company, event: event, facility: facility)
    EmployeeEventAppointment.create!(company: company, event: event, employee: host) if host
    CustomerEventAppointment.create!(company: company, event: event, customer: customer) if customer
    event
  end

  def set_time(name, value)
    input = find("input[name=\"" + name + "\"]")
    page.execute_script(
      "arguments[0].value = arguments[1]; arguments[0].dispatchEvent(new Event('input', { bubbles: true })); arguments[0].dispatchEvent(new Event('change', { bubbles: true }))",
      input, value
    )
  end

  def create_booking_on(date:, name:, facility:, start_time:, end_time:)
    event = create(:event, company: company, branch: branch, category: event_category,
      name: name, start_at: LocalTime.parse(date, start_time, branch),
      end_at: LocalTime.parse(date + 1.day, end_time, branch), workflow_status: :confirmed)
    EventFacilityAppointment.create!(company: company, event: event, facility: facility)
    event
  end

  before do
    page.driver.browser.manage.window.resize_to(1400, 900)
    sign_in(owner)
  end

  after do
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "shows only real chrome, KPIs and categories" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      create_booking(name: "Current review", facility: office, start_time: "09:30", end_time: "10:30")
      create_booking(name: "Later storage", facility: store, start_time: "14:00", end_time: "15:00")
      create_booking(name: "Morning retail", facility: retail, start_time: "08:00", end_time: "09:00")

      visit booking_path

      expect(page).to have_content("Booking Operations Console", wait: 10)
      expect(page).to have_link("Bookings", href: booking_path)
      expect(page).to have_content("Skycom ERP · Booking")
      expect(page).to have_content(company.name)
      expect(page).to have_content("Day window 08:00–18:00")
      expect(page).to have_content("Spaces by type")
      expect(page.all('a[href="#"]')).to be_empty

      %w[Resource\ Directory Room\ Management Analytics\ &\ Usage Live\ Scheduling\ Engine
         Synced\ with\ live\ Event\ reservations Reception\ Console Floor\ 4 Zone\ A
         Claim\ Seat 10-Min\ No-Show\ Release Room\ List Desk\ Zones Release\ Unused
         Equipment\ Deployed Hot\ Desk\ Occupancy Check-In\ Room Ring\ Organizer
         v4.8 Skycom\ Enterprise\ Corp Zone\ B Micro-Pods].each do |copy|
        expect(page).to have_no_content(copy)
      end
      within("[data-booking-inspector]") do
        expect(page).to have_content("Select a booking")
        expect(page).to have_content("or lock a room with the form.")
        expect(page).to have_no_content("Idle")
      end

      within('[data-booking-kpi="bookings"]') do
        expect(page).to have_content("3")
        expect(page).to have_content("1 upcoming")
        expect(page).to have_content("1 in progress")
        expect(page).to have_content("1 done")
      end
      within('[data-booking-kpi="spaces"]') do
        expect(page).to have_content("1/3")
        expect(page).to have_content("33%")
      end

      expect(page).to have_css('[data-booking-category-kpi="Office Space"]', text: "1/1")
      expect(page).to have_css('[data-booking-category-kpi="Storage Room"]', text: "0/1")
      expect(page).to have_css('[data-booking-category-kpi="Retail Floor"]', text: "0/1")
      expect(page).to have_no_css('[data-booking-category-kpi="Parking Area"]')
      expect(page).to have_no_content("0/0")

      expect(page).to have_css('[data-booking-spaces-by-type="Office Space"]', text: "1 in use · 0 free")
      expect(page).to have_css('[data-booking-spaces-by-type="Storage Room"]', text: "0 in use · 1 free")
      expect(page).to have_no_css('[data-booking-spaces-by-type="Parking Area"]')
      expect(page).to have_no_content("Showing the first")

      click_link "Bookings"
      expect(page).to have_content("Booking Operations Console", wait: 10)
    end
  end

  scenario "shows an outside-window booking as a tag and omits the needle before eight" do
    travel_to Time.utc(2026, 11, 20, 5, 4, 0) do
      event = create_booking_on(date: LocalTime.today(branch), name: "Event 1-1 Procedure Booking",
        facility: retail, start_time: "23:50", end_time: "00:50")

      visit booking_path

      expect(page).to have_content("Booking Operations Console", wait: 10)
      row = find('[data-booking-row="' + retail.id + '"]')
      within(row) do
        expect(page).to have_content("1 booking outside this window")
        expect(page).to have_content("11:50 PM")
        expect(page).to have_no_content("Available all day")
        expect(page).to have_no_css('[data-booking-block][data-booking-id="' + event.id + '"]')
      end
      expect(page).to have_css('[data-booking-outside-tag][data-booking-id="' + event.id + '"]')
      expect(page).to have_no_css("[data-booking-now-needle]")

      find('[data-booking-outside-tag][data-booking-id="' + event.id + '"]').click

      within("[data-booking-inspector]") do
        expect(page).to have_content(/Selected booking/i)
        expect(page).to have_content("Event 1-1 Procedure Booking")
        expect(page).to have_content("Retail Floor 1")
        expect(page).to have_content("Retail Floor")
        expect(page).to have_content("11:50 PM – 12:50 AM")
        expect(page).to have_content("Upcoming")
      end
    end
  end

  scenario "draws the now needle inside the day window" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      create_booking(name: "Current review", facility: office, start_time: "09:30", end_time: "10:30")

      visit booking_path

      expect(page).to have_css("[data-booking-now-needle]", wait: 10)
      expect(page).to have_css("[data-booking-now-label]", text: "10:00 AM")

      # CSSOM normalizes the nested calc, so the browser may serialize the
      # equivalent position as 20.0001%. Compare the percentage, not the string.
      style = find("[data-booking-now-needle]")["style"]
      percent = style.scan(/(\d+(?:\.\d+)?)%/).flatten.first.to_f
      expect(percent).to be_within(0.01).of(20)
    end
  end


  scenario "omits the now needle after the day window" do
    travel_to Time.utc(2026, 11, 20, 19, 0, 0) do
      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)
      expect(page).to have_no_css("[data-booking-now-needle]")
    end
  end

  scenario "selects the booking the host clicks and keeps it on a background click" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      first = create_booking(name: "First booking", facility: office, start_time: "08:30", end_time: "09:30")
      second = create_booking(name: "Second booking", facility: store, start_time: "09:00", end_time: "10:00")

      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)

      find('[data-booking-block][data-booking-id="' + first.id + '"]').click
      within("[data-booking-inspector]") { expect(page).to have_content("First booking") }

      find('[data-booking-block][data-booking-id="' + second.id + '"]').click
      within("[data-booking-inspector]") { expect(page).to have_content("Second booking") }
      expect(page).to have_css('[data-booking-block][data-booking-id="' + second.id + '"][data-selected="true"]')

      find("h1").click
      within("[data-booking-inspector]") { expect(page).to have_content("Second booking") }
    end
  end

  scenario "refuses an overlapping reservation without losing the typed values" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      create_booking(name: "Existing booking", facility: office, start_time: "14:00", end_time: "15:00")

      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)

      fill_in "booking[title]", with: "Second host"
      select "Boardroom Orion — Office Space", from: "booking[facility_id]"
      fill_in "booking[start_time]", with: "14:30"
      fill_in "booking[end_time]", with: "15:30"
      click_button "Confirm & Lock Booking"

      expect(page).to have_css("[data-booking-form-error]", text: "Boardroom Orion is already booked 2:00 PM–3:00 PM.", wait: 5)
      expect(find('input[name="booking[title]"]').value).to eq("Second host")
      expect(find('input[name="booking[start_time]"]').value).to eq("14:30")
      expect(Event.find_by(company: company, name: "Second host")).to be_nil

      select "Storage 3 — Storage Room", from: "booking[facility_id]"
      expect(page).to have_css("[data-booking-form-error]", text: "", visible: :all)

      click_button "Confirm & Lock Booking"
      expect(page).to have_content("Reservation confirmed for Second host.", wait: 5)
      expect(Event.find_by(company: company, name: "Second host")).to be_present
    end
  end

  scenario "collects a real host and customer and shows them in the inspector" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      Customer.ms_clear_index!
      customer.ms_index!(true)

      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)

      fill_in "booking[title]", with: "Client workshop"
      select "Boardroom Orion — Office Space", from: "booking[facility_id]"
      select "Marcus Sterling", from: "booking[host_id]"
      fill_in "booking[customer_query]", with: "Vanguard"
      expect(page).to have_css("[data-booking-customer-result]", text: "Vanguard Capital", wait: 10)
      find("[data-booking-customer-result]", text: "Vanguard Capital").click
      fill_in "booking[start_time]", with: "14:00"
      fill_in "booking[end_time]", with: "15:00"
      click_button "Confirm & Lock Booking"

      expect(page).to have_content("Reservation confirmed for Client workshop.", wait: 5)
      within("[data-booking-inspector]") do
        expect(page).to have_content("Client workshop")
        expect(page).to have_content("Marcus Sterling")
        expect(page).to have_content("Vanguard Capital")
        expect(page).to have_content("Attendees")
        expect(page).to have_content("2")
      end
      expect(page).to have_css("[data-booking-upcoming-item]", text: "Client workshop")
      expect(find('input[name="booking[title]"]').value).to eq("")

      fill_in "booking[title]", with: "No host booking"
      select "Boardroom Orion — Office Space", from: "booking[facility_id]"
      fill_in "booking[start_time]", with: "16:00"
      fill_in "booking[end_time]", with: "17:00"
      click_button "Confirm & Lock Booking"
      expect(page).to have_content("Reservation confirmed for No host booking.", wait: 5)
      within("[data-booking-inspector]") do
        expect(page).to have_content("No host")
        expect(page).to have_content("No customer")
        expect(page).to have_content("0")
      end
      expect(page).to have_no_css('input[name="booking[host]"]')
    end
  end


  scenario "clears a selected customer back to no customer" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      Customer.ms_clear_index!
      customer.ms_index!(true)

      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)
      fill_in "booking[customer_query]", with: "Vanguard"
      expect(page).to have_css("[data-booking-customer-result]", text: "Vanguard Capital", wait: 10)
      find("[data-booking-customer-result]", text: "Vanguard Capital").click
      expect(find('input[name="booking[customer_id]"]', visible: :all).value).to eq(customer.id)

      find("[data-booking-customer-field] button[title='Clear customer']").click

      expect(find('input[name="booking[customer_id]"]', visible: :all).value).to eq("")
      expect(page).to have_field("booking[customer_query]", with: "")
    end
  end


  scenario "keeps a blank meeting name on the page with a specific message" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)

      select "Boardroom Orion — Office Space", from: "booking[facility_id]"
      fill_in "booking[start_time]", with: "14:00"
      fill_in "booking[end_time]", with: "15:00"
      click_button "Confirm & Lock Booking"

      expect(page).to have_content("Meeting / event name is required.", wait: 5)
      expect(Event.find_by(company: company, name: "")).to be_nil
      expect(page).to have_content("Booking Operations Console")
    end
  end

  scenario "quick room fills a fifteen-minute range and never creates a booking" do
    travel_to Time.utc(2026, 11, 20, 10, 7, 0) do
      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)
      count = Event.count

      click_button "15-Min Quick Room"

      expect(find('input[name="booking[start_time]"]').value).to eq("10:15")
      expect(find('input[name="booking[end_time]"]').value).to eq("10:30")
      expect(find('select[name="booking[facility_id]"]').value).to eq("")
      expect(find('select[name="booking[host_id]"]').value).to eq("")
      expect(page.evaluate_script("document.activeElement.name")).to eq("booking[title]")
      expect(Event.count).to eq(count)
    end
  end

  scenario "quick room falls back to eight when now is outside the day window" do
    travel_to Time.utc(2026, 11, 20, 5, 4, 0) do
      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)

      click_button "15-Min Quick Room"

      expect(find('input[name="booking[start_time]"]').value).to eq("08:00")
      expect(find('input[name="booking[end_time]"]').value).to eq("08:15")
      expect(page).to have_content("Starts at 08:00 — outside the day window the grid shows")
    end
  end

  scenario "extends a booking or explains the next booking" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      event = create_booking(name: "In progress", facility: office, start_time: "09:30", end_time: "11:00")
      create_booking(name: "Next booking", facility: office, start_time: "11:15", end_time: "12:00")

      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)
      find('[data-booking-block][data-booking-id="' + event.id + '"]').click
      click_button "Extend +30m"

      expect(page).to have_css("[data-booking-inspector]", text: "Next booking starts at 11:15 AM.", wait: 5)
      expect(event.reload.end_at).to eq(Time.utc(2026, 11, 20, 11, 0, 0))
    end
  end

  scenario "end and release frees the space immediately" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      event = create_booking(name: "In progress", facility: office, start_time: "09:30", end_time: "11:00")

      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)
      find('[data-booking-block][data-booking-id="' + event.id + '"]').click
      click_button "End & release"

      expect(page).to have_content("Booking ended. The space is free.", wait: 5)
      expect(event.reload.workflow_status).to eq("completed")
      expect(event.end_at).to eq(Time.utc(2026, 11, 20, 10, 0, 0))
      within('[data-booking-kpi="spaces"]') { expect(page).to have_content("0/3") }
      within("[data-booking-inspector]") { expect(page).to have_content("Done") }

      fill_in "booking[title]", with: "Replacement booking"
      select "Boardroom Orion — Office Space", from: "booking[facility_id]"
      set_time("booking[start_time]", "10:15")
      set_time("booking[end_time]", "11:00")
      click_button "Confirm & Lock Booking"
      expect(page).to have_content("Reservation confirmed for Replacement booking.", wait: 5)
    end
  end

  scenario "cancel confirms, frees the space and lets it be booked again" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      event = create_booking(name: "To cancel", facility: office, start_time: "14:00", end_time: "15:00")

      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)
      find('[data-booking-block][data-booking-id="' + event.id + '"]').click
      click_button "Cancel booking"

      within("[data-booking-inspector]") do
        expect(page).to have_content("Cancel this booking?")
        click_button "Keep"
      end
      expect(event.reload.workflow_status).to eq("confirmed")

      click_button "Cancel booking"
      within("[data-booking-inspector]") { click_button "Cancel booking" }
      expect(page).to have_content("Booking cancelled. The space can be booked again.", wait: 5)
      expect(event.reload.workflow_status).to eq("cancelled")
      expect(page).to have_no_css('[data-booking-block][data-booking-id="' + event.id + '"]')
      within('[data-booking-kpi="bookings"]') { expect(page).to have_content("0") }

      fill_in "booking[title]", with: "Rebooked"
      select "Boardroom Orion — Office Space", from: "booking[facility_id]"
      fill_in "booking[start_time]", with: "14:00"
      fill_in "booking[end_time]", with: "15:00"
      click_button "Confirm & Lock Booking"
      expect(page).to have_content("Reservation confirmed for Rebooked.", wait: 5)
    end
  end

  scenario "prints a run sheet with the day in time order" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      create_booking(name: "Morning booking", facility: office, start_time: "08:30", end_time: "09:30",
        host: host, customer: customer)
      create_booking(name: "Evening booking", facility: store, start_time: "14:00", end_time: "15:00")

      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)
      page.execute_script("window.__printed = false; window.print = () => { window.__printed = true }")
      click_button "Daily run sheet"

      expect(page.evaluate_script("window.__printed")).to be(true)
      sheet = find("[data-booking-run-sheet]", visible: :all)
      expect(sheet.text(:all)).to include("Downtown Branch")
      expect(sheet.text(:all)).to include("Morning booking")
      expect(sheet.text(:all)).to include("Evening booking")
      text = sheet.text(:all)
      expect(text.index("Morning booking")).to be < text.index("Evening booking")
      expect(sheet.text(:all)).to include("Marcus Sterling")
      expect(sheet.text(:all)).to include("Vanguard Capital")
      expect(sheet.text(:all)).not_to include("Spaces in use")
    end
  end


  scenario "moves the end with extend and shows the new time" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      event = create_booking(name: "In progress", facility: office, start_time: "09:30", end_time: "11:00")

      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)
      find('[data-booking-block][data-booking-id="' + event.id + '"]').click
      click_button "Extend +30m"

      expect(page).to have_content("Booking extended by 30 minutes.", wait: 5)
      expect(event.reload.end_at).to eq(Time.utc(2026, 11, 20, 11, 30, 0))
      within("[data-booking-inspector]") do
        expect(page).to have_content("11:30 AM")
        expect(page).to have_content(event.code)
        expect(page).to have_content("Guest check-in is in Reception.")
      end
    end
  end

  scenario "moves through days and filters the real spaces" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)

      click_button "Storage Room (1)"
      expect(page).to have_no_css('[data-booking-row="' + office.id + '"]')
      expect(page).to have_css('[data-booking-row="' + store.id + '"]')

      click_button "All spaces (3)"
      expect(page).to have_css('[data-booking-row="' + office.id + '"]')

      find("[title='Next day']").click
      expect(page).to have_content("Saturday, Nov 21, 2026", wait: 10)
      find("[title='Previous day']").click
      expect(page).to have_content("Friday, Nov 20, 2026", wait: 10)
      click_button "Today"
      expect(page).to have_content("Friday, Nov 20, 2026", wait: 10)
    end
  end

  scenario "focuses the meeting name from New Reservation" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)

      click_button "New Reservation"

      expect(page.evaluate_script("document.activeElement.name")).to eq("booking[title]")
    end
  end

  scenario "cancels an upcoming check-in without pretending to check in" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      event = create_booking(name: "Tonight review", facility: office, start_time: "14:00", end_time: "15:00")

      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)
      within('[data-booking-upcoming-item="' + event.id + '"]') do
        expect(page).to have_content("Boardroom Orion")
        expect(page).to have_no_content("Check In Now")
        click_button "Cancel"
      end

      within('[data-booking-upcoming-item="' + event.id + '"]') do
        expect(page).to have_content("Cancel this booking?")
        click_button "Cancel booking"
      end

      expect(page).to have_content("Booking cancelled. The space can be booked again.", wait: 5)
      expect(event.reload.workflow_status).to eq("cancelled")
      expect(page).to have_no_css('[data-booking-upcoming-item="' + event.id + '"]')
    end
  end

  scenario "rejects an end before the start without losing the page" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)

      fill_in "booking[title]", with: "Backwards"
      select "Boardroom Orion — Office Space", from: "booking[facility_id]"
      fill_in "booking[start_time]", with: "15:00"
      fill_in "booking[end_time]", with: "14:00"
      click_button "Confirm & Lock Booking"

      expect(page).to have_css("[data-booking-form-error]", text: "End time must be after start time.", wait: 5)
      expect(Event.find_by(company: company, name: "Backwards")).to be_nil
      expect(find('input[name="booking[title]"]').value).to eq("Backwards")
    end
  end

  scenario "prints No bookings for an empty day" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)
      page.execute_script("window.__printed = false; window.print = () => { window.__printed = true }")
      click_button "Daily run sheet"

      expect(page.evaluate_script("window.__printed")).to be(true)
      expect(find("[data-booking-run-sheet]", visible: :all).text(:all)).to include("No bookings")
    end
  end


  scenario "clips a booking that starts before the day window" do
    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      event = create_booking(name: "Early booking", facility: office, start_time: "07:00", end_time: "09:00")

      visit booking_path
      expect(page).to have_content("Booking Operations Console", wait: 10)

      block = find('[data-booking-block][data-booking-id="' + event.id + '"]')
      expect(block["style"]).to include("left: 0%")
      expect(block["style"]).to include("width: 10%")
      expect(page).to have_no_css('[data-booking-outside-tag][data-booking-id="' + event.id + '"]')
    end
  end

  scenario "labels capped lists without shrinking the counts" do
    stub_const("BOOKING_DAY_BOOKING_LIMIT", 1)
    stub_const("BOOKING_FACILITY_LIMIT", 1)
    stub_const("BOOKING_HOST_LIMIT", 1)

    travel_to Time.utc(2026, 11, 20, 10, 0, 0) do
      create_booking(name: "Second facility", facility: store, start_time: "14:00", end_time: "15:00")
      create_booking(name: "First facility", facility: office, start_time: "15:00", end_time: "16:00")
      create(:employee, company: company, branch: branch, name: "Second Host")

      visit booking_path

      expect(page).to have_content("Showing the first 1 bookings for this day.", wait: 10)
      expect(page).to have_content("Showing the first 1.")
      within('[data-booking-kpi="bookings"]') { expect(page).to have_content("2") }
      within('[data-booking-kpi="spaces"]') { expect(page).to have_content("0/3") }
    end
  end
end
