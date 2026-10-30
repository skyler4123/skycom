# frozen_string_literal: true

# CacheKeyService — Atomic purpose: the single source of truth for every
# application cache key (catalog: docs/CACHE.md §7).
#
# Why it exists: keys used to be built inline at each call site, so answering
# "which key must be cleared when X happens?" meant grepping the whole app.
# Every key now has exactly one builder, one doc contract, and one place to
# change the pattern.
#
# How it works: pure class methods that return a String — no cache reads, no
# writes, no database access. Call sites keep the store explicit:
#
#   Rails.sync_cache.fetch(
#     CacheKeyService.employee_manager_ids(employee.id),
#     expires_in: CACHE_DEFAULT_EXPIRY
#   ) { ... }
#
# Two key families:
#   - Versioned keys embed `cache_version`. Freshness comes from `touch`:
#     the next read addresses a new key and the old one dies by TTL.
#   - Delete-based keys are stable. `delete` must always address the same
#     string, so these never embed a version.
#
# Kredis keys (`stock_*`, `company_credit_usage`) are pass-throughs to the
# exact strings already stored in Redis. They hold unsynced data — never
# change their shape without a migration.
#
# Every builder carries the contract below (enforced by
# spec/services/cache_key_service_spec.rb):
#   # Pattern:
#   # Purpose:
#   # Store:
#   # TTL:
#   # Written by:
#   # Cleared by:
class CacheKeyService
  # Analytics periods accepted by Analytics::DashboardService (its `case`
  # falls back to this_month for anything else). Keeping the same fallback
  # here means a malformed param can never alias a real period's cache entry.
  ANALYTICS_PERIODS = %w[this_month last_month last_6_months this_year].freeze

  # Pattern: session:<session_id>
  # Purpose: the authentication hot-path hash for one browser session.
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: Session#refresh_cache (after_commit create/update)
  # Cleared by: Session#remove_cache on destroy; AuthenticationConcern#cleanup_invalid_session
  def self.session(session_id)
    "session:#{session_id}"
  end

  # Pattern: user:<user_id>:record:v2
  # Purpose: the full User attributes hash, re-instantiated on every request.
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: User#refresh_cache (after_commit create/update)
  # Cleared by: User#remove_cache on destroy; overwritten by the next write
  def self.user(user_id)
    "user:#{user_id}:record:v2"
  end

  # Pattern: company:<company_id>:record:v2
  # Purpose: the full Company attributes hash for the current-company path.
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: Company#refresh_cache (after_commit create/update)
  # Cleared by: Company#remove_cache on destroy; overwritten by the next write
  def self.company(company_id)
    "company:#{company_id}:record:v2"
  end

  # Pattern: employee:user:<user_id>:company:<company_id>:record:v2
  # Purpose: the current Employee attributes hash, keyed by the lookup pair used
  #   during authentication (a user has at most one employee per company).
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: Employee#refresh_cache (after_commit create/update)
  # Cleared by: Employee#remove_cache on destroy; Role#invalidate_employee_caches touches holders
  def self.employee_record(user_id:, company_id:)
    "employee:user:#{user_id}:company:#{company_id}:record:v2"
  end

  # Pattern: user:<user_id>:companies_max_updated_at
  # Purpose: the client-cache version aggregate (latest company touch per user).
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: ApplicationController::CookieConcern#cache_version
  # Cleared by: Company#refresh_cache and Company#remove_cache
  def self.user_companies_max_updated_at(user_id)
    "user:#{user_id}:companies_max_updated_at"
  end

  # Pattern: employee:<employee_id>:manager_ids
  # Purpose: ids of the group managers this employee reports to (Employee#managers).
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: Employee::ManagerConcern#manager_ids
  # Cleared by: Employee#clear_managers_cache — group manager change,
  #   EmployeeEmployeeGroupAppointment save/destroy
  def self.employee_manager_ids(employee_id)
    "employee:#{employee_id}:manager_ids"
  end

  # Pattern: company:<company_id>:tickets:open_count
  # Purpose: open support-ticket count shown on the company ticket index.
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: Companies::CompanyTicketsController#index
  # Cleared by: CompanyTicket#invalidate_count_caches (create/assign/transition)
  def self.company_open_ticket_count(company_id)
    "company:#{company_id}:tickets:open_count"
  end

  # Pattern: company_ticket:admin:open_count
  # Purpose: open support-ticket count across every company (admin pool).
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: Admin::CompanyTicketsController#index
  # Cleared by: CompanyTicket#invalidate_count_caches (create/assign/transition)
  def self.admin_open_ticket_count
    "company_ticket:admin:open_count"
  end

  # Pattern: employee:<employee_id>:notifications:unread
  # Purpose: cached unread-notification count for one employee.
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: Notifications::UnreadQuery#count
  # Cleared by: Notifications::CreateService, MarkReadService, MarkAllReadService,
  #   Notifications::PruneJob
  def self.employee_unread_notifications(employee_id)
    "employee:#{employee_id}:notifications:unread"
  end

  # Pattern: company:<company_id>:analytics:<period>
  # Purpose: the analytics dashboard payload for one period.
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: Companies::AnalyticsController#index
  # Cleared by: TTL only — clear this key if a dashboard must reflect a change immediately
  def self.company_analytics(company_id, period)
    normalized = period.to_s
    normalized = "this_month" unless ANALYTICS_PERIODS.include?(normalized)
    "company:#{company_id}:analytics:#{normalized}"
  end

  # Pattern: company:<company_id>:storage_statistics
  # Purpose: aggregated storage usage for the storage statistics page.
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: Companies::StorageStatisticsController#index
  # Cleared by: TTL only — uploads/deletes intentionally do not bust it
  def self.company_storage_statistics(company_id)
    "company:#{company_id}:storage_statistics"
  end

  # Pattern: employee:<employee_id>:<cache_version>:owner_role
  # Purpose: the hot boolean behind Employee#owner_role? (owner bypass in ABAC).
  # Store: Rails.ram_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: Employee::PermissionConcern#owner_role?
  # Cleared by: Employee#clear_permissions_cache; a touch changes the version segment
  def self.employee_owner_role(employee)
    "employee:#{employee.id}:#{version_segment(employee)}:owner_role"
  end

  # Pattern: employee:<employee_id>:<cache_version>:permissions
  # Purpose: every role with every company policy (Permissions UI payload).
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: Employee::PermissionConcern#permissions
  # Cleared by: touch — Employee#clear_permissions_cache, role appointment changes,
  #   Role#invalidate_employee_caches
  def self.employee_permissions(employee)
    "employee:#{employee.id}:#{version_segment(employee)}:permissions"
  end

  # Pattern: employee:<employee_id>:<cache_version>:permissions_by_role
  # Purpose: active policy grants used by Employee#can? checks.
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: Employee::PermissionConcern#permissions_by_role
  # Cleared by: touch — Employee#clear_permissions_cache, role appointment changes,
  #   Role#invalidate_employee_caches
  def self.employee_permissions_by_role(employee)
    "employee:#{employee.id}:#{version_segment(employee)}:permissions_by_role"
  end

  # Pattern: company:<company_id>:<cache_version>:permissions
  # Purpose: every role with every company policy (company-level RBAC view).
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: Company::PermissionConcern#permissions
  # Cleared by: Company#clear_permissions_cache and the *RoleAppointment callbacks
  def self.company_permissions(company)
    "company:#{company.id}:#{version_segment(company)}:permissions"
  end

  # Pattern: company:<company_id>:<cache_version>:permissions_by_role
  # Purpose: active policy grants per role for company-level checks.
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: Company::PermissionConcern#permissions_by_role
  # Cleared by: Company#clear_permissions_cache and the *RoleAppointment callbacks
  def self.company_permissions_by_role(company)
    "company:#{company.id}:#{version_segment(company)}:permissions_by_role"
  end

  # Pattern: company:<company_id>:<cache_version>:permissions_by_resource
  # Purpose: role => resource => actions map used by the permissions matrix.
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: Company::PermissionConcern#permissions_by_resource
  # Cleared by: Company#clear_permissions_cache and the *RoleAppointment callbacks
  def self.company_permissions_by_resource(company)
    "company:#{company.id}:#{version_segment(company)}:permissions_by_resource"
  end

  # Pattern: <owner_domain>:<owner_id>:<cache_version>:current_address
  # Purpose: the active Address of any AddressConcern owner (Branch, Company,
  #   Customer, CustomerGroup, Department, Employee, EmployeeGroup, User).
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: AddressConcern#address
  # Cleared by: touch — attach_address calls touch on the owner
  def self.current_address(record)
    "#{record.model_name.name.underscore}:#{record.id}:#{version_segment(record)}:current_address"
  end

  # Pattern: customer:<customer_id>:<cache_version>:current_membership
  # Purpose: the most recent active Membership of a customer.
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: MembershipConcern#membership
  # Cleared by: touch — attach_membership calls touch on the customer
  def self.customer_current_membership(customer)
    "customer:#{customer.id}:#{version_segment(customer)}:current_membership"
  end

  # Pattern: customer:<customer_id>:<cache_version>:membership:<type>
  # Purpose: the active Membership of one business type (e.g. :primary).
  # Store: Rails.sync_cache
  # TTL: CACHE_DEFAULT_EXPIRY (1 hour)
  # Written by: MembershipConcern#membership_of_type
  # Cleared by: touch — attach_membership calls touch on the customer
  def self.customer_membership_of_type(customer, type)
    "customer:#{customer.id}:#{version_segment(customer)}:membership:#{segment(type)}"
  end

  # Pattern: stock:<stock_id>:available
  # Purpose: the atomic Kredis counter backing Stock#available_count and reservations.
  # Store: Rails.global_cache (Kredis)
  # TTL: none — data-bearing, healed from the DB when missing
  # Written by: Stock#reserve_stock!, Stock#release_reserved!, Stock#available_count
  # Cleared by: never delete; changing this string orphans unsynced stock counts
  def self.stock_available(stock_id)
    "stock:#{stock_id}:available"
  end

  # Pattern: companies:<company_id>:credit_usage
  # Purpose: the Kredis delta counter drained into CompanyDailyUsage/MonthlyUsage.
  # Store: Rails.global_cache (Kredis)
  # TTL: none — data-bearing, drained by CompanyUsageSyncJob
  # Written by: Company#record_credit_usage!
  # Cleared by: never delete; changing this string loses unsynced credit usage
  def self.company_credit_usage(company_id)
    "companies:#{company_id}:credit_usage"
  end

  class << self
    private

    # Rails' cache version (microsecond precision) when available, else the
    # updated_at epoch. Records without either collapse to "0" so the key is
    # still a stable String.
    def version_segment(record)
      record.cache_version.to_s.presence || record.updated_at&.to_i&.to_s || "0"
    end

    # Cache segments must not contain separators or whitespace: callers pass
    # user-controlled values (analytics period) and symbols (membership type).
    def segment(value)
      value.to_s.parameterize(separator: "_").presence || "unknown"
    end
  end
end
