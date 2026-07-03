require 'rails_helper'

RSpec.describe Attendance::BreakDeductor do
  it "deducts break for long single segment" do
    template = ShiftTemplate.new(unpaid_break_minutes: 60)
    segments = [ { start_at: Time.current, end_at: Time.current + 9.hours, duration_minutes: 540 } ]
    net = described_class.deduct(540, template, segments)
    expect(net).to eq(480)
  end

  it "skips deduction for multi-punch" do
    template = ShiftTemplate.new(unpaid_break_minutes: 60)
    segments = [
      { start_at: Time.current, end_at: Time.current + 4.hours, duration_minutes: 240 },
      { start_at: Time.current + 5.hours, end_at: Time.current + 9.hours, duration_minutes: 240 }
    ]
    net = described_class.deduct(480, template, segments)
    expect(net).to eq(480)
  end

  it "returns 0 for negative result" do
    template = ShiftTemplate.new(unpaid_break_minutes: 120)
    segments = [ { start_at: Time.current, end_at: Time.current + 6.hours, duration_minutes: 360 } ]
    net = described_class.deduct(360, template, segments)
    expect(net).to eq(240)
  end

  it "does not deduct when gross is under 5 hours" do
    template = ShiftTemplate.new(unpaid_break_minutes: 60)
    segments = [ { start_at: Time.current, end_at: Time.current + 4.hours, duration_minutes: 240 } ]
    net = described_class.deduct(240, template, segments)
    expect(net).to eq(240)
  end
end
