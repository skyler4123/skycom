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
#   company.record_usage!("orders")         # Redis-backed with Kredis (DB fallback on restart)
#
#   # Read with Redis restart safety (Kredis default → DailyMetricLog)
#   company.meter_usage("orders")           # today's count
#   company.meter_usage("orders", log_date: 5.days.ago.to_date)
#
module Company::BillingConcern
  extend ActiveSupport::Concern

  def active_billing_contract
    billing_contracts.currently_active.sole
  rescue ActiveRecord::RecordNotFound
    nil
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
    key = "c:#{id}:#{resource_key}:#{log_date.strftime('%Y%m%d')}"
    Kredis.integer(key, default: -> {
      DailyMetricLog.where(company_id: id)
                    .joins(:billing_resource)
                    .where(billing_resources: { name: resource_key.to_s })
                    .where(log_date: log_date)
                    .sum(:usage_count)
    }, expires_in: REDIS_COUNTER_TTL)
  end

  def meter_usage(resource_key, log_date: Date.current)
    daily_meter(resource_key, log_date: log_date).value.to_i
  end

  # Uses atomic Redis INCRBY (single trip) instead of GET+SET (two trips).
  # After a Redis restart, the first increment for a given day starts from 0
  # instead of the DailyMetricLog-backed value. The SyncDailyMetricJob (every
  # 4h) eventually re-hydrates from DailyMetricLog via the "value" getter's
  # default lambda. This is an acceptable trade-off for atomicity.
  def billing_contract_summary
    contract = active_billing_contract
    return nil unless contract

    enabled = contract.contract_features.active.joins(:billing_resource).pluck("billing_resources.name")
    {
      contract_type: contract.contract_type,
      enabled_features: enabled
    }
  end

  def record_usage!(resource_key, quantity: 1)
    Kredis.redis.incrby(daily_meter(resource_key).key, quantity)
  rescue Redis::BaseConnectionError => e
    Rails.logger.warn("Metering Redis unavailable for company #{id}: #{e.message}")
  end
end
