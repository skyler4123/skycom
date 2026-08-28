// Shared sidebar registry — the single source of truth for both the sidebar
// renderer (layout_controller.js) and the Settings "Sidebar" tab.
// Keep `key` values in sync with `SIDEBAR_ITEM_KEYS` in app/models/company.rb.
import { currentSettings } from "controllers/helpers/auth_helpers"

export const DEFAULT_SETTINGS_CODE = "SETTINGS-DEFAULT"

export const SIDEBAR_ITEMS = [
  { key: "dashboard", group: "company", icon: "dashboard", label: "Dashboard", href: (cid) => Helpers.company_dashboards_path(cid) },
  { key: "branches", group: "company", icon: "apartment", label: "Branches", href: (cid) => Helpers.company_branches_path(cid) },
  { key: "departments", group: "company", icon: "family_group", label: "Departments", href: (cid) => Helpers.company_departments_path(cid) },
  { key: "categories", group: "company", icon: "category", label: "Categories", href: (cid) => Helpers.company_categories_path(cid) },
  { key: "property_mappings", group: "company", icon: "settings_applications", label: "Dynamic Properties", href: (cid) => Helpers.company_property_mappings_path(cid) },
  { key: "table_configs", group: "company", icon: "table", label: "Dynamic Tables", href: (cid) => Helpers.company_table_configs_path(cid) },
  { key: "products", group: "company", icon: "inventory_2", label: "Products", href: (cid) => Helpers.company_products_path(cid) },
  { key: "brands", group: "company", icon: "diamond", label: "Brands", href: (cid) => Helpers.company_brands_path(cid) },
  { key: "services", group: "company", icon: "concierge", label: "Services", href: (cid) => Helpers.company_services_path(cid) },
  { key: "orders", group: "company", icon: "order_approve", label: "Orders", href: (cid) => Helpers.company_orders_path(cid) },
  { key: "employees", group: "company", icon: "groups", label: "Employees", href: (cid) => Helpers.company_employees_path(cid) },
  { key: "shift_templates", group: "company", icon: "schedule", label: "Shift Templates", href: (cid) => Helpers.company_shift_templates_path(cid) },
  { key: "scheduled_shifts", group: "company", icon: "calendar_month", label: "Shifts", href: (cid) => Helpers.company_scheduled_shifts_path(cid) },
  { key: "attendance_days", group: "company", icon: "badge", label: "Attendance Days", href: (cid) => Helpers.company_attendance_days_path(cid) },
  { key: "attendance_policies", group: "company", icon: "gps_fixed", label: "Attendance Policies", href: (cid) => Helpers.company_attendance_policies_path(cid) },
  { key: "attendance_logs", group: "company", icon: "receipt_long", label: "Attendance Logs", href: (cid) => Helpers.company_attendance_logs_path(cid) },
  { key: "attendance_months", group: "company", icon: "calendar_view_month", label: "Attendance Months", href: (cid) => Helpers.company_attendance_months_path(cid) },
  { key: "stocks", group: "company", icon: "inventory", label: "Stocks", href: (cid) => Helpers.company_stocks_path(cid) },
  { key: "stock_transfers", group: "company", icon: "swap_horiz", label: "Stock Transfers", href: (cid) => Helpers.company_stock_transfers_path(cid) },
  { key: "stock_imports", group: "company", icon: "download", label: "Stock Imports", href: (cid) => Helpers.company_stock_imports_path(cid) },
  { key: "stock_exports", group: "company", icon: "upload", label: "Stock Exports", href: (cid) => Helpers.company_stock_exports_path(cid) },
  { key: "customers", group: "company", icon: "person_add", label: "Customers", href: (cid) => Helpers.company_customers_path(cid) },
  { key: "invoices", group: "company", icon: "receipt_long", label: "Invoices", href: (cid) => Helpers.company_invoices_path(cid) },
  { key: "policies", group: "company", icon: "security", label: "Policies", href: (cid) => Helpers.company_policies_path(cid) },
  { key: "pages", group: "company", icon: "description", label: "Pages", href: (cid) => Helpers.company_pages_path(cid) },
  { key: "payment_methods", group: "company", icon: "payments", label: "Payment Methods", href: (cid) => Helpers.company_payment_method_appointments_path(cid) },
  { key: "permissions", group: "company", icon: "shield", label: "Permissions", href: (cid) => Helpers.company_permissions_path(cid) },
  { key: "analytics", group: "company", icon: "insights", label: "Analytics", href: (cid) => Helpers.company_analytics_path(cid) },
  { key: "facilities", group: "company", icon: "warehouse", label: "Facilities", href: (cid) => Helpers.company_facilities_path(cid) },
  { key: "usage", group: "system", icon: "monitoring", label: "Usage", href: (cid) => Helpers.company_usage_path(cid) },
  { key: "top_up", group: "system", icon: "account_balance_wallet", label: "Top Up", href: (cid) => Helpers.new_company_top_up_path(cid) },
  { key: "billing", group: "system", icon: "receipt_long", label: "Billing", href: (cid) => Helpers.company_billing_path(cid) },
  { key: "settings", group: "system", icon: "settings", label: "Settings", href: (cid) => Helpers.company_settings_path(cid) }
]

// System sidebar items (Usage, Top Up, Billing, Settings) are platform-managed:
// they can never be hidden via company settings.
export const SYSTEM_ITEM_KEYS = new Set(
  SIDEBAR_ITEMS.filter(i => i.group === "system").map(i => i.key)
)

/**
 * Returns the set of sidebar keys the default company setting hides.
 * Absent keys default to visible (the seeded default marks everything visible).
 * System items are never hidden, even if stale metadata says otherwise.
 * @returns {Set<string>}
 */
export const hiddenSidebarKeys = () => {
  const settings = currentSettings() || []
  const defaultSetting = settings.find(s => s.code === DEFAULT_SETTINGS_CODE) || settings[0]
  const items = defaultSetting?.metadata?.sidebar_items || []
  return new Set(
    items
      .filter(i => i.visible === false && !SYSTEM_ITEM_KEYS.has(i.key))
      .map(i => i.key)
  )
}