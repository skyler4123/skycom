# frozen_string_literal: true

# == Purpose:
# Idempotent single mark-as-read (direct write, no job — one row insert is
# cheaper than a Solid Queue enqueue). No callbacks; explicit service call.
#
# == Returns (never raises for business failures):
#   { success: true, created: bool } | { success: false, errors: ["..."] }
module Notifications
  class MarkReadService
    def self.call(employee:, notification:)
      new(employee: employee, notification: notification).call
    end

    def initialize(employee:, notification:)
      @employee = employee
      @notification = notification
    end

    def call
      record, created = EmployeeNotificationRead.find_or_create_by!(
        company: @employee.company, employee: @employee, notification: @notification
      ).then { |r| [ r, r.previously_new_record? ] }
      Rails.sync_cache.delete(Notifications::UnreadQuery.cache_key(@employee.id)) if created
      { success: true, created: created }
    rescue ActiveRecord::RecordInvalid => e
      { success: false, errors: e.record.errors.full_messages }
    end
  end
end
