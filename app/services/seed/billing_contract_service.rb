# frozen_string_literal: true

# Creates a free-tier BillingContract for a company with default metrics and features.
# Called automatically by Company#setup_owner_records after owner role/policy/employee setup.
#
#   Seed::BillingContractService.create(company: company)
#   # => BillingContract (active, basic) + 7 ContractMetrics + 4 ContractFeatures
#
# Uses the company's country_code to look up country-specific pricing from BillingResource.
#
module Seed
  class BillingContractService
    def self.create(company:)
      contract = BillingContract.find_or_create_by!(
        company: company,
        name: "#{company.name} Free Tier",
        contract_type: :basic,
        lifecycle_status: :active,
        start_date: Time.current,
        fixed_monthly_price_cents: 0
      )

      attach_volumetric_metrics(contract, company)
      attach_core_features(contract, company)

      contract
    end

    def self.attach_volumetric_metrics(contract, company)
      DEFAULT_FREE_TIER_ALLOWANCES.each do |resource_name, config|
        resource = BillingResource.find_by(name: resource_name.to_s, country_code: company.country_code)
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

    def self.attach_core_features(contract, company)
      CORE_FREE_FEATURES.each do |feature_name|
        resource = BillingResource.find_by(name: feature_name, country_code: company.country_code)
        next unless resource&.addon_feature?

        ContractFeature.find_or_create_by!(
          billing_contract: contract,
          billing_resource: resource
        ) do |feature|
          feature.name = feature_name
          feature.monthly_flat_price_cents = 0
          feature.monthly_flat_price_currency = resource.currency
          feature.lifecycle_status = :active
        end
      end
    end
  end
end
