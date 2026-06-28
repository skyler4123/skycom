# frozen_string_literal: true

# Seeds the BillingResource catalog with all known metered resources and add-on features.
# Each resource is created per supported country (US, VN) with market-specific pricing.
# Must be called during onboarding (e.g. rake task or company setup).
#
#   Billing::SeedResourcesService.call
#   # => 7 volumetric + 16 addon_feature BillingResource records created per country
#
# Volumetric resources (usage-based metering):
#   orders, storage_mb, employees, branches, customers, api_calls, stock_mutations
#
# Addon features (flat monthly fee):
#   pos_basic, inventory_basic, crm_basic, finance_basic (free),
#   hrm_attendance, inventory_advanced, analytics_dashboard, custom_roles, ...
#
module Billing
  class SeedResourcesService
    def self.call
      BILLING_COUNTRIES.each do |country|
        BILLING_VOLUMETRIC_RESOURCES.each do |name, description|
          BillingResource.find_or_create_by!(name: name.to_s, country_code: country[:code]) do |r|
            r.description = description
            r.resource_type = :volumetric
            r.price_cents = 0
            r.currency = country[:currency]
          end
        end

        BILLING_ADDON_FEATURES.each do |name, description|
          prices = BILLING_PRICES_BY_COUNTRY[country[:code]]
          BillingResource.find_or_create_by!(name: name.to_s, country_code: country[:code]) do |r|
            r.description = description
            r.resource_type = :addon_feature
            r.price_cents = prices[name]
            r.currency = country[:currency]
          end
        end
      end
    end
  end
end
