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
