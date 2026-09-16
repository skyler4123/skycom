// Shared sidebar registry — the single source of truth for both the sidebar
// renderer (layout_controller.js) and the Settings "Sidebar" tab.
// Keep `key` values in sync with `SIDEBAR_ITEM_KEYS` and `SIDEBAR_GROUP_KEYS`
// in app/models/company.rb.
import { currentSettings } from "controllers/helpers/auth_helpers"

export const DEFAULT_SETTINGS_CODE = "SETTINGS-DEFAULT"

// Group registry — array order is the sidebar render order.
// `locked: true` groups can never be hidden via company settings.
export const SIDEBAR_GROUPS = [
  { key: "general", label: "General" },
  { key: "catalog", label: "Catalog" },
  { key: "sales", label: "Sales" },
  { key: "organization", label: "Organization" },
  { key: "platform", label: "Platform" },
  { key: "attendance", label: "Attendance" },
  { key: "inventory", label: "Inventory" },
  { key: "authorization", label: "Authorization" },
  { key: "system", label: "System", locked: true }
]

export const SIDEBAR_ITEMS = [
  { key: "dashboard", group: "general", icon: "dashboard", label: "Dashboard", href: (cid) => Helpers.company_dashboards_path(cid) },
  { key: "analytics", group: "general", icon: "insights", label: "Analytics", href: (cid) => Helpers.company_analytics_path(cid) },
  { key: "products", group: "catalog", icon: "inventory_2", label: "Products", href: (cid) => Helpers.company_products_path(cid) },
  { key: "brands", group: "catalog", icon: "diamond", label: "Brands", href: (cid) => Helpers.company_brands_path(cid) },
  { key: "services", group: "catalog", icon: "concierge", label: "Services", href: (cid) => Helpers.company_services_path(cid) },
  { key: "orders", group: "sales", icon: "order_approve", label: "Orders", href: (cid) => Helpers.company_orders_path(cid) },
  { key: "customers", group: "sales", icon: "person_add", label: "Customers", href: (cid) => Helpers.company_customers_path(cid) },
  { key: "invoices", group: "sales", icon: "receipt_long", label: "Invoices", href: (cid) => Helpers.company_invoices_path(cid) },
  { key: "branches", group: "organization", icon: "apartment", label: "Branches", href: (cid) => Helpers.company_branches_path(cid) },
  { key: "departments", group: "organization", icon: "family_group", label: "Departments", href: (cid) => Helpers.company_departments_path(cid) },
  { key: "employees", group: "organization", icon: "groups", label: "Employees", href: (cid) => Helpers.company_employees_path(cid) },
  { key: "facilities", group: "organization", icon: "meeting_room", label: "Facilities", href: (cid) => Helpers.company_facilities_path(cid) },
  { key: "categories", group: "platform", icon: "category", label: "Categories", href: (cid) => Helpers.company_categories_path(cid) },
  { key: "property_mappings", group: "platform", icon: "settings_applications", label: "Dynamic Properties", href: (cid) => Helpers.company_property_mappings_path(cid) },
  { key: "table_configs", group: "platform", icon: "table", label: "Dynamic Tables", href: (cid) => Helpers.company_table_configs_path(cid) },
  { key: "pages", group: "platform", icon: "description", label: "Pages", href: (cid) => Helpers.company_pages_path(cid) },
  { key: "payment_methods", group: "platform", icon: "payments", label: "Payment Methods", href: (cid) => Helpers.company_payment_method_appointments_path(cid) },
  { key: "shift_templates", group: "attendance", icon: "schedule", label: "Shift Templates", href: (cid) => Helpers.company_shift_templates_path(cid) },
  { key: "scheduled_shifts", group: "attendance", icon: "calendar_month", label: "Shifts", href: (cid) => Helpers.company_scheduled_shifts_path(cid) },
  { key: "attendance_days", group: "attendance", icon: "badge", label: "Attendance Days", href: (cid) => Helpers.company_attendance_days_path(cid) },
  { key: "attendance_policies", group: "attendance", icon: "gps_fixed", label: "Attendance Policies", href: (cid) => Helpers.company_attendance_policies_path(cid) },
  { key: "attendance_logs", group: "attendance", icon: "receipt_long", label: "Attendance Logs", href: (cid) => Helpers.company_attendance_logs_path(cid) },
  { key: "attendance_months", group: "attendance", icon: "calendar_view_month", label: "Attendance Months", href: (cid) => Helpers.company_attendance_months_path(cid) },
  { key: "warehouses", group: "inventory", icon: "warehouse", label: "Warehouses", href: (cid) => Helpers.company_warehouses_path(cid) },
  { key: "stocks", group: "inventory", icon: "inventory", label: "Stocks", href: (cid) => Helpers.company_stocks_path(cid) },
  { key: "stock_transfers", group: "inventory", icon: "swap_horiz", label: "Stock Transfers", href: (cid) => Helpers.company_stock_transfers_path(cid) },
  { key: "stock_imports", group: "inventory", icon: "download", label: "Stock Imports", href: (cid) => Helpers.company_stock_imports_path(cid) },
  { key: "stock_exports", group: "inventory", icon: "upload", label: "Stock Exports", href: (cid) => Helpers.company_stock_exports_path(cid) },
  { key: "policies", group: "authorization", icon: "security", label: "Policies", href: (cid) => Helpers.company_policies_path(cid) },
  { key: "permissions", group: "authorization", icon: "shield", label: "Permissions", href: (cid) => Helpers.company_permissions_path(cid) },
  { key: "usage", group: "system", icon: "monitoring", label: "Usage", href: (cid) => Helpers.company_usage_path(cid) },
  { key: "top_up", group: "system", icon: "account_balance_wallet", label: "Top Up", href: (cid) => Helpers.new_company_top_up_path(cid) },
  { key: "billing", group: "system", icon: "receipt_long", label: "Billing", href: (cid) => Helpers.company_billing_path(cid) },
  { key: "settings", group: "system", icon: "settings", label: "Settings", href: (cid) => Helpers.company_settings_path(cid) }
]

// Locked groups (System) can never be hidden via company settings.
export const SYSTEM_GROUP_KEYS = new Set(
  SIDEBAR_GROUPS.filter(g => g.locked).map(g => g.key)
)

// System sidebar items (Usage, Top Up, Billing, Settings) are platform-managed:
// they can never be hidden via company settings.
export const SYSTEM_ITEM_KEYS = new Set(
  SIDEBAR_ITEMS.filter(i => i.group === "system").map(i => i.key)
)

/**
 * Returns both hidden sets derived from the default company setting.
 * Absent groups/items default to visible (the seeded default marks everything visible).
 * Locked groups/items are never hidden, even if stale metadata says otherwise.
 * @returns {{ hiddenGroups: Set<string>, hiddenItems: Set<string> }}
 */
export const sidebarVisibility = () => {
  const settings = currentSettings() || []
  const defaultSetting = settings.find(s => s.code === DEFAULT_SETTINGS_CODE) || settings[0]

  const groups = defaultSetting?.metadata?.sidebar_groups || []
  const hiddenGroups = new Set(
    groups.filter(g => g.visible === false && !SYSTEM_GROUP_KEYS.has(g.key)).map(g => g.key)
  )

  const items = defaultSetting?.metadata?.sidebar_items || []
  const hiddenItems = new Set(
    items.filter(i => i.visible === false && !SYSTEM_ITEM_KEYS.has(i.key)).map(i => i.key)
  )

  return { hiddenGroups, hiddenItems }
}
