# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Operations::Booking", type: :feature, js: true do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :education).tap(&:save!) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }
  let(:operation_record) { create(:operation, company: company, branch: branch, operation_type: :booking) }
  let(:booking_path) { "/companies/#{company.id}/operations/booking/#{operation_record.id}?branch_id=#{branch.id}" }
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let(:host) { create(:employee, company: company, branch: branch, name: "Marcus Sterling") }
  let(:room) { create(:facility, company: company, branch: branch, name: "Boardroom Orion", property_integer_1: 16) }
  let!(:pod) { create(:facility, company: company, branch: branch, name: "Aurora Pod 1", property_integer_1: 2) }

  let!(:booking_event) do
    customer = create(:customer, company: company, name: "Vanguard Capital")
    event = create(:event, company: company, branch: branch, category: event_category,
      name: "Executive Board Review", code: "BKG-EXEC", start_at: Time.current.change(hour: 9, min: 0),
      end_at: Time.current.change(hour: 11, min: 0), workflow_status: :confirmed)

    CustomerEventAppointment.create!(company: company, event: event, customer: customer)
    EmployeeEventAppointment.create!(company: company, event: event, employee: host)
    EventFacilityAppointment.create!(company: company, event: event, facility: room)
    event
  end

  before { sign_in(owner) }

  scenario "loads the real facility timeline and booking blocks" do
    visit booking_path

    expect(page).to have_content("Booking Operations Console", wait: 10)
    expect(page).to have_content("Boardroom Orion")
    expect(page).to have_content("Aurora Pod 1")
    expect(page).to have_content("Executive Board Review")
    expect(page).to have_content("Vanguard Capital")
    expect(page).to have_content("Day Timeline Grid")
    expect(page).to have_content("New Reservation")
    expect(page).to have_css("[data-booking-now-needle]")
    expect(page).to have_css("[data-booking-block]", text: "Executive Board Review")
  end

  scenario "keeps the current-time needle visible while rendering dynamic rows" do
    visit booking_path

    expect(page).to have_content("Booking Operations Console", wait: 10)
    expect(page).to have_css("[data-booking-now-needle]")
    expect(page).to have_css("[data-booking-now-label]", text: /(AM|PM)/)
  end

  scenario "creates a reservation from the instant reservation form" do
    visit booking_path
    expect(page).to have_content("Booking Operations Console", wait: 10)

    find('input[name="booking[title]"]').set("Q4 Planning Session")
    find('select[name="booking[facility_id]"]').find("option[value='#{pod.id}']").select_option
    find('input[name="booking[start_time]"]').set("14:00")
    find('input[name="booking[end_time]"]').set("15:00")
    click_button "Confirm & Lock Booking"

    expect(page).to have_content("Reservation confirmed for Q4 Planning Session.", wait: 5)
    expect(page).to have_content("Q4 Planning Session")

    event = Event.find_by(company: company, name: "Q4 Planning Session")
    expect(event).to be_present
    expect(event.workflow_status).to eq("confirmed")
    expect(event.facilities).to include(pod)
  end

  scenario "rejects a reservation whose end time is before its start time" do
    visit booking_path
    expect(page).to have_content("Booking Operations Console", wait: 10)

    find('input[name="booking[title]"]').set("Invalid Window")
    find('select[name="booking[facility_id]"]').find("option[value='#{pod.id}']").select_option
    find('input[name="booking[start_time]"]').set("15:00")
    find('input[name="booking[end_time]"]').set("14:00")
    click_button "Confirm & Lock Booking"

    expect(page).to have_content("End time must be after start time.", wait: 5)
    expect(Event.find_by(company: company, name: "Invalid Window")).to be_nil
  end
end
