# frozen_string_literal: true

# Seed-only demo support: the payroll page opens on the current month, so a
# company seeded early in a month must still have a current-month attendance
# rollup and payroll draft. Uses the real resolved attendance when present and
# falls back to a month-to-date summary when no attendance day has elapsed yet.
class Seed::PayrollService
  FALLBACK_WORK_MINUTES_PER_DAY = 480

  def self.ensure_current_month!(company:)
    new(company: company).call
  end

  def initialize(company:)
    @company = company
    @month = Date.current.beginning_of_month
  end

  def call
    @company.employees.where(discarded_at: nil).find_each do |employee|
      ensure_attendance_month(employee)
    end

    Payrolls::GenerateService.new(company: @company, month: @month).call
  end

  private

  def ensure_attendance_month(employee)
    month = employee.attendance_months.find_by(month: @month..@month.end_of_month)
    return if month && month.total_present_days.to_i.positive?

    workdays = elapsed_workdays
    attributes = {
      branch: employee.branch,
      total_work_minutes: workdays * FALLBACK_WORK_MINUTES_PER_DAY,
      total_present_days: workdays,
      total_absent_days: 0,
      total_records: workdays,
      total_late_minutes: 0,
      total_overtime_minutes: 0,
      total_deficit_minutes: 0
    }

    if month
      month.update!(attributes)
    else
      AttendanceMonth.create!(attributes.merge(company: @company, employee: employee, month: @month))
    end
  end

  def elapsed_workdays
    count = (@month..Date.current).count { |date| (1..5).cover?(date.wday) }
    [ count, 1 ].max
  end
end
