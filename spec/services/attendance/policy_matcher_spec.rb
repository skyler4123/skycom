require 'rails_helper'

RSpec.describe Attendance::PolicyMatcher do
  it "pure_flexible: full day when net >= 480" do
    result = described_class.match(480, [], ShiftTemplate.new(policy_type: "pure_flexible"), nil, Date.current)
    expect(result[:status]).to eq(:present)
  end

  it "pure_flexible: half day when 240 <= net < 480" do
    result = described_class.match(300, [], ShiftTemplate.new(policy_type: "pure_flexible"), nil, Date.current)
    expect(result[:status]).to eq(:half_day)
  end

  it "pure_flexible: absent when net < 240" do
    result = described_class.match(100, [], ShiftTemplate.new(policy_type: "pure_flexible"), nil, Date.current)
    expect(result[:status]).to eq(:absent)
  end

  it "fixed: present when on time" do
    employee = Employee.new
    date = Date.new(2026, 7, 2)
    shift = ScheduledShift.new(expected_start_at: date.to_time.change(hour: 8))
    allow(ScheduledShift).to receive(:find_by).and_return(shift)
    template = ShiftTemplate.new(policy_type: "fixed", grace_period_minutes: 15)
    segments = [ { start_at: date.to_time.change(hour: 8, min: 5), has_check_out: true } ]
    result = described_class.match(480, segments, template, employee, date)
    expect(result[:status]).to eq(:present)
  end

  it "fixed: late when arriving after grace window" do
    employee = Employee.new
    date = Date.new(2026, 7, 2)
    shift = ScheduledShift.new(expected_start_at: date.to_time.change(hour: 8))
    allow(ScheduledShift).to receive(:find_by).and_return(shift)
    template = ShiftTemplate.new(policy_type: "fixed", grace_period_minutes: 15)
    segments = [ { start_at: date.to_time.change(hour: 9), has_check_out: true } ]
    result = described_class.match(480, segments, template, employee, date)
    expect(result[:status]).to eq(:late)
  end
end
