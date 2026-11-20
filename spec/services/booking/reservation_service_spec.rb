# frozen_string_literal: true

require "rails_helper"

RSpec.describe Booking::ReservationService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company, timezone: :utc) }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :booking) }
  let(:appointment) { BranchOperationAppointment.find_by!(operation: operation, branch: branch) }
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let(:category) { Seed::CategoryService.create(company: company, name: "Office Space", resource_name: "facilities") }
  let(:room) do
    create(:facility, company: company, branch: branch, name: "Boardroom Orion",
      category: category, property_mapping: category.default_property_mapping)
  end
  let(:date) { Date.new(2026, 11, 20) }
  let(:host) { create(:employee, company: company, branch: branch, name: "Marcus Sterling") }
  let(:customer) { create(:customer, company: company, name: "Vanguard Capital") }

  def existing_booking(name:, start_time:, end_time:, workflow_status: :confirmed)
    event = create(:event, company: company, branch: branch, category: event_category,
      name: name,
      start_at: LocalTime.parse(date, start_time, branch),
      end_at: LocalTime.parse(date, end_time, branch),
      workflow_status: workflow_status)
    EventFacilityAppointment.create!(company: company, event: event, facility: room)
    event
  end

  def call(params)
    described_class.call(company: company, appointment: appointment, params: params, date: date)
  end

  def params(overrides = {})
    {
      title: "Quarterly Review",
      facility_id: room.id,
      start_time: "14:00",
      end_time: "15:00"
    }.merge(overrides)
  end

  it "creates the reservation with the chosen host and customer" do
    result = call(params(host_id: host.id, customer_id: customer.id))

    expect(result[:success]).to be(true)
    event = result[:event]
    expect(event.name).to eq("Quarterly Review")
    expect(event.business_type).to eq("reservation")
    expect(event.workflow_status).to eq("confirmed")
    expect(event.facilities).to contain_exactly(room)
    expect(event.employees).to contain_exactly(host)
    expect(event.customers).to contain_exactly(customer)
    expect(event.start_at).to eq(LocalTime.parse(date, "14:00", branch))
    expect(event.end_at).to eq(LocalTime.parse(date, "15:00", branch))
  end

  it "refuses an overlapping booking and names the facility and time" do
    first = existing_booking(name: "Existing", start_time: "11:50", end_time: "12:50")
    original_start = first.start_at
    original_end = first.end_at

    result = call(params(title: "Second Host", start_time: "12:00", end_time: "13:00"))

    expect(result[:success]).to be(false)
    expect(result[:errors]).to eq([ "Boardroom Orion is already booked 11:50 AM–12:50 PM." ])
    expect(Event.find_by(company: company, name: "Second Host")).to be_nil
    expect(first.reload.start_at).to eq(original_start)
    expect(first.reload.end_at).to eq(original_end)
  end

  it "allows a back-to-back booking" do
    existing_booking(name: "Existing", start_time: "11:00", end_time: "12:00")

    result = call(params(start_time: "12:00", end_time: "13:00"))

    expect(result[:success]).to be(true)
  end

  it "does not let cancelled or completed bookings block the space" do
    existing_booking(name: "Cancelled", start_time: "09:00", end_time: "10:00", workflow_status: :cancelled)
    existing_booking(name: "Completed", start_time: "10:00", end_time: "11:00", workflow_status: :completed)

    result = call(params(start_time: "09:30", end_time: "10:30"))

    expect(result[:success]).to be(true)
  end

  it "rejects an unknown host or customer" do
    host_result = call(params(host_id: SecureRandom.uuid))
    customer_result = call(params(title: "Other", customer_id: SecureRandom.uuid))

    expect(host_result[:success]).to be(false)
    expect(host_result[:errors]).to eq([ "Host not found." ])
    expect(customer_result[:success]).to be(false)
    expect(customer_result[:errors]).to eq([ "Customer not found." ])
  end

  it "rejects a blank title, a missing space and a backwards time window" do
    expect(call(params(title: " "))[:errors]).to eq([ "Meeting / event name is required." ])
    expect(call(params(facility_id: nil))[:errors]).to eq([ "Select a space for this reservation." ])
    expect(call(params(start_time: "15:00", end_time: "14:00"))[:errors])
      .to eq([ "End time must be after start time." ])
  end
end
