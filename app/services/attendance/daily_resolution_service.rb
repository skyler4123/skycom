# Orchestrates the daily attendance resolution pipeline.
# Loads AttendanceLogs for an employee on a date, dispatches to the configured
# ResolutionStrategy (PairedStrategy or CheckInOnlyStrategy), then creates or
# updates the AttendanceDay and AttendanceMonth records with computed metrics
# (net minutes, late, overtime, deficit).
module Attendance
  class DailyResolutionService
    STRATEGIES = {
      "paired" => Strategies::PairedStrategy,
      "check_in_only" => Strategies::CheckInOnlyStrategy
    }.freeze

    def call(employee:, date: Date.yesterday)
      logs = AttendanceLog.where(employee: employee)
        .where("logged_at >= ? AND logged_at < ?", date.beginning_of_day, date.next_day.beginning_of_day)
        .order(:logged_at)

      strategy = resolve_strategy(employee)
      shift = ScheduledShift.find_by(employee: employee, work_date: date)
      template = shift&.shift_template

      result = strategy.new.call(logs, employee, date, template)

      day = AttendanceDay.find_or_initialize_by(employee: employee, attendance_date: date)
      day.company = employee.company
      day.branch = employee.branch

      if result[:segments].any?
        day.check_in = result[:segments].first[:start_at]
        day.check_out = result[:segments].last[:end_at]
      end

      day.total_seconds_worked = result[:net_minutes] * 60
      day.total_seconds_overtime = (result[:overtime_minutes] || 0) * 60
      day.attendance_status = result[:status]
      day.save!

      update_month(employee, date, result, template)
      day
    end

    private

    def resolve_strategy(employee)
      policy = employee.branch&.attendance_policy
      key = policy&.resolution_strategy || "paired"
      STRATEGIES[key] || Strategies::PairedStrategy
    end

    def update_month(employee, date, result, template)
      month_start = date.beginning_of_month.to_date
      monthly = AttendanceMonth.find_or_initialize_by(employee: employee, month: month_start)
      monthly.company = employee.company
      monthly.branch = employee.branch

      monthly.total_work_minutes = (monthly.total_work_minutes || 0) + result[:net_minutes]
      monthly.total_records = (monthly.total_records || 0) + 1

      if %i[present late].include?(result[:status])
        monthly.total_present_days = (monthly.total_present_days || 0) + 1
      else
        monthly.total_absent_days = (monthly.total_absent_days || 0) + 1
      end

      full_day = template&.full_day_minutes || 480
      deficit = [ full_day - result[:net_minutes], 0 ].max
      monthly.total_deficit_minutes = (monthly.total_deficit_minutes || 0) + deficit
      monthly.total_late_minutes = (monthly.total_late_minutes || 0) + (result[:late_minutes] || 0)
      monthly.total_overtime_minutes = (monthly.total_overtime_minutes || 0) + (result[:overtime_minutes] || 0)
      monthly.save!
    end
  end
end
