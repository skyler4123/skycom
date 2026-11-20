# frozen_string_literal: true

# == Purpose:
# Lazy unread computation for one employee: visible notifications (subscribed
# tags plus direct recipient rows) minus individually-read rows minus the
# mark-all-read shortcut.
#
# Unread = visible AND created_at > last_read_all_at AND id NOT IN reads.
module Notifications
  class UnreadQuery
    def initialize(company:, employee:)
      @company = company
      @employee = employee
    end

    def scope
      Notification.subscribed_for(@employee, @company)
        .where("notifications.created_at > ?", last_read_all_at)
        .where.not(id: read_ids)
    end

    def count
      key = CacheKeyService.employee_unread_notifications(@employee.id)
      cached = Rails.sync_cache.read(key)
      return cached.to_i unless cached.nil?

      value = scope.count
      Rails.sync_cache.write(key, value, expires_in: CACHE_DEFAULT_EXPIRY)
      value
    end

    private

    # Read-path must never write: fall back to employee creation time when the
    # employee has never opened the config page (no row yet).
    def last_read_all_at
      NotificationConfig.where(employee: @employee).pick(:last_read_all_at) || @employee.created_at
    end

    def read_ids
      EmployeeNotificationRead.where(employee: @employee).select(:notification_id)
    end
  end
end
