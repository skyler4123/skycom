# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reception::NotifyHostService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :reception) }
  let(:appointment) { BranchOperationAppointment.find_by!(company: company, branch: branch, operation: operation) }
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let(:host) { create(:employee, company: company, branch: branch, name: "Eleanor Vance") }
  let(:now) { Time.utc(2026, 11, 20, 9, 0, 0) }

  def create_visit(status: :confirmed, with_host: true)
    customer = create(:customer, company: company, name: "Jessica Tan", description: "Deloitte")
    event = create(:event, company: company, branch: branch, category: event_category,
      name: "Visit · Jessica Tan · #{SecureRandom.hex(2)}", start_at: now, end_at: now + 1.hour,
      workflow_status: status,
      metadata: { "reception_kind" => "visit", "visitor_company" => "Deloitte" })
    CustomerEventAppointment.create!(company: company, event: event, customer: customer)
    EmployeeEventAppointment.create!(company: company, event: event, employee: host) if with_host
    event
  end

  it "creates one direct notification for the host and stamps the visit" do
    event = create_visit

    result = described_class.call(company: company, appointment: appointment, event_id: event.id, now: now)

    expect(result[:success]).to be true
    expect(result[:message]).to eq("Host notified for Jessica Tan.")
    expect(event.reload.metadata["host_notified_at"]).to eq(now.iso8601)
    notification = result[:notification]
    expect(notification.recipient_employee).to eq(host)
    expect(Notification.subscribed_for(host, company)).to include(notification)
  end

  it "creates another notification on Notify again" do
    event = create_visit
    first = described_class.call(company: company, appointment: appointment, event_id: event.id, now: now)
    second = described_class.call(company: company, appointment: appointment, event_id: event.id, now: now + 1.minute)

    expect(first[:success]).to be true
    expect(second[:success]).to be true
    expect(Notification.where(recipient_employee: host).count).to eq(2)
  end

  it "does not notify another employee" do
    other = create(:employee, company: company, branch: branch, name: "David Chen")
    event = create_visit
    described_class.call(company: company, appointment: appointment, event_id: event.id, now: now)

    expect(Notification.subscribed_for(other, company)).to be_empty
  end

  it "fails with no host and persists no notification" do
    event = create_visit(with_host: false)

    result = described_class.call(company: company, appointment: appointment, event_id: event.id, now: now)

    expect(result[:success]).to be false
    expect(result[:errors]).to contain_exactly("No host to notify.")
    expect(Notification.where(company: company).count).to eq(0)
    expect(event.reload.metadata["host_notified_at"]).to be_nil
  end

  it "rejects a parcel or unlinked booking" do
    parcel = create(:event, company: company, branch: branch, category: event_category,
      name: "Parcel #{SecureRandom.hex(2)}", start_at: now, end_at: now + 1.hour, workflow_status: :received,
      metadata: { "reception_kind" => "parcel" })

    parcel_result = described_class.call(company: company, appointment: appointment, event_id: parcel.id, now: now)
    expect(parcel_result[:errors]).to contain_exactly("This is not a reception visit.")

    booking = create(:event, company: company, branch: branch, category: event_category,
      name: "Booking #{SecureRandom.hex(2)}", start_at: now, end_at: now + 1.hour, workflow_status: :confirmed)
    booking_result = described_class.call(company: company, appointment: appointment, event_id: booking.id, now: now)
    expect(booking_result[:errors]).to contain_exactly("This is not a reception visit.")
  end
end
