// Shared analytics block registry — the single source of truth for the
// analytics renderer and the Analytics Config page. Keep this list in the same
// order as Analytic::BLOCKS on the backend.
export const ANALYTICS_BLOCKS = [
  {
    key: "pillars",
    label: "Key pillars",
    description: "Net revenue, gross profit, customer economics, and inventory velocity.",
    icon: "speed"
  },
  {
    key: "secondary_metrics",
    label: "Secondary metrics",
    description: "Orders, new customers, revenue per worked hour, and low stock.",
    icon: "analytics"
  },
  {
    key: "margin_chart",
    label: "Revenue vs tracked cost",
    description: "Gross billing, tracked product cost, and margin rate.",
    icon: "show_chart"
  },
  {
    key: "revenue_mix",
    label: "Revenue mix",
    description: "Where this period's revenue came from.",
    icon: "pie_chart"
  },
  {
    key: "top_items",
    label: "Top products & services",
    description: "Ranked by revenue in the selected period.",
    icon: "leaderboard"
  },
  {
    key: "cohorts",
    label: "Customer cohorts",
    description: "Retention from each customer's first paid order month.",
    icon: "groups"
  },
  {
    key: "inventory",
    label: "Inventory velocity",
    description: "Sell-through, days of cover, and low-stock risk.",
    icon: "inventory"
  },
  {
    key: "workforce",
    label: "Workforce",
    description: "Attendance, hours, and overtime from monthly rollups.",
    icon: "badge"
  },
  {
    key: "clv",
    label: "Top customers by lifetime value",
    description: "All-time paid order spend, not just the selected period.",
    icon: "star"
  }
]

export const ANALYTICS_BLOCK_KEYS = ANALYTICS_BLOCKS.map((block) => block.key)
