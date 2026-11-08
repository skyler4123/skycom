# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reception::CheckInService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :reception) }
  let(:appointment) { BranchOperationAppointment.find_by!(company: company, branch: branch, operation: operation) }
  let(:host) { create(:employee, company: company, branch: branch, name: "Eleanor Vance") }

  it "creates a Customer and a confirmed visit Event linked to the host" do
    result = described_class.call(
      company: company,
      appointment: appointment,
      params: { name: "Jessica Tan", company: "Deloitte Consulting", host_id: host.id }
    )

    expect(result[:success]).to be true
    expect(result[:message]).to eq("Walk-in check-in complete for Jessica Tan.")

    event = result[:event]
    expect(event.workflow_status).to eq("confirmed")
    expect(event.branch).to eq(branch)
    expect(event.metadata["reception_kind"]).to eq("visit")
    expect(event.metadata["visitor_company"]).to eq("Deloitte Consulting")
    expect(event.customer_event_appointments.first.customer.name).to eq("Jessica Tan")
    expect(event.employee_event_appointments.first.employee).to eq(host)
  end

  it "reuses an existing Customer with the same name" do
    existing = create(:customer, company: company, name: "Jessica Tan")

    result = described_class.call(
      company: company,
      appointment: appointment,
      params: { name: "Jessica Tan", company: "Deloitte Consulting" }
    )

    expect(result[:success]).to be true
    expect(result[:customer]).to eq(existing)
    expect(Customer.where(company: company, name: "Jessica Tan").count).to eq(1)
  end

  it "fails without a guest name and persists nothing" do
    result = described_class.call(
      company: company,
      appointment: appointment,
      params: { name: " ", company: "Deloitte Consulting" }
    )

    expect(result[:success]).to be false
    expect(result[:errors]).to contain_exactly("Guest name is required.")
    expect(Event.where(company: company).count).to eq(0)
    expect(Customer.where(company: company).count).to eq(0)
  end

  it "fails without a company and persists nothing" do
    result = described_class.call(
      company: company,
      appointment: appointment,
      params: { name: "Jessica Tan", company: "" }
    )

    expect(result[:success]).to be false
    expect(result[:errors]).to contain_exactly("Company or organization is required.")
    expect(Event.where(company: company).count).to eq(0)
  end
end
