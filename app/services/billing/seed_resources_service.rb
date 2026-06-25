# frozen_string_literal: true

# Seeds the BillingResource catalog with all known metered resources and add-on features.
# Must be called during onboarding (e.g. rake task or company setup).
#
#   Billing::SeedResourcesService.call
#   # => 7 volumetric + 12 addon_feature BillingResource records created
#
# Volumetric resources (usage-based metering):
#   orders, storage_mb, employees, branches, customers, api_calls, stock_mutations
#
# Addon features (flat monthly fee):
#   hrm_attendance, inventory_advanced, analytics_dashboard, custom_roles, ...
#
module Billing
  class SeedResourcesService
    VOLUMETRIC_RESOURCES = {
      orders: "Customer orders placed",
      storage_mb: "File storage in megabytes",
      employees: "Active employee records",
      branches: "Active branch locations",
      customers: "Customer records",
      api_calls: "API requests",
      stock_mutations: "Stock import/export/transfer operations"
    }.freeze

    ADDON_FEATURES = {
      hrm_attendance: "Time and attendance tracking",
      hrm_payroll_commissions: "Payroll and commission management",
      inventory_advanced: "Multi-warehouse and supplier management",
      crm_loyalty: "Loyalty and rewards program",
      multi_branch: "Multi-branch management",
      automation_engine: "Automated workflow rules",
      analytics_dashboard: "Advanced analytics and reporting",
      payment_gateways: "Integrated payment processing",
      audit_logs: "Advanced auditing",
      custom_roles: "Granular RBAC",
      open_api: "Developer API access",
      sso_saml: "Single sign-on"
    }.freeze

    def self.call
      VOLUMETRIC_RESOURCES.each do |name, description|
        BillingResource.find_or_create_by!(name: name.to_s) do |r|
          r.description = description
          r.resource_type = :volumetric
        end
      end

      ADDON_FEATURES.each do |name, description|
        BillingResource.find_or_create_by!(name: name.to_s) do |r|
          r.description = description
          r.resource_type = :addon_feature
        end
      end
    end
  end
end
