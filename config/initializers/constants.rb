# =============================================================================
# Environment-backed configuration
#
# Rule: ENV > Rails.application.credentials > hardcoded default.
# Every other file uses the constant, never ENV. See docs/ENVIRONMENT.md.
# =============================================================================

# --- Meilisearch ---
MEILISEARCH_HOST = ENV["MEILISEARCH_HOST"].presence ||
  Rails.application.credentials.dig(:meilisearch_host) ||
  "http://localhost:7700"

MEILISEARCH_API_KEY = ENV["MEILISEARCH_API_KEY"].presence ||
  Rails.application.credentials.dig(:meilisearch_api_key) ||
  "skycom_master_key_password_2026"

# --- Centrifugo (websocket) ---
CENTRIFUGO_API_KEY = ENV["CENTRIFUGO_API_KEY"].presence ||
  Rails.application.credentials.dig(:centrifugo_api_key) ||
  "skycom_super_secret_api_key_2026"

CENTRIFUGO_ENDPOINT = ENV["CENTRIFUGO_ENDPOINT"].presence ||
  Rails.application.credentials.dig(:centrifugo_endpoint) ||
  "http://localhost:8000/api"

CENTRIFUGO_TOKEN_HMAC_SECRET_KEY = ENV["CENTRIFUGO_TOKEN_HMAC_SECRET_KEY"].presence ||
  Rails.application.credentials.dig(:centrifugo_token_hmac_secret_key) ||
  "skycom_jwt_hmac_secret_token_key_2026"

# --- Google OAuth ---
GOOGLE_CLIENT_ID = ENV["GOOGLE_CLIENT_ID"].presence ||
  Rails.application.credentials.dig(:google_client_id)

GOOGLE_CLIENT_SECRET = ENV["GOOGLE_CLIENT_SECRET"].presence ||
  Rails.application.credentials.dig(:google_client_secret)

# --- Payment webhook signatures ---
WEBHOOK_BANK_PAYMENT_SECRET = ENV["WEBHOOK_BANK_PAYMENT_SECRET"].presence ||
  Rails.application.credentials.dig(:webhook_bank_payment_secret) ||
  "local_secure_dev_secret"

WEBHOOK_REDIRECT_PAYMENT_SECRET = ENV["WEBHOOK_REDIRECT_PAYMENT_SECRET"].presence ||
  Rails.application.credentials.dig(:webhook_redirect_payment_secret) ||
  "local_secure_dev_secret"

# --- Mock payment gateways + mock API server ---
MOCK_QR_GATEWAY_URL = ENV["MOCK_QR_GATEWAY_URL"].presence ||
  Rails.application.credentials.dig(:mock_qr_gateway_url) ||
  "http://localhost:4000/api/v1/bank/qr-generate"

MOCK_QR_WEBHOOK_URL = ENV["MOCK_QR_WEBHOOK_URL"].presence ||
  Rails.application.credentials.dig(:mock_qr_webhook_url) ||
  "http://192.168.0.100:3000/webhooks/payments/mock_qr_gateway"

MOCK_REDIRECT_GATEWAY_URL = ENV["MOCK_REDIRECT_GATEWAY_URL"].presence ||
  Rails.application.credentials.dig(:mock_redirect_gateway_url) ||
  "http://localhost:4000/api/v1/bank/redirect-session"

MOCK_REDIRECT_WEBHOOK_URL = ENV["MOCK_REDIRECT_WEBHOOK_URL"].presence ||
  Rails.application.credentials.dig(:mock_redirect_webhook_url) ||
  "http://192.168.0.100:3000/webhooks/payments/mock_redirect_gateway"

MOCK_API_PING_URL = ENV["MOCK_API_PING_URL"].presence ||
  Rails.application.credentials.dig(:mock_api_ping_url) ||
  "http://localhost:4000/api/v1/ping"

# --- Background jobs (config/queue.yml) ---
JOB_CONCURRENCY = (
  ENV["JOB_CONCURRENCY"].presence ||
  Rails.application.credentials.dig(:job_concurrency) ||
  1
).to_i

# --- Redis (config/redis/shared.yml) ---
REDIS_URL_PRODUCTION = ENV["REDIS_URL_PRODUCTION"].presence ||
  Rails.application.credentials.dig(:redis_url_production) ||
  "redis://127.0.0.1:6379/0"

REDIS_URL_DEVELOPMENT = ENV["REDIS_URL_DEVELOPMENT"].presence ||
  Rails.application.credentials.dig(:redis_url_development) ||
  "redis://127.0.0.1:6379/0"

REDIS_URL_TEST = ENV["REDIS_URL_TEST"].presence ||
  Rails.application.credentials.dig(:redis_url_test) ||
  "redis://127.0.0.1:6379/0"

# --- Object storage (config/storage.yml) ---
AWS_ACCESS_KEY_ID = ENV["AWS_ACCESS_KEY_ID"].presence ||
  Rails.application.credentials.dig(:aws_access_key_id) ||
  "admin"

AWS_SECRET_ACCESS_KEY = ENV["AWS_SECRET_ACCESS_KEY"].presence ||
  Rails.application.credentials.dig(:aws_secret_access_key) ||
  "password"

# Credential key stays :aws_endpoint (legacy name) while the ENV uses the
# standard AWS SDK name.
AWS_ENDPOINT_URL = ENV["AWS_ENDPOINT_URL"].presence ||
  Rails.application.credentials.dig(:aws_endpoint) ||
  "http://10.88.0.2:9000"

# --- OpenTelemetry ---
OTEL_SERVICE_NAME = ENV["OTEL_SERVICE_NAME"].presence ||
  Rails.application.credentials.dig(:otel_service_name) ||
  "skyceer-#{Rails.env}"

OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = ENV["OTEL_EXPORTER_OTLP_TRACES_ENDPOINT"].presence ||
  Rails.application.credentials.dig(:otel_exporter_otlp_traces_endpoint) ||
  "http://localhost:5080/api/default/v1/traces"

OTEL_EXPORTER_OTLP_LOGS_ENDPOINT = ENV["OTEL_EXPORTER_OTLP_LOGS_ENDPOINT"].presence ||
  Rails.application.credentials.dig(:otel_exporter_otlp_logs_endpoint) ||
  "http://localhost:5080/api/default/v1/logs"

OTEL_EXPORTER_OTLP_HEADERS = ENV["OTEL_EXPORTER_OTLP_HEADERS"].presence ||
  Rails.application.credentials.dig(:otel_exporter_otlp_headers) ||
  "Authorization=Basic YWRtaW5AZXhhbXBsZS5jb206UGFzc3dvcmRAMTIz,organization=default"

# --- Mission Control (jobs dashboard) ---
MISSION_CONTROL_USER = ENV["MISSION_CONTROL_USER"].presence ||
  Rails.application.credentials.dig(:mission_control_user) ||
  "dev"

MISSION_CONTROL_PASSWORD = ENV["MISSION_CONTROL_PASSWORD"].presence ||
  Rails.application.credentials.dig(:mission_control_password) ||
  "secret"

# --- Test harness / runtime flags ---
TEST_ENV_NUMBER = ENV["TEST_ENV_NUMBER"].presence ||
  Rails.application.credentials.dig(:test_env_number) ||
  ""

TEST_RUN_INSIDE_DOCKER = ActiveModel::Type::Boolean.new.cast(
  ENV["TEST_RUN_INSIDE_DOCKER"].presence ||
  Rails.application.credentials.dig(:test_run_inside_docker) ||
  false
)

# true = skip the db:seed that db:prepare runs on a freshly created database
# (the rspec container sets it; the seed-test pipeline leaves it false).
SKIP_DB_SEED = ActiveModel::Type::Boolean.new.cast(
  ENV["SKIP_DB_SEED"].presence ||
  Rails.application.credentials.dig(:skip_db_seed) ||
  false
)

# A secret silently falling back to its compiled-in development default in
# production is a misconfiguration. Warn once at boot, keep serving.
if Rails.env.production?
  {
    "MEILISEARCH_API_KEY" => :meilisearch_api_key,
    "CENTRIFUGO_API_KEY" => :centrifugo_api_key,
    "CENTRIFUGO_TOKEN_HMAC_SECRET_KEY" => :centrifugo_token_hmac_secret_key,
    "WEBHOOK_BANK_PAYMENT_SECRET" => :webhook_bank_payment_secret,
    "WEBHOOK_REDIRECT_PAYMENT_SECRET" => :webhook_redirect_payment_secret,
    "AWS_SECRET_ACCESS_KEY" => :aws_secret_access_key,
    "MISSION_CONTROL_PASSWORD" => :mission_control_password,
    "OTEL_EXPORTER_OTLP_HEADERS" => :otel_exporter_otlp_headers
  }.each do |env_key, credential_key|
    next if ENV[env_key].present? || Rails.application.credentials.dig(credential_key).present?

    Rails.logger.warn("[env] #{env_key} is unset; using its compiled-in development default.")
  end
end

# Dynamic property string slots are unbounded varchar in PostgreSQL. Skycom
# applies the conventional varchar(255) maximum in the model layer.
PROPERTY_STRING_MAX_LENGTH = 255

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

# 100% expressed in basis points. Tax rates are stored as integer bp so no
# float ever touches money (1000 = 10.00%; 825 = 8.25%).
TAX_RATE_BP_MAX = 10_000

# POS catalog page size before server-side search takes over.
POS_CATALOG_LIMIT = 50

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

# Exam attempt submission grace period. The client auto-submits at the
# deadline; this window absorbs network latency before the server expires the
# attempt instead of accepting the submission.
EXAM_SUBMIT_GRACE_SECONDS = 30

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
# Payment API callback secrets are declared in the environment section above
# (WEBHOOK_BANK_PAYMENT_SECRET / WEBHOOK_REDIRECT_PAYMENT_SECRET).

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

# The Operations and Operation Configs index payloads are company-level and
# change rarely. Explicit deletes keep them fresh; the TTL is a backstop.
OPERATIONS_CACHE_EXPIRY = 1.day

# Booking console reference/day caps. Lists are capped and labelled; KPI counts
# are computed over the full data set. See docs/OPERATIONS.md §7.
BOOKING_DAY_BOOKING_LIMIT = 200
BOOKING_FACILITY_LIMIT = 100
BOOKING_HOST_LIMIT = 100

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
# Referenced in: Payrolls::GenerateService, Payroll, Mobile::Companies::PayrollsController.
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

# Promo credits granted to every newly created company, including system-owned
# companies. They land in promo_credit_balance so normal deductions drain them first.
SIGNUP_PROMO_CREDITS = 1_000_000

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

# Allowed reasons on a manual stock adjustment (Inventory console Adjust
# drawer). Stored verbatim on stock_adjustments.reason; the note lives on
# stock_adjustments.description. docs/business_analysis/05-inventory.md.
STOCK_ADJUSTMENT_REASONS = [ "Count correction", "Damage", "Found", "Other" ].freeze

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

# Per-run cap on stored error samples (details operation).
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

# Latest records rendered under the resolved headers on the show operation.
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
# =============================================================================
# Operation catalog
#
# An Operation is company-level and keyed by purpose. Every company receives one Operation
# per entry. `appointment_scope` is a seed-time hint only: branch-scoped operations
# get BranchOperationAppointment rows on branch creation, warehouse-scoped operations get
# OperationWarehouseAppointment rows on warehouse creation. `label` is the seeded
# display name and is identical for every business type. See docs/OPERATIONS.md.
# =============================================================================
OPERATION_TYPES = {
  pos: { label: "POS", code_prefix: "POS", appointment_scope: :branch }.freeze,
  booking: { label: "Booking", code_prefix: "BKG", appointment_scope: :branch }.freeze,
  inventory: { label: "Inventory", code_prefix: "INV", appointment_scope: :warehouse }.freeze,
  reception: { label: "Reception", code_prefix: "RCP", appointment_scope: :branch }.freeze,
  store_manager: { label: "Store Manager", code_prefix: "MGR", appointment_scope: :branch }.freeze
}.freeze

# Resource keys (URL/controller name) listed here have the "Export" button on
# their index operation and accept `?export=1` to return the full filtered record set.
# Add/remove a key to enable/disable export for that operation globally.
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
  permission_logs permissions policies products property_mappings
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

# =============================================================================
# ERP domain enums (ledger, commercial, inventory, projects, platform, MRP)
#
# One constant per column so models and services share a single vocabulary.
# Integer values are permanent: add new keys at the end, never renumber.
# =============================================================================

# Chart of accounts type. Determines which financial statement an account feeds.
LEDGER_ACCOUNT_TYPES = { asset: 0, liability: 1, equity: 2, revenue: 3, expense: 4 }.freeze

# Side of the double entry an account grows on. Stored explicitly because contra
# accounts (accumulated depreciation, sales returns) sit opposite their type.
NORMAL_BALANCES = { debit: 0, credit: 1 }.freeze

# Accounting period lifecycle. locked/closed periods reject new postings.
FISCAL_PERIOD_STATUSES = { open: 0, locked: 1, closed: 2 }.freeze

# Journal entry lifecycle. posted entries are immutable; corrections are reversals.
JOURNAL_ENTRY_STATUSES = { draft: 0, posted: 1, reversed: 2 }.freeze

# Tax classification used to pick the right calculation and reporting box.
TAX_CODE_KINDS = { vat: 0, gst: 1, sales: 2, withholding: 3 }.freeze

# Fixed-asset depreciation formula.
DEPRECIATION_METHODS = { straight_line: 0, declining_balance: 1 }.freeze

# What a budget's ceiling covers.
BUDGET_SCOPES = { company: 0, branch: 1, cost_center: 2 }.freeze

# Delivery channel for an overdue-invoice reminder.
DUNNING_CHANNELS = { email: 0, sms: 1, in_app: 2, letter: 3 }.freeze

# Reminder attempt lifecycle (a failed send stays visible as its own row).
INVOICE_REMINDER_STATUSES = { scheduled: 0, sent: 1, failed: 2, skipped: 3 }.freeze

# Salary payment batch lifecycle.
DISBURSEMENT_BATCH_STATUSES = { draft: 0, approved: 1, exported: 2, paid: 3, failed: 4 }.freeze

# E-signature request lifecycle.
SIGNATURE_REQUEST_STATUSES = { pending: 0, completed: 1, declined: 2, expired: 3, canceled: 4 }.freeze

# Sales document kind. One orders table carries quotes through returns.
ORDER_DOCUMENT_TYPES = { quote: 0, sales_order: 1, credit_note: 2, sales_return: 3 }.freeze

# Purchase document kind. One purchases table carries requisitions through bills.
PURCHASE_DOCUMENT_TYPES = {
  requisition: 0,
  rfq: 1,
  purchase_order: 2,
  blanket_order: 3,
  vendor_bill: 4,
  supplier_return: 5
}.freeze

# Meaning of a Purchase ↔ Purchase self-link.
PURCHASE_LINK_TYPES = { rfq_response: 0, blanket_call_off: 1 }.freeze

# Three-way match state of a PO / goods receipt / vendor bill triple.
PURCHASE_MATCH_STATUSES = { unmatched: 0, partial: 1, matched: 2, disputed: 3 }.freeze

# What a commission plan pays on.
COMMISSION_BASES = { revenue: 0, margin: 1, collected: 2 }.freeze

# Commission earning lifecycle, ending in payroll consumption.
COMMISSION_ENTRY_STATUSES = { pending: 0, approved: 1, paid: 2, cancelled: 3 }.freeze

# Recurrence unit for subscription billing.
BILLING_INTERVALS = { weekly: 0, monthly: 1, quarterly: 2, yearly: 3 }.freeze

# Direction of a loyalty points movement.
LOYALTY_DIRECTIONS = { earn: 0, redeem: 1, expire: 2, adjust: 3 }.freeze

# External sales channel a connection talks to.
CHANNEL_KINDS = { shopify: 0, woocommerce: 1, amazon: 2, shopee: 3, lazada: 4, tiktok: 5 }.freeze

# Direction of a channel sync attempt.
SYNC_DIRECTIONS = { inbound: 0, outbound: 1 }.freeze

# Channel sync attempt lifecycle.
CHANNEL_SYNC_STATUSES = { pending: 0, running: 1, completed: 2, failed: 3 }.freeze

# Permission level of a B2B portal user on one customer record.
PORTAL_ROLES = { viewer: 0, buyer: 1, approver: 2, admin: 3 }.freeze

# Warehouse location tree level.
STORAGE_LOCATION_TYPES = { zone: 0, aisle: 1, rack: 2, bin: 3 }.freeze

# Lot/batch availability state (quarantine keeps history without shipping it).
STOCK_LOT_STATUSES = { open: 0, quarantine: 1, consumed: 2, expired: 3, scrapped: 4 }.freeze

# Serialised unit lifecycle.
SERIAL_STATUSES = { in_stock: 0, reserved: 1, sold: 2, returned: 3, scrapped: 4 }.freeze

# What a reorder rule does when the trigger is breached.
REORDER_ACTIONS = { purchase_requisition: 0, stock_transfer: 1, notify_only: 2 }.freeze

# Stocktake scope.
STOCK_COUNT_TYPES = { full: 0, cycle: 1, spot: 2, blind: 3 }.freeze

# Non-material cost attached to a goods receipt.
LANDED_COST_CHARGE_TYPES = { freight: 0, duty: 1, insurance: 2, handling: 3, other: 4 }.freeze

# Basis used to spread a landed cost across received stock.
ALLOCATION_METHODS = { by_quantity: 0, by_value: 1, by_weight: 2, by_volume: 3, equal: 4 }.freeze

# Task precedence relationship type (Gantt / critical path).
TASK_DEPENDENCY_TYPES = { finish_to_start: 0, start_to_start: 1, finish_to_finish: 2, start_to_finish: 3 }.freeze

# How a project is billed.
PROJECT_BILLING_MODELS = { fixed_price: 0, milestone: 1, time_and_materials: 2, retainer: 3 }.freeze

# Reporting-line type between an employee and a manager.
EMPLOYEE_MANAGER_RELATIONSHIPS = { primary: 0, dotted: 1, mentor: 2 }.freeze

# Applicant pipeline stage (drives time-to-hire and funnel reporting).
APPLICANT_STAGES = {
  applied: 0,
  screening: 1,
  interview: 2,
  offer: 3,
  hired: 4,
  rejected: 5,
  withdrawn: 6
}.freeze

# Interview conclusion.
INTERVIEW_OUTCOMES = { pending: 0, advance: 1, hold: 2, reject: 3 }.freeze

# Course enrolment and certification lifecycle.
ENROLLMENT_STATUSES = { enrolled: 0, in_progress: 1, completed: 2, expired: 3, dropped: 4 }.freeze

# SSO provider protocol.
IDENTITY_PROVIDER_TYPES = { saml: 0, oidc: 1 }.freeze

# Second-factor type.
MFA_METHODS = { totp: 0, webauthn: 1, sms: 2, email: 3 }.freeze

# Which area of the product an IP allowlist rule protects.
NETWORK_POLICY_SCOPES = { all: 0, finance: 1, hr: 2, admin: 3 }.freeze

# What a retention policy does when the window ends.
RETENTION_ACTIONS = { anonymize: 0, destroy: 1, archive: 2 }.freeze

# Privacy request kind.
DATA_SUBJECT_REQUEST_TYPES = { access: 0, erasure: 1, portability: 2, rectification: 3 }.freeze

# Privacy request lifecycle.
DATA_SUBJECT_REQUEST_STATUSES = { received: 0, in_progress: 1, completed: 2, rejected: 3 }.freeze

# Outbound notification transport.
NOTIFICATION_CHANNEL_KINDS = { email: 0, slack: 1, teams: 2, zalo: 3, whatsapp: 4, push: 5, sms: 6 }.freeze

# Notification delivery attempt result.
NOTIFICATION_DELIVERY_STATUSES = { pending: 0, sent: 1, failed: 2, bounced: 3 }.freeze

# Outbound webhook delivery attempt result.
WEBHOOK_DELIVERY_STATUSES = { pending: 0, delivered: 1, failed: 2, exhausted: 3 }.freeze

# Tenant data export lifecycle.
DATA_EXPORT_STATUSES = { queued: 0, running: 1, completed: 2, failed: 3 }.freeze

# Quality inspection checkpoint.
QUALITY_INSPECTION_TYPES = { receiving: 0, in_process: 1, final: 2 }.freeze

# Quality check outcome.
QUALITY_RESULTS = { pass: 0, fail: 1, conditional: 2 }.freeze

# Non-conformance severity.
NON_CONFORMANCE_SEVERITIES = { minor: 0, major: 1, critical: 2 }.freeze

# Non-conformance disposition (what happens to the affected goods).
NON_CONFORMANCE_DISPOSITIONS = { use_as_is: 0, rework: 1, scrap: 2, return_to_supplier: 3 }.freeze

# Subcontract job lifecycle.
SUBCONTRACT_STATUSES = { draft: 0, sent: 1, partially_received: 2, received: 3, cancelled: 4 }.freeze
