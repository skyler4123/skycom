require 'rails_helper'

RSpec.describe AttendanceLog, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:employee) }
  end

  describe "validations" do
    it { should validate_presence_of(:log_type) }
    it { should validate_presence_of(:logged_at) }
  end

  describe "GPS metadata" do
    it "exposes accuracy and distance from metadata" do
      log = create(:attendance_log)
      log.update!(gps_accuracy_meters: 8.5, geofence_distance_meters: 42)

      expect(log.reload.gps_accuracy_meters).to eq(8.5)
      expect(log.geofence_distance_meters).to eq(42)
      expect(log.metadata).to include(
        "gps_accuracy_meters" => 8.5,
        "geofence_distance_meters" => 42
      )
    end
  end
end
