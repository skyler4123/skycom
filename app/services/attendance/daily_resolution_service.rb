module Attendance
  class DailyResolutionService
    def initialize
      @segment_fuser = SegmentFuser
      @break_deductor = BreakDeductor
      @policy_matcher = PolicyMatcher
    end

    def call(employee:, date: Date.yesterday)
      logs = AttendanceLog.where(employee: employee)
        .where("logged_at >= ? AND logged_at < ?", date.beginning_of_day, date.next_day.beginning_of_day)
        .order(:logged_at)

      segments = @segment_fuser.fuse(logs)

      if segments.empty? || segments.none? { |s| s[:has_check_out] }
        return mark_absent(employee, date)
      end

      gross = segments.select { |s| s[:has_check_out] }.sum { |s| s[:duration_minutes] }
      shift = ScheduledShift.find_by(employee: employee, work_date: date)
      template = shift&.shift_template

      net = @break_deductor.deduct(gross, template, segments)
      result = @policy_matcher.match(net, segments, template, employee, date)

      day = AttendanceDay.find_or_initialize_by(employee: employee, attendance_date: date)
      day.company = employee.company
      day.branch = employee.branch
      day.check_in = segments.first[:start_at]
      day.check_out = segments.last[:end_at]
      day.total_seconds_worked = net * 60
      day.total_seconds_overtime = (result[:overtime_minutes] || 0) * 60
      day.attendance_status = result[:status]
      day.save!

      update_month(employee, date, net, result, template)
      day
    end

    private

    def mark_absent(employee, date)
      day = AttendanceDay.find_or_initialize_by(employee: employee, attendance_date: date)
      day.company = employee.company
      day.branch = employee.branch
      day.attendance_date = date
      day.attendance_status = :absent
      day.save!
      day
    end

    def update_month(employee, date, net_minutes, result, template)
      month_start = date.beginning_of_month.to_date
      monthly = AttendanceMonth.find_or_initialize_by(employee: employee, month: month_start)
      monthly.company = employee.company
      monthly.branch = employee.branch

      monthly.total_work_minutes = (monthly.total_work_minutes || 0) + net_minutes
      monthly.total_records = (monthly.total_records || 0) + 1

      if %i[present late].include?(result[:status])
        monthly.total_present_days = (monthly.total_present_days || 0) + 1
      else
        monthly.total_absent_days = (monthly.total_absent_days || 0) + 1
      end

      full_day = template&.full_day_minutes || 480
      deficit = [ full_day - net_minutes, 0 ].max
      monthly.total_deficit_minutes = (monthly.total_deficit_minutes || 0) + deficit
      monthly.total_late_minutes = (monthly.total_late_minutes || 0) + (result[:late_minutes] || 0)
      monthly.total_overtime_minutes = (monthly.total_overtime_minutes || 0) + (result[:overtime_minutes] || 0)

      monthly.save!
    end
  end
end
