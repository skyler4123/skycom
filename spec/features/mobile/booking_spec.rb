# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Booking", type: :feature, js: true do
  let(:company) { create(:company).tap { |record| record.update!(timezone: :utc) } }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company, name: "Downtown Branch") }
  let!(:operation_record) do
    create(:operation, company: company, branch: branch, name: "Booking Desk", operation_type: :booking)
  end
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let(:host) { create(:employee, company: company, branch: branch, name: "Marcus Sterling") }
  let(:room) { create(:facility, company: company, branch: branch, name: "Boardroom Orion", property_integer_1: 16) }
  let(:booking_path) do
    "/mobile/companies/#{company.id}/operations/booking/#{operation_record.id}?branch_id=#{branch.id}"
  end

  # The console renders the branch-local day and its fixed 08:00–18:00 window.
  # Sign in before freezing so the session cookie keeps a real-time expiry,
  # then pin the branch clock so the booking always lands inside the window.
  before do
    sign_in(user)
    travel_to(Time.utc(2026, 11, 20, 10, 0, 0))

    customer = create(:customer, company: company, name: "Vanguard Capital")
    event = create(:event, company: company, branch: branch, category: event_category,
      name: "Executive Board Review", code: "BKG-EXEC",
      start_at: LocalTime.parse(LocalTime.today(branch), "09:00", branch),
      end_at: LocalTime.parse(LocalTime.today(branch), "11:00", branch), workflow_status: :confirmed)
    CustomerEventAppointment.create!(company: company, event: event, customer: customer)
    EmployeeEventAppointment.create!(company: company, event: event, employee: host)
    EventFacilityAppointment.create!(company: company, event: event, facility: room)
  end

  after { travel_back }

  scenario "loads the booking console in the mobile shell" do
    visit booking_path

    expect(page).to have_content("Booking Operations Console", wait: 10)
    expect(page).to have_content("Boardroom Orion")
    expect(page).to have_content("Executive Board Review")
    expect(page).to have_content("Day window 08:00–18:00")
  end

  scenario "opens booking from the mobile operations list" do
    visit mobile_company_operations_path(company)

    click_link "Open Booking"

    expect(page).to have_current_path(booking_path, wait: 10)
    expect(page).to have_content("Booking Operations Console", wait: 10)
  end

  scenario "stacks the inspector panels under the timeline in portrait" do
    page.driver.browser.manage.window.resize_to(768, 1024)
    visit booking_path

    expect(page).to have_content("Booking Operations Console", wait: 10)
    timeline = find("section", text: /Day window/i)
    panels = find("aside")

    expect(panels.native.rect.y).to be > timeline.native.rect.y
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "shows the inspector panels beside the timeline on a landscape tablet" do
    page.driver.browser.manage.window.resize_to(1280, 800)
    visit booking_path

    expect(page).to have_content("Booking Operations Console", wait: 10)
    timeline = find("section", text: /Day window/i)
    panels = find("aside")

    expect(panels.native.rect.x).to be > timeline.native.rect.x
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end
end
