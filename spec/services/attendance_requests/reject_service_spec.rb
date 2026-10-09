require "rails_helper"

RSpec.describe AttendanceRequests::RejectService do
  let(:company) { create(:company) }
  let(:owner) { company.employees.find_by(business_type: "owner") }
  let(:employee) { create(:employee, company: company) }
  let(:stranger) { create(:employee, company: company) }

  let!(:request) do
    AttendanceRequest.create!(
      company: company, employee: employee,
      attendance_date: Date.yesterday,
      check_in: Time.zone.parse("#{Date.yesterday} 09:00"),
      check_out: Time.zone.parse("#{Date.yesterday} 17:00"),
      reason: "Field work - no GPS"
    )
  end

  it "stamps decided without creating a day" do
    result = nil
    expect { result = described_class.call(request: request, approver: owner, note: "No proof provided") }
      .not_to change(AttendanceDay, :count)

    expect(result[:success]).to be true
    expect(request.reload).to be_status_rejected
    expect(request.decided_by).to eq(owner)
    expect(request.decided_at).to be_present
  end

  it "reports already decided on a second decide" do
    expect(described_class.call(request: request, approver: owner)[:success]).to be true

    second = described_class.call(request: request, approver: owner)
    expect(second[:success]).to be false
    expect(second[:errors]).to eq([ "Request already decided" ])
  end

  it "fails when approver lacks update permission" do
    result = described_class.call(request: request, approver: stranger)

    expect(result[:success]).to be false
    expect(request.reload).to be_status_pending
  end
end
