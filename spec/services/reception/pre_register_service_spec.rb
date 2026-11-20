# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reception::PreRegisterService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company, timezone: :utc) }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :reception) }
  let(:appointment) { BranchOperationAppointment.find_by!(company: company, branch: branch, operation: operation) }
  let(:host) { create(:employee, company: company, branch: branch, name: "Eleanor Vance") }
  let(:room) { create(:facility, company: company, branch: branch, name: "Boardroom Orion") }
  let(:now) { Time.utc(2026, 11, 20, 9, 0, 0) }

  def call(params)
    described_class.call(company: company, appointment: appointment, params: params, now: now)
  end

  it "saves a pending visit for a branch-local date and time" do
    result = call(
      name: "Jessica Tan", company: "Deloitte", date: "2026-11-21", start_time: "09:30",
      end_time: "10:30", host_id: host.id, facility_id: room.id, vip: "1"
    )

    expect(result[:success]).to be true
    event = result[:event]
    expect(event.workflow_status).to eq("pending")
    expect(event.start_at).to eq(Time.utc(2026, 11, 21, 9, 30))
    expect(event.end_at).to eq(Time.utc(2026, 11, 21, 10, 30))
    expect(event.metadata["reception_kind"]).to eq("visit")
    expect(event.metadata["visitor_kind"]).to eq("Pre-registered")
    expect(event.metadata["vip"]).to be(true)
    expect(event.metadata["pre_registered_at"]).to be_present
    expect(event.customer_event_appointments.first.customer.name).to eq("Jessica Tan")
    expect(event.employee_event_appointments.first.employee).to eq(host)
    expect(event.event_facility_appointments.first.facility).to eq(room)
  end

  it "defaults the end time to one hour after start" do
    result = call(name: "Jessica Tan", company: "Deloitte", date: "2026-11-21", start_time: "09:30")

    expect(result[:success]).to be true
    expect(result[:event].end_at).to eq(result[:event].start_at + 1.hour)
  end

  it "allows two pre-registrations in the same room and time" do
    first = call(name: "Jessica Tan", company: "Deloitte", date: "2026-11-21", start_time: "09:30", facility_id: room.id)
    second = call(name: "Arthur Pendelton", company: "Acme", date: "2026-11-21", start_time: "09:30", facility_id: room.id)

    expect(first[:success]).to be true
    expect(second[:success]).to be true
    expect(EventFacilityAppointment.where(facility: room, event: company.events).count).to eq(2)
  end

  it "is absent from today's queue and present tomorrow" do
    event = call(name: "Tomorrow Guest", company: "Acme", date: "2026-11-21", start_time: "09:30")[:event]

    today = Reception::ConsoleService.call(company: company, appointment: appointment, now: now)
    tomorrow = Reception::ConsoleService.call(company: company, appointment: appointment, now: Time.utc(2026, 11, 21, 8, 0, 0))

    expect(today[:visits].map { |row| row[:id] }).not_to include(event.id)
    expect(tomorrow[:visits].map { |row| row[:id] }).to include(event.id)
    expect(tomorrow[:counts][:expected]).to eq(1)
  end

  it "adds one expected visit and no lobby visit for today" do
    call(name: "Today Guest", company: "Acme", date: "2026-11-20", start_time: "15:00")

    payload = Reception::ConsoleService.call(company: company, appointment: appointment, now: now)

    expect(payload[:counts]).to include(expected: 1, lobby: 0, inside: 0, scheduled_today: 1)
  end

  it "requires a guest, company, date and start time" do
    expect(call(name: "", company: "Acme", date: "2026-11-21", start_time: "09:30")[:errors]).to contain_exactly("Guest name is required.")
    expect(call(name: "Jessica", company: "", date: "2026-11-21", start_time: "09:30")[:errors]).to contain_exactly("Company or organization is required.")
    expect(call(name: "Jessica", company: "Acme", date: "", start_time: "09:30")[:errors]).to contain_exactly("Date is required.")
    expect(call(name: "Jessica", company: "Acme", date: "2026-11-21", start_time: "")[:errors]).to contain_exactly("Start time is required.")
  end

  it "rejects an end time before the start time and persists nothing" do
    result = call(name: "Jessica", company: "Acme", date: "2026-11-21", start_time: "10:00", end_time: "09:00")

    expect(result[:success]).to be false
    expect(result[:errors]).to contain_exactly("End time must be after start time.")
    expect(Event.where(company: company).count).to eq(0)
  end
end
