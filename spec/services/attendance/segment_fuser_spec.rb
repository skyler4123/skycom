require 'rails_helper'

RSpec.describe Attendance::SegmentFuser do
  def log(type, time)
    AttendanceLog.new(log_type: type, logged_at: time)
  end

  it "pairs check_in and check_out into segments" do
    logs = [
      log("check_in", Time.zone.parse("2026-07-02 08:00")),
      log("check_out", Time.zone.parse("2026-07-02 12:00"))
    ]
    segments = described_class.fuse(logs)
    expect(segments.length).to eq(1)
    expect(segments[0][:duration_minutes]).to eq(240)
    expect(segments[0][:has_check_out]).to be true
  end

  it "handles multi-punch with lunch break" do
    logs = [
      log("check_in", Time.zone.parse("2026-07-02 08:00")),
      log("check_out", Time.zone.parse("2026-07-02 12:00")),
      log("check_in", Time.zone.parse("2026-07-02 13:00")),
      log("check_out", Time.zone.parse("2026-07-02 17:00"))
    ]
    segments = described_class.fuse(logs)
    expect(segments.length).to eq(2)
    expect(segments[0][:duration_minutes]).to eq(240)
    expect(segments[1][:duration_minutes]).to eq(240)
  end

  it "flags missing check_out" do
    logs = [
      log("check_in", Time.zone.parse("2026-07-02 08:00"))
    ]
    segments = described_class.fuse(logs)
    expect(segments.length).to eq(1)
    expect(segments[0][:has_check_out]).to be false
  end

  it "ignores orphan check_out" do
    logs = [
      log("check_out", Time.zone.parse("2026-07-02 12:00"))
    ]
    segments = described_class.fuse(logs)
    expect(segments).to be_empty
  end
end
