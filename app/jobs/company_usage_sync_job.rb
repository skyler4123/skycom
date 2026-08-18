# frozen_string_literal: true

# Drains the Kredis credit-usage delta counter into the persisted usage tables.
# The counter only counts and resets — it is agnostic to this job's period:
# whatever accumulated since the last run is added to the DB (CompanyDailyUsage
# h<drain hour>, CompanyMonthlyUsage d<drain day>) and then the counter is reset
# to 0. The DB holds the cumulative total; a coarser schedule only coarsens
# hour-slot attribution, never loses or double-counts data.
class CompanyUsageSyncJob < ApplicationJob
  queue_as :default

  def perform
    Company.find_each(batch_size: 50) do |company|
      sync_company(company)
    rescue StandardError => e
      Rails.logger.error("[CompanyUsageSync] company #{company.id}: #{e.message}")
    end
  end

  private

  def sync_company(company)
    counter = company.credit_usage
    delta = counter.value.to_i
    return if delta.zero?

    now = Time.current
    date = now.to_date

    daily_usage = CompanyDailyUsage.find_or_create_for(company, date)
    daily_usage.add_hour_usage(now.hour, delta)

    monthly_usage = CompanyMonthlyUsage.find_or_create_for(company, date.beginning_of_month)
    monthly_usage.add_day_usage(date.day, delta)

    counter.decrement(by: delta)
  end
end
