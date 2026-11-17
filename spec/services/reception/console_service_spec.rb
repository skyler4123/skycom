# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reception::ConsoleService, type: :service do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :education).tap(&:save!) }
  let(:branch) { create(:branch, company: company, name: "Front Desk", timezone: :plus_7) }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :reception) }
  let(:appointment) { operation.branch_operation_appointments.find_by!(branch: branch) }
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let(:host) { create(:employee, company: company, branch: branch, name: "Eleanor Vance") }

  def create_visit(customer_name:, start_at:, status: :confirmed, metadata: nil)
    customer = create(:customer, company: company, name: customer_name)
    event = create(:event, company: company, branch: branch, category: event_category,
      name: "Visit · #{customer_name}", start_at: start_at, end_at: start_at + 1.hour,
      workflow_status: status, metadata: metadata)
    CustomerEventAppointment.create!(company: company, event: event, customer: customer)
    EmployeeEventAppointment.create!(company: company, event: event, employee: host)
    event
  end

  it "returns ISO timestamps instead of server-formatted clock strings" do
    visit_event = create_visit(customer_name: "Arthur Pendelton", start_at: Time.utc(2026, 11, 17, 2, 0, 0))

    payload = described_class.call(
      company: company,
      appointment: appointment,
      now: Time.utc(2026, 11, 17, 2, 5, 0)
    )

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

    payload = described_class.call(
      company: company,
      appointment: appointment,
      now: Time.utc(2026, 11, 17, 2, 0, 0)
    )

    visitor = payload[:visits].find { |row| row[:id] == visit_event.id }
    expect(visitor[:note_key]).to eq("checked_in")
    expect(visitor[:note_at]).to eq("2026-11-17T01:35:00Z")
  end

  it "uses the branch calendar day for the visit queue" do
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

    payload = described_class.call(
      company: company,
      appointment: appointment,
      now: Time.utc(2026, 11, 17, 18, 0, 0)
    )

    ids = payload[:visits].map { |visitor| visitor[:id] }
    expect(ids).to include(late_local_visit.id)
    expect(ids).not_to include(previous_local_day.id)
  end
end
