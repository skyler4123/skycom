# Persisted snapshot of "did this company receive value on this calendar date?"
# Written by Billing::SyncDailyActiveJob (runs every 6 hours).
# Read by Billing::CalculatorService at invoice time to compute daily-prorated
# add-on feature charges.
#
#   # Snapshot for a day
#   DailyActiveLog.create!(company: c, log_date: Date.today)
#
#   # Count active days in a billing period
#   DailyActiveLog.where(company: c).for_period(start_date, end_date).count
#
# One row per company + calendar date (uniqueness enforced by index).
# A row existing means "accessible" on that date, regardless of how many
# times the 6-hour job fired. Absence means the company was suspended
# (or not yet created) for the entire day.
#
class DailyActiveLog < ApplicationRecord
  belongs_to :company

  validates :log_date, presence: true
  validates :log_date, uniqueness: { scope: :company_id }

  scope :for_period, ->(start_date, end_date) { where(log_date: start_date..end_date) }
end
