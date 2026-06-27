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
    COUNTRIES = [
      { code: :us, currency: "USD" },
      { code: :vn, currency: "VND" }
    ].freeze

    VOLUMETRIC_RESOURCES = {
      orders:          "Customer orders placed",
      storage_mb:      "File storage in megabytes",
      employees:       "Active employee records",
      branches:        "Active branch locations",
      customers:       "Customer records",
      api_calls:       "API requests",
      stock_mutations: "Stock import/export/transfer operations"
    }.freeze

    ADDON_FEATURES = {
      # Core Tier 1 (always free, always enabled)
      pos_basic:           "Point of Sale & Invoicing",
      inventory_basic:     "Single-location inventory",
      crm_basic:           "Customer directory",
      finance_basic:       "Income & expense tracking",
      # Tier 2 add-on features
      hrm_attendance:             "Time and attendance tracking",
      hrm_payroll_commissions:    "Payroll and commission management",
      inventory_advanced:         "Multi-warehouse and supplier management",
      crm_loyalty:                "Loyalty and rewards program",
      # Tier 3 add-on features
      multi_branch:               "Multi-branch management",
      automation_engine:          "Automated workflow rules",
      analytics_dashboard:        "Advanced analytics and reporting",
      payment_gateways:           "Integrated payment processing",
      # Tier 4 add-on features
      audit_logs:                 "Advanced auditing",
      custom_roles:               "Granular RBAC",
      open_api:                   "Developer API access",
      sso_saml:                   "Single sign-on"
    }.freeze

    US_PRICES = {
      pos_basic: 0, inventory_basic: 0, crm_basic: 0, finance_basic: 0,
      hrm_attendance: 200, hrm_payroll_commissions: 300,
      inventory_advanced: 300, crm_loyalty: 200,
      multi_branch: 400, automation_engine: 300,
      analytics_dashboard: 500, payment_gateways: 300,
      audit_logs: 300, custom_roles: 500,
      open_api: 700, sso_saml: 1000
    }.freeze

    VN_PRICES = {
      pos_basic: 0, inventory_basic: 0, crm_basic: 0, finance_basic: 0,
      hrm_attendance: 50_000, hrm_payroll_commissions: 75_000,
      inventory_advanced: 75_000, crm_loyalty: 50_000,
      multi_branch: 100_000, automation_engine: 75_000,
      analytics_dashboard: 125_000, payment_gateways: 75_000,
      audit_logs: 75_000, custom_roles: 125_000,
      open_api: 175_000, sso_saml: 250_000
    }.freeze

    PRICES_BY_COUNTRY = {
      us: US_PRICES,
      vn: VN_PRICES
    }.freeze

    def self.call
      COUNTRIES.each do |country|
        VOLUMETRIC_RESOURCES.each do |name, description|
          BillingResource.find_or_create_by!(name: name.to_s, country_code: country[:code]) do |r|
            r.description = description
            r.resource_type = :volumetric
            r.price_cents = 0
            r.currency = country[:currency]
          end
        end

        ADDON_FEATURES.each do |name, description|
          prices = PRICES_BY_COUNTRY[country[:code]]
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
