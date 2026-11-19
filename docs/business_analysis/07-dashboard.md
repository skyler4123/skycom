# Dashboard

> **Last audited:** 2026-11-19 · **Audit scope:** dashboard page controller,
> dashboard config controller, overview service, revenue calculator, dashboard
> controller, feature and request specs. No live browser run.
> **Ship readiness:** 🟠 shippable with gaps — no fabricated numbers and no dead
> controls; the gaps are period scope and time-zone edges.
> **Who this is for:** the owner, manager, or administrator starting the day.
> **Mobile:** not mounted; the web dashboard is the only surface.
> **Read first:** [README](README.md) · **Related:** [00-app-overview](00-app-overview.md),
> [08-analytics](08-analytics.md)

---

## 1. What this page is for

The dashboard is the company's morning briefing: how the month is going, what
needs attention right now, and who is working today. It is an exception surface,
not a report — the deeper numbers live in Analytics.

"Done" means the reader knows the one or two things that need action and has a
link to each.

The page is assembled from **ten configurable blocks**; a company can hide the
ones it does not use, and the order is fixed. Financial blocks are hidden from
employees who cannot read invoices.

---

## 2. Who uses it

**The person:** the owner or a manager, usually first thing in the morning and
again before closing.

**Their goal:** spot the exception — a stockout, an approval, a late payment, an
urgent ticket — before it becomes a problem.

**What they can do here today:**

- Read this month's revenue, orders, AOV, margin, customers, stock, approvals,
  and credits.
- See the last 30 days of revenue and order trend.
- See the revenue mix by order category.
- See low stock, pending approvals, overdue invoices, and urgent tickets.
- See recent orders, top customers, today's attendance, and upcoming events.
- See the company wallet and top up.
- Open the related list for any block.
- Configure which blocks appear.

**What they must do elsewhere:**

- Change the period — the dashboard is fixed to this month.
- Drill into a metric beyond the linked list — Analytics or the module page.
- See per-branch comparisons — Analytics.

**Access:** every employee with dashboard read access sees the operational
blocks; financial blocks require the invoice read permission.

---

## 3. The screen, in words

**Header:** "Company health", the subtitle "What needs attention across your
company right now", a "This month" chip, a **Config** link, and **Open Analytics**
(for financial readers).

**Blocks, stacked full width in this order when enabled:**

1. **Company details** — logo, name, code, industry, owner, address, phone,
   email, website, timezone, created date, inside a collapsible summary.
2. **Key metrics** — a row of KPI cards: revenue, orders, AOV, gross margin,
   active customers, low stock, pending approvals, and credits. Some cards only
   appear for financial readers.
3. **Revenue & orders** — a 30-day area/line chart with a legend.
4. **Sales channels** — a revenue-mix chart by order category.
5. **Needs attention** — low stock rows, pending approvals by type, overdue
   invoices, and urgent tickets.
6. **Recent orders** — the last five orders with status and total.
7. **Top customers** — the five highest-spend customers this month.
8. **Staff today** — present, late, absent, scheduled, attendance rate, missing
   checkout.
9. **Upcoming events** — the next five events.
10. **Company wallet** — available credits, main vs promo, used this month,
    access fee, and a top-up link.

**Config page:** ten checkbox cards, each with an icon, label, and description,
plus **Back to dashboard** and **Save changes**. Blocks are stacked full width;
unchecked blocks are hidden but keep their settings.

**States:** loading skeleton, inline error with a retry link, "No dashboard
blocks are enabled…", "No dashboard data available", and per-block empty states
("No orders yet", "Stock levels look healthy", "No overdue invoices", …).

---

## 4. Control inventory

29 interactive controls across the dashboard and its config page.

| ID | Area | Control | What it does today | Status |
|---|---|---|---|---|
| DSH-01 | Header | Config | Opens the dashboard configuration | ✅ |
| DSH-02 | Header | Open Analytics | Opens Analytics (financial readers only) | ✅ |
| DSH-03 | Company details | Collapsible summary | Expands the detail grid | ✅ |
| DSH-04 | Needs attention | View stock | Opens the stock list | ✅ |
| DSH-05 | Needs attention | Purchases approval row | Opens the purchase list | ✅ |
| DSH-06 | Needs attention | Tickets approval row | Opens the ticket list | ✅ |
| DSH-07 | Needs attention | Attendance requests row | Opens attendance requests | ✅ |
| DSH-08 | Needs attention | View invoices | Opens the invoice list | ✅ |
| DSH-09 | Needs attention | View tickets | Opens the ticket list | ✅ |
| DSH-10 | Recent orders | View all | Opens the order list | ✅ |
| DSH-11 | Recent orders | Order row | Opens the order | ✅ |
| DSH-12 | Top customers | View all | Opens the customer list | ✅ |
| DSH-13 | Top customers | Customer row | Opens the customer | ✅ |
| DSH-14 | Staff today | View attendance | Opens attendance days | ✅ |
| DSH-15 | Upcoming events | View all | Opens the event list | ✅ |
| DSH-16 | Upcoming events | Event row | Opens the event | ✅ |
| DSH-17 | Company wallet | Top up | Opens the top-up page | ✅ |
| DSH-18 | Config | Company details checkbox | Toggles the block | ✅ |
| DSH-19 | Config | Key metrics checkbox | Toggles the block | ✅ |
| DSH-20 | Config | Revenue & orders checkbox | Toggles the block | ✅ |
| DSH-21 | Config | Sales channels checkbox | Toggles the block | ✅ |
| DSH-22 | Config | Needs attention checkbox | Toggles the block | ✅ |
| DSH-23 | Config | Recent orders checkbox | Toggles the block | ✅ |
| DSH-24 | Config | Top customers checkbox | Toggles the block | ✅ |
| DSH-25 | Config | Staff today checkbox | Toggles the block | ✅ |
| DSH-26 | Config | Upcoming events checkbox | Toggles the block | ✅ |
| DSH-27 | Config | Company wallet checkbox | Toggles the block | ✅ |
| DSH-28 | Config | Back to dashboard | Returns without saving | ✅ |
| DSH-29 | Config | Save changes | PATCHes the block list and toasts | ✅ |

**Count by status:** ✅ 29. Nothing is dead and nothing is invented.

---

## 5. Numbers on screen

| Claim | Meaning | Source | Verdict |
|---|---|---|---|
| Revenue | Paid sales this month | Shared revenue calculator over paid orders in the current month | ✅ |
| Revenue delta | Change vs last month | Same calculation for the previous month | ✅ |
| Orders | Paid orders this month | Count of paid orders | ✅ |
| Average order value | Revenue ÷ orders | Derived | ✅ |
| Gross margin | Margin percentage | Revenue calculator; shows cost coverage alongside | ✅ estimated — coverage below 100% means some lines have no cost |
| Active customers | Customers with paid orders this month | Distinct customer ids | ✅ |
| New customers | Customers created this month | Creation date | ✅ |
| Low stock | Stock rows below the threshold | quantity − pending < 10, company-wide | ✅ |
| Pending approvals | Purchases + tickets + attendance requests awaiting action | Three real counts | ✅ |
| Credits remaining | Wallet balance | Company wallet total | ✅ |
| Revenue & orders trend | Last 30 days | Daily revenue and paid-order counts | ✅ |
| Sales channels | Revenue by order category | Revenue calculator grouping | ✅ |
| Overdue invoices | Unpaid invoices past due date | Invoice due date vs now | ✅ only for financial readers |
| Urgent tickets | High/urgent, not completed or cancelled | Ticket priority and status | ✅ |
| Top customers | Highest spend this month | Paid order totals grouped by customer | ✅ excludes orders with no customer |
| Staff today | Present / late / absent / scheduled | Today's attendance day rows and scheduled shifts | 🟡 "today" uses the application date, not the company clock |
| Attendance rate | Present ÷ recorded | Derived from attendance days | ✅ |
| Upcoming events | Next five events | End time in the future | ✅ |
| "This month" | The reporting period | Current calendar month in the application time zone | 🟡 a company west or east of UTC can see a month boundary that is off by one day |
| "Last 30 days" | The trend window | 30 dates ending today in the application time zone | 🟡 same edge |
| "Balance is shown before this visit's access fee." | Honest disclosure | True: the fee is deducted after the response | ✅ |

**No hardcoded or invented values were found.** The risk on this page is scope,
not honesty: every figure is monthly or today-only, and the reader cannot change
either.

---

## 6. Gaps by user job

### G1 — "Show me last week."
The page is fixed to this month and the last 30 days. A manager cannot review a
different period without opening Analytics.

- Smallest real version: keep the fixed period and label it clearly (S, current).
- Better: a period selector shared with Analytics (M).

### G2 — "Which branch is behind?"
Every number is company-wide. There is no branch comparison, no per-branch
revenue, and no location filter.

- Smallest real version: link to Analytics for branch views (S).
- Full version: a branch comparison block (M).

### G3 — "Today's attendance looks wrong after midnight."
Attendance, new customers, and the trend use the application date (UTC), not the
company's clock. Near midnight, a company in UTC+7 sees the previous day as
"today".

- Smallest real version: compute day boundaries with the company time zone (S).

### G4 — "The margin says 42% but I do not trust it."
Margin depends on product costs being filled in; the card shows a cost-coverage
percentage beside it but does not explain what to do when coverage is low.

- Smallest real version: a tooltip explaining coverage and what is missing (S).
- Better: a "costs missing" warning with a link to products (M).

### G5 — "What changed since I looked an hour ago?"
The page caches for five minutes and does not refresh itself.

- Smallest real version: a manual refresh (S).
- Better: auto-refresh or realtime on the attention block (M).

### G6 — "Hide the financial blocks from my cashier."
Block visibility is company-wide. A cashier sees the operational blocks because
permissions hide the money, but the block list itself cannot differ by role.

- Smallest real version: rely on the financial permission gate (current, S).
- Better: per-role dashboards (M).

### G7 — "Why is my dashboard empty?"
A new company with no orders, no stock, and no events sees several empty blocks
at once. Each block has an empty state, but the page has no onboarding message.

- Smallest real version: a first-run welcome card with the next three steps (S).
- Better: hide empty blocks until they have data (M).

### G8 — "Reorder the blocks."
The order is fixed in code; only visibility is configurable.

- Smallest real version: document the fixed order (S).
- Better: drag or up/down ordering with persisted order (M).

### G9 — "Who can see the wallet?"
The wallet block requires the financial permission, which is the same permission
as invoices. A company may want a finance clerk to see invoices but not credits.

- Smallest real version: accept the shared gate (S).
- Better: a dedicated wallet permission (M).

---

## 7. Decisions for the BA

**DSH-D1 — Does the dashboard get a period selector?**
- A. Keep "this month" and send history to Analytics. Effort S.
- B. Share Analytics' period selector here. Effort M.
- *Recommendation:* A. The dashboard is a morning briefing; Analytics is the
  review surface.

**DSH-D2 — Branch comparison: build or defer?**
- A. Defer, link to Analytics. Effort S.
- B. Add a branch comparison block. Effort M.
- *Recommendation:* B for multi-branch customers; it is the first question a
  regional manager asks.

**DSH-D3 — Company-clock day boundaries?**
- A. Keep the application date. Effort S. Risk: wrong "today" near midnight.
- B. Use the company time zone everywhere on this page. Effort S.
- *Recommendation:* B. The product already has the conversion helper; not using it
  here is an inconsistency, not a design choice.

**DSH-D4 — Do empty blocks hide themselves?**
- A. Keep empty states for every block. Effort S.
- B. Hide a block until it has data, with a first-run card. Effort M.
- *Recommendation:* B for new companies; A once a company has data.

**DSH-D5 — Block ordering?**
- A. Fixed order. Effort S.
- B. Up/down ordering saved per company. Effort M.
- *Recommendation:* A. One owner per concept: visibility is the company's choice,
  order is the product's recommendation.

**DSH-D6 — Per-role dashboards?**
- A. One company dashboard with permission-gated blocks. Effort S.
- B. Role-specific dashboards. Effort L.
- *Recommendation:* A until a customer asks. The permission gate already prevents
  a cashier from seeing money.

**DSH-D7 — Wallet visibility?**
- A. Reuse the invoice permission. Effort S.
- B. Add a wallet permission. Effort S–M.
- *Recommendation:* B when there is more than one financial role.

---

## 8. Safe demo path

1. Sign in as the owner of a company with paid orders this month, stock, and at
   least one pending approval.
2. Show **Company health** and the KPI row.
3. Point out the trend chart and the revenue mix.
4. Open **Needs attention**, then open one linked list and come back.
5. Show **Recent orders** and **Top customers**.
6. Show **Staff today**, **Upcoming events**, and **Company wallet**.
7. Open **Config**, uncheck a block, save, and show it disappear.

**Do not demo:**

- A brand-new company with no data — most blocks will be empty.
- The margin card without explaining cost coverage if product costs are missing.
- The page as "current" in the first five minutes after a change — it is cached
  for five minutes.
- Attendance near midnight in a non-UTC company.
- "Reorder blocks" — it does not exist.

---

## 9. Engineering appendix

**Routes**

- `GET /companies/:company_id/dashboards` (HTML + `.json`)
- `GET/PATCH /companies/:company_id/dashboard` (config page)

**Backend:** `Companies::DashboardsController#index|show|update`;
`Dashboards::OverviewService`; `Analytics::RevenueCalculator`;
`Analytics::PeriodRange`.

**Frontend:** `companies/dashboards/index_controller.js` (page),
`companies/dashboards/show_controller.js` (config),
`companies/dashboards/blocks.js` (shared registry).

**Payload:** `period`, `dashboard.blocks`, `company`, `permissions.kpis`,
`attention`, `recent_orders`, `staff_today`, `upcoming_events`, and — for
financial readers — `trend`, `revenue_mix`, `top_customers`, `wallet`.

**Caching:** the index payload is cached in `Rails.sync_cache` for
`DASHBOARD_CACHE_EXPIRY` (5 minutes), keyed by company and
`can_view_financials`. Credit deduction still runs on every request through the
controller filter.

**Time:** `Analytics::PeriodRange.new("this_month")` and `Date.current` drive the
period and "today"; both use the application time zone (UTC), not the company
time zone.

**Source tables:** `orders`, `invoices`, `customers`, `stocks`, `purchases`,
`tickets`, `attendance_requests`, `attendance_days`, `scheduled_shifts`,
`events`, company wallet tables.

**Proof:** `spec/features/companies/dashboards_spec.rb`,
`spec/requests/companies/dashboards_spec.rb`,
`spec/services/dashboards/overview_service_spec.rb`.

**Not covered by tests:** time-zone day boundaries, cost-coverage messaging, and
per-role block visibility.
