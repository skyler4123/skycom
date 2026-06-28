# frozen_string_literal: true

# Idempotent 6-hour snapshot of which addon features are active per company.
# A row in `daily_feature_logs` means: on this calendar date, the company was
# reachable AND this addon feature was enabled.
#
# The unique index on [company_id, contract_feature_id, log_date] makes this job
# idempotent — running it 4x in one calendar day produces exactly 1 row per
# active feature per day.
#
# Billing::CalculatorService reads these rows at month end to compute daily-prorated
# addon feature charges per feature:
#   feature_cents = (monthly_flat_price × feature_active_days) / days_in_period
#
# Why 6-hour frequency?
#   If a feature is enabled at 10:00 AM, the 06:00 or 12:00 run recorded the day.
#   The company got value from that feature for 10+ hours → fair to bill for 1 date.
#
module Billing
  class SyncDailyFeatureJob < ApplicationJob
    queue_as :default

    def perform(log_date: Date.current)
      Company.where.not(lifecycle_status: %i[disabled suspended]).find_each(batch_size: COMPANY_PROCESSING_BATCH_SIZE) do |company|
        log_features_for_company(company, log_date)
      rescue StandardError => e
        Rails.logger.error("SyncDailyFeatureJob: Failed for company #{company.id}: #{e.message}")
      end
    end

    private

    def log_features_for_company(company, log_date)
      return unless company.is_accessible?

      company.active_billing_contract&.contract_features&.active&.find_each do |feature|
        DailyFeatureLog.find_or_create_by!(
          company: company,
          contract_feature: feature,
          log_date: log_date
        )
      end
    end
  end
end
