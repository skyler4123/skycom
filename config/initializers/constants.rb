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
  failed: 8,
  initiated: 9,
  received: 10,
  shipped: 11
}

# Company-only workflow statuses (companies.workflow_status).
#
# These answer "can this tenant use Skycom and should background jobs process it?"
# They are deliberately separate from the order/payment WORKFLOW_STATUS above.
#
# active   — normal company with usable credit. Full web access and processed by
#            company-wide background jobs.
# disabled — owner no longer uses Skycom. Excluded from company-wide background
#            jobs. Not derived automatically; a later credit movement returns it
#            to active.
# suspend  — no usable credit (main + promo <= 0). Web, JSON, and mobile requests
#            are blocked and sent to the top-up flow. Still processed by
#            company-wide background jobs (usage sync, promo grants) because
#            those jobs are free-credit.
#
# companies.lifecycle_status is legacy and is NOT used for access control.
COMPANY_WORKFLOW_STATUS = {
  active: 0,
  disabled: 1,
  suspend: 2
}.freeze

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

# Strategy key → gateway service class (used by Payments::InitiateService).
# Only implemented strategies are registered; others raise at initiation.
GATEWAY_STRATEGY_CLASSES = {
  mock_qr_gateway: "Payments::MockQrGateway",
  mock_redirect_gateway: "Payments::MockRedirectGateway"
}.freeze

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

# TTL applied to every application cache key (see docs/CACHE.md §7).
# TTL is a backstop: freshness comes from explicit deletes or record touches.
CACHE_DEFAULT_EXPIRY = 1.hour

# =============================================================================
# Owner Role Constants (ABAC)
# Magic-string values used across the permission system to identify
# owner-level access. Owner roles bypass all ABAC permission checks.
# Referenced in: Company, Employee, PolicyRoleAppointment, EmployeeRoleAppointment,
# seed services, and permission concerns.
# =============================================================================

OWNER_BUSINESS_TYPE = "owner".freeze

# =============================================================================
# Model Validation Limits
# =============================================================================

# Max length for phone_number fields on Company and Branch models.
MAX_PHONE_NUMBER_LENGTH = 20

# =============================================================================
# Payroll Calculation
# Referenced in: Payrolls::GenerateService, Payroll, MobileHelper, payroll views.
# =============================================================================

# Withholding tax applied to gross pay.
PAYROLL_TAX_RATE = 0.10

# Employee social-insurance contribution applied to gross pay.
PAYROLL_SOCIAL_INSURANCE_RATE = 0.084

# Overtime pay multiplier for recorded overtime minutes.
PAYROLL_OVERTIME_MULTIPLIER = 1.5

# Paid working minutes in a year (52 weeks × 40 hours × 60 minutes).
PAYROLL_ANNUAL_WORK_MINUTES = 124_800

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

# Promo credits granted to every newly created company (except system companies).
# They land in promo_credit_balance so normal deductions drain them first.
SIGNUP_PROMO_CREDITS = 1_000

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

# Dashboard/analytics low-stock alert threshold. Stock is per warehouse; the
# count is warehouse SKU rows whose available quantity (quantity - pending) is
# below this value. Products do not carry a per-SKU reorder point yet.
LOW_STOCK_THRESHOLD = 10

# =============================================================================
# Company Support Tickets (B2B — company → Skycom)
# Ticket-level: used by CompanyTicket::FileAttachmentConcern (CompanyTicket).
# Comment-level: used by CompanyTicketComment (one image XOR one file).
# =============================================================================

# Max number of file attachments per ticket.
MAX_TICKET_ATTACHMENTS = 5

# Max file size per support ticket attachment.
MAX_TICKET_FILE_SIZE = 5.megabytes

# Max image size per ticket comment image_attachment.
MAX_TICKET_COMMENT_IMAGE_SIZE = 2.megabytes

# Max file size per ticket comment file_attachment (Excel only).
MAX_TICKET_COMMENT_FILE_SIZE = 1.megabyte

# Display variant target for ticket comment images (resize_to_limit).
TICKET_COMMENT_IMAGE_DIMENSIONS = [ 800, 800 ].freeze

# Allowed image types for ticket comment image_attachment (PNG, JPEG only).
ACCEPTABLE_TICKET_COMMENT_IMAGE_TYPES = %w[image/jpeg image/png].freeze

# Allowed file types for ticket comment file_attachment (Excel only, for now).
ACCEPTABLE_TICKET_COMMENT_FILE_TYPES = %w[
  application/vnd.ms-excel
  application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
].freeze

# Allowed MIME types for support ticket attachments:
# images, plain text, PDF, Word and Excel.
ACCEPTABLE_TICKET_FILE_TYPES = %w[
  image/jpeg image/png image/gif
  text/plain
  application/pdf
  application/msword
  application/vnd.openxmlformats-officedocument.wordprocessingml.document
  application/vnd.ms-excel
  application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
].freeze

# =============================================================================
# Company Storage (Folder + StoredFile — S3-like browser, metering-ready)
# Folder roots act as buckets; files live only inside folders. StoredFile wraps
# one Active Storage blob with audit columns for future per-GB charging.
# See docs/STORAGE.md.
# =============================================================================

# Allowed MIME types for StoredFile uploads:
# images, text/csv, PDF, Word/Excel, zip/rar.
ACCEPTABLE_STORED_FILE_TYPES = %w[
  image/jpeg image/png image/gif
  text/plain text/csv
  application/pdf
  application/msword
  application/vnd.openxmlformats-officedocument.wordprocessingml.document
  application/vnd.ms-excel
  application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  application/zip application/x-zip-compressed
  application/x-rar-compressed application/vnd.rar
].freeze

# Per-category max upload size for StoredFile (category derived from MIME).
STORED_FILE_MAX_SIZES_BY_TYPE = {
  image: 10.megabytes,
  pdf: 20.megabytes,
  office: 20.megabytes,
  text: 5.megabytes,
  archive: 50.megabytes
}.freeze

# =============================================================================
# Data Migration (CompanyMigration) — config-driven CSV ingestion
# =============================================================================

# Max bytes per uploaded CSV chunk. Must stay under
# STORED_FILE_MAX_SIZES_BY_TYPE[:text] (5MB) so each chunk is a valid StoredFile.
MIGRATION_CHUNK_MAX_BYTES = 4.megabytes

# Data rows shown in the raw preview and validated by a dry run.
MIGRATION_PREVIEW_ROW_LIMIT = 10

# Rows persisted per batch during import/rollback.
MIGRATION_IMPORT_BATCH_SIZE = 500

# Per-run cap on stored error samples (details page).
MIGRATION_ERROR_SAMPLES_LIMIT = 20

# System notification tag owner notifications for a migration carry.
MIGRATION_NOTIFICATION_TAG = "Migrations"

# Models a config may never target (permission/auth machinery).
MIGRATION_IMPORT_EXCLUDED_RESOURCES = %w[
  Role Policy PermissionLog PolicyRoleAppointment RoleTagAppointment
  CustomerRoleAppointment CustomerGroupRoleAppointment DepartmentRoleAppointment
  EmployeeRoleAppointment EmployeeGroupRoleAppointment User Session
].freeze

# =============================================================================
# Import — user-prepared CSV ingestion (docs/IMPORT.md)
# Deliberately isolated from Data Migration: new tables (imports/import_logs),
# new Imports:: service namespace, new Companies::ImportsController.
# =============================================================================

# Import lifecycle stored in imports.workflow_status (there is no
# lifecycle_status column for this feature; see docs/IMPORT.md).
IMPORT_WORKFLOW_STATUS = {
  draft: 0,
  approved: 1,
  processing: 2,
  completed: 3,
  failed: 4,
  rolling_back: 5,
  rolled_back: 6
}.freeze

# Root storage folder holding one child folder per import.
IMPORT_ROOT_FOLDER_NAME = "Imports"

# Single-file upload cap. Must stay at or under
# STORED_FILE_MAX_SIZES_BY_TYPE[:text] (5MB) so the StoredFile is accepted.
IMPORT_MAX_FILE_BYTES = 5.megabytes

# Hard cap on data rows in one import (dry run validates all of them).
IMPORT_MAX_ROWS = 20_000

# Rows written per audit-log/progress batch.
IMPORT_BATCH_SIZE = 500

# Latest records rendered under the resolved headers on the show page.
IMPORT_PREVIEW_ROW_LIMIT = 10

# Per-run cap on stored row error samples.
IMPORT_ERROR_SAMPLES_LIMIT = 50

# System notification tag import notifications carry.
IMPORT_NOTIFICATION_TAG = "Imports"

# Columns the engine owns or does not support as CSV headers. Everything else
# on a target model is importable (including business_type/lifecycle/workflow
# enums, external_id, and *_id foreign keys). JSON columns are excluded too;
# see Imports::SchemaResolver.
IMPORT_ENGINE_COLUMNS = %w[
  id company_id category_id property_mapping_id
  created_at updated_at discarded_at permission_resource_name
  metadata type lock_version
].freeze

# Target models v1 exposes. Master/reference data only: no permission/auth,
# platform schema, order/invoice/payment/credit, or stock tables.
# The FE picker keeps a mirror in
# app/javascript/controllers/helpers/import_tables.js — update both together.
IMPORTABLE_RESOURCES = {
  "branches" => "Branch",
  "brands" => "Brand",
  "customer_profiles" => "CustomerProfile",
  "customer_subprofiles" => "CustomerSubprofile",
  "customers" => "Customer",
  "departments" => "Department",
  "employee_profiles" => "EmployeeProfile",
  "employee_subprofiles" => "EmployeeSubprofile",
  "employees" => "Employee",
  "facilities" => "Facility",
  "products" => "Product",
  "services" => "Service",
  "suppliers" => "Supplier",
  "warehouses" => "Warehouse"
}.freeze

# =============================================================================
# Company Settings (company-level config incl. custom sidebar groups)
# One CompanySetting per company per business_type is active at a time
# (see CompanySetting). The active sidebar_groups record holds all custom
# groups in metadata["sidebar_groups"]. See docs/SIDEBAR.md.
# =============================================================================

# =============================================================================
# Export (index pages → CSV). Skycom-level toggle: applies to every company.
# Resource keys (URL/controller name) listed here have the "Export" button on
# their index page and accept `?export=1` to return the full filtered record set.
# Add/remove a key to enable/disable export for that page globally.
# =============================================================================
# analytics is intentionally excluded: its JSON is a nested report, not a flat
# index array, so the generic index CSV exporter would produce an empty file.
EXPORT_ENABLED_RESOURCES = %w[
  attendance_config_logs attendance_configs attendance_days
  attendance_logs attendance_months attendance_requests branches brands
  calendars categories company_ticket_logs company_tickets customer_profiles
  customers customer_subprofiles departments discount_groups discounts
  documents employee_profiles employees employee_subprofiles event_configs
  events facilities folders invoices notifications notification_tags orders
  pages permission_logs permissions policies products property_mappings
  purchases roles scheduled_shifts services shift_templates stock_adjustments
  stock_exports stock_imports stock_pendings stocks stock_transfers storage_statistics
  suppliers table_config_logs table_configs warehouses workflows
].freeze

# Safety cap for a single export request (records).
EXPORT_MAX_RECORDS = 10_000

# =============================================================================
# Welcome Notification (new-company onboarding)
# Country-versioned copy for the delayed welcome job
# (Companies::WelcomeNotificationJob). Business-domain agnostic — keyed by
# country only. See docs/MODEL_CALLBACKS.md (Company#initialize_company).
# =============================================================================

# Country → welcome name/description. Fallback is :us when the country is unknown.
WELCOME_NOTIFICATION_CONTENT = {
  us: {
    name: "Welcome to Skycom!",
    description: "Your company is ready. Explore your dashboard, invite your team, and start selling — we're here if you need help."
  },
  vn: {
    name: "Chào mừng bạn đến với Skycom!",
    description: "Công ty của bạn đã sẵn sàng. Hãy khám phá bảng điều khiển, mời đội ngũ của bạn và bắt đầu bán hàng — chúng tôi luôn sẵn sàng hỗ trợ."
  }
}.freeze

# =============================================================================
# Promo Campaign Notification (admin promo-credit giveaway)
# Customer-facing defaults for PromoCampaign#title/#body, used by
# PromoCampaigns::ExecuteService#notify_owner as fallback when title/body
# blank (legacy rows) and as UI placeholders in admin forms.
# Interpolation keys: %{amount}, %{name}, %{max_cap}.
# =============================================================================

# Default notification title. Example: "Skycom gave you 300 credits!"
PROMO_DEFAULT_TITLE = "Skycom gave you %{amount} credits!".freeze

# Default notification body. Example: "Promo 'Holiday Bonus' added 300 promo credits (cap 1000). ..."
PROMO_DEFAULT_BODY = "Promo '%{name}' added %{amount} promo credits (cap %{max_cap}). Thank you for using Skycom! Here is our help to grow your business.".freeze

# =============================================================================
# Workflow Step Colors (semantic Tailwind classes — must be listed literally so
# Tailwind can scan & compile them). Used by WorkflowStep validation + seed
# defaults. Order matters: seeds reference these by index — neutral, primary,
# success, warning, danger, info. Never use raw palette classes here; a rebrand
# in app/assets/tailwind/application.css must recolor every workflow step.
# =============================================================================
WORKFLOW_STEP_COLORS = {
  neutral: { text: "text-muted-foreground", background: "bg-muted" },
  primary: { text: "text-primary",          background: "bg-primary/10" },
  success: { text: "text-success",          background: "bg-success/10" },
  warning: { text: "text-warning",          background: "bg-warning/10" },
  danger:  { text: "text-danger",           background: "bg-danger/10" },
  info:    { text: "text-info",             background: "bg-info/10" }
}.freeze
WORKFLOW_STEP_TEXT_COLORS = WORKFLOW_STEP_COLORS.values.map { |c| c[:text] }.freeze
WORKFLOW_STEP_BACKGROUND_COLORS = WORKFLOW_STEP_COLORS.values.map { |c| c[:background] }.freeze
