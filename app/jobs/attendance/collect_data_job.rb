# Collects/resolves attendance data for a company.
# Resets monthly aggregates then re-runs DailyResolutionService for every
# (employee, date) that has AttendanceLogs, so re-running is idempotent.
module Attendance
  class CollectDataJob < ApplicationJob
    queue_as :default

    def perform(company_id)
      company = Company.find(company_id)

      # Reset monthly totals to avoid double-counting on re-runs
      company.attendance_months.update_all(
        total_work_minutes: 0,
        total_late_minutes: 0,
        total_early_leave_minutes: 0,
        total_overtime_minutes: 0,
        total_absent_days: 0,
        total_present_days: 0,
        total_records: 0,
        total_deficit_minutes: 0
      )

      pairs = AttendanceLog.where(company: company)
        .group(:employee_id, "DATE(logged_at)")
        .pluck(:employee_id, "DATE(logged_at)")

      pairs.each do |employee_id, date|
        employee = Employee.find(employee_id)
        Attendance::DailyResolutionService.new.call(employee: employee, date: date.to_date)
      rescue => e
        Rails.logger.warn("CollectData failed for employee #{employee_id} on #{date}: #{e.message}")
      end
    end
  end
end
