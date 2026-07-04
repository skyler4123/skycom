require 'rails_helper'

RSpec.describe Attendance::Strategies::CheckInOnlyStrategy do
  def log(type, time)
    AttendanceLog.new(log_type: type, logged_at: time)
  end

  let(:date) { Date.new(2026, 7, 6) }

  it "full day: first to last check_in covers full shift" do
    logs = [
      log("check_in", date.to_time.change(hour: 7, min: 55)),
      log("check_in", date.to_time.change(hour: 17, min: 5))
    ]
    template = ShiftTemplate.new(policy_type: "fixed", grace_period_minutes: 15, unpaid_break_minutes: 60, full_day_minutes: 480)
    shift = ScheduledShift.new(expected_start_at: date.to_time.change(hour: 8))
    allow(ScheduledShift).to receive(:find_by).and_return(shift)

    result = described_class.new.call(logs, Employee.new, date, template)
    expect(result[:status]).to eq(:present)
  end

  it "early departure when last check_in is before expected end" do
    logs = [
      log("check_in", date.to_time.change(hour: 8)),
      log("check_in", date.to_time.change(hour: 16))
    ]
    template = ShiftTemplate.new(policy_type: "fixed", unpaid_break_minutes: 60, full_day_minutes: 480)
    shift = ScheduledShift.new(expected_start_at: date.to_time.change(hour: 8))
    allow(ScheduledShift).to receive(:find_by).and_return(shift)

    result = described_class.new.call(logs, Employee.new, date, template)
    # 480min gross - 60min break = 420min net → :half_day
    expect(result[:status]).to eq(:half_day)
  end

  it "late when first check_in after grace window" do
    logs = [
      log("check_in", date.to_time.change(hour: 10)),
      log("check_in", date.to_time.change(hour: 20))
    ]
    template = ShiftTemplate.new(policy_type: "fixed", grace_period_minutes: 15, unpaid_break_minutes: 60, full_day_minutes: 480)
    shift = ScheduledShift.new(expected_start_at: date.to_time.change(hour: 8))
    allow(ScheduledShift).to receive(:find_by).and_return(shift)

    result = described_class.new.call(logs, Employee.new, date, template)
    expect(result[:status]).to eq(:late)
  end

  it "absent when no check_in logs" do
    result = described_class.new.call([], Employee.new, date, nil)
    expect(result[:status]).to eq(:absent)
  end

  it "pure flexible full day" do
    logs = [
      log("check_in", date.to_time.change(hour: 6)),
      log("check_in", date.to_time.change(hour: 15))
    ]
    template = ShiftTemplate.new(policy_type: "pure_flexible", unpaid_break_minutes: 60, full_day_minutes: 480)

    result = described_class.new.call(logs, Employee.new, date, template)
    # 540min gross - 60min break = 480min net → :present
    expect(result[:status]).to eq(:present)
  end

  it "pure flexible half day" do
    logs = [
      log("check_in", date.to_time.change(hour: 10)),
      log("check_in", date.to_time.change(hour: 14))
    ]
    template = ShiftTemplate.new(policy_type: "pure_flexible", unpaid_break_minutes: 60, full_day_minutes: 480)

    result = described_class.new.call(logs, Employee.new, date, template)
    # 240min gross - no deduct (< 5h) = 240min net → :half_day
    expect(result[:status]).to eq(:half_day)
  end
end
