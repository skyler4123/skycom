# frozen_string_literal: true

# Deletes notifications older than the retention window (dependent destroys
# clear tag links + read rows). Idempotent — a second run deletes 0.
module Notifications
  class PruneJob < ApplicationJob
    RETENTION = 90.days

    queue_as :default

    def perform
      stale = Notification.where("created_at < ?", RETENTION.ago)
      employee_ids = EmployeeNotificationRead.where(notification: stale).distinct.pluck(:employee_id)
      subscriber_ids = EmployeeNotificationTagAppointment.where(
        notification_tag_id: NotificationTagAppointment.where(notification: stale).select(:notification_tag_id)
      ).distinct.pluck(:employee_id)
      pruned = stale.destroy_all.size
      (employee_ids + subscriber_ids).uniq.each do |employee_id|
        Rails.sync_cache.delete(Notifications::UnreadQuery.cache_key(employee_id))
      end
      Rails.logger.info("[Notifications::PruneJob] pruned #{pruned} notifications")
    end
  end
end
