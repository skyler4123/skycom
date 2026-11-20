# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reception::ParcelService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :reception) }
  let(:appointment) { BranchOperationAppointment.find_by!(company: company, branch: branch, operation: operation) }
  let(:recipient) { create(:employee, company: company, branch: branch, name: "Eleanor Vance") }
  let(:now) { Time.utc(2026, 11, 20, 9, 0, 0) }

  def create_parcel
    described_class.create(
      company: company,
      appointment: appointment,
      params: { carrier: "DHL", item: "Legal documents", employee_id: recipient.id },
      now: now
    )
  end

  it "creates a held parcel without a locker claim" do
    result = create_parcel

    expect(result[:success]).to be true
    event = result[:event]
    expect(event.workflow_status).to eq("received")
    expect(event.metadata["reception_kind"]).to eq("parcel")
    expect(event.metadata).not_to have_key("locker")
    expect(event.employee_event_appointments.first.employee).to eq(recipient)
  end

  it "notifies the recipient and keeps the parcel waiting" do
    parcel = create_parcel[:event]

    result = described_class.notify(company: company, appointment: appointment, parcel_id: parcel.id, now: now + 5.minutes)

    expect(result[:success]).to be true
    expect(parcel.reload.workflow_status).to eq("received")
    expect(parcel.metadata["notified_at"]).to eq((now + 5.minutes).iso8601)
    notification = Notification.find_by(recipient_employee: recipient)
    expect(notification).to be_present
    expect(notification.name).to include("Parcel for Eleanor Vance")
  end

  it "creates another notification on Notify again" do
    parcel = create_parcel[:event]
    described_class.notify(company: company, appointment: appointment, parcel_id: parcel.id, now: now)
    described_class.notify(company: company, appointment: appointment, parcel_id: parcel.id, now: now + 1.minute)

    expect(Notification.where(recipient_employee: recipient).count).to eq(2)
    expect(parcel.reload.workflow_status).to eq("received")
  end

  it "marks a parcel picked up and completes it" do
    parcel = create_parcel[:event]

    result = described_class.pick_up(company: company, appointment: appointment, parcel_id: parcel.id, now: now + 1.hour)

    expect(result[:success]).to be true
    expect(parcel.reload.workflow_status).to eq("completed")
    expect(parcel.metadata["picked_up_at"]).to be_present
    expect(Notification.where(recipient_employee: recipient).count).to eq(0)
  end

  it "fails without carrier, item or recipient" do
    expect(described_class.create(company: company, appointment: appointment, params: { carrier: "", item: "x", employee_id: recipient.id }, now: now)[:errors]).to contain_exactly("Carrier is required.")
    expect(described_class.create(company: company, appointment: appointment, params: { carrier: "DHL", item: "", employee_id: recipient.id }, now: now)[:errors]).to contain_exactly("Item summary is required.")
    expect(described_class.create(company: company, appointment: appointment, params: { carrier: "DHL", item: "x", employee_id: "" }, now: now)[:errors]).to contain_exactly("Recipient is required.")
  end
end
