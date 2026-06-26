# frozen_string_literal: true

# Idempotent 6-hour snapshot of which companies are "accessible" (operational).
# A row in `daily_active_logs` means: on this calendar date, the company was
# reachable by its users and received value from the platform.
#
# The unique index on [company_id, log_date] makes this job idempotent — running
# it 4x in one calendar day produces exactly 1 row per accessible company.
#
# Billing::CalculatorService reads these rows at month end to compute
# daily-prorated add-on feature charges:
#   features_cents = (monthly_flat_price × active_days) / days_in_period
#
# Why 6-hour frequency?
#   If an admin suspends a company at 10:00 AM, the 06:00 or 12:00 run already
#   recorded the day. The company got 10 hours of value → fair to bill them for
#   that 1 calendar date. The unique index guarantees no double-counting.
#
module Billing
  class SyncDailyActiveJob < ApplicationJob
    queue_as :default

    def perform(log_date: Date.current)
      Company.where.not(lifecycle_status: :disabled).find_each(batch_size: 50) do |company|
        log_company_if_accessible(company, log_date)
      rescue StandardError => e
        Rails.logger.error("SyncDailyActiveJob: Failed for company #{company.id}: #{e.message}")
      end
    end

    private

    def log_company_if_accessible(company, log_date)
      return unless company.is_accessible?

      DailyActiveLog.find_or_create_by!(company: company, log_date: log_date)
    end
  end
end
