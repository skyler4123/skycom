require 'rails_helper'

RSpec.describe Attendance::Strategies::PairedStrategy do
  def log(type, time)
    AttendanceLog.new(log_type: type, logged_at: time)
  end

  let(:date) { Date.new(2026, 7, 6) }

  it "full day: paired check_in → check_out, fixed shift" do
    logs = [
      log("check_in", date.to_time.change(hour: 7, min: 55)),
      log("check_out", date.to_time.change(hour: 17, min: 5))
    ]
    template = ShiftTemplate.new(policy_type: "fixed", grace_period_minutes: 15, unpaid_break_minutes: 60, full_day_minutes: 480)
    shift = ScheduledShift.new(expected_start_at: date.to_time.change(hour: 8))

    allow(ScheduledShift).to receive(:find_by).and_return(shift)
    result = described_class.new.call(logs, Employee.new, date, template)
    expect(result[:status]).to eq(:present)
    expect(result[:net_minutes]).to eq(0) # Will be computed by resolution service
  end

  it "multi-punch with lunch break produces 2 segments" do
    logs = [
      log("check_in", date.to_time.change(hour: 8)),
      log("check_out", date.to_time.change(hour: 12)),
      log("check_in", date.to_time.change(hour: 13)),
      log("check_out", date.to_time.change(hour: 17))
    ]
    template = ShiftTemplate.new(policy_type: "pure_flexible", unpaid_break_minutes: 60, full_day_minutes: 480)

    result = described_class.new.call(logs, Employee.new, date, template)
    expect(result[:status]).to eq(:present)
  end

  it "late arrival when check_in after grace window but still works full day" do
    logs = [
      log("check_in", date.to_time.change(hour: 10)),
      log("check_out", date.to_time.change(hour: 19))
    ]
    template = ShiftTemplate.new(policy_type: "fixed", grace_period_minutes: 15, unpaid_break_minutes: 60, full_day_minutes: 480)
    shift = ScheduledShift.new(expected_start_at: date.to_time.change(hour: 8))
    allow(ScheduledShift).to receive(:find_by).and_return(shift)

    result = described_class.new.call(logs, Employee.new, date, template)
    expect(result[:status]).to eq(:late)
    expect(result[:late_minutes]).to be > 0
  end

  it "half day when net below full_day_minutes" do
    logs = [
      log("check_in", date.to_time.change(hour: 10)),
      log("check_out", date.to_time.change(hour: 14))
    ]
    template = ShiftTemplate.new(policy_type: "pure_flexible", full_day_minutes: 480)

    result = described_class.new.call(logs, Employee.new, date, template)
    expect(result[:status]).to eq(:half_day)
  end

  it "absent when no check_out segments" do
    logs = [
      log("check_in", date.to_time.change(hour: 8))
    ]
    template = ShiftTemplate.new(policy_type: "pure_flexible", full_day_minutes: 480)

    result = described_class.new.call(logs, Employee.new, date, template)
    expect(result[:status]).to eq(:absent)
  end

  it "pure flexible full day" do
    logs = [
      log("check_in", date.to_time.change(hour: 6)),
      log("check_out", date.to_time.change(hour: 15))
    ]
    template = ShiftTemplate.new(policy_type: "pure_flexible", full_day_minutes: 480)

    result = described_class.new.call(logs, Employee.new, date, template)
    expect(result[:status]).to eq(:present)
  end

  it "core-hours violation when segment misses core block" do
    logs = [
      log("check_in", date.to_time.change(hour: 6)),
      log("check_out", date.to_time.change(hour: 12)),
      log("check_in", date.to_time.change(hour: 14)),
      log("check_out", date.to_time.change(hour: 18))
    ]
    template = ShiftTemplate.new(
      policy_type: "core_hours_flexible", full_day_minutes: 480
    )
    # Use a stub to make core_start_time and core_end_time return the right values
    allow(template).to receive(:core_start_time).and_return(Time.zone.parse("13:00"))
    allow(template).to receive(:core_end_time).and_return(Time.zone.parse("16:00"))

    result = described_class.new.call(logs, Employee.new, date, template)
    expect(result[:status]).to eq(:present)
    expect(result[:policy_violation]).to eq("missed_core_hours")
  end
end
