# frozen_string_literal: true

require "rails_helper"

RSpec.describe Attendance::CheckInService do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company) }
  let(:employee) { create(:employee, company: company, branch: branch) }

  def service(**overrides)
    described_class.new(employee: employee, branch: branch, require_scheduled_shift: false, **overrides)
  end

  it "creates a check-in inside the radius and stores GPS audit fields" do
    create(:attendance_config, company: company, branch: branch, latitude: 10.773, longitude: 106.694, allowed_radius_meters: 100)
    result = service(latitude: 10.773, longitude: 106.694, accuracy_meters: 8).call

    expect(result).to be_success
    log = AttendanceLog.last
    expect(log.latitude).to be_within(0.000001).of(10.773)
    expect(log.longitude).to be_within(0.000001).of(106.694)
    expect(log.gps_accuracy_meters).to eq(8)
    expect(log.geofence_distance_meters).to eq(0)
  end

  it "allows a point just inside the radius" do
    create(:attendance_config, company: company, branch: branch, latitude: 10.773, longitude: 106.694, allowed_radius_meters: 100)
    expect(service(latitude: 10.77388, longitude: 106.694).call).to be_success
  end

  it "rejects a point just outside the radius and creates no log" do
    create(:attendance_config, company: company, branch: branch, latitude: 10.773, longitude: 106.694, allowed_radius_meters: 100)
    result = service(latitude: 10.77391, longitude: 106.694).call

    expect(result).not_to be_success
    expect(result.error).to eq("You are outside the allowed check-in area.")
    expect(AttendanceLog.count).to eq(0)
  end

  it "rejects missing coordinates when a config exists" do
    create(:attendance_config, company: company, branch: branch, latitude: 10.773, longitude: 106.694)
    result = service.call

    expect(result.error).to eq("Location is required to check in.")
    expect(AttendanceLog.count).to eq(0)
  end

  it "treats out-of-range coordinates as missing" do
    create(:attendance_config, company: company, branch: branch, latitude: 10.773, longitude: 106.694)
    expect(service(latitude: 999, longitude: 106.694).call.error).to eq("Location is required to check in.")
  end

  it "allows a matching Wi-Fi SSID without coordinates" do
    config = create(:attendance_config, company: company, branch: branch, latitude: 10.773, longitude: 106.694)
    config.update!(allowed_wifi_ssid: "Clinic_WiFi")
    result = service(wifi_ssid: "Clinic_WiFi").call

    expect(result).to be_success
    expect(AttendanceLog.last.wifi_ssid).to eq("Clinic_WiFi")
  end

  it "accepts poor accuracy when the fix is inside the radius" do
    create(:attendance_config, company: company, branch: branch, latitude: 10.773, longitude: 106.694, allowed_radius_meters: 100)
    expect(service(latitude: 10.773, longitude: 106.694, accuracy_meters: 500).call).to be_success
  end

  it "allows a branch without an attendance config" do
    expect(service.call).to be_success
  end

  it "skips the geofence when enforce_geofence is false" do
    create(:attendance_config, company: company, branch: branch, latitude: 10.773, longitude: 106.694)
    expect(service(latitude: 10.8, longitude: 106.8, enforce_geofence: false).call).to be_success
  end

  it "requires a scheduled shift by default" do
    create(:attendance_config, company: company, branch: branch, latitude: 10.773, longitude: 106.694)
    result = described_class.new(employee: employee, branch: branch, latitude: 10.773, longitude: 106.694).call

    expect(result.error).to eq("No scheduled shift today")
  end

  it "marks the scheduled shift active" do
    create(:attendance_config, company: company, branch: branch, latitude: 10.773, longitude: 106.694)
    shift = create(:scheduled_shift, company: company, branch: branch, employee: employee)
    result = described_class.new(employee: employee, branch: branch, latitude: 10.773, longitude: 106.694).call

    expect(result).to be_success
    expect(shift.reload).to be_status_active
  end
end
