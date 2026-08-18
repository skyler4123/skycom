# frozen_string_literal: true

# Drains the Kredis credit-usage delta counters into the persisted usage tables.
# Counters are DELTAS since the last run: each counter's value is added to the
# DB (CompanyDailyUsage h<HH>, CompanyMonthlyUsage d<DD>) and then reset to 0,
# so the DB holds the cumulative total and a crash mid-run only loses the
# unsynced delta (re-synced on the next run).
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
    now = Time.current
    date = now.to_date

    daily_usage = CompanyDailyUsage.find_or_create_for(company, date)
    (0..23).each do |hour|
      counter = company.public_send("credit_usage_hour_#{hour}")
      delta = counter.value.to_i
      next if delta.zero?

      daily_usage.add_hour_usage(hour, delta)
      counter.decrement(by: delta)
    end

    monthly_usage = CompanyMonthlyUsage.find_or_create_for(company, date.beginning_of_month)
    daily_counter = company.credit_usage_daily
    daily_delta = daily_counter.value.to_i
    return if daily_delta.zero?

    monthly_usage.add_day_usage(date.day, daily_delta)
    daily_counter.decrement(by: daily_delta)
  end
end
