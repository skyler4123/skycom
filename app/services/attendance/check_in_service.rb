# Handles employee check-in at a branch location.
# Validates the geofence (GPS radius or matching Wi-Fi SSID) against the branch's
# AttendanceConfig, optionally requires a scheduled shift, creates an immutable
# AttendanceLog with the GPS audit fields, and marks the shift active.
# Returns Result.success or Result.failure.
module Attendance
  class Result
    def self.success(data) = new(true, data, nil)
    def self.failure(error) = new(false, nil, error)

    def initialize(success, data, error)
      @success = success
      @data = data
      @error = error
    end

    def success? = @success
    def data = @data
    def error = @error
  end

  class CheckInService
    def initialize(employee:, branch:, latitude: nil, longitude: nil, wifi_ssid: nil,
                   accuracy_meters: nil, require_scheduled_shift: true, enforce_geofence: true)
      @employee = employee
      @branch = branch
      @latitude = latitude
      @longitude = longitude
      @wifi_ssid = wifi_ssid
      @accuracy_meters = accuracy_meters
      @require_scheduled_shift = require_scheduled_shift
      @enforce_geofence = enforce_geofence
      @time = Time.current
    end

    def call
      policy = @enforce_geofence ? @branch&.attendance_config : nil
      coordinates_valid = valid_coordinates?
      distance = geofence_distance(policy, coordinates_valid)

      if policy && !wifi_match?(policy)
        return Result.failure("Location is required to check in.") unless coordinates_valid
        return Result.failure("You are outside the allowed check-in area.") if distance > policy.allowed_radius_meters
      end

      shift = ScheduledShift.find_by(employee: @employee, work_date: @time.to_date, status: :scheduled)
      return Result.failure("No scheduled shift today") if @require_scheduled_shift && !shift

      ActiveRecord::Base.transaction do
        AttendanceLog.create!(
          company: @employee.company, branch: @branch, employee: @employee,
          log_type: "check_in", logged_at: @time,
          latitude: coordinates_valid ? @latitude : nil,
          longitude: coordinates_valid ? @longitude : nil,
          wifi_ssid: @wifi_ssid,
          gps_accuracy_meters: @accuracy_meters,
          geofence_distance_meters: distance&.round
        )

        shift&.update!(status: :active)
        Result.success(shift)
      end
    end

    private

    def wifi_match?(policy)
      @wifi_ssid.present? && @wifi_ssid == policy.allowed_wifi_ssid
    end

    def geofence_distance(policy, coordinates_valid)
      return nil unless policy && coordinates_valid

      haversine_distance(@latitude, @longitude, policy.latitude, policy.longitude)
    end

    def valid_coordinates?
      @latitude.is_a?(Numeric) && @longitude.is_a?(Numeric) &&
        @latitude.between?(-90, 90) && @longitude.between?(-180, 180)
    end

    def haversine_distance(lat1, lon1, lat2, lon2)
      rad = ->(deg) { deg * Math::PI / 180 }
      dlat = rad.call(lat2 - lat1)
      dlon = rad.call(lon2 - lon1)
      a = Math.sin(dlat / 2)**2 + Math.cos(rad.call(lat1)) * Math.cos(rad.call(lat2)) * Math.sin(dlon / 2)**2
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
      6_371_000 * c
    end
  end
end
