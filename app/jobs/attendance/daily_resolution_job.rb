module Attendance
  class DailyResolutionJob < ApplicationJob
    queue_as :default

    def perform(date: Date.yesterday)
      employee_ids = AttendanceLog.where("logged_at >= ? AND logged_at < ?",
        date.beginning_of_day, date.next_day.beginning_of_day)
        .distinct.pluck(:employee_id)

      employee_ids.each do |eid|
        employee = Employee.find(eid)
        DailyResolutionService.new.call(employee: employee, date: date)
      rescue => e
        Rails.logger.error("DailyResolution failed for employee #{eid} on #{date}: #{e.message}")
      end
    end
  end
end
