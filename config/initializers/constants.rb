# Timezone offsets used by the Period model (periods.timezone enum),
# Branch model, and Company model. Keyed as Rails enum values.
TIMEZONES = {
  minus_12: -12, minus_11: -11, minus_10: -10, minus_9:  -9,
  minus_8:  -8,  minus_7:  -7,  minus_6:  -6,  minus_5:  -5,
  minus_4:  -4,  minus_3:  -3,  minus_2:  -2,  minus_1:  -1,
  utc:      0,   plus_1:   1,   plus_2:   2,   plus_3:   3,
  plus_4:   4,   plus_5:   5,   plus_6:   6,   plus_7:   7,
  plus_8:   8,   plus_9:   9,   plus_10:  10,  plus_11:  11,
  plus_12:  12
}.freeze

# Currency ISO numeric codes used by the Price model (prices.currency_code enum).
CURRENCIE_CODES = {
  usd: 840,
  vnd: 704
}

# Country ISO numeric codes used by User (user.country_code enum).
COUNTRIE_CODES = {
  us: 840,
  vn: 704
}

# Lifecycle statuses used across all business models (lifecycle_status enum).
LIFECYCLE_STATUS = {
  active: 0,
  inactive: 1,
  archived: 2,
  suspended: 3,
  deleted: 4
}

# Workflow statuses used across order, invoice, payment, and policy models (workflow_status enum).
WORKFLOW_STATUS = {
  draft: 0,
  pending: 1,
  confirmed: 2,
  in_progress: 3,
  completed: 4,
  paid: 5,
  cancelled: 6,
  refunded: 7,
  failed: 8
}

# =============================================================================
# Image & Avatar Constraints
# Applied across 7 model concerns (Branch, Brand, Customer, Department,
# Employee, Product, Service) via their respective ImageConcern modules.
# =============================================================================

# Max number of image attachments per record (used in validation).
MAX_IMAGE_ATTACHMENTS = 3

# Max file size for business entity images (products, employees, etc.).
# Used by Branch::ImageConcern, Employee::ImageConcern, and all other ImageConcern modules.
MAX_IMAGE_FILE_SIZE = 1.megabyte

# Max file size for user/company avatar images.
# Used by User::AvatarConcern.
MAX_AVATAR_FILE_SIZE = 500.kilobytes

# Allowed MIME types for business entity images.
# Used by all 7 ImageConcern modules + User::ChatImagesConcern.
ACCEPTABLE_IMAGE_TYPES = %w[image/jpeg image/png image/gif].freeze

# Allowed MIME types for user/company avatars (stricter than images).
# Used by User::AvatarConcern.
ACCEPTABLE_AVATAR_TYPES = %w[image/jpeg image/png].freeze

# ActiveStorage variant dimensions for business entity images.
IMAGE_FULL_DIMENSIONS = [ 300, 300 ].freeze
IMAGE_THUMB_DIMENSIONS = [ 50, 50 ].freeze

# ActiveStorage variant dimensions for user/company avatars.
# Used by User::AvatarConcern (thumb, medium, profile, full) and
# AvatarConcern (common: thumb, medium, profile, card, common_full).
AVATAR_THUMB_DIMENSIONS = [ 50, 50 ].freeze
AVATAR_MEDIUM_DIMENSIONS = [ 150, 150 ].freeze
AVATAR_PROFILE_DIMENSIONS = [ 300, 300 ].freeze
AVATAR_FULL_DIMENSIONS = [ 800, 800 ].freeze
AVATAR_CARD_DIMENSIONS = [ 400, 250 ].freeze
AVATAR_COMMON_FULL_DIMENSIONS = [ 1200, 1200 ].freeze

# =============================================================================
# Cache & Expiry
# =============================================================================

# How long session/cache cookies persist in the browser (set via expires:).
# Used by ApplicationController::CookieConcern (4 occurrences).
COOKIE_EXPIRY = 1.day

# TTL for cached ABAC permission data per employee/company.
# Used by Employee::PermissionConcern and Company::PermissionConcern.
PERMISSIONS_CACHE_EXPIRY = 1.minute

# Default TTL for model attribute caching in Cache::RecordsConcern.
# Used by cached_find / cached_where class methods when no explicit
# expires_in is provided.
DEFAULT_CACHE_EXPIRY = 5.minutes

# TTL for Redis daily usage counter keys (Kredis).
# After this period, Redis may evict the key; DailyMetricLog serves
# as fallback. Used by Company::BillingConcern#daily_meter.
REDIS_COUNTER_TTL = 36.hours

# Default TTL for cache_query Kernel method (defined in global_methods.rb).
QUERY_CACHE_EXPIRY = 1.hour

# =============================================================================
# Security & Token Expiry
# =============================================================================

# How long email verification links remain valid.
# Used by User model (generates_token_for :email_verification).
EMAIL_VERIFICATION_TOKEN_EXPIRY = 2.days

# How long password reset links remain valid.
# Used by User model (generates_token_for :password_reset).
PASSWORD_RESET_TOKEN_EXPIRY = 20.minutes

# How long magic-link sign-in tokens remain valid.
# Used by UserMailer#passwordless (signed_id).
SIGN_IN_TOKEN_EXPIRY = 1.day

# Max registration attempts per time window (rack-rate_limit gem).
REGISTRATION_RATE_LIMIT_MAX = 3
REGISTRATION_RATE_LIMIT_WINDOW = 1.minute

# =============================================================================
# Owner Role Constants (ABAC)
# Magic-string values used across the permission system to identify
# owner-level access. Owner roles bypass all ABAC permission checks.
# Referenced in: Company, Employee, PolicyAppointment, RoleAppointment,
# seed services, and permission concerns.
# =============================================================================

OWNER_BUSINESS_TYPE = "owner".freeze
OWNER_POLICY_RESOURCE = "all".freeze
OWNER_POLICY_ACTION = "all".freeze

# =============================================================================
# Model Validation Limits
# =============================================================================

# Max length for phone_number fields on Company and Branch models.
MAX_PHONE_NUMBER_LENGTH = 20

# =============================================================================
# Billing Policy Thresholds
# =============================================================================

# How long after has_unpaid_invoices_at before the billing warning banner
# appears in the UI. Used by Companies::ApplicationController.
UNPAID_WARNING_THRESHOLD = 5.days

# Default soft_debt_threshold_cents for BillingContracts created via
# migrations. When wallet_balance_cents drops below this,
# debt_ceiling_reached? returns true.
DEFAULT_SOFT_DEBT_THRESHOLD_CENTS = -10000

# =============================================================================
# Billing Resource Catalog (Seed Data)
# Used by Billing::SeedResourcesService to populate the BillingResource
# catalog — the global registry of all metered and add-on features.
# =============================================================================

# Volumetric resources tracked by the metering engine (usage-based).
BILLING_VOLUMETRIC_RESOURCES = {
  orders:          "Customer orders placed",
  storage_mb:      "File storage in megabytes",
  employees:       "Active employee records",
  branches:        "Active branch locations",
  customers:       "Customer records",
  api_calls:       "API requests",
  stock_mutations: "Stock import/export/transfer operations"
}.freeze

# All known add-on features available in the platform (flat monthly fee).
BILLING_ADDON_FEATURES = {
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

# =============================================================================
# Free Tier Defaults
# Used by Seed::BillingContractService for new company onboarding.
# =============================================================================

# Default allowances and overage unit prices for new free-tier contracts.
DEFAULT_FREE_TIER_ALLOWANCES = {
  orders:           { allowance: 200,   unit_price_cents: 10 },
  storage_mb:       { allowance: 500,   unit_price_cents: 1 },
  employees:        { allowance: 3,     unit_price_cents: 500 },
  branches:         { allowance: 1,     unit_price_cents: 1000 },
  customers:        { allowance: 100,   unit_price_cents: 5 },
  api_calls:        { allowance: 10_000, unit_price_cents: 0 },
  stock_mutations:  { allowance: 500,   unit_price_cents: 2 }
}.freeze

# Feature keys auto-enabled on every new free-tier contract.
CORE_FREE_FEATURES = %w[pos_basic inventory_basic crm_basic finance_basic].freeze

# =============================================================================
# Country Pricing Tables
# Per-feature monthly add-on prices in cents, keyed by country.
# Used by Billing::SeedResourcesService to seed BillingResource records.
# =============================================================================

# Supported billing markets.
BILLING_COUNTRIES = [
  { code: :us, currency: "USD" }.freeze,
  { code: :vn, currency: "VND" }.freeze
].freeze

# US market prices (cents per month).
BILLING_US_PRICES = {
  pos_basic: 0, inventory_basic: 0, crm_basic: 0, finance_basic: 0,
  hrm_attendance: 200, hrm_payroll_commissions: 300,
  inventory_advanced: 300, crm_loyalty: 200,
  multi_branch: 400, automation_engine: 300,
  analytics_dashboard: 500, payment_gateways: 300,
  audit_logs: 300, custom_roles: 500,
  open_api: 700, sso_saml: 1000
}.freeze

# VN market prices (cents per month).
BILLING_VN_PRICES = {
  pos_basic: 0, inventory_basic: 0, crm_basic: 0, finance_basic: 0,
  hrm_attendance: 50_000, hrm_payroll_commissions: 75_000,
  inventory_advanced: 75_000, crm_loyalty: 50_000,
  multi_branch: 100_000, automation_engine: 75_000,
  analytics_dashboard: 125_000, payment_gateways: 75_000,
  audit_logs: 75_000, custom_roles: 125_000,
  open_api: 175_000, sso_saml: 250_000
}.freeze

# Lookup: country code -> price hash.
BILLING_PRICES_BY_COUNTRY = {
  us: BILLING_US_PRICES,
  vn: BILLING_VN_PRICES
}.freeze

# =============================================================================
# Job Processing Defaults
# =============================================================================

# Number of records per batch when iterating companies in billing jobs.
# Used by SyncSuspensionJob, SyncDailyFeatureJob, MonthlyBillingJob.
COMPANY_PROCESSING_BATCH_SIZE = 50

# Number of keys to scan per cursor in Redis SCAN.
# Used by SyncDailyMetricJob to paginate through metering keys.
REDIS_SCAN_COUNT = 100

# =============================================================================
# RailsPulse Retention
# Performance monitoring data retention settings.
# Applied in config/initializers/rails_pulse.rb.
# =============================================================================

# How long raw request/query data is retained before automatic cleanup.
RAILS_PULSE_RETENTION_PERIOD = 2.weeks

# Max rows per table before oldest records are pruned during cleanup.
RAILS_PULSE_MAX_TABLE_RECORDS = {
  rails_pulse_requests: 10000,
  rails_pulse_operations: 50000,
  rails_pulse_routes: 1000,
  rails_pulse_queries: 500
}.freeze

# =============================================================================
# Property Mapping & Table Config (Dynamic Schema Validation)
# =============================================================================

# Allowed metadata keys per property type in PropertyMapping#property_metadata.
# Used by PropertyMapping#validate_property_metadata.
PROPERTY_MAPPING_SUPPORTED_KEYS = {
  property_string:  %w[label input_type placeholder suffix prefix default].freeze,
  property_text:    %w[label input_type placeholder default].freeze,
  property_integer: %w[label input_type placeholder suffix prefix default min max options].freeze,
  property_decimal: %w[label input_type placeholder suffix prefix default currency precision].freeze,
  property_boolean: %w[label input_type placeholder suffix prefix default true_label false_label].freeze,
  property_datetime: %w[label input_type placeholder suffix prefix default format timezone].freeze
}.freeze

# Allowed input_type values per property type.
# Used by PropertyMapping#validate_property_metadata.
PROPERTY_MAPPING_VALID_INPUT_TYPES = {
  property_string:  %w[text].freeze,
  property_text:    %w[textarea].freeze,
  property_integer: %w[select progress_bar slider star].freeze,
  property_decimal: %w[currency number percentage].freeze,
  property_boolean: %w[toggle].freeze,
  property_datetime: nil
}.freeze

# Valid values for column alignment and pinned position in TableConfig.
# Used by TableConfig#columns_metadata_must_conform_to_schema.
ALLOWED_TABLE_ALIGNS = %w[left center right].freeze
ALLOWED_TABLE_PINNEDS = %w[left right].freeze

# =============================================================================
# Subscription Limits
# Maximum values per company on free/basic plans.
# Used by frontend controllers for usage guardrails and upgrade prompts.
# =============================================================================

SUBSCRIPTION_LIMITS = {
  max_of_branches: 3,
  max_of_employees: 5
}.freeze
