require 'rails_helper'

RSpec.describe Attendance::DailyResolutionService do
  it "runs without error when no logs exist", skip: "Requires full factory setup" do
    employee = create(:employee)
    result = described_class.new.call(employee: employee, date: Date.yesterday)
    expect(result).to be_persisted
    expect(result.attendance_status).to eq("absent")
  end

  it "creates attendance_day from logs", skip: "Requires full factory setup" do
    company = create(:company)
    branch = create(:branch, company: company)
    employee = create(:employee, company: company, branch: branch)
    yesterday = Date.yesterday

    ScheduledShift.create!(
      company: company, branch: branch, employee: employee,
      work_date: yesterday, expected_start_at: yesterday.to_time.change(hour: 8),
      expected_end_at: yesterday.to_time.change(hour: 17), status: :completed
    )

    AttendanceLog.create!(company: company, employee: employee, log_type: "check_in",
      logged_at: yesterday.to_time.change(hour: 7, min: 55))
    AttendanceLog.create!(company: company, employee: employee, log_type: "check_out",
      logged_at: yesterday.to_time.change(hour: 17, min: 5))

    day = described_class.new.call(employee: employee, date: yesterday)
    expect(day).to be_persisted
    expect(day.attendance_date).to eq(yesterday)
  end
end
