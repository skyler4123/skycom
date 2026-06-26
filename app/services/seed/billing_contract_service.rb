# frozen_string_literal: true

# Creates a free-tier BillingContract for a company with default metrics and features.
# Called automatically by Company#setup_owner_records after owner role/policy/employee setup.
#
#   Seed::BillingContractService.create(company: company)
#   # => BillingContract (active, free_tier) + 7 ContractMetrics + 4 ContractFeatures
#
# Gracefully skips resources that aren't in the BillingResource catalog yet,
# so it works even if Billing::SeedResourcesService hasn't been run.
#
module Seed
  class BillingContractService
    # Default volumetric allowances + overage pricing (in cents) for free tier
    VOLUMETRIC_DEFAULTS = {
      orders:           { allowance: 200,   unit_price_cents: 10 },     # $0.10/order overage
      storage_mb:       { allowance: 500,   unit_price_cents: 1 },      # $0.01/MB overage
      employees:        { allowance: 3,     unit_price_cents: 500 },    # $5/employee overage
      branches:         { allowance: 1,     unit_price_cents: 1000 },   # $10/branch overage
      customers:        { allowance: 100,   unit_price_cents: 5 },      # $0.05/customer overage
      api_calls:        { allowance: 10_000, unit_price_cents: 0 },     # included, no overage
      stock_mutations:  { allowance: 500,   unit_price_cents: 2 }       # $0.02/mutation overage
    }.freeze

    # Core Tier 1 features that are always free (price = 0)
    CORE_FEATURES = %w[pos_basic inventory_basic crm_basic finance_basic].freeze

    def self.create(company:)
      contract = BillingContract.find_or_create_by!(
        company: company,
        name: "#{company.name} Free Tier",
        contract_type: :free_tier,
        lifecycle_status: :active,
        start_date: Time.current,
        fixed_monthly_price_cents: 0
      )

      attach_volumetric_metrics(contract)
      attach_core_features(contract)

      contract
    end

    def self.attach_volumetric_metrics(contract)
      VOLUMETRIC_DEFAULTS.each do |resource_name, config|
        resource = BillingResource.find_by(name: resource_name.to_s)
        next unless resource&.volumetric?

        ContractMetric.find_or_create_by!(
          billing_contract: contract,
          billing_resource: resource
        ) do |metric|
          metric.name = resource.name
          metric.free_allowance = config[:allowance]
          metric.unit_price_cents = config[:unit_price_cents]
          metric.lifecycle_status = :active
        end
      end
    end

    def self.attach_core_features(contract)
      CORE_FEATURES.each do |feature_name|
        resource = BillingResource.find_by(name: feature_name)
        next unless resource&.addon_feature?

        ContractFeature.find_or_create_by!(
          billing_contract: contract,
          billing_resource: resource
        ) do |feature|
          feature.name = feature_name
          feature.monthly_flat_price_cents = 0
          feature.lifecycle_status = :active
        end
      end
    end
  end
end
