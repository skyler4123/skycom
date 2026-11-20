# frozen_string_literal: true

require "rails_helper"

RSpec.describe Booking::ExtendService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company, timezone: :utc) }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :booking) }
  let(:appointment) { BranchOperationAppointment.find_by!(operation: operation, branch: branch) }
  let(:category) { Seed::CategoryService.create(company: company, name: "Office Space", resource_name: "facilities") }
  let(:room) do
    create(:facility, company: company, branch: branch, name: "Boardroom Orion",
      category: category, property_mapping: category.default_property_mapping)
  end
  let(:now) { Time.utc(2026, 11, 20, 10, 0, 0) }
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }

  def booking(name:, start_time:, end_time:)
    record = create(:event, company: company, branch: branch, category: event_category,
      name: name, start_at: LocalTime.parse(Date.new(2026, 11, 20), start_time, branch),
      end_at: LocalTime.parse(Date.new(2026, 11, 20), end_time, branch), workflow_status: :confirmed)
    EventFacilityAppointment.create!(company: company, event: record, facility: room)
    record
  end

  def call(event)
    described_class.call(company: company, appointment: appointment, event_id: event.id, now: now)
  end

  it "moves the end thirty minutes later" do
    event = booking(name: "Session", start_time: "10:00", end_time: "11:00")

    result = call(event)

    expect(result[:success]).to be(true)
    expect(event.reload.end_at).to eq(Time.utc(2026, 11, 20, 11, 30, 0))
    expect(result[:message]).to eq("Booking extended by 30 minutes.")
  end

  it "refuses to overlap the next booking and names its start" do
    event = booking(name: "Session", start_time: "10:00", end_time: "11:00")
    booking(name: "Next", start_time: "11:15", end_time: "12:00")

    result = call(event)

    expect(result[:success]).to be(false)
    expect(result[:errors]).to eq([ "Next booking starts at 11:15 AM." ])
    expect(event.reload.end_at).to eq(Time.utc(2026, 11, 20, 11, 0, 0))
  end

  it "refuses to extend a closed booking" do
    event = booking(name: "Session", start_time: "10:00", end_time: "11:00")
    event.update!(workflow_status: :completed)

    result = call(event)

    expect(result[:success]).to be(false)
    expect(result[:errors]).to eq([ "This booking is already closed." ])
  end
end

RSpec.describe Booking::FinishService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company, timezone: :utc) }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :booking) }
  let(:appointment) { BranchOperationAppointment.find_by!(operation: operation, branch: branch) }
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let(:now) { Time.utc(2026, 11, 20, 10, 0, 0) }

  def booking(name:, start_time:, end_time:, workflow_status: :confirmed)
    create(:event, company: company, branch: branch, category: event_category,
      name: name, start_at: LocalTime.parse(Date.new(2026, 11, 20), start_time, branch),
      end_at: LocalTime.parse(Date.new(2026, 11, 20), end_time, branch), workflow_status: workflow_status)
  end

  def call(event)
    described_class.call(company: company, appointment: appointment, event_id: event.id, now: now)
  end

  it "sets an in-progress booking to done and ends it now" do
    event = booking(name: "Current", start_time: "09:30", end_time: "11:00")

    result = call(event)

    expect(result[:success]).to be(true)
    expect(event.reload.workflow_status).to eq("completed")
    expect(event.end_at).to eq(now)
    expect(result[:message]).to eq("Booking ended. The space is free.")
  end

  it "marks an upcoming booking done without rewriting its end" do
    event = booking(name: "Tonight", start_time: "14:00", end_time: "15:00")
    original_end = event.end_at

    result = call(event)

    expect(result[:success]).to be(true)
    expect(event.reload.workflow_status).to eq("completed")
    expect(event.end_at).to eq(original_end)
  end

  it "refuses a cancelled booking" do
    event = booking(name: "Cancelled", start_time: "14:00", end_time: "15:00", workflow_status: :cancelled)

    result = call(event)

    expect(result[:success]).to be(false)
    expect(result[:errors]).to eq([ "This booking is already closed." ])
  end
end

RSpec.describe Booking::CancelService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company, timezone: :utc) }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :booking) }
  let(:appointment) { BranchOperationAppointment.find_by!(operation: operation, branch: branch) }
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let(:now) { Time.utc(2026, 11, 20, 10, 0, 0) }

  def booking(name:)
    create(:event, company: company, branch: branch, category: event_category,
      name: name, start_at: LocalTime.parse(Date.new(2026, 11, 20), "14:00", branch),
      end_at: LocalTime.parse(Date.new(2026, 11, 20), "15:00", branch), workflow_status: :confirmed)
  end

  it "cancels the booking and frees its time" do
    event = booking(name: "Cancelled")

    result = described_class.call(company: company, appointment: appointment, event_id: event.id, now: now)

    expect(result[:success]).to be(true)
    expect(event.reload.workflow_status).to eq("cancelled")
    expect(result[:message]).to eq("Booking cancelled. The space can be booked again.")
  end

  it "refuses a completed booking" do
    event = booking(name: "Done")
    event.update!(workflow_status: :completed)

    result = described_class.call(company: company, appointment: appointment, event_id: event.id, now: now)

    expect(result[:success]).to be(false)
    expect(result[:errors]).to eq([ "This booking is already closed." ])
  end
end
