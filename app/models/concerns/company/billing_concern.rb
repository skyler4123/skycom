# frozen_string_literal: true

# Feature gating, wallet helpers, and Redis-backed usage metering.
# Included in Company — all methods available on any company instance.
#
#   # Feature check (gates UI and API access)
#   company.feature_enabled?("analytics_dashboard")  # => true/false
#
#   # Wallet balance
#   company.wallet_balance_cents            # promo + main
#   company.debt_ceiling_reached?           # below soft_debt_threshold?
#
#   # Metering (called by MeteringConcern after_commit)
#   company.record_usage!("orders")         # atomic INCRBY in Redis
#
#   # Read with Redis restart safety (Kredis default → DailyUsageLog)
#   company.meter_usage("orders")           # today's count
#   company.meter_usage("orders", log_date: 5.days.ago.to_date)
#
module Company::BillingConcern
  extend ActiveSupport::Concern

  def active_billing_contract
    billing_contracts.currently_active.first
  end

  def feature_enabled?(feature_key)
    contract = active_billing_contract
    return false unless contract

    resource = BillingResource.find_by(name: feature_key.to_s, resource_type: :addon_feature)
    return false unless resource

    contract.contract_features.active.exists?(billing_resource: resource)
  end

  def wallet_balance_cents
    main_balance_cents + promo_balance_cents
  end

  def debt_ceiling_reached?
    wallet_balance_cents < soft_debt_threshold_cents
  end

  def daily_meter(resource_key, log_date: Date.current)
    key = "skycom:company:#{id}:#{resource_key}:#{log_date.strftime('%Y%m%d')}"
    Kredis.integer(key, default: -> {
      DailyUsageLog.where(company_id: id)
                   .joins(:billing_resource)
                   .where(billing_resources: { name: resource_key.to_s })
                   .where(log_date: log_date)
                   .sum(:usage_count)
    })
  end

  def meter_usage(resource_key, log_date: Date.current)
    daily_meter(resource_key, log_date: log_date).value.to_i
  end

  def record_usage!(resource_key, quantity: 1)
    date_key = Date.current.strftime("%Y%m%d")
    redis_key = "skycom:company:#{id}:#{resource_key}:#{date_key}"

    Kredis.redis.incrby(redis_key, quantity)
  rescue Redis::BaseConnectionError => e
    Rails.logger.warn("Metering Redis unavailable for company #{id}: #{e.message}")
  end
end
