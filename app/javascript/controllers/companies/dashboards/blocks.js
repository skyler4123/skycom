// Shared dashboard block registry — the single source of truth for the
// dashboard renderer and the Dashboard Config page. Keep this list in the same
// order as Dashboard::BLOCKS on the backend.
export const DASHBOARD_BLOCKS = [
  {
    key: "company_meta",
    label: "Company details",
    description: "Company name, address, contact details, and owner.",
    icon: "business"
  },
  {
    key: "kpis",
    label: "Key metrics",
    description: "Revenue, orders, customers, stock, approvals, and credits.",
    icon: "speed"
  },
  {
    key: "revenue_orders",
    label: "Revenue & orders",
    description: "Revenue and order trend for the last 30 days.",
    icon: "monitoring"
  },
  {
    key: "sales_channels",
    label: "Sales channels",
    description: "Revenue mix by order category for the current month.",
    icon: "pie_chart"
  },
  {
    key: "attention",
    label: "Needs attention",
    description: "Low stock, pending approvals, overdue invoices, and urgent tickets.",
    icon: "priority_high"
  },
  {
    key: "recent_orders",
    label: "Recent orders",
    description: "The latest orders across the company.",
    icon: "receipt_long"
  },
  {
    key: "top_customers",
    label: "Top customers",
    description: "Customers with the highest spend this month.",
    icon: "group"
  },
  {
    key: "staff_today",
    label: "Staff today",
    description: "Present, late, absent, and attendance rate for today.",
    icon: "groups"
  },
  {
    key: "upcoming_events",
    label: "Upcoming events",
    description: "The next scheduled company events.",
    icon: "event"
  },
  {
    key: "company_wallet",
    label: "Company wallet",
    description: "Available credits, usage this month, and access fee.",
    icon: "account_balance_wallet"
  }
]

export const DASHBOARD_BLOCK_KEYS = DASHBOARD_BLOCKS.map((block) => block.key)
