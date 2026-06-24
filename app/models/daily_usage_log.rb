# app/models/daily_usage_log.rb
class DailyUsageLog < ApplicationRecord
  belongs_to :company
  belongs_to :billing_resource

  validates :usage_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :log_date, presence: true

  # Ensure we only have one log entry per company, per resource, per day
  validates :log_date, uniqueness: { scope: [ :company_id, :billing_resource_id ],
                                     message: "already has a usage log for this resource on this day" }

  # Fast lookup helper for the monthly calculation cron-job
  scope :for_period, ->(start_date, end_date) { where(log_date: start_date..end_date) }
end
