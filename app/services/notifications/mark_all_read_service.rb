# frozen_string_literal: true

# == Purpose:
# Mark-all-read via a single timestamp shortcut: set last_read_all_at = now
# and prune this employee's individual read rows (they are subsumed by the
# timestamp). Second consecutive call marks 0.
#
# == Returns (never raises for business failures):
#   { success: true, marked: int } | { success: false, errors: ["..."] }
module Notifications
  class MarkAllReadService
    def self.call(employee:)
      new(employee: employee).call
    end

    def initialize(employee:)
      @employee = employee
    end

    def call
      marked = Notifications::UnreadQuery.new(company: @employee.company, employee: @employee).scope.count
      ActiveRecord::Base.transaction do
        config = NotificationConfig.for_employee!(@employee)
        config.update!(last_read_all_at: Time.current)
        EmployeeNotificationRead.where(employee: @employee).delete_all
      end
      Rails.sync_cache.delete(Notifications::UnreadQuery.cache_key(@employee.id))
      { success: true, marked: marked }
    rescue ActiveRecord::RecordInvalid => e
      { success: false, errors: e.record.errors.full_messages }
    end
  end
end
