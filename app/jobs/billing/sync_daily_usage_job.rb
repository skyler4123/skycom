# frozen_string_literal: true

module Billing
  class SyncDailyUsageJob < ApplicationJob
    queue_as :default

    SCAN_PATTERN = "skycom:company:*:*:"

    def perform(log_date: Date.current)
      date_str = log_date.strftime("%Y%m%d")
      scan_match = "#{SCAN_PATTERN}#{date_str}"

      cursor = "0"
      loop do
        cursor, keys = Kredis.redis.scan(cursor, match: scan_match, count: 100)
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
        Rails.logger.warn("SyncDailyUsageJob: Skipping key #{key} — company or resource not found")
        return
      end

      value = Kredis.redis.get(key).to_i
      return if value.zero?

      DailyUsageLog.find_or_initialize_by(
        company: company,
        billing_resource: resource,
        log_date: log_date
      ).update!(usage_count: value)

      Kredis.redis.del(key)
    rescue ActiveRecord::RecordInvalid, Redis::BaseConnectionError => e
      Rails.logger.warn("SyncDailyUsageJob: Error processing key #{key}: #{e.message}")
    end
  end
end
