# Timezone offsets used by Branch model, Company model, and Product model.
# Keyed as Rails enum values.
TIMEZONES = {
  minus_12: -12, minus_11: -11, minus_10: -10, minus_9:  -9,
  minus_8:  -8,  minus_7:  -7,  minus_6:  -6,  minus_5:  -5,
  minus_4:  -4,  minus_3:  -3,  minus_2:  -2,  minus_1:  -1,
  utc:      0,   plus_1:   1,   plus_2:   2,   plus_3:   3,
  plus_4:   4,   plus_5:   5,   plus_6:   6,   plus_7:   7,
  plus_8:   8,   plus_9:   9,   plus_10:  10,  plus_11:  11,
  plus_12:  12
}.freeze

# Currency ISO numeric codes used by Product (products.currency_code enum).
CURRENCIE_CODES = {
  usd: 840,
  vnd: 704
}

# Country ISO numeric codes used by User (user.country_code enum).
COUNTRY_CODES = {
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

GATEWAY_STRATEGIES = {
  # System payments (value < 10 — no external gateway call)
  cash: 0,
  wallet_auto_debit: 1,
  # External gateway strategies (value >= 10)
  mock_qr_gateway: 10,
  mock_redirect_gateway: 11,
  stripe_gateway: 12,
  viet_qr_gateway: 13
}.freeze

GATEWAY_STRATEGY_CLASSES = {
  cash: "Payments::Cash",
  wallet_auto_debit: "Payments::WalletAutoDebit",
  mock_qr_gateway: "Payments::MockQrGateway",
  mock_redirect_gateway: "Payments::MockRedirectGateway",
  stripe_gateway: "Payments::StripeGateway",
  viet_qr_gateway: "Payments::VietQrGateway"
}.freeze

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

# Per-session cache TTL for Session.cached_find in AuthenticationConcern.
# Longer than DEFAULT_CACHE_EXPIRY because session records rarely change
# and the global cache (Redis) provides cross-instance invalidation.
SESSION_CACHE_EXPIRY = 1.hour

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
# Property Mapping & Table Config (Dynamic Schema Validation)
# =============================================================================

# Allowed metadata keys per property type in PropertyMapping#property_metadata.
# Used by PropertyMapping#validate_property_metadata.
PROPERTY_MAPPING_SUPPORTED_KEYS = {
  property_string:  %w[input_type placeholder suffix prefix default].freeze,
  property_text:    %w[input_type placeholder default].freeze,
  property_integer: %w[input_type placeholder suffix prefix default min max options].freeze,
  property_decimal: %w[input_type placeholder suffix prefix default currency precision].freeze,
  property_boolean: %w[input_type placeholder suffix prefix default true_label false_label].freeze,
  property_datetime: %w[input_type placeholder suffix prefix default format timezone].freeze
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

# =============================================================================
# OmniAuth Mock Credentials
# Used in development/test for Google OAuth sign-in.
# =============================================================================

MOCK_OAUTH_EMAIL = "Manager_1_clinic_1@company3.com".freeze

# =============================================================================
# Company Defaults
# =============================================================================

# Default resource names for new companies. Used by Company#resource_names
# (which reads from metadata with this as a fallback).
DEFAULT_RESOURCE_NAMES = %w[
  Product Order Customer Employee Branch Department
  PolicyAppointment Invoice Transaction Service Policy
  Category PropertyMapping TableConfig Brand Facility
  Table Reservation Room Guest
  Patient Appointment Course Student Exam
  Membership
  Page ShiftTemplate ScheduledShift
  AttendancePolicy AttendanceLog AttendanceDay AttendanceMonth
  Stock StockTransfer StockImport StockExport
].freeze

# =============================================================================
# Retail Init Defaults
# Used by Seed::RetailInitService to bootstrap a new retail company with
# system records (roles, categories, property_mappings, table_configs).
# =============================================================================

RETAIL_INIT_ROLES = [
  :Manager, :Cashier, :Seller, :Security, :Admin, :Doctor, :Therapist, :Consultant
].freeze

RETAIL_INIT_COMPANY_GROUP_BUSINESS_TYPE = :retail

RETAIL_INIT_CATEGORIES = {
  products: {
    "Cosmetics" => {
      properties: {
        property_string_1: "Skin Type Suitability",
        property_string_2: "Key Ingredients",
        property_integer_1: "Volume (ml)",
        property_boolean_1: "Organic Certified"
      },
      visible_columns: %w[name code property_string_1 property_string_2 property_integer_1 property_boolean_1]
    },
    "Perfumes" => {
      properties: {
        property_string_1: "Scent Profile / Notes",
        property_integer_1: "Volume (ml)",
        property_boolean_1: "Includes Tester Unit"
      },
      visible_columns: %w[name code property_string_1 property_integer_1 property_boolean_1]
    },
    "Beauty Tools" => {
      properties: {
        property_string_1: "Power Source",
        property_integer_1: "Wattage",
        property_boolean_1: "Rechargeable"
      },
      visible_columns: %w[name code property_string_1 property_integer_1 property_boolean_1]
    },
    "Makeup" => {
      properties: {
        property_string_1: "Finish Type",
        property_string_2: "Shade Range",
        property_boolean_1: "Long-lasting"
      },
      visible_columns: %w[name code property_string_1 property_string_2 property_boolean_1]
    },
    "Jewelry" => {
      properties: {
        property_string_1: "Material",
        property_decimal_1: "Weight (g)",
        property_boolean_1: "Hypoallergenic"
      },
      visible_columns: %w[name code property_string_1 property_decimal_1 property_boolean_1]
    },
    "Accessories" => {
      properties: {
        property_string_1: "Material",
        property_boolean_1: "Adjustable"
      },
      visible_columns: %w[name code property_string_1 property_boolean_1]
    }
  },
  employees: {
    "Management" => {
      properties: {
        property_integer_1: "Team Size",
        property_string_1: "Department"
      },
      visible_columns: %w[name code business_type workflow_status property_integer_1 property_string_1]
    },
    "Sales Specialist" => {
      properties: {
        property_decimal_1: "Monthly Target",
        property_integer_1: "Client Portfolio Size"
      },
      visible_columns: %w[name code business_type workflow_status property_decimal_1 property_integer_1]
    },
    "Cashier" => {
      properties: {
        property_string_1: "POS Station",
        property_decimal_1: "Cash Drawer Limit"
      },
      visible_columns: %w[name code business_type workflow_status property_string_1]
    },
    "Technical Support" => {
      properties: {
        property_string_1: "Specialization",
        property_integer_1: "Years of Experience"
      },
      visible_columns: %w[name code business_type workflow_status property_string_1 property_integer_1]
    },
    "Marketing" => {
      properties: {
        property_string_1: "Focus Area",
        property_integer_1: "Campaigns Managed"
      },
      visible_columns: %w[name code business_type workflow_status property_string_1 property_integer_1]
    }
  },
  branches: {
    "Flagship Store" => {
      properties: {
        property_integer_1: "Maximum Occupancy",
        property_integer_2: "Number of POS Tills",
        property_integer_3: "Parking Spaces",
        property_integer_4: "Display Shelves",
        property_boolean_1: "Has Back Office",
        property_boolean_2: "Has Fitting Rooms",
        property_decimal_1: "Lease Size (sq ft)",
        property_decimal_2: "Monthly Rent",
        property_string_1: "Store Manager Name",
        property_string_2: "Operating Hours"
      },
      visible_columns: %w[name code property_string_2 property_integer_1 property_decimal_1 workflow_status]
    },
    "Mall Kiosk" => {
      properties: {
        property_string_5: "Mall Name",
        property_string_1: "Kiosk Size Category",
        property_string_2: "Foot Traffic Level",
        property_string_3: "Product Category Focus",
        property_decimal_1: "Monthly Rent",
        property_decimal_2: "Revenue Target",
        property_integer_1: "Staff Assigned",
        property_integer_2: "Years in Operation",
        property_boolean_1: "Has Storage Unit",
        property_boolean_2: "Has POS System"
      },
      visible_columns: %w[name code property_string_5 property_integer_1 workflow_status]
    },
    "Warehouse Distribution" => {
      properties: {
        property_integer_1: "Warehouse Capacity (sq ft)",
        property_integer_2: "Loading Docks",
        property_integer_3: "Staff Count",
        property_decimal_1: "Monthly Throughput (tons)",
        property_decimal_2: "Temperature Range",
        property_boolean_1: "Climate Controlled",
        property_boolean_2: "Has Cold Storage",
        property_string_1: "Warehouse Manager",
        property_string_2: "Operating Hours",
        property_datetime_1: "Last Inspection Date"
      },
      visible_columns: %w[name code property_integer_1 property_boolean_1 workflow_status]
    },
    "Pop-up Shop" => {
      properties: {
        property_datetime_1: "Start Date",
        property_datetime_2: "End Date",
        property_datetime_3: "Last Inventory Count",
        property_string_1: "Theme / Concept",
        property_string_2: "Location Type",
        property_string_3: "Target Audience",
        property_decimal_1: "Setup Cost",
        property_decimal_2: "Expected Revenue",
        property_integer_1: "Staff Assigned",
        property_boolean_1: "Has Social Media Promotion"
      },
      visible_columns: %w[name code property_string_1 property_datetime_1 property_datetime_2 workflow_status]
    }
  },
  departments: {
    "Operations" => {
      properties: {
        property_string_1: "Scope",
        property_string_2: "Region",
        property_integer_1: "Staff Count",
        property_boolean_1: "Is Outsourced",
        property_decimal_1: "Annual Budget",
        property_decimal_2: "Operational Cost",
        property_integer_2: "Active Projects",
        property_string_3: "Reporting Manager",
        property_string_4: "Department Head",
        property_string_5: "Shift Schedule"
      },
      visible_columns: %w[name code property_string_4 property_integer_1 workflow_status]
    },
    "Human Resources" => {
      properties: {
        property_string_1: "HR Focus",
        property_string_2: "Recruitment Region",
        property_integer_1: "Employees Managed",
        property_boolean_1: "Handles Payroll",
        property_decimal_1: "Training Budget",
        property_decimal_2: "HR Software Cost",
        property_integer_2: "Open Positions",
        property_string_3: "HR Lead",
        property_string_4: "Benefits Coordinator",
        property_string_5: "Compliance Officer"
      },
      visible_columns: %w[name code property_string_1 property_integer_1 workflow_status]
    },
    "Finance" => {
      properties: {
        property_string_1: "Finance Area",
        property_string_2: "Reporting Standard",
        property_integer_1: "Accounts Managed",
        property_boolean_1: "Handles Audits",
        property_decimal_1: "Budget Allocated",
        property_decimal_2: "Revenue Target",
        property_integer_2: "Quarterly Reports",
        property_string_3: "CFO",
        property_string_4: "Tax Specialist",
        property_string_5: "Accounting Method"
      },
      visible_columns: %w[name code property_string_1 property_integer_1 workflow_status]
    },
    "Customer Service" => {
      properties: {
        property_string_1: "Service Channel",
        property_string_2: "Support Region",
        property_integer_1: "Agent Count",
        property_boolean_1: "24/7 Support",
        property_decimal_1: "Monthly Spend",
        property_decimal_2: "Avg Handle Time (min)",
        property_integer_2: "Daily Tickets",
        property_string_3: "Service Manager",
        property_string_4: "Escalation Lead",
        property_string_5: "Tech Stack"
      },
      visible_columns: %w[name code property_string_1 property_integer_1 property_integer_2 workflow_status]
    },
    "Inventory Control" => {
      properties: {
        property_string_1: "Inventory Type",
        property_string_2: "Stock Region",
        property_integer_1: "SKUs Managed",
        property_boolean_1: "Uses Barcode System",
        property_decimal_1: "Inventory Value",
        property_decimal_2: "Monthly Turnover",
        property_integer_2: "Warehouses",
        property_string_3: "Inventory Manager",
        property_string_4: "Supplier Coordinator",
        property_string_5: "System Used"
      },
      visible_columns: %w[name code property_string_1 property_integer_1 workflow_status]
    }
  },
  brands: {
    "Luxury" => {
      properties: { property_string_1: "Tier Level", property_integer_1: "Minimum Order Quantity" },
      visible_columns: %w[name code property_string_1 workflow_status]
    },
    "Mass Market" => {
      properties: { property_string_1: "Target Demographic", property_decimal_1: "Average Price Point" },
      visible_columns: %w[name code property_string_1 workflow_status]
    },
    "Indie" => {
      properties: { property_string_1: "Origin Country", property_boolean_1: "Exclusive Distribution" },
      visible_columns: %w[name code property_string_1 workflow_status]
    },
    "Organic" => {
      properties: { property_string_1: "Certification Type", property_boolean_1: "Cruelty-Free" },
      visible_columns: %w[name code property_string_1 workflow_status]
    },
    "Eco-friendly" => {
      properties: { property_string_1: "Sustainability Rating", property_boolean_1: "Recyclable Packaging" },
      visible_columns: %w[name code property_string_1 workflow_status]
    }
  },
  customers: {
    "Retail VIP" => {
      properties: { property_integer_1: "Loyalty Points", property_decimal_1: "Credit Limit", property_boolean_1: "Premium Member" },
      visible_columns: %w[name code property_integer_1 property_boolean_1 workflow_status]
    },
    "Regular" => {
      properties: { property_string_1: "Preferred Category", property_integer_1: "Visit Frequency (monthly)" },
      visible_columns: %w[name code property_string_1 workflow_status]
    },
    "Wholesale" => {
      properties: { property_decimal_1: "Bulk Discount Rate", property_string_1: "Business Type" },
      visible_columns: %w[name code property_decimal_1 workflow_status]
    },
    "Occasional" => {
      properties: { property_string_1: "Referral Source", property_boolean_1: "Has Made Purchase" },
      visible_columns: %w[name code property_string_1 workflow_status]
    },
    "Walk-in" => {
      properties: { property_boolean_1: "Signed Up For Newsletter", property_string_1: "Interest Area" },
      visible_columns: %w[name code workflow_status]
    }
  },
  services: {
    "Skincare Consultation" => {
      properties: { property_integer_1: "Duration (min)", property_string_1: "Room Required" },
      visible_columns: %w[name code property_integer_1 workflow_status]
    },
    "Makeup Artistry" => {
      properties: { property_integer_1: "Duration (min)", property_string_1: "Skill Level" },
      visible_columns: %w[name code property_integer_1 workflow_status]
    },
    "Spa Treatment" => {
      properties: { property_integer_1: "Duration (min)", property_string_1: "Room Required" },
      visible_columns: %w[name code property_integer_1 workflow_status]
    },
    "Delivery & Installation" => {
      properties: { property_string_1: "Coverage Area", property_decimal_1: "Base Fee" },
      visible_columns: %w[name code property_string_1 workflow_status]
    },
    "Membership Registration" => {
      properties: { property_string_1: "Package Name", property_decimal_1: "Monthly Fee" },
      visible_columns: %w[name code property_string_1 workflow_status]
    }
  },
  facilities: {
    "Retail Floor" => {
      properties: { property_integer_1: "Floor Space (sq ft)", property_string_1: "Department" },
      visible_columns: %w[name code property_integer_1 workflow_status]
    },
    "Storage Room" => {
      properties: { property_integer_1: "Capacity (sq ft)", property_boolean_1: "Climate Controlled" },
      visible_columns: %w[name code property_integer_1 workflow_status]
    },
    "Office Space" => {
      properties: { property_integer_1: "Seating Capacity", property_boolean_1: "Has Meeting Room" },
      visible_columns: %w[name code property_integer_1 workflow_status]
    },
    "Break Room" => {
      properties: { property_integer_1: "Seating Capacity", property_boolean_1: "Has Kitchenette" },
      visible_columns: %w[name code workflow_status]
    },
    "Parking Area" => {
      properties: { property_integer_1: "Car Spaces", property_integer_2: "Bike Spaces" },
      visible_columns: %w[name code property_integer_1 workflow_status]
    },
    "Security Station" => {
      properties: { property_integer_1: "Monitors", property_boolean_1: "Has Alarm System" },
      visible_columns: %w[name code workflow_status]
    }
  },
  warehouses: {
    "Distribution Center" => {
      properties: { property_integer_1: "Capacity (sq ft)", property_string_1: "Region Served" },
      visible_columns: %w[name code property_integer_1 workflow_status]
    },
    "Cold Storage" => {
      properties: { property_integer_1: "Temperature Range (°C)", property_boolean_1: "Humidity Controlled" },
      visible_columns: %w[name code property_integer_1 workflow_status]
    },
    "Fulfillment Hub" => {
      properties: { property_integer_1: "Processing Capacity (orders/day)", property_string_1: "Service Area" },
      visible_columns: %w[name code property_integer_1 workflow_status]
    }
  },
  stock_transfers: {
    "Inter-Branch Transfer" => {
      properties: { property_string_1: "Transfer Reason", property_string_2: "Authorized By" },
      visible_columns: %w[name code workflow_status]
    },
    "Emergency Replenishment" => {
      properties: { property_string_1: "Priority Level", property_string_2: "Approval Status" },
      visible_columns: %w[name code workflow_status]
    }
  },
  stock_exports: {
    "Customer Sale" => {
      properties: { property_string_1: "Customer Name", property_string_2: "Invoice Reference" },
      visible_columns: %w[name code workflow_status]
    },
    "Damaged Write-off" => {
      properties: { property_string_1: "Damage Description", property_string_2: "Reported By" },
      visible_columns: %w[name code workflow_status]
    },
    "Expired Disposal" => {
      properties: { property_string_1: "Expiry Date Range", property_string_2: "Disposal Method" },
      visible_columns: %w[name code workflow_status]
    }
  },
  stock_imports: {
    "Supplier Purchase" => {
      properties: { property_string_1: "Supplier Name", property_string_2: "Purchase Order Ref" },
      visible_columns: %w[name code workflow_status]
    },
    "Customer Return" => {
      properties: { property_string_1: "Return Reason", property_string_2: "Return Authorization" },
      visible_columns: %w[name code workflow_status]
    },
    "Transfer In" => {
      properties: { property_string_1: "Source Branch", property_string_2: "Transfer Reference" },
      visible_columns: %w[name code workflow_status]
    }
  },
  orders: {
    "In-Store Purchase" => {
      properties: { property_string_1: "POS Terminal ID", property_string_2: "Cashier Name" },
      visible_columns: %w[name code workflow_status]
    },
    "Online Order" => {
      properties: { property_string_1: "Delivery Method", property_string_2: "Tracking Number" },
      visible_columns: %w[name code workflow_status]
    },
    "Phone Order" => {
      properties: { property_string_1: "Customer Phone", property_string_2: "Call Duration" },
      visible_columns: %w[name code workflow_status]
    }
  },
  invoices: {
    "B2C Retail Invoice" => {
      properties: { property_string_1: "Customer Email", property_boolean_1: "Email Sent" },
      visible_columns: %w[name code workflow_status]
    },
    "B2B Corporate Invoice" => {
      properties: { property_string_1: "Company Name", property_string_2: "Tax ID" },
      visible_columns: %w[name code workflow_status]
    },
    "Tax Refund Invoice" => {
      properties: { property_string_1: "Tax Authority", property_decimal_1: "Refund Amount" },
      visible_columns: %w[name code workflow_status]
    }
  }
}.freeze

# =============================================================================
# Hospital Init Defaults
# Used by Seed::HospitalInitService to bootstrap a new hospital company with
# system records (roles, categories, property_mappings, table_configs).
# =============================================================================

HOSPITAL_INIT_ROLES = [
  :Receptionist, :Dentist, :DentalAssistant, :Hygienist, :Manager, :Admin
].freeze

HOSPITAL_INIT_COMPANY_GROUP_BUSINESS_TYPE = :hospital

HOSPITAL_INIT_CATEGORIES = {
  branches: {
    "Flagship Clinic" => {
      properties: { property_string_1: "Clinic Director", property_integer_1: "Number of Chairs", property_boolean_1: "Has Emergency Entrance" },
      visible_columns: %w[name code property_string_1 property_integer_1 workflow_status]
    },
    "Satellite Clinic" => {
      properties: { property_string_1: "Managing Dentist", property_integer_1: "Distance from HQ (km)", property_boolean_1: "Weekend Hours" },
      visible_columns: %w[name code property_string_1 property_integer_1 workflow_status]
    },
    "Emergency Center" => {
      properties: { property_string_1: "After-Hours Contact", property_integer_1: "Urgent Care Capacity", property_boolean_1: "24/7 Operation" },
      visible_columns: %w[name code property_string_1 workflow_status]
    }
  },
  departments: {
    "Orthodontics" => { properties: { property_string_1: "Lead Orthodontist", property_integer_1: "Active Braces Cases" }, visible_columns: %w[name code property_string_1 property_integer_1 workflow_status] },
    "Endodontics" => { properties: { property_string_1: "Lead Endodontist", property_integer_1: "Microscopes Available" }, visible_columns: %w[name code property_string_1 property_integer_1 workflow_status] },
    "Periodontics" => { properties: { property_string_1: "Lead Periodontist", property_boolean_1: "Laser Therapy Available" }, visible_columns: %w[name code property_string_1 workflow_status] },
    "Oral Surgery" => { properties: { property_string_1: "Lead Surgeon", property_boolean_1: "IV Sedation Offered" }, visible_columns: %w[name code property_string_1 workflow_status] },
    "Pediatrics" => { properties: { property_string_1: "Pediatric Specialist", property_boolean_1: "Child-Friendly Environment" }, visible_columns: %w[name code property_string_1 workflow_status] }
  },
  employees: {
    "Dentist" => { properties: { property_string_1: "Specialization", property_integer_1: "Years of Experience", property_boolean_1: "Board Certified" }, visible_columns: %w[name code property_string_1 property_integer_1 workflow_status] },
    "Dental Assistant" => { properties: { property_string_1: "Assigned Dentist", property_boolean_1: "X-Ray Certified" }, visible_columns: %w[name code property_string_1 workflow_status] },
    "Receptionist" => { properties: { property_string_1: "Languages Spoken", property_boolean_1: "Insurance Certified" }, visible_columns: %w[name code property_string_1 workflow_status] },
    "Hygienist" => { properties: { property_string_1: "Licensed In", property_integer_1: "Daily Patient Cap" }, visible_columns: %w[name code property_string_1 property_integer_1 workflow_status] },
    "Practice Manager" => { properties: { property_string_1: "Management Focus", property_boolean_1: "Financial Sign-Off Authority" }, visible_columns: %w[name code property_string_1 workflow_status] }
  },
  customers: {
    "New Patient" => { properties: { property_string_1: "Referral Source", property_boolean_1: "Insurance Verified" }, visible_columns: %w[name code property_string_1 workflow_status] },
    "Regular" => { properties: { property_integer_1: "Visit Frequency (months)", property_string_1: "Preferred Dentist" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Insurance" => { properties: { property_string_1: "Insurance Provider", property_string_2: "Policy Number" }, visible_columns: %w[name code property_string_1 workflow_status] },
    "VIP" => { properties: { property_decimal_1: "Lifetime Value", property_string_1: "Account Manager" }, visible_columns: %w[name code property_decimal_1 workflow_status] },
    "Pediatric" => { properties: { property_string_1: "Guardian Name", property_integer_1: "Age" }, visible_columns: %w[name code property_string_1 property_integer_1 workflow_status] }
  },
  services: {
    "Cleaning & Exam" => { properties: { property_integer_1: "Duration (min)", property_decimal_1: "Base Price", property_boolean_1: "Requires X-Ray" }, visible_columns: %w[name code property_integer_1 property_decimal_1 workflow_status] },
    "Filling" => { properties: { property_integer_1: "Duration (min)", property_string_1: "Material Options" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Root Canal" => { properties: { property_integer_1: "Duration (min)", property_string_1: "Tooth Range" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Crown" => { properties: { property_integer_1: "Duration (days)", property_string_1: "Material Type" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Extraction" => { properties: { property_integer_1: "Duration (min)", property_boolean_1: "Requires Sedation" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Whitening" => { properties: { property_integer_1: "Duration (min)", property_string_1: "Treatment Type" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Implant" => { properties: { property_integer_1: "Duration (months)", property_string_1: "Implant Brand" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Brace" => { properties: { property_integer_1: "Duration (months)", property_string_1: "Brace Type" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Invisalign" => { properties: { property_integer_1: "Number of Trays", property_string_1: "Treatment Plan" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Emergency" => { properties: { property_string_1: "Urgency Level", property_boolean_1: "After Hours" }, visible_columns: %w[name code property_string_1 workflow_status] }
  },
  facilities: {
    "Treatment Room" => { properties: { property_integer_1: "Chair Number", property_boolean_1: "Has X-Ray Panel" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Operatory" => { properties: { property_integer_1: "Room Capacity", property_boolean_1: "Surgical Grade" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "X-ray Room" => { properties: { property_string_1: "Equipment Type", property_boolean_1: "Lead Shielded" }, visible_columns: %w[name code property_string_1 workflow_status] },
    "Sterilization Room" => { properties: { property_string_1: "Autoclave Model", property_integer_1: "Cycle Capacity" }, visible_columns: %w[name code property_string_1 workflow_status] },
    "Consultation Room" => { properties: { property_string_1: "Purpose", property_boolean_1: "Has TV/Display" }, visible_columns: %w[name code property_string_1 workflow_status] },
    "Recovery Area" => { properties: { property_integer_1: "Bed Count", property_boolean_1: "Has Monitoring" }, visible_columns: %w[name code property_integer_1 workflow_status] }
  },
  stock_exports: {
    "Patient Sale" => { properties: { property_string_1: "Patient Name", property_string_2: "Treatment Code" }, visible_columns: %w[name code workflow_status] },
    "Damaged Write-off" => { properties: { property_string_1: "Damage Description", property_string_2: "Reported By" }, visible_columns: %w[name code workflow_status] },
    "Expired Disposal" => { properties: { property_string_1: "Expiry Date Range", property_string_2: "Disposal Method" }, visible_columns: %w[name code workflow_status] }
  },
  stock_imports: {
    "Supplier Purchase" => { properties: { property_string_1: "Supplier Name", property_string_2: "Purchase Order Ref" }, visible_columns: %w[name code workflow_status] },
    "Customer Return" => { properties: { property_string_1: "Return Reason", property_string_2: "Return Authorization" }, visible_columns: %w[name code workflow_status] },
    "Transfer In" => { properties: { property_string_1: "Source Clinic", property_string_2: "Transfer Reference" }, visible_columns: %w[name code workflow_status] }
  },
  orders: {
    "In-Clinic Treatment" => { properties: { property_string_1: "Treating Dentist", property_string_2: "Chair Number" }, visible_columns: %w[name code workflow_status] },
    "Online Booking" => { properties: { property_string_1: "Booking Platform", property_string_2: "Insurance Pre-Auth" }, visible_columns: %w[name code workflow_status] },
    "Emergency Visit" => { properties: { property_string_1: "Triage Level", property_boolean_1: "After Hours Fee Applied" }, visible_columns: %w[name code workflow_status] }
  },
  invoices: {
    "Patient Invoice" => { properties: { property_string_1: "Patient Name", property_boolean_1: "Insurance Claim Filed" }, visible_columns: %w[name code workflow_status] },
    "Insurance Claim" => { properties: { property_string_1: "Insurance Company", property_string_2: "Claim Number" }, visible_columns: %w[name code workflow_status] },
    "Corporate Account" => { properties: { property_string_1: "Company Name", property_decimal_1: "Contract Rate Discount" }, visible_columns: %w[name code workflow_status] }
  }
}.freeze
