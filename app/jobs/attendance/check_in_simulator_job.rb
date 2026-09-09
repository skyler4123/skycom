# Dev-only simulator: every tick picks 1 random employee per company and
# attempts a realistic check-in via Attendance::CheckInService.
# Most ticks fail-safe (no :scheduled shift today / already checked in) and are
# skipped at debug level — writes stay bounded to one check-in per employee/day.
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
  end
end
