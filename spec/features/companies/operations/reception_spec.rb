# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Operations::Reception", type: :feature, js: true do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :education).tap(&:save!) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company, timezone: :utc, name: "Downtown") }
  let(:operation_record) { create(:operation, company: company, branch: branch, operation_type: :reception) }
  let(:reception_path) { "/companies/#{company.id}/operations/reception/#{operation_record.id}?branch_id=#{branch.id}" }
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let(:host) { create(:employee, company: company, branch: branch, name: "Eleanor Vance") }
  let(:second_host) { create(:employee, company: company, branch: branch, name: "David Chen") }
  let(:room) { create(:facility, company: company, branch: branch, name: "Boardroom Orion") }
  let(:quiet_room) { create(:facility, company: company, branch: branch, name: "Aurora Pod 1") }

  before do
    sign_in(owner)
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  def create_visit(customer_name:, status:, start_at:, host_record: host, facility: nil, code: "VIS-#{SecureRandom.hex(2).upcase}", metadata: {})
    customer = create(:customer, company: company, name: customer_name,
      description: "Vanguard Global Capital")
    event = create(:event, company: company, branch: branch, category: event_category,
      name: "Visit · #{customer_name} · #{SecureRandom.hex(2)}", code: code, start_at: start_at,
      end_at: start_at + 1.hour, workflow_status: status,
      metadata: { "reception_kind" => "visit", "visitor_company" => "Vanguard Global Capital" }.merge(metadata))
    CustomerEventAppointment.create!(company: company, event: event, customer: customer)
    EmployeeEventAppointment.create!(company: company, event: event, employee: host_record) if host_record
    EventFacilityAppointment.create!(company: company, event: event, facility: facility) if facility
    event
  end

  def create_booking(name:, start_at:, facility:)
    event = create(:event, company: company, branch: branch, category: event_category,
      name: name, start_at: start_at, end_at: start_at + 1.hour, workflow_status: :pending)
    EventFacilityAppointment.create!(company: company, event: event, facility: facility)
    event
  end

  def kpi_value(key)
    find(%([data-reception-kpi="#{key}"] .text-3xl)).text
  end

  scenario "renders one honest page with real counts and no fake terminal chrome" do
    create_visit(customer_name: "Arthur Pendelton", status: :confirmed, start_at: 10.minutes.ago,
      facility: room, metadata: { "lobby_entered_at" => 5.minutes.ago.iso8601 })
    create_visit(customer_name: "Camila Gomez", status: :confirmed, start_at: 4.minutes.ago, host_record: second_host,
      metadata: { "lobby_entered_at" => 5.minutes.ago.iso8601 })
    create_visit(customer_name: "Maya Lindqvist", status: :in_progress, start_at: 30.minutes.ago,
      host_record: second_host, facility: quiet_room, metadata: { "inside_at" => 3.minutes.ago.iso8601 })
    create_visit(customer_name: "Sarah Miller", status: :pending, start_at: 30.minutes.from_now)
    create_visit(customer_name: "Nora Past", status: :completed, start_at: 2.hours.ago,
      metadata: { "checked_out_at" => 1.hour.ago.iso8601 })
    create_booking(name: "Boardroom planning", start_at: 1.hour.from_now, facility: room)

    visit reception_path

    expect(page).to have_content("Skycom Reception", wait: 10)
    expect(page).to have_content(company.name)
    expect(page).to have_content("Downtown · Reception")
    expect(page).to have_content("Skycom · Reception · #{company.name}")

    expect(kpi_value("inside")).to eq("1")
    expect(kpi_value("lobby")).to eq("2")
    expect(kpi_value("expected")).to eq("1")
    expect(kpi_value("parcels")).to eq("0")
    expect(kpi_value("rooms")).to eq("0")
    expect(page).to have_content("5 scheduled today")
    expect(page).to have_content("Avg wait: 5 mins")

    expect(page).to have_css("[data-reception-tab='lobby']", text: "In lobby (2)")
    expect(page).to have_css("[data-reception-tab='active']", text: "Inside (1)")
    expect(page).to have_css("[data-reception-tab='upcoming']", text: "Expected (1)")
    expect(page).to have_css("[data-reception-tab='departed']", text: "Departed (1)")

    find("[data-reception-tab='active']").click
    expect(page).to have_content("Maya Lindqvist")
    find("button[title='Waiting guests in lobby']").click
    expect(page).to have_content("Arthur Pendelton")

    %w[FrontDesk Hospitality Valet Concierge Turnstile Terminal\ Active Terminal\ Operational
       Desk\ Station Locker lockers\ available Locker\ capacity VOIP PA\ System Test\ Chime
       Speed\ Dial Manage\ key Issue\ Temp\ Badge Density Auto-sync Visitor\ Log Security\ &\ Badges
       Appointments\ &\ Rooms Deliveries\ &\ Packages scan\ waybill SMS adhesive Access\ Level
       Emergency broadcast].each do |copy|
      expect(page).not_to have_content(copy)
    end
    expect(page).not_to have_content("coming soon")
    expect(page).to have_content("Updated")
  end

  scenario "renders honest empty states when the branch has no activity" do
    visit reception_path

    expect(page).to have_content("No visitors match this view.", wait: 10)
    expect(page).to have_content("No parcels waiting at the desk.")
    expect(page).to have_content("No appointments today.")
    expect(page).to have_content("No rooms configured for this branch.")
    expect(kpi_value("inside")).to eq("0")
    expect(kpi_value("lobby")).to eq("0")
    expect(kpi_value("expected")).to eq("0")
    expect(kpi_value("parcels")).to eq("0")
    expect(kpi_value("rooms")).to eq("0")
  end

  scenario "checks in a walk-in with no host or room as a lobby card" do
    visit reception_path
    expect(page).to have_content("Downtown · Reception", wait: 10)

    click_button "Walk-in check-in"
    expect(page).to have_content("Creates a lobby visit", wait: 5)
    click_button "Check in to lobby"
    expect(page).to have_content("Guest name is required.", wait: 5)
    find("button[title='Close']").click
    expect(page).to have_no_content("Creates a lobby visit")
    click_button "Walk-in check-in"
    find('input[name="visitor[name]"]').set("Jessica Tan")
    find('input[name="visitor[company]"]').set("Deloitte Consulting")
    find('input[name="visitor[vip]"]').check
    click_button "Check in to lobby"

    expect(page).to have_content("Walk-in check-in complete for Jessica Tan", wait: 5)
    within("[data-reception-visitor]", text: "Jessica Tan") do
      expect(page).to have_content("No host")
      expect(page).to have_content("No room")
      expect(page).to have_button("No host to notify", disabled: true)
      expect(page).to have_css("[title='VIP Client']")
    end
    expect(kpi_value("lobby")).to eq("1")
    expect(page).not_to have_content("SMS")
    expect(page).not_to have_content("adhesive")

    event = Event.where(company: company).order(:created_at).to_a
      .find { |candidate| candidate.name.start_with?("Walk-in · Jessica Tan") }
    expect(event.metadata["reception_kind"]).to eq("visit")
    expect(event.metadata["lobby_entered_at"]).to be_present
    expect(event.metadata).not_to have_key("notify_host")
  end

  scenario "pre-registers tomorrow's guest and arrives them into the lobby tomorrow" do
    tomorrow = (Date.current + 1).iso8601
    visit reception_path
    expect(page).to have_content("Downtown · Reception", wait: 10)

    click_button "Pre-register"
    expect(page).to have_content("Saves an expected visit", wait: 5)
    click_button "Save pre-registration"
    expect(page).to have_content("Guest name is required.", wait: 5)
    find("button[title='Close']").click
    expect(page).to have_no_content("Saves an expected visit")
    click_button "Pre-register"
    find('input[name="pre_registration[name]"]').set("Tomorrow Guest")
    find('input[name="pre_registration[company]"]').set("Acme")
    page.execute_script("document.querySelector('input[name=\"pre_registration[date]\"]').value = arguments[0]", tomorrow)
    expect(find('input[name="pre_registration[date]"]').value).to eq(tomorrow)
    find('input[name="pre_registration[start_time]"]').set("09:30")
    click_button "Save pre-registration"

    expect(page).to have_content("Pre-registration saved for Tomorrow Guest", wait: 5)
    expect(page).not_to have_css("[data-reception-visitor]", text: "Tomorrow Guest")
    expect(kpi_value("expected")).to eq("0")
    pre_registration = Event.where(company: company).where("name LIKE ?", "Pre-registration · Tomorrow Guest%").first
    expect(pre_registration.start_at.to_date).to eq(Date.current + 1)

    travel_to((Date.current + 1).in_time_zone.change(hour: 8)) do
      sign_in(owner)
      visit reception_path
      expect(page).to have_css("[data-reception-tab='upcoming']", text: "Expected (1)", wait: 10)
      find("[data-reception-tab='upcoming']").click
      expect(page).to have_content("Tomorrow Guest", wait: 10)

      within("[data-reception-visitor]", text: "Tomorrow Guest") do
        click_button "They've arrived"
      end

      expect(page).to have_content("has arrived and is waiting in the lobby", wait: 5)
      event = Event.where(company: company).where("name LIKE ?", "Pre-registration · Tomorrow Guest%").first
      expect(event.reload.workflow_status).to eq("confirmed")
      expect(event.metadata["lobby_entered_at"]).to be_present
    end
  end

  scenario "moves one visit through every queue state and button" do
    event = create_visit(customer_name: "Sarah Miller", status: :pending, start_at: 30.minutes.from_now)

    visit reception_path
    expect(page).to have_css("[data-reception-tab='upcoming']", text: "Expected (1)", wait: 10)
    find("[data-reception-tab='upcoming']").click
    expect(page).to have_content("Sarah Miller", wait: 10)

    within("[data-reception-visitor]", text: "Sarah Miller") do
      expect(page).to have_button("Notify host")
      click_button "They've arrived"
    end
    expect(page).to have_content("has arrived and is waiting in the lobby", wait: 5)
    expect(kpi_value("expected")).to eq("0")
    expect(kpi_value("lobby")).to eq("1")
    find("[data-reception-tab='lobby']").click
    within("[data-reception-visitor]", text: "Sarah Miller") { click_button "Mark inside" }
    expect(page).to have_content("is now inside the building", wait: 5)
    expect(kpi_value("lobby")).to eq("0")
    expect(kpi_value("inside")).to eq("1")
    find("[data-reception-tab='active']").click
    within("[data-reception-visitor]", text: "Sarah Miller") do
      expect(page).to have_css("button[title='Print visitor badge']")
      click_button "Check out"
    end
    expect(page).to have_content("has checked out", wait: 5)
    expect(kpi_value("inside")).to eq("0")
    expect(page).to have_css("[data-reception-tab='departed']", text: "Departed (1)")
    find("[data-reception-tab='departed']").click
    within("[data-reception-visitor]", text: "Sarah Miller") { click_button "Reopen" }
    expect(page).to have_content("was re-opened inside the building", wait: 5)
    expect(page).to have_css("[data-reception-tab='departed']", text: "Departed (0)")
    expect(kpi_value("inside")).to eq("1")
    find("[data-reception-tab='active']").click
    expect(page).to have_content("Sarah Miller")
    expect(event.reload.workflow_status).to eq("in_progress")
  end

  scenario "notifies the host, records the timestamp and notifies again" do
    event = create_visit(customer_name: "Arthur Pendelton", status: :confirmed, start_at: 10.minutes.ago)

    visit reception_path
    expect(page).to have_content("Arthur Pendelton", wait: 10)

    within("[data-reception-visitor]", text: "Arthur Pendelton") { click_button "Notify host" }
    expect(page).to have_content("Host notified for Arthur Pendelton", wait: 5)
    within("[data-reception-visitor]", text: "Arthur Pendelton") do
      expect(page).to have_content("Notified")
      click_button "Notify again"
    end
    expect(page).to have_content("Host notified for Arthur Pendelton", wait: 5)

    expect(event.reload.metadata["host_notified_at"]).to be_present
    expect(Notification.where(recipient_employee: host).count).to eq(2)
  end

  scenario "prints only the selected visit badge" do
    event = create_visit(customer_name: "Arthur Pendelton", status: :confirmed, start_at: 10.minutes.ago,
      facility: room, metadata: { "lobby_entered_at" => 5.minutes.ago.iso8601 })

    visit reception_path
    expect(page).to have_content("Arthur Pendelton", wait: 10)
    page.execute_script("window.__receptionPrintCalls = 0; window.print = () => { window.__receptionPrintCalls += 1 }")
    find("button[title='Print visitor badge']").click
    expect(page.evaluate_script("window.__receptionPrintCalls")).to eq(1)

    badge = page.evaluate_script("document.getElementById('reception-badge-print').textContent")
    expect(badge).to include(company.name)
    expect(badge).to include("Visitor")
    expect(badge).to include("Arthur Pendelton")
    expect(badge).to include("Vanguard Global Capital")
    expect(badge).to include("Eleanor Vance")
    expect(badge).to include("Boardroom Orion")
    expect(badge).to include("Downtown")
    expect(badge).to include(event.code)
    expect(badge).not_to include("QR")
    expect(badge).not_to include("photo")
    expect(page.evaluate_script("window.__receptionPrintCalls")).to eq(1)
    expect(page).not_to have_content("sent to the printer")
    expect(event.reload.workflow_status).to eq("confirmed")
  end

  scenario "logs, notifies, notifies again and picks up a parcel" do
    host
    visit reception_path
    expect(page).to have_content("Parcels held", wait: 10)

    find("[data-reception-open-parcel]").click
    expect(page).to have_content("Item summary", wait: 5)
    click_button "Save delivery"
    expect(page).to have_content("Carrier is required.", wait: 5)
    find("[data-reception-cancel-parcel]").click
    expect(page).to have_no_content("Item summary")
    find("[data-reception-open-parcel]").click
    find('input[name="parcel[carrier]"]').set("UPS")
    find('select[name="parcel[employee_id]"]').find("option[value='#{host.id}']").select_option
    find('input[name="parcel[item]"]').set("Passport envelope")
    click_button "Save delivery"

    expect(page).to have_content("Parcel logged for Eleanor Vance", wait: 5)
    expect(page).to have_content("Passport envelope")
    expect(kpi_value("parcels")).to eq("1")
    expect(page).not_to have_content("locker")

    click_button "Notify"
    expect(page).to have_content("Pickup notification sent for Eleanor Vance", wait: 5)
    expect(page).to have_content("Notified")
    parcel = Event.where(company: company).where("metadata ->> 'reception_kind' = ?", "parcel").last
    expect(parcel.workflow_status).to eq("received")
    expect(Notification.where(recipient_employee: host).count).to eq(1)

    click_button "Notify again"
    expect(page).to have_content("Pickup notification sent for Eleanor Vance", wait: 5)
    expect(Notification.where(recipient_employee: host).count).to eq(2)

    find("button[title='Mark picked up']").click
    expect(page).to have_content("Parcel marked as picked up by Eleanor Vance", wait: 5)
    expect(kpi_value("parcels")).to eq("0")
    expect(parcel.reload.workflow_status).to eq("completed")
  end

  scenario "shows every room and appointment with working Show all controls" do
    company.facilities.destroy_all
    room_category = Category.create!(company: company, resource_name: "facilities", name: "Meeting Room")
    10.times do |index|
      create(:facility, company: company, branch: branch, category: room_category, name: "Room #{format("%02d", index + 1)}")
    end
    rooms = company.facilities.order(:name).to_a
    7.times do |index|
      create_booking(name: "Booking #{index + 1}", start_at: (index + 1).hours.from_now, facility: rooms[index])
    end

    visit reception_path
    expect(page).to have_content("Room 01", wait: 10)
    expect(page).to have_content("Showing 8 of 10")
    expect(page).to have_no_content("Room 10")
    find("[data-reception-show-rooms]").click
    expect(page).to have_content("Room 10", wait: 5)
    find("[data-reception-show-rooms]").click
    expect(page).to have_no_content("Room 10")

    expect(page).to have_content("Show all 7 appointments")
    expect(page).to have_content("Booking 5")
    expect(page).not_to have_content("Booking 6")
    find("[data-reception-show-appointments]").click
    expect(page).to have_content("Booking 7", wait: 5)
    find("[data-reception-show-appointments]").click
    expect(page).to have_no_content("Booking 7")
    expect(page).not_to have_content("coming soon")
    expect(kpi_value("expected")).to eq("0")
    expect(kpi_value("lobby")).to eq("0")
  end

  scenario "jumps across visits and parcels and keeps the queue filter local" do
    create_visit(customer_name: "Arthur Pendelton", status: :confirmed, start_at: 10.minutes.ago)
    create_visit(customer_name: "Camila Gomez", status: :confirmed, start_at: 5.minutes.ago)
    parcel = create(:event, company: company, branch: branch, category: event_category,
      name: "Parcel TEST", code: "PKG-TEST", start_at: Time.current, workflow_status: :received,
      metadata: { "reception_kind" => "parcel", "carrier" => "DHL", "item" => "Passport envelope",
                  "recipient_name" => host.name })
    EmployeeEventAppointment.create!(company: company, event: parcel, employee: host)

    visit reception_path
    expect(page).to have_content("Arthur Pendelton", wait: 10)

    fill_in "reception-quick-search", with: "Arthur"
    expect(page).to have_css("[data-reception-search-result='visit']", text: "Arthur Pendelton")
    first("[data-reception-search-result='visit']").click
    expect(page).to have_css("[data-reception-visitor]", text: "Arthur Pendelton")

    fill_in "reception-quick-search", with: "Passport"
    expect(page).to have_css("[data-reception-search-result='parcel']", text: "Passport envelope")
    first("[data-reception-search-result='parcel']").click
    expect(page).to have_content("Passport envelope")

    fill_in "reception-filter-input", with: "Arthur"
    expect(page).to have_content("Arthur Pendelton")
    expect(page).not_to have_content("Camila Gomez")
    expect(kpi_value("lobby")).to eq("2")
    find("[data-reception-tab='active']").click
    expect(page).not_to have_content("Arthur Pendelton")
  end

  scenario "polls without clearing an open form or the queue filter" do
    create_visit(customer_name: "Arthur Pendelton", status: :confirmed, start_at: 10.minutes.ago)
    visit reception_path
    expect(page).to have_content("Arthur Pendelton", wait: 10)

    click_button "Walk-in check-in"
    find('input[name="visitor[name]"]').set("Draft Guest")
    fill_in "reception-filter-input", with: "Session"

    create_visit(customer_name: "New Session Guest", status: :confirmed, start_at: 2.minutes.ago)
    page.execute_script("window.dispatchEvent(new CustomEvent('reception:poll'))")

    expect(page).to have_content("New Session Guest", wait: 10)
    expect(find('input[name="visitor[name]"]').value).to eq("Draft Guest")
    expect(find("#reception-filter-input").value).to eq("Session")
    expect(page).to have_content("Updated")
    interval = page.evaluate_script("Stimulus.getControllerForElementAndIdentifier(document.querySelector('[data-controller*=\"companies--operations--reception--show\"]'), 'companies--operations--reception--show').pollInterval")
    expect(interval).to eq(20000)
  end

  scenario "shows the shift pill only when a real scheduled shift covers now" do
    visit reception_path
    expect(page).to have_content("Downtown · Reception", wait: 10)
    expect(page).not_to have_content("Shift:")

    template = create(:shift_template, company: company, branch: branch, name: "Morning")
    owner_employee = company.employees.find_by(business_type: "owner")
    shift = create(:scheduled_shift, company: company, branch: branch, employee: owner_employee)
    shift.update!(shift_template: template, work_date: Time.current.to_date,
      expected_start_at: 1.hour.ago, expected_end_at: 1.hour.from_now)

    visit reception_path
    expect(page).to have_content("Shift: Morning", wait: 10)
  end

  scenario "shows lobby wait and inside timers from their real stamps" do
    create_visit(customer_name: "Arthur Pendelton", status: :confirmed, start_at: 30.minutes.ago,
      metadata: { "lobby_entered_at" => 5.minutes.ago.iso8601 })
    create_visit(customer_name: "Maya Lindqvist", status: :in_progress, start_at: 30.minutes.ago,
      host_record: second_host, metadata: { "inside_at" => 3.minutes.ago.iso8601 })

    visit reception_path
    expect(page).to have_content("Waiting 5 mins", wait: 10)
    expect(page).to have_content("Avg wait: 5 mins")
    find("[data-reception-tab='active']").click
    expect(page).to have_content("Inside 3 mins")
  end

  scenario "says Just arrived when the average lobby wait is under a minute" do
    create_visit(customer_name: "Just Now", status: :confirmed, start_at: 10.minutes.ago,
      metadata: { "lobby_entered_at" => Time.current.iso8601 })

    visit reception_path
    expect(page).to have_content("Just arrived", wait: 10)
    expect(page).not_to have_content("Avg wait: 0 mins")
  end
end
