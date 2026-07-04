# Handles employee check-out.
# Creates an immutable AttendanceLog with log_type "check_out".
# Metrics like total_work_minutes are computed later by DailyResolutionService.
module Attendance
  class CheckOutService
    def initialize(employee:, latitude: nil, longitude: nil)
      @employee = employee
      @latitude = latitude
      @longitude = longitude
      @time = Time.current
    end

    def call
      AttendanceLog.create!(
        company: @employee.company, employee: @employee,
        log_type: "check_out", logged_at: @time,
        latitude: @latitude, longitude: @longitude
      )

      Result.success(true)
    end
  end
end
