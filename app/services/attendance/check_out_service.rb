module Attendance
  class CheckOutService
    def initialize(employee:, latitude: nil, longitude: nil)
      @employee = employee
      @latitude = latitude
      @longitude = longitude
      @time = Time.current
    end

    def call
      record = AttendanceRecord.where(employee: @employee, check_out_at: nil).order(:created_at).last
      return Result.failure("No active session") unless record

      ActiveRecord::Base.transaction do
        AttendanceLog.create!(
          company: @employee.company, branch: record.branch, employee: @employee,
          log_type: "check_out", logged_at: @time,
          latitude: @latitude, longitude: @longitude
        )

        total_min = ((@time - record.check_in_at) / 60).to_i
        break_min = record.scheduled_shift&.shift_template&.unpaid_break_minutes || 0
        net_min = [ total_min - break_min, 0 ].max

        early = 0
        overtime = 0
        if record.scheduled_shift
          early = if @time < record.scheduled_shift.expected_end_at
                    ((record.scheduled_shift.expected_end_at - @time) / 60).to_i
          else
                    0
          end
          overtime = if @time > record.scheduled_shift.expected_end_at
                       ((@time - record.scheduled_shift.expected_end_at) / 60).to_i
          else
                       0
          end
        end

        status = early > 60 ? :half_day : :present

        record.update!(
          check_out_at: @time, total_work_minutes: net_min,
          early_leave_minutes: early, overtime_minutes: overtime, computed_status: status
        )
        record.scheduled_shift&.update!(status: :completed)
        Result.success(record)
      end
    end
  end
end
