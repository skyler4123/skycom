# Analytics

> **Last audited:** 2026-11-19 · **Audit scope:** analytics page controller,
> config controller, dashboard service, revenue calculator, period range, feature
> and service specs. No live browser run.
> **Ship readiness:** 🟠 shippable with gaps — every number is real and the page
> returns blanks instead of fake zeros; the gaps are export, drill-down, and
> time-zone period edges.
> **Who this is for:** the owner, finance lead, or operations manager reviewing a
> period.
> **Mobile:** not mounted; web only.
> **Read first:** [README](README.md) · **Related:** [00-app-overview](00-app-overview.md),
> [07-dashboard](07-dashboard.md)

---

## 1. What this page is for

Analytics is the periodic review: revenue and margin, where the money came from,
what sold, how much stock is turning, how the team is performing, and which
customers are worth keeping. It is the deliberate counterpart to the live
dashboard.

"Done" means the reader can answer "how did the period go, and what should I
change?" — not "what needs attention right now?".

The page is assembled from **nine configurable blocks** in a fixed order.

---

## 2. Who uses it

**The person:** the owner or finance lead, usually weekly or monthly, on a
desktop.

**Their goal:** compare a period with the one before, find the products,
branches, and customers that drive the result, and spot margin or stock problems.

**What they can do here today:**

- Choose one of four periods: this month, last month, last six months, this year.
- Read the four key pillars and the secondary metrics.
- Read revenue vs tracked cost and margin by month.
- Read revenue mix by order category and by branch.
- Read top products and services.
- Read customer cohorts and retention.
- Read inventory velocity, days of cover, fast movers, and low stock.
- Read workforce hours, overtime, and attendance.
- Read top customers by lifetime value.
- Configure which blocks appear.

**What they must do elsewhere:**

- Export a report — no export.
- Drill into a chart or a row — no drill-down.
- Change the period comparison — always "previous period".
- See a forecast — none exists.

**Access:** analytics requires the invoice read permission; the whole page is
financial.

---

## 3. The screen, in words

**Header:** "Executive analysis", the subtitle "Period-based financial, customer,
inventory, and workforce signals", a **Period** select (This Month, Last Month,
Last 6 Months, This Year), a **Config** link, and a "vs previous period" chip.

**Blocks, stacked full width when enabled:**

1. **Key pillars** — four cards: Net revenue, Profitability, Customer economics,
   Inventory velocity.
2. **Secondary metrics** — orders, new customers, revenue per worked hour, low
   stock, plus gross profit and cost coverage.
3. **Revenue vs tracked cost** — a chart with revenue, tracked cost, and margin.
4. **Revenue mix** — two lists: by order category and by branch.
5. **Top products & services** — ranked lists with units and margin.
6. **Customer cohorts** — a retention table by first-order month.
7. **Inventory velocity** — days of cover, stock value, tracked cost, low stock,
   fast movers, low-stock items.
8. **Workforce** — hours, overtime, absence, attendance rate by employee.
9. **Top customers by lifetime value** — spend, orders, average order value.

**Config page:** nine checkbox cards with icon, label, and description, then
**Back to analytics** and **Save changes**.

**States:** loading skeleton, inline error, "No analytics blocks are enabled…",
"No analytics data available", and per-block empties ("No revenue data for this
period", "Not enough paid order history yet", "No stock movement yet", …).

---

## 4. Control inventory

13 interactive controls across the analytics page and its config page.

| ID | Area | Control | What it does today | Status |
|---|---|---|---|---|
| ANL-01 | Header | Period select | Reloads the page with `?period=` and updates the URL | ✅ |
| ANL-02 | Header | Config | Opens the analytics configuration | ✅ |
| ANL-03 | Config | Key pillars checkbox | Toggles the block | ✅ |
| ANL-04 | Config | Secondary metrics checkbox | Toggles the block | ✅ |
| ANL-05 | Config | Revenue vs tracked cost checkbox | Toggles the block | ✅ |
| ANL-06 | Config | Revenue mix checkbox | Toggles the block | ✅ |
| ANL-07 | Config | Top products & services checkbox | Toggles the block | ✅ |
| ANL-08 | Config | Customer cohorts checkbox | Toggles the block | ✅ |
| ANL-09 | Config | Inventory velocity checkbox | Toggles the block | ✅ |
| ANL-10 | Config | Workforce checkbox | Toggles the block | ✅ |
| ANL-11 | Config | Top customers by lifetime value checkbox | Toggles the block | ✅ |
| ANL-12 | Config | Back to analytics | Returns without saving | ✅ |
| ANL-13 | Config | Save changes | PATCHes the block list and toasts | ✅ |

**Count by status:** ✅ 13. Nothing is dead and nothing is invented.

---

## 5. Numbers on screen

| Claim | Meaning | Source | Verdict |
|---|---|---|---|
| Net revenue | Paid sales in the period | Shared revenue calculator over paid orders | ✅ |
| Revenue delta | Change vs the previous period | Same calculation for the comparison window | ✅ blank when there is no baseline |
| Orders | Paid orders in the period | Count | ✅ |
| Average order value | Revenue ÷ orders | Derived | ✅ |
| Active customers | Customers with a paid order in the period | Distinct ids | ✅ |
| Returning rate | Share of active customers who bought before | Prior paid orders | ✅ |
| New customers | Customers created in the period | Creation date | ✅ |
| Gross profit | Revenue minus tracked cost | Only orders with cost data | ✅ |
| Gross margin | Margin percentage | Revenue calculator | ✅ blank when no cost data |
| Cost coverage | Share of revenue with known cost | Calculator | ✅ honest gap indicator |
| Revenue per worked hour | Revenue ÷ attendance hours | Attendance months for the period | ✅ blank when no hours |
| Low stock | Rows below the threshold | quantity − pending < 10 | ✅ |
| Days of cover | How long stock lasts at current sell-through | Units sold from stock transactions ÷ period days | ✅ estimated from actual removals |
| Turnover rate | Units sold ÷ on-hand | Derived | ✅ |
| Stock value (retail / cost) | Value of stock on hand | Product price × quantity; cost where known | ✅ retail uses price, cost may be missing |
| Revenue mix | Revenue by category and branch | Calculator groupings | ✅ |
| Top products / services | Ranked by revenue | Calculator | ✅ |
| Cohort retention | Share of a first-order cohort buying again | Paid orders by month, six-month window | ✅ limited to six months |
| Workforce hours | Worked and overtime hours | Attendance months | ✅ |
| Attendance rate | Present ÷ recorded days | Attendance months | ✅ |
| Top customers by lifetime value | Spend, orders, AOV | All paid orders | ✅ top ten |
| "vs previous period" | The comparison basis | Fixed previous window from `PeriodRange` | ✅ |
| Period boundaries | The exact dates compared | Application time zone (UTC) | 🟡 companies away from UTC can see a boundary off by one day |

**No hardcoded values were found.** When a baseline or a cost is missing the
service returns `nil` and the page renders "—", not a fake zero — the right
behaviour to preserve.

---

## 6. Gaps by user job

### G1 — "Send me this report."
There is no export, no print layout, and no scheduled email. The reader can only
look at the screen.

- Smallest real version: export the summary and tables to CSV (M).
- Better: a printable PDF of the selected period (M).

### G2 — "Which branch or product is behind?"
Charts and lists are display-only; rows do not open anything.

- Smallest real version: link rows to their module pages (S).
- Better: click a chart segment to filter the page (M).

### G3 — "Compare with the same month last year."
Only the immediately previous period is compared. Seasonality cannot be seen.

- Smallest real version: keep the fixed comparison and label it (S).
- Better: a comparison selector (M).

### G4 — "The month boundary is off."
Periods use the application date (UTC). A company in UTC+7 sees a day shift at
the edges of every period.

- Smallest real version: compute period boundaries in the company time zone (S).

### G5 — "Margin is blank."
When product costs are missing, margin is correctly blank and cost coverage
shows why. Nothing tells the reader how to fix it.

- Smallest real version: a tooltip that links to products without costs (S).
- Better: a "costs missing" list with a bulk edit path (M).

### G6 — "The cohort table stops at six months."
Retention is capped at six months, and older cohorts are not shown.

- Smallest real version: state the six-month window on the block (S).
- Better: a 12-month option (M).

### G7 — "Forecast next month."
No forecast, no targets, no budget comparison. Every number is backward-looking.

- Full version: targets and a simple run-rate projection (L).

### G8 — "Why is a block missing?"
A block the role cannot see (or one turned off) simply is not there, with no
explanation.

- Smallest real version: in Config, mark blocks hidden by permission (S).

### G9 — "What counts as cost?"
The reader cannot see which cost field feeds margin (product cost, stock cost,
or order line cost).

- Smallest real version: a definition line on the margin block (S).

---

## 7. Decisions for the BA

**ANL-D1 — Export in the first release?**
- A. No export. Effort S.
- B. CSV of the summary and tables. Effort M.
- C. PDF report. Effort M.
- *Recommendation:* B. A finance lead will ask on day one, and CSV is honest about
  being raw.

**ANL-D2 — Drill-down or stay read-only?**
- A. Read-only. Effort S.
- B. Rows link to their module pages. Effort S.
- C. Chart-driven filtering. Effort M.
- *Recommendation:* B now, C later. Links cost almost nothing and answer "show
  me those orders".

**ANL-D3 — Comparison periods?**
- A. Previous period only. Effort S.
- B. Same period last year or custom. Effort M.
- *Recommendation:* B for seasonal businesses; A otherwise.

**ANL-D4 — Company-clock boundaries?**
- A. Keep UTC. Effort S. Risk: edge-of-month reports are wrong by a day.
- B. Use the company time zone for every period. Effort S.
- *Recommendation:* B, together with DSH-D3.

**ANL-D5 — Cost coverage guidance?**
- A. Show the percentage. Effort S.
- B. Link to the products missing costs. Effort M.
- *Recommendation:* B. A margin report nobody can trust is worse than no margin
  report.

**ANL-D6 — Forecast and targets?**
- A. Out of scope. Effort S.
- B. Monthly targets with run-rate. Effort L.
- *Recommendation:* A until the core report has export and drill-down.

---

## 8. Safe demo path

1. Sign in as the owner of a company with at least three months of paid orders,
   stock movement, and attendance months.
2. Open **Analytics** and show the four pillar cards.
3. Switch **Period** to Last 6 Months and show the URL and numbers change.
4. Show revenue vs tracked cost, then revenue mix by branch.
5. Show top products and the cohort table.
6. Show inventory velocity and fast movers.
7. Show workforce, then top customers by lifetime value.
8. Open **Config**, hide a block, save, and show it disappear.

**Do not demo:**

- A company with no costs configured — margin and gross profit will be blank (it
  is honest, but it looks broken without explanation).
- A brand-new company — cohorts and days of cover need history.
- "Export", "drill-down", "forecast", or "compare to last year" — none exist.
- Period edges near midnight in a non-UTC company.
- The six-month cohort limit as if it were all history.

---

## 9. Engineering appendix

**Routes**

- `GET /companies/:company_id/analytics(.json?period=this_month|last_month|last_6_months|this_year)`
- `GET/PATCH /companies/:company_id/analytic` (config)

**Backend:** `Companies::AnalyticsController`; `Analytics::DashboardService`;
`Analytics::RevenueCalculator`; `Analytics::PeriodRange`.

**Frontend:** `companies/analytics/index_controller.js`,
`companies/analytics/show_controller.js` (config),
`companies/analytics/blocks.js` (shared registry).

**Payload:** `{ period, analytic, summary, profit_margins, revenue_mix,
top_items, inventory_velocity, staff_performance, customer_clv, cohorts }`.

**Honesty rules in code:** `percentage_change` returns `nil` when the previous
value is zero; margin fields are `nil` when no cost data exists; the page renders
"—" rather than zero.

**Time:** `Analytics::PeriodRange` computes boundaries from `Date.current` and
`Time.current` in the application time zone (UTC), not the company time zone.

**Source tables:** `orders`, `order_*_appointments`, `invoices`, `customers`,
`stocks`, `stock_transactions`, `attendance_months`, `employees`, product costs.

**Proof:** `spec/features/companies/analytics_spec.rb`,
`spec/requests/companies/analytics_spec.rb`,
`spec/services/analytics/*.rb`.

**Not covered by tests:** time-zone boundaries, export (absent), drill-down
(absent), and the six-month cohort cap.
