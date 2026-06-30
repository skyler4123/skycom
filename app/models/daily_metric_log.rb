# Persisted daily snapshot of Redis metering counters for volumetric metrics.
# Written by Billing::SyncDailyMetricJob (runs every 4 hours).
# Read by Billing::CalculatorService during monthly billing.
#
#   # Record usage for a day
#   DailyMetricLog.create!(company: c, billing_resource: r, log_date: Date.today, usage_count: 42)
#
#   # Sum usage over a billing period
#   DailyMetricLog.where(company: c, billing_resource: r)
#                .for_period(start_date, end_date)
#                .sum(:usage_count)
#
# One row per company + resource + day (uniqueness enforced).
#
class DailyMetricLog < ApplicationRecord
  belongs_to :company
  belongs_to :billing_resource

  validates :usage_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :log_date, presence: true

  validates :log_date, uniqueness: { scope: [ :company_id, :billing_resource_id ],
                                     message: "already has a usage log for this resource on this day" }

  scope :for_period, ->(start_date, end_date) { where(log_date: start_date..end_date) }
end
