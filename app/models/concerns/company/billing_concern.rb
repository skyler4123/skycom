# frozen_string_literal: true

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

  def record_usage!(resource_key, quantity: 1)
    date_key = Date.current.strftime("%Y%m%d")
    redis_key = "skycom:company:#{id}:#{resource_key}:#{date_key}"

    Kredis.redis.incrby(redis_key, quantity)
  rescue Redis::BaseConnectionError => e
    Rails.logger.warn("Metering Redis unavailable for company #{id}: #{e.message}")
  end
end
