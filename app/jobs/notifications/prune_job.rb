# frozen_string_literal: true

# Deletes notifications older than the retention window (dependent destroys
# clear tag links + read rows). Idempotent — a second run deletes 0.
module Notifications
  class PruneJob < ApplicationJob
    RETENTION = 90.days

    queue_as :default

    def perform
      pruned = Notification.where("created_at < ?", RETENTION.ago).destroy_all.size
      Rails.logger.info("[Notifications::PruneJob] pruned #{pruned} notifications")
    end
  end
end
