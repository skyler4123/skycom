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

GATEWAY_STRATEGIES = begin
  base = {
    # System payments (value < 10 — no external gateway call)
    cash: 0,
    wallet_auto_debit: 1,
    # External gateway strategies (value >= 10)
    stripe_gateway: 12,
    viet_qr_gateway: 13
  }
  mock = {
    mock_qr_gateway: 10,
    mock_redirect_gateway: 11
  }
  if Rails.env.production?
    base
  else
    base.merge(mock)
  end
end.freeze

# --- Webhooks ---
# Payment API callback secrets for the mock bank gateways (future Token implementation).
WEBHOOK_BANK_PAYMENT_SECRET = ENV.fetch("WEBHOOK_BANK_PAYMENT_SECRET", "local_secure_dev_secret").freeze
WEBHOOK_REDIRECT_PAYMENT_SECRET = ENV.fetch("WEBHOOK_REDIRECT_PAYMENT_SECRET", "local_secure_dev_secret").freeze

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

# Allowed MIME types for business entity images.
# Used by all 7 ImageConcern modules + User::ChatImagesConcern.
ACCEPTABLE_IMAGE_TYPES = %w[image/jpeg image/png image/gif].freeze

# ActiveStorage variant dimensions for business entity images.
IMAGE_FULL_DIMENSIONS = [ 300, 300 ].freeze
IMAGE_THUMB_DIMENSIONS = [ 50, 50 ].freeze

# ActiveStorage variant dimensions shared by both avatar concerns
# (User::AvatarConcern and AvatarConcern).
AVATAR_THUMB_DIMENSIONS = [ 50, 50 ].freeze
AVATAR_MEDIUM_DIMENSIONS = [ 150, 150 ].freeze
AVATAR_PROFILE_DIMENSIONS = [ 300, 300 ].freeze

# =============================================================================
# Cache & Expiry
# =============================================================================

# TTL for cached ABAC permission data per employee/company.
# Used by Employee::PermissionConcern and Company::PermissionConcern.
PERMISSIONS_CACHE_EXPIRY = 1.minute

# =============================================================================
# Owner Role Constants (ABAC)
# Magic-string values used across the permission system to identify
# owner-level access. Owner roles bypass all ABAC permission checks.
# Referenced in: Company, Employee, PolicyAppointment, RoleAppointment,
# seed services, and permission concerns.
# =============================================================================

OWNER_BUSINESS_TYPE = "owner".freeze

# =============================================================================
# Model Validation Limits
# =============================================================================

# Max length for phone_number fields on Company and Branch models.
MAX_PHONE_NUMBER_LENGTH = 20

# =============================================================================
# Job Processing Defaults
# =============================================================================

# =============================================================================
# Seed Defaults
# =============================================================================

# Company group business type used when seeding retail companies.
# Referenced in: Seed::ApplicationService and Seed::RetailEnrichService.
RETAIL_INIT_COMPANY_GROUP_BUSINESS_TYPE = :retail

# =============================================================================
# OmniAuth Mock Credentials
# Used in development/test for Google OAuth sign-in.
# =============================================================================

MOCK_OAUTH_EMAIL = "Manager_1_clinic_1@company3.com".freeze

# =============================================================================
# Credit System (Pay-as-You-Go)
# =============================================================================

# Per-country credit purchase tiers: money in CENTS → credits.
# CompanyOrder validates its money_amount_cents/credit_amount against these.
CREDIT_RATES = {
  us: { 500 => 500_000, 1_000 => 1_000_000 },
  vn: { 10_000_000 => 400_000, 100_000_000 => 800_000 }
}.freeze

# Per-action credit cost (global — not country-based).
# CompanyUsageLog.action_type strings mirror these keys.
CREDIT_USAGE_RATES = {
  create_order: 10,
  access_dashboard: 2,
  create_customer: 7
}.freeze
