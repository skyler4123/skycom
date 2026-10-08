require "rails_helper"

RSpec.describe AttendanceRequests::ApproveService do
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

  it "creates the AttendanceDay with approver stamped" do
    result = described_class.call(request: request, approver: owner)

    expect(result[:success]).to be true
    day = result[:attendance_day]
    expect(day).to be_present
    expect(day.attendance_status).to eq("present")
    expect(day.total_seconds_worked).to eq(8 * 3600)
    expect(day.recorded_method).to eq("request")
    expect(day.approved_by_id).to eq(owner.id)
    expect(day.approved_by_type).to eq("Employee")
    expect(day.notes).to eq("Field work - no GPS")
    expect(request.reload).to be_status_approved
  end

  it "marks short days as half_day" do
    request.update!(check_out: request.check_in + 2.hours)
    result = described_class.call(request: request, approver: owner)

    expect(result[:success]).to be true
    expect(result[:attendance_day].attendance_status).to eq("half_day")
  end

  it "marks missing check_out as missing_checkout" do
    request.update!(check_out: nil)
    result = described_class.call(request: request, approver: owner)

    expect(result[:success]).to be true
    day = result[:attendance_day]
    expect(day.attendance_status).to eq("missing_checkout")
    expect(day.total_seconds_worked).to eq(0)
  end

  it "fails when a day already exists and leaves the request pending" do
    AttendanceDay.create!(
      company: company, employee: employee, attendance_date: request.attendance_date,
      attendance_status: :present, total_seconds_worked: 28800
    )

    result = nil
    expect { result = described_class.call(request: request, approver: owner) }.not_to change(AttendanceDay, :count)
    expect(result[:success]).to be false
    expect(result[:errors]).to be_present
    expect(request.reload).to be_status_pending
  end

  it "fails on a second decide (terminal state)" do
    expect(described_class.call(request: request, approver: owner)[:success]).to be true

    second = described_class.call(request: request, approver: owner)
    expect(second[:success]).to be false
    expect(AttendanceDay.where(company: company, employee: employee, attendance_date: request.attendance_date).count).to eq(1)
  end

  it "fails when approver lacks update permission" do
    result = nil
    expect { result = described_class.call(request: request, approver: stranger) }.not_to change(AttendanceDay, :count)
    expect(result[:success]).to be false
    expect(request.reload).to be_status_pending
  end

  it "approves the same employee on two different dates including month boundary" do
    first = described_class.call(request: request, approver: owner)
    other_date = request.attendance_date - 1.day
    other = AttendanceRequest.create!(
      company: company, employee: employee, attendance_date: other_date,
      check_in: Time.zone.parse("#{other_date} 09:00"),
      check_out: Time.zone.parse("#{other_date} 17:00"),
      reason: "Remote work"
    )
    second = described_class.call(request: other, approver: owner)

    expect(first[:success]).to be true
    expect(second[:success]).to be true
  end
end
