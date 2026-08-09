# frozen_string_literal: true

# Catalog of everything that can be metered or billed in the platform.
# Two types: volumetric (usage-based) and addon_feature (flat monthly fee).
# Each resource has country-specific pricing (US, VN, etc.).
#
# Seeded by Billing::SeedResourcesService:
#   volumetric:   orders, storage_mb, employees, branches, customers, api_calls, stock_mutations
#   addon_feature: pos_basic, inventory_basic, crm_basic, finance_basic (free),
#                  hrm_attendance, inventory_advanced, analytics_dashboard, ...
#
#   BillingResource.volumetric     # scope
#   BillingResource.addon_feature  # scope
#   resource.volumetric?           # => true
#
class BillingResource < ApplicationRecord
  attribute :price_cents, :integer, default: 0

  monetize :price_cents,
           as: "price",
           with_model_currency: :currency,
           disable_validation: true

  has_many :contract_features, dependent: :destroy
  has_many :contract_metrics, dependent: :destroy
  has_many :daily_metric_logs, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :country }

  enum :resource_type, { volumetric: 0, addon_feature: 1 }, default: :volumetric
  enum :lifecycle_status, { active: 0, deprecated: 1, archived: 2 }, default: :active
  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # Volumetric resources tracked by the metering engine (usage-based).
  VOLUMETRIC_RESOURCES = {
    orders:          "Customer orders placed",
    storage_mb:      "File storage in megabytes",
    employees:       "Active employee records",
    branches:        "Active branch locations",
    customers:       "Customer records",
    api_calls:       "API requests",
    stock_mutations: "Stock import/export/transfer operations"
  }.freeze

  # All known add-on features available in the platform (flat monthly fee).
  ADDON_FEATURES = {
    # Core Tier 1 (always free)
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

  # Supported billing markets.
  COUNTRIES = [
    { code: :us, currency: "USD" }.freeze,
    { code: :vn, currency: "VND" }.freeze
  ].freeze

  # US market prices (cents per month).
  US_PRICES = {
    pos_basic: 0, inventory_basic: 0, crm_basic: 0, finance_basic: 0,
    hrm_attendance: 200, hrm_payroll_commissions: 300,
    inventory_advanced: 300, crm_loyalty: 200,
    multi_branch: 400, automation_engine: 300,
    analytics_dashboard: 500, payment_gateways: 300,
    audit_logs: 300, custom_roles: 500,
    open_api: 700, sso_saml: 1000
  }.freeze

  # VN market prices (cents per month).
  VN_PRICES = {
    pos_basic: 0, inventory_basic: 0, crm_basic: 0, finance_basic: 0,
    hrm_attendance: 50_000, hrm_payroll_commissions: 75_000,
    inventory_advanced: 75_000, crm_loyalty: 50_000,
    multi_branch: 100_000, automation_engine: 75_000,
    analytics_dashboard: 125_000, payment_gateways: 75_000,
    audit_logs: 75_000, custom_roles: 125_000,
    open_api: 175_000, sso_saml: 250_000
  }.freeze

  # Lookup: country code -> price hash.
  PRICES_BY_COUNTRY = {
    us: US_PRICES,
    vn: VN_PRICES
  }.freeze
end
