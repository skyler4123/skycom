# frozen_string_literal: true

require "rails_helper"

RSpec.describe Booking::ConsoleService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company, timezone: :utc) }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :booking) }
  let(:appointment) { BranchOperationAppointment.find_by!(operation: operation, branch: branch) }
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let(:now) { Time.utc(2026, 11, 20, 10, 0, 0) }
  let(:date) { Date.new(2026, 11, 20) }

  def facility_category(name)
    Seed::CategoryService.create(company: company, name: name, resource_name: "facilities")
  end

  def facility(name:, category:)
    create(:facility, company: company, branch: branch, name: name, category: category,
      property_mapping: category.default_property_mapping)
  end

  def event(name:, facility:, start_at:, end_at:, workflow_status: :confirmed)
    record = create(:event, company: company, branch: branch, category: event_category,
      name: name, start_at: start_at, end_at: end_at, workflow_status: workflow_status)
    EventFacilityAppointment.create!(company: company, event: record, facility: facility)
    record
  end

  def call
    described_class.call(company: company, appointment: appointment, now: now, date: date)
  end

  it "returns the server now and the fixed day window" do
    payload = call

    expect(payload[:now]).to eq("2026-11-20T10:00:00Z")
    expect(payload[:timeline]).to eq(start_hour: 8, end_hour: 18)
  end

  it "includes a booking that starts the previous day but touches this day" do
    office = facility_category("Office Space")
    room = facility(name: "Boardroom", category: office)
    record = event(name: "Overnight", facility: room,
      start_at: Time.utc(2026, 11, 19, 23, 0, 0), end_at: Time.utc(2026, 11, 20, 1, 0, 0))

    payload = call

    expect(payload[:bookings].map { |booking| booking[:id] }).to include(record.id)
  end

  it "derives upcoming, in progress and done statuses from the server clock" do
    office = facility_category("Office Space")
    room = facility(name: "Boardroom", category: office)
    upcoming = event(name: "Upcoming", facility: room,
      start_at: Time.utc(2026, 11, 20, 14, 0, 0), end_at: Time.utc(2026, 11, 20, 15, 0, 0))
    current = event(name: "Current", facility: room,
      start_at: Time.utc(2026, 11, 20, 9, 30, 0), end_at: Time.utc(2026, 11, 20, 10, 30, 0))
    done = event(name: "Done", facility: room,
      start_at: Time.utc(2026, 11, 20, 8, 0, 0), end_at: Time.utc(2026, 11, 20, 9, 0, 0))

    payload = call
    by_id = payload[:bookings].index_by { |booking| booking[:id] }

    expect(by_id[upcoming.id][:status]).to eq("upcoming")
    expect(by_id[current.id][:status]).to eq("in_progress")
    expect(by_id[done.id][:status]).to eq("done")
    expect(payload[:counts]).to include(total_bookings: 3, upcoming: 1, in_progress: 1, done: 1)
  end

  it "marks only facilities with an in-progress booking as in use and groups real categories" do
    office = facility_category("Office Space")
    storage = facility_category("Storage Room")
    busy_room = facility(name: "Boardroom", category: office)
    free_room = facility(name: "Office 2", category: office)
    store = facility(name: "Store", category: storage)
    event(name: "Current", facility: busy_room,
      start_at: Time.utc(2026, 11, 20, 9, 30, 0), end_at: Time.utc(2026, 11, 20, 10, 30, 0))

    payload = call
    resources = payload[:resources].index_by { |resource| resource[:id] }
    categories = payload[:counts][:categories].index_by { |category| category[:name] }

    expect(resources[busy_room.id][:in_use]).to be(true)
    expect(resources[free_room.id][:in_use]).to be(false)
    expect(resources[store.id][:in_use]).to be(false)
    expect(payload[:counts]).to include(spaces_total: 3, spaces_in_use: 1, utilization: 33)
    expect(categories["Office Space"]).to include(total: 2, in_use: 1, free: 1)
    expect(categories["Storage Room"]).to include(total: 1, in_use: 0, free: 1)
  end

  it "does not invent a category for a facility without one or count cancelled bookings" do
    office = facility_category("Office Space")
    room = facility(name: "Boardroom", category: office)
    event(name: "Cancelled", facility: room,
      start_at: Time.utc(2026, 11, 20, 9, 30, 0), end_at: Time.utc(2026, 11, 20, 10, 30, 0),
      workflow_status: :cancelled)

    payload = call

    expect(payload[:bookings]).to be_empty
    expect(payload[:counts][:total_bookings]).to eq(0)
    expect(payload[:counts][:categories].map { |category| category[:name] }).to eq([ "Office Space" ])
  end

  it "returns only the next five upcoming bookings while counting all of them" do
    office = facility_category("Office Space")
    room = facility(name: "Boardroom", category: office)
    6.times do |index|
      event(name: "Upcoming #{index}", facility: room,
        start_at: Time.utc(2026, 11, 20, 14 + index, 0, 0),
        end_at: Time.utc(2026, 11, 20, 14 + index, 30, 0))
    end

    payload = call

    expect(payload[:counts][:upcoming]).to eq(6)
    expect(payload[:upcoming].length).to eq(5)
  end

  it "labels capped bookings and resources while keeping full counts" do
    stub_const("BOOKING_DAY_BOOKING_LIMIT", 1)
    stub_const("BOOKING_FACILITY_LIMIT", 1)
    office = facility_category("Office Space")
    first = facility(name: "Boardroom", category: office)
    second = facility(name: "Office 2", category: office)
    event(name: "First", facility: first,
      start_at: Time.utc(2026, 11, 20, 14, 0, 0), end_at: Time.utc(2026, 11, 20, 15, 0, 0))
    event(name: "Second", facility: second,
      start_at: Time.utc(2026, 11, 20, 16, 0, 0), end_at: Time.utc(2026, 11, 20, 17, 0, 0))

    payload = call

    expect(payload[:bookings].length).to eq(1)
    expect(payload[:resources].length).to eq(1)
    expect(payload[:counts][:total_bookings]).to eq(2)
    expect(payload[:counts][:spaces_total]).to eq(2)
    expect(payload[:caps][:bookings]).to include(capped: true, limit: 1)
    expect(payload[:caps][:resources]).to include(capped: true, limit: 1)
  end
end
