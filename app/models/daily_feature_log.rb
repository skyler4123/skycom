# frozen_string_literal: true

# Persisted snapshot of "was this addon feature active for this company on this calendar date?"
# Written by Billing::SyncDailyFeatureJob (runs every 6 hours).
# Read by Billing::CalculatorService at invoice time to compute daily-prorated
# addon feature charges per feature.
#
#   # Snapshot for a day
#   DailyFeatureLog.create!(company: c, contract_feature: f, log_date: Date.today)
#
#   # Count active days for a specific feature in a billing period
#   DailyFeatureLog.where(contract_feature: f).for_period(start_date, end_date).count
#
# One row per company + contract_feature + calendar date (uniqueness enforced by index).
# A row existing means the feature was active on that date and the company was accessible.
# Absence means the feature was disabled, or the company was suspended, on that day.
#
class DailyFeatureLog < ApplicationRecord
  belongs_to :company
  belongs_to :contract_feature

  validates :log_date, presence: true
  validates :log_date, uniqueness: { scope: %i[company_id contract_feature_id] }

  scope :for_period, ->(start_date, end_date) { where(log_date: start_date..end_date) }
end
