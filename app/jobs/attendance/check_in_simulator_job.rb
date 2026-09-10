# Dev-only simulator: every tick picks 1 random employee per company and
# performs a realistic check-in via Attendance::CheckInService.
# Seeded shifts go stale (they drift into the past), so the job ensures a
# :scheduled shift for today before checking in — self-sustaining with no
# re-seed. Writes stay bounded to one check-in per employee/day.
# Scheduled per-second in config/recurring.yml (development section only).
module Attendance
  class CheckInSimulatorJob < ApplicationJob
    queue_as :default

    def perform
      return unless Rails.env.development?

      Company.find_each(batch_size: 50) do |company|
        simulate_company(company)
      rescue StandardError => e
        Rails.logger.warn("[CheckInSimulator] company #{company.id}: #{e.message}")
      end
    end

    private

    def simulate_company(company)
      employee = company.employees.kept.order("RANDOM()").first
      return Rails.logger.debug("[CheckInSimulator] company #{company.id}: no employees, skipped") if employee.nil?

      branch = employee.branch || company.branches.order("RANDOM()").first
      return Rails.logger.debug("[CheckInSimulator] company #{company.id}: no branch, skipped") if branch.nil?

      ensure_today_shift(employee, branch)

      policy = branch.attendance_policy
      result = Attendance::CheckInService.new(
        employee: employee,
        branch: branch,
        latitude: policy&.latitude,
        longitude: policy&.longitude,
        wifi_ssid: policy&.allowed_wifi_ssid
      ).call

      if result.success?
        Rails.logger.info("[CheckInSimulator] check-in: employee #{employee.id} @ branch #{branch.id}")
      else
        Rails.logger.debug("[CheckInSimulator] skipped employee #{employee.id}: #{result.error}")
      end
    end

    # Seeded shifts drift into the past, so guarantee a :scheduled shift for
    # today. Never touches :active/:completed rows — find_or_create only fills
    # the gap when no row exists for (employee, today).
    def ensure_today_shift(employee, branch)
      return if employee.scheduled_shifts.exists?(work_date: Date.current)

      template = ShiftTemplate.where(company: employee.company, branch: branch).order("RANDOM()").first
      start_at = template ? Date.current.to_time.change(hour: template.start_time.hour, min: template.start_time.min) : Time.current.change(hour: 9)
      end_at = template ? Date.current.to_time.change(hour: template.end_time.hour, min: template.end_time.min) : Time.current.change(hour: 18)

      ScheduledShift.create!(
        company: employee.company, branch: branch, employee: employee,
        shift_template: template, work_date: Date.current,
        expected_start_at: start_at, expected_end_at: end_at,
        status: :scheduled
      )
    end
  end
end
