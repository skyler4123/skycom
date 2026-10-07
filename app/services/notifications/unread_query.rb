# frozen_string_literal: true

# == Purpose:
# Lazy unread computation for one employee: subscribed-tag join minus
# individually-read rows minus the mark-all-read shortcut.
#
# Unread = subscribed AND created_at > last_read_all_at AND id NOT IN reads.
module Notifications
  class UnreadQuery
    def self.cache_key(employee_id)
      "notifications:unread:#{employee_id}"
    end

    def initialize(company:, employee:)
      @company = company
      @employee = employee
    end

    def scope
      tag_ids = @employee.subscribed_notification_tag_ids
      return Notification.none if tag_ids.empty?

      config = NotificationConfig.for_employee!(@employee)
      Notification
        .joins(:notification_tag_appointments)
        .where(company: @company)
        .where(notification_tag_appointments: { notification_tag_id: tag_ids })
        .where("notifications.created_at > ?", config.last_read_all_at || @employee.created_at)
        .where.not(id: read_ids)
        .distinct
    end

    def count
      key = self.class.cache_key(@employee.id)
      cached = Rails.sync_cache.read(key)
      return cached.to_i unless cached.nil?

      value = scope.count
      Rails.sync_cache.write(key, value, expires_in: 10.minutes)
      value
    end

    private

    def read_ids
      EmployeeNotificationRead.where(employee: @employee).select(:notification_id)
    end
  end
end
