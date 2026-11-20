# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reception::AdvanceService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :reception) }
  let(:appointment) { BranchOperationAppointment.find_by!(company: company, branch: branch, operation: operation) }
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }

  def create_event(status, metadata: {})
    event = create(:event, company: company, branch: branch, name: "Visit #{SecureRandom.hex(3)}",
      start_at: 30.minutes.ago, end_at: 30.minutes.from_now,
      workflow_status: status, metadata: { "reception_kind" => "visit" }.merge(metadata))
    customer = create(:customer, company: company, name: "Guest #{SecureRandom.hex(3)}")
    CustomerEventAppointment.create!(company: company, event: event, customer: customer)
    event
  end

  it "arrives an expected visit and stamps lobby_entered_at" do
    event = create_event(:pending)

    result = described_class.call(
      company: company,
      appointment: appointment,
      params: { event_id: event.id, transition: "arrive" }
    )

    expect(result[:success]).to be true
    expect(event.reload.workflow_status).to eq("confirmed")
    expect(event.metadata["lobby_entered_at"]).to be_present
  end

  it "marks a lobby visit inside and stamps inside_at" do
    event = create_event(:confirmed)

    result = described_class.call(
      company: company,
      appointment: appointment,
      params: { event_id: event.id, transition: "mark_inside" }
    )

    expect(result[:success]).to be true
    expect(event.reload.workflow_status).to eq("in_progress")
    expect(event.metadata["inside_at"]).to be_present
  end

  it "checks an inside visit out and stamps checked_out_at" do
    event = create_event(:in_progress)

    result = described_class.call(
      company: company,
      appointment: appointment,
      params: { event_id: event.id, transition: "check_out" }
    )

    expect(result[:success]).to be true
    expect(event.reload.workflow_status).to eq("completed")
    expect(event.metadata["checked_out_at"]).to be_present
  end

  it "reopens a completed visit inside and clears checked_out_at" do
    event = create_event(:completed, metadata: { "checked_out_at" => 5.minutes.ago.iso8601 })

    result = described_class.call(
      company: company,
      appointment: appointment,
      params: { event_id: event.id, transition: "reopen" }
    )

    expect(result[:success]).to be true
    expect(event.reload.workflow_status).to eq("in_progress")
    expect(event.metadata["checked_out_at"]).to be_nil
    expect(event.metadata["inside_at"]).to be_present
  end

  it "rejects an unknown transition without touching the Event" do
    event = create_event(:confirmed)

    result = described_class.call(
      company: company,
      appointment: appointment,
      params: { event_id: event.id, transition: "teleport" }
    )

    expect(result[:success]).to be false
    expect(result[:errors]).to contain_exactly("Unknown reception action.")
    expect(event.reload.workflow_status).to eq("confirmed")
  end

  it "rejects a parcel Event" do
    parcel = create(:event, company: company, branch: branch, name: "Parcel #{SecureRandom.hex(2)}",
      start_at: 30.minutes.ago, end_at: 30.minutes.from_now, workflow_status: :received,
      metadata: { "reception_kind" => "parcel" })

    result = described_class.call(
      company: company,
      appointment: appointment,
      params: { event_id: parcel.id, transition: "arrive" }
    )

    expect(result[:success]).to be false
    expect(result[:errors]).to contain_exactly("This is not a reception visit.")
    expect(parcel.reload.workflow_status).to eq("received")
  end

  it "rejects a visit Event without a linked guest" do
    event = create(:event, company: company, branch: branch, name: "Booking #{SecureRandom.hex(2)}",
      start_at: 30.minutes.ago, end_at: 30.minutes.from_now, workflow_status: :pending,
      metadata: { "reception_kind" => "visit" })

    result = described_class.call(
      company: company,
      appointment: appointment,
      params: { event_id: event.id, transition: "arrive" }
    )

    expect(result[:success]).to be false
    expect(result[:errors]).to contain_exactly("This is not a reception visit.")
  end
end
