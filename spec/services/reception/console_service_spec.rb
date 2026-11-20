# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reception::ConsoleService, type: :service do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :education).tap(&:save!) }
  let(:branch) { create(:branch, company: company, name: "Downtown", timezone: :utc) }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :reception) }
  let(:appointment) { operation.branch_operation_appointments.find_by!(branch: branch) }
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let(:host) { create(:employee, company: company, branch: branch, name: "Eleanor Vance") }
  let(:now) { Time.utc(2026, 11, 17, 12, 0, 0) }

  def create_visit(customer_name:, start_at:, status: :confirmed, metadata: {}, host_record: host)
    customer = create(:customer, company: company, name: customer_name)
    event = create(:event, company: company, branch: branch, category: event_category,
      name: "Visit · #{customer_name} · #{SecureRandom.hex(2)}", start_at: start_at, end_at: start_at + 1.hour,
      workflow_status: status, metadata: { "reception_kind" => "visit" }.merge(metadata))
    CustomerEventAppointment.create!(company: company, event: event, customer: customer)
    EmployeeEventAppointment.create!(company: company, event: event, employee: host_record) if host_record
    event
  end

  def create_booking(name:, start_at:, facility: nil)
    event = create(:event, company: company, branch: branch, category: event_category,
      name: name, start_at: start_at, end_at: start_at + 1.hour, workflow_status: :pending)
    EventFacilityAppointment.create!(company: company, event: event, facility: facility) if facility
    event
  end

  it "only counts guest-linked visits and keeps non-visit bookings in appointments" do
    room = create(:facility, company: company, branch: branch, name: "Boardroom Orion")
    expected = create_visit(customer_name: "Expected Guest", start_at: now + 30.minutes, status: :pending)
    lobby = create_visit(customer_name: "Lobby Guest", start_at: now - 10.minutes,
      metadata: { "lobby_entered_at" => (now - 5.minutes).iso8601 })
    inside = create_visit(customer_name: "Inside Guest", start_at: now - 30.minutes, status: :in_progress,
      metadata: { "inside_at" => (now - 3.minutes).iso8601 })
    departed = create_visit(customer_name: "Departed Guest", start_at: now - 2.hours, status: :completed,
      metadata: { "checked_out_at" => (now - 1.hour).iso8601 })
    booking = create_booking(name: "Boardroom booking", start_at: now + 1.hour, facility: room)

    payload = described_class.call(company: company, appointment: appointment, now: now)

    expect(payload[:visits].map { |row| row[:id] }).to contain_exactly(expected.id, lobby.id, inside.id, departed.id)
    expect(payload[:visits].map { |row| row[:id] }).not_to include(booking.id)
    expect(payload[:appointments].map { |row| row[:id] }).to contain_exactly(booking.id)
    expect(payload[:counts]).to include(
      expected: 1, lobby: 1, inside: 1, departed: 1, scheduled_today: 4
    )
    expect(payload[:counts][:average_wait_minutes]).to eq(5.0)
    expect(payload[:visits].find { |row| row[:id] == lobby.id }[:wait_minutes]).to eq(5)
    expect(payload[:visits].find { |row| row[:id] == inside.id }[:inside_minutes]).to eq(3)
  end

  it "shows Expected 0 and scheduled today 4 when four guests are already in the lobby" do
    4.times do |index|
      create_visit(customer_name: "Lobby Guest #{index}", start_at: now - 10.minutes,
        metadata: { "lobby_entered_at" => now.iso8601 })
    end

    payload = described_class.call(company: company, appointment: appointment, now: now)

    expect(payload[:counts]).to include(lobby: 4, expected: 0, scheduled_today: 4)
  end

  it "returns ISO timestamps instead of server-formatted clock strings" do
    visit_event = create_visit(customer_name: "Arthur Pendelton", start_at: Time.utc(2026, 11, 17, 2, 0, 0))

    payload = described_class.call(company: company, appointment: appointment, now: Time.utc(2026, 11, 17, 2, 5, 0))

    arrival = payload[:visits].find { |visitor| visitor[:id] == visit_event.id }[:arrival_at]
    expect(arrival).to eq("2026-11-17T02:00:00Z")
    expect(payload[:visits].map { |visitor| visitor[:arrival_at] }).to all(match(/Z\z/))
  end

  it "returns the check-in stamp as ISO instead of a formatted clock" do
    visit_event = create_visit(
      customer_name: "Maya Lindqvist",
      start_at: Time.utc(2026, 11, 17, 1, 30, 0),
      status: :in_progress,
      metadata: { "checked_in_at" => "2026-11-17T01:35:00Z" }
    )

    payload = described_class.call(company: company, appointment: appointment, now: Time.utc(2026, 11, 17, 2, 0, 0))

    visitor = payload[:visits].find { |row| row[:id] == visit_event.id }
    expect(visitor[:inside_at]).to eq("2026-11-17T01:35:00Z")
    expect(visitor[:inside_minutes]).to eq(25)
  end

  it "uses the branch calendar day for the visit queue" do
    branch.update!(timezone: :plus_7)
    # 01:00 on 18 Nov at UTC+7 is 18:00Z on 17 Nov. The branch day is 18 Nov.
    late_local_visit = create_visit(
      customer_name: "Late Local",
      start_at: Time.utc(2026, 11, 17, 17, 30, 0),
      status: :pending
    )
    previous_local_day = create_visit(
      customer_name: "Previous Local Day",
      start_at: Time.utc(2026, 11, 17, 16, 30, 0),
      status: :pending
    )

    payload = described_class.call(company: company, appointment: appointment, now: Time.utc(2026, 11, 17, 18, 0, 0))

    ids = payload[:visits].map { |visitor| visitor[:id] }
    expect(ids).to include(late_local_visit.id)
    expect(ids).not_to include(previous_local_day.id)
  end

  it "shows a room only from real facility events and omits locker data from parcels" do
    room = create(:facility, company: company, branch: branch, name: "Boardroom Orion")
    create_booking(name: "Room booking", start_at: now - 5.minutes, facility: room)
    parcel = create(:event, company: company, branch: branch, category: event_category,
      name: "Parcel TEST", code: "PKG-TEST", start_at: now, workflow_status: :received,
      metadata: { "reception_kind" => "parcel", "carrier" => "DHL", "item" => "Legal documents",
                  "recipient_name" => host.name })
    EmployeeEventAppointment.create!(company: company, event: parcel, employee: host)

    payload = described_class.call(company: company, appointment: appointment, now: now)

    room_row = payload[:rooms].find { |row| row[:id] == room.id }
    expect(room_row[:status]).to eq("reserved")
    expect(payload[:counts][:parcels]).to eq(1)
    expect(payload[:parcels].first).not_to have_key(:locker)
  end

  it "returns the current employee's scheduled shift only when it covers now" do
    template = create(:shift_template, company: company, branch: branch, name: "Morning")
    shift = create(:scheduled_shift, company: company, branch: branch, employee: host)
    shift.update!(shift_template: template, work_date: now.to_date,
      expected_start_at: now - 1.hour, expected_end_at: now + 1.hour)

    payload = described_class.call(company: company, appointment: appointment, employee: host, now: now)
    expect(payload[:shift]).to include(name: "Morning")
    expect(payload[:shift][:start_at]).to be_present

    shift.update!(expected_end_at: now - 30.minutes)
    payload = described_class.call(company: company, appointment: appointment, employee: host, now: now)
    expect(payload[:shift]).to be_nil
  end
end
