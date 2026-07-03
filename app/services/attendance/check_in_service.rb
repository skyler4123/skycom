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
    def initialize(employee:, branch:, latitude: nil, longitude: nil, wifi_ssid: nil)
      @employee = employee
      @branch = branch
      @latitude = latitude
      @longitude = longitude
      @wifi_ssid = wifi_ssid
      @time = Time.current
    end

    def call
      policy = @branch.attendance_policy
      return Result.failure("Outside allowed area") if policy && !inside_geofence?(policy)

      shift = ScheduledShift.find_by(employee: @employee, work_date: @time.to_date, status: :scheduled)
      return Result.failure("No scheduled shift today") unless shift

      ActiveRecord::Base.transaction do
        AttendanceLog.create!(
          company: @employee.company, branch: @branch, employee: @employee,
          log_type: "check_in", logged_at: @time,
          latitude: @latitude, longitude: @longitude, wifi_ssid: @wifi_ssid
        )

        late_min = [ ((@time - shift.expected_start_at) / 60).to_i, 0 ].max
        record = AttendanceRecord.create!(
          company: @employee.company, branch: @branch, employee: @employee,
          scheduled_shift: shift, check_in_at: @time, late_minutes: late_min
        )
        shift.update!(status: :active)
        Result.success(record)
      end
    end

    private

    def inside_geofence?(policy)
      return true if @wifi_ssid.present? && @wifi_ssid == policy.allowed_wifi_ssid
      return false if @latitude.nil? || @longitude.nil?

      distance = haversine_distance(@latitude, @longitude, policy.latitude, policy.longitude)
      distance <= policy.allowed_radius_meters
    end

    def haversine_distance(lat1, lon1, lat2, lon2)
      rad = ->(deg) { deg * Math::PI / 180 }
      dlat = rad.call(lat2 - lat1)
      dlon = rad.call(lon2 - lon1)
      a = Math.sin(dlat / 2)**2 + Math.cos(rad.call(lat1)) * Math.cos(rad.call(lat2)) * Math.sin(dlon / 2)**2
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
      6_371_000 * c # Earth radius in meters
    end
  end
end
