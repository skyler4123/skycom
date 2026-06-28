# frozen_string_literal: true

# Scans Redis for today's metering counters and persists them to DailyMetricLog.
# Runs every 4 hours (configured in config/recurring.yml).
#
# Flow:
#   1. SCAN Redis for keys matching "skycom:company:*:*:<YYYYMMDD>"
#   2. For each key: read via company.meter_usage (Kredis with DB fallback)
#   3. Upsert DailyMetricLog row
#   4. Key remains in Redis with 36h TTL (set by Kredis) — no manual clean-up needed
#
# After Redis restart, meter_usage's Kredis default lambda re-hydrates
# from DailyMetricLog, so no data is lost within the 4-hour window.
#
module Billing
  class SyncDailyMetricJob < ApplicationJob
    queue_as :default

    SCAN_PATTERN = "skycom:company:*:*:"

    def perform(log_date: Date.current)
      date_str = log_date.strftime("%Y%m%d")
      scan_match = "#{SCAN_PATTERN}#{date_str}"

      cursor = "0"
      loop do
        cursor, keys = Kredis.redis.scan(cursor, match: scan_match, count: REDIS_SCAN_COUNT)
        break if cursor == "0" && keys.empty?

        keys.each { |key| process_key(key, log_date) }

        break if cursor == "0"
      end
    end

    private

    def process_key(key, log_date)
      # Key format: skycom:company:<uuid>:<resource_name>:<YYYYMMDD>
      parts = key.split(":")
      company_id = parts[2]
      resource_name = parts[3]

      company = Company.find_by(id: company_id)
      resource = BillingResource.find_by(name: resource_name)

      unless company && resource
        Rails.logger.warn("SyncDailyMetricJob: Skipping key #{key} — company or resource not found")
        return
      end

      value = company.meter_usage(resource_name, log_date: log_date)
      return if value.zero?

      DailyMetricLog.find_or_initialize_by(
        company: company,
        billing_resource: resource,
        log_date: log_date
      ).update!(usage_count: value)
    rescue ActiveRecord::RecordInvalid, Redis::BaseConnectionError => e
      Rails.logger.warn("SyncDailyMetricJob: Error processing key #{key}: #{e.message}")
    end
  end
end
