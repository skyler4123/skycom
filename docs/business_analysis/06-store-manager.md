# Store Manager

> **Last audited:** 2026-11-19 · **Audit scope:** frontend controller, console
> service, backend controller, feature and service specs. No live browser run.
> **Ship readiness:** 🔴 not shippable — six dead tabs and three fabricated
> status claims are visible to an operator.
> **Who this is for:** the store manager or shift lead on duty at one branch.
> **Mobile:** same console, mounted through the Hotwire shell.
> **Read first:** [README](README.md) · **Related:** [00-app-overview](00-app-overview.md),
> [05-inventory](05-inventory.md), [02-pos](02-pos.md)

---

## 1. What this page is for

The Store Manager console is the branch-level command screen for a retail day.
A manager opens it mid-shift to answer four questions at a glance: how much have
we sold, what still has to be handed to a customer, what is nearly empty on the
shelf, and who is working. It is also the place a manager is supposed to close
the day from.

"Done" on this page means one of three things: an order in the queue has moved
towards handover, a low shelf has a restock decision, or the manager has left the
console for the specific screen that owns the detailed work.

The page is read-only. It intentionally sends the manager to the order, stock,
attendance, and POS screens rather than duplicating their actions. That design is
sound; the gaps below are about the console promising more than it delivers.

---

## 2. Who uses it

**The person:** a store manager, shift lead, or duty supervisor responsible for
one branch during one shift. They are on their feet, often on a tablet, and they
check this screen between serving customers.

**Their goal:** a fast, trustworthy picture of the shift, and a short path to the
one thing that needs attention.

**What they can do here today:**

- Read today's sales, fulfilment, shelf-stock and staffing numbers.
- Search and filter the fulfilment queue and open any listed order.
- Jump to a low-stock row in the stock ledger.
- Jump to the orders, stock-adjustment, and attendance screens.
- Refresh the data on demand.

**What they must do elsewhere:**

- Take a payment or open the cash drawer — POS operation.
- Move an order through fulfilment — the order detail page.
- Request stock from the warehouse — stock transfer or purchase screens.
- Close the shift, count the float, or print a report — nothing exists yet.

**Access:** the Store Manager operation must be active at the branch, and the
employee's role must be allowed by the operation's role configuration.

---

## 3. The screen, in words

**Top bar:** the Skycom mark (links back to the Operations list), the company
name, the branch name and code, a green "Cloud Sync Active" pill, a dark-mode
toggle, and the signed-in user's name and role.

**Second row:** seven navigation tabs — Store Overview (active), Counter & POS
Terminals, Orders & Fulfillment, Store Replenishment, Inventory & Stock Ledger,
Warehouse Transfers, BOM & Procurement.

**Context banner:** a green "Store Open • Fully Operational" pill, the branch
name, the "Current Shift", and five quick actions: New Store Order, Request
Restock, Stock Adjustment, Daily Shift Report, Float Audit.

**KPI strip (five cards):** Gross Sales Today, Active POS Counters, Orders To
Fulfill, Shelf Stock Alerts, Store Staff On Duty.

**Main column:** the fulfilment queue (order tabs, search, barcode button, a
five-column table, and a "View all orders" link), then Shelf Replenishment
Requisitions (a six-column table of low-stock rows).

**Side column:** Active Register & POS Status (one card per cashier), Footfall &
Conversion (visitor and conversion placeholders plus an hourly bar chart), and
the On-Duty Shift Roster with a "Manage Shift Attendance & Overtime" button.

**Footer strip:** "Live data synced from the regional cloud", the refresh time,
the operation code, the branch name, and a Diagnostics button.

**States**

- *Loading:* the page is blank until the JSON payload returns.
- *Error:* a full-screen red message with the server's error text.
- *Empty orders:* "No orders match this view."
- *Empty shelves:* "No shelf stock is below the minimum threshold."
- *Empty registers:* "No register activity today."
- *Empty staff:* "No employees are assigned to this branch."
- *Responsive:* two columns on desktop become one on phones and tablets; wide
  tables scroll inside their card.

---

## 4. Control inventory

28 interactive controls. Non-interactive claims are listed in §5.

| ID | Area | Control | What it does today | Status | If shipped as-is |
|---|---|---|---|---|---|
| SM-01 | Top bar | Skycom logo | Returns to the Operations list | ✅ | — |
| SM-02 | Tabs | Store Overview | Already active; does nothing | ✅ | — |
| SM-03 | Tabs | Counter & POS Terminals | Toast: "Counter & POS Terminals is coming soon." | 🗑️ | Looks like a second page that does not exist |
| SM-04 | Tabs | Orders & Fulfillment | Toast: "… is coming soon." | 🗑️ | Same |
| SM-05 | Tabs | Store Replenishment | Toast: "… is coming soon." | 🗑️ | Same |
| SM-06 | Tabs | Inventory & Stock Ledger | Toast: "… is coming soon." | 🗑️ | Same |
| SM-07 | Tabs | Warehouse Transfers | Toast: "… is coming soon." | 🗑️ | Same |
| SM-08 | Tabs | BOM & Procurement | Toast: "… is coming soon." | 🗑️ | Same |
| SM-09 | Top bar | Dark-mode toggle | Switches theme | ✅ | — |
| SM-10 | Context banner | New Store Order | Opens the new-order screen | ✅ | — |
| SM-11 | Context banner | Request Restock | Scrolls to the shelf section; creates nothing | 🟡 | Label promises a request that never happens |
| SM-12 | Context banner | Stock Adjustment | Opens the stock-adjustment list | ✅ | Leaves the console |
| SM-13 | Context banner | Daily Shift Report | Toast: "Daily shift report export is not connected yet." | 🗑️ | A manager cannot close the day |
| SM-14 | Context banner | Float Audit | Toast: "Float audit is handled from the POS operation." | 🗑️ | Points at a POS flow that has no float audit either |
| SM-15 | Fulfilment | Refresh orders | Reloads the payload and re-renders | ✅ | — |
| SM-16 | Fulfilment | All Orders tab | Filters the loaded queue | ✅ | — |
| SM-17 | Fulfilment | Click & Collect tab | Filters the loaded queue by channel | 🟡 | Only the 8 loaded rows are filtered |
| SM-18 | Fulfilment | Local Delivery tab | Filters the loaded queue by channel | 🟡 | Only the 8 loaded rows are filtered |
| SM-19 | Fulfilment | Completed tab | Filters the loaded queue by status | 🟡 | Only the 8 loaded rows are filtered |
| SM-20 | Fulfilment | Order search | Filters loaded rows by code, customer, channel, status, assignee | 🟡 | Placeholder promises SKU scanning; SKU is not searched |
| SM-21 | Fulfilment | Barcode scanner button | Focuses the search box and shows a toast | 🟡 | No scanner integration exists |
| SM-22 | Fulfilment | Order code link | Opens the order detail page | ✅ | — |
| SM-23 | Fulfilment | Row action link | Opens the order detail page (label varies by status) | ✅ | Action happens on the order page, not here |
| SM-24 | Fulfilment | View all orders | Opens the orders list | ✅ | — |
| SM-25 | Replenishment | Restock row action | Opens the stock row | ✅ | No request is created |
| SM-26 | Replenishment | Open stock ledger | Opens the stock list | ✅ | — |
| SM-27 | Staff | Manage Shift Attendance & Overtime | Opens the attendance months list | ✅ | Leaves the console |
| SM-28 | Footer | Diagnostics | Toast: "Store manager diagnostics are not connected yet." | 🗑️ | Dead-end button in the footer |

**Count by status:** ✅ 13 · 🟡 6 · 🗑️ 9 · ⛔ 0 · 💤 0 · 🔢 0 (fabrication is in
the claims and numbers, not the controls).

---

## 5. Numbers on screen

| Claim on screen | What it appears to mean | Where it actually comes from | Verdict |
|---|---|---|---|
| Gross Sales Today | Money sold today | Sum of line-item totals for today's paid/completed orders, on the branch's calendar day | 🟡 line-item totals, not invoice totals — tax and order-level adjustments are excluded |
| +N% vs yesterday | Day-over-day change | Same calculation for yesterday; blank when yesterday had no sales | ✅ |
| "N Lanes" (Active POS Counters) | Working POS terminals | Number of employees who recorded at least one order today | 🟡 no terminal model exists; the label describes hardware that is not tracked |
| "N transactions processed" | Completed sales | Count of paid/completed orders today | ✅ |
| "N Pending" (Orders To Fulfill) | Orders awaiting fulfilment | Count of today's draft, pending, confirmed and in-progress orders | ✅ |
| "N Click & Collect" | Orders for pickup | Fulfilment-state orders whose order type is set to "in store" | 🟡 channel is inferred from a field that means something else |
| "N Delivery" | Orders for delivery | Fulfilment-state orders whose order type is set to "online" | 🟡 same inference |
| "Shift Sales" (register card) | Money taken during that person's shift | Today's paid/completed orders for that employee; no shift start or end is read | 🟡 labelled "shift", measured "today" |
| "Orders Processed" (register card) | Orders handled in the shift | Count of today's orders assigned to that employee | 🟡 same |
| "N Low" (Shelf Stock Alerts) | Products near empty | Branch stock rows where quantity minus pending is 10 or less | ✅ threshold is global, not per product |
| "N Team" (Store Staff On Duty) | People clocked in now | Active employees assigned to the branch; no attendance or shift check | 🟡 "on duty" is assumed from assignment, not observed |
| Current Shift | The scheduled shift | The branch-local hour bucketed at 12:00 and 17:00 into three fixed labels, ignoring scheduled shifts and branch opening hours | 🔢 fabricated; the labels ("Morning 08:00–17:00") contradict the cut-off at noon |
| Register name ("Main Counter", "Express Kiosk", "Pickup Desk", "Floor Register") | A named POS terminal | Invented from the employee's position in the grouped list | 🔢 |
| "Synced" on a register card | Terminal acknowledged the cloud | Static text | 🔢 |
| Hourly Order Volume bars | Orders per hour at this branch | Orders bucketed by their **UTC** hour over a fixed 08:00–18:00 window, while the "Now" bar uses the branch clock | 🔢 wrong time base; a branch east of UTC sees an almost empty chart |
| "Peak: 14h (6)" | Busiest hour | Maximum of the same flawed hourly series | 🔢 inherits the error above |
| Today's Visitors / Store Conversion | People who entered, and the share who bought | No source; the panel shows "—" and "Sensor not connected" | 💤 honest gap |
| "N buyers" | Distinct customers who bought | Distinct customer IDs among today's orders | ✅ |
| "Cloud Sync Active" | Live connection to the cloud | Static green pill | 🔢 |
| "Store Open • Fully Operational" | Trade status | Static text; branch opening hours are not modelled | 🔢 |
| "Live data synced from the regional cloud." | Freshness guarantee | Static text | 🔢 |
| "Refreshed at 9:41 AM" | When the data was built | Server timestamp of the payload | ✅ |
| "Threshold: 10 units" | Restock warning level | Global constant of 10 for every product in every company | 🟡 |
| "Displaying 8 of 27 today's queue entries" | How much of the queue is visible | 8 is the loaded row count; 27 is the true count — the rest cannot be reached from this page | 🟡 |

---

## 6. Gaps by user job

### G1 — "Which part of the store am I looking at?"
Six of the seven tabs do nothing but say "coming soon". The console is one
screen wearing a seven-tab costume. A manager learns within seconds that the
navigation cannot be trusted.

- Smallest real version: remove the six tabs and keep one clear title (S).
- Alternative: turn each tab into an anchor that scrolls to the matching section
  already on the page (S–M).
- Full version: build the six sections as separate views (L, incremental).

### G2 — "How did we do yesterday?"
Every number is today. There is no date or period selector, so the page is
useless before opening and after closing, and a manager cannot review a past
shift from it.

- Smallest real version: add a date selector and scope the payload to it (M).
- Alternative: keep "today" and link to Analytics for history (S).

### G3 — "How do I close the shift?"
There is no shift report, no cash reconciliation, no handover note, and no
print/export. "Daily Shift Report" and "Float Audit" are both dead ends, and the
cash-management note sends the manager to a POS flow that has no float audit.

- Smallest real version: a printable or downloadable end-of-day summary of the
  numbers already on this page (M).
- Full version: a shift record (open/close, counted cash, variance, notes) (L).

### G4 — "Which terminal is which?"
Register cards are grouped by cashier and named by list position. Two cashiers
in the same order produce "Main Counter" and "Express Kiosk" — names that exist
nowhere in the company's configuration.

- Smallest real version: rename the card to "Cashier" and drop the invented
  names and numbers (S).
- Full version: model terminals and appoint them to branches (L).

### G5 — "Who is actually on duty?"
"On duty" means "assigned to this branch and active". Nobody has to have checked
in, and a person on leave still appears. Scheduled shifts and attendance already
exist in the system but are not read here.

- Smallest real version: rename to "Branch staff" (S).
- Better: join today's scheduled shifts and attendance check-ins (M).

### G6 — "What should I order?"
"Request Restock" scrolls the page. There is no requisition, no quantity, no
approval, and no link to the purchase or transfer flows — only a link to the
stock row.

- Smallest real version: rename to "Show low stock" (S).
- Better: link each row to the stock transfer or purchase request flow (M).
- Full version: create a restock request from the console (L).

### G7 — "How busy are we, and when?"
The hourly chart buckets orders by UTC hour over a fixed 08:00–18:00 window. For
a branch east of UTC, most orders fall outside the window, so the chart is
empty, and the "Now" marker does not line up with the bars.

- Smallest real version: bucket by the branch clock and derive the window from
  the earliest and latest order of the day (S).

### G8 — "How many people came in?"
No footfall sensor exists. The panel is honest about it, but it occupies a third
of the side column to say so.

- Smallest real version: collapse it to one line, or remove the panel (S).
- Alternative: accept manual door counts (M).

### G9 — "I need the rest of the queue."
The table loads 8 orders. The tabs, the search, and the count in the footer all
operate on those 8 only, while the footer's total refers to all of today's
queue. A manager can search for an order that exists and be told there are no
matches.

- Smallest real version: remove the cap and paginate, or move filters to the
  server (M).
- Alternative: label the cap honestly and link to the orders list (S).

### G10 — "Is the data live?"
Three separate green claims — "Cloud Sync Active", "Store Open • Fully
Operational", "Live data synced from the regional cloud" — are static text. The
page has no auto-refresh; a manager sees stale data until they press Refresh.

- Smallest real version: remove the three claims (S).
- Better: show only "Refreshed at…" and add auto-refresh (M).

### G11 — "Something changed — tell me."
There is no realtime signal, no unread indicator, and no sound when a new order
or a click-and-collect handover arrives. The manager must keep pressing Refresh.

- Full version: subscribe to the orders channel and update the queue (M).

### G12 — "Who is this for, on mobile?"
The same console is mounted on tablet and phone. The two-column layout stacks,
but the target device is not stated anywhere in the page or the docs.

- Smallest real version: document the intended devices (S).

---

## 7. Decisions for the BA

**SM-D1 — What happens to the six dead tabs?**
- A. Remove them; one screen, one title. Cost: loses the visual story that the
  console will grow. Effort S.
- B. Turn them into scroll anchors to sections that already exist. Cost: three of
  the six have no section to scroll to. Effort S–M.
- C. Build the six sections. Cost: six new feature areas; the largest project on
  this page. Effort L.
- *Recommendation:* A now, C later only where a real operator asks for it.

**SM-D2 — Does the console get a date selector?**
- A. Today only, with a link to Analytics for history. Effort S.
- B. A date selector that re-scopes all numbers. Effort M.
- *Recommendation:* B — "how did yesterday go" is the most common manager
  question, and the payload is already day-scoped.

**SM-D3 — Is a shift report in scope for the first release?**
- A. Cut both report and float audit from the UI until they exist. Effort S.
- B. Ship a printable end-of-day summary of the current numbers. Effort M.
- C. Build a shift-close record with cash count and variance. Effort L.
- *Recommendation:* A for the first release, B immediately after; C only if a
  pilot customer asks for cash reconciliation.

**SM-D4 — Terminals: model them or drop the pretence?**
- A. Rename to "Cashier" and remove invented names/numbers. Effort S.
- B. Add a terminal record and appointment to branch. Effort L.
- *Recommendation:* A. Nothing in the product needs terminal identity yet.

**SM-D5 — Staff status: rename or derive from attendance?**
- A. Rename to "Branch staff". Effort S.
- B. Derive from scheduled shifts and attendance check-ins. Effort M.
- *Recommendation:* B once attendance is reliable; A until then.

**SM-D6 — Restock: rename, link, or build?**
- A. Rename the button "Show low stock". Effort S.
- B. Link each row to stock transfer / purchase. Effort M.
- C. Create a requisition here. Effort L.
- *Recommendation:* B — the flows exist; the console should route to them.

**SM-D7 — Hourly chart: fix the time base?**
- A. Bucket by branch clock and derive the window from the day's orders. Effort S.
- B. Remove the chart. Effort S.
- *Recommendation:* A. It is a real question with a cheap real answer.

**SM-D8 — Footfall: keep the honest gap?**
- A. Keep as-is. Effort S.
- B. Collapse to one line. Effort S.
- C. Add manual door counts. Effort M.
- *Recommendation:* B. Honest, but it should not cost a third of the column.

**SM-D9 — Queue cap: paginate or label?**
- A. Remove the cap, paginate and filter on the server. Effort M.
- B. Keep 8 rows, label the cap, link to the orders list. Effort S.
- *Recommendation:* A if the console is meant for busy stores; B otherwise.

**SM-D10 — Live claims: remove or wire?**
- A. Remove the three static status claims. Effort S.
- B. Replace with a real "refreshed at" and auto-refresh. Effort M.
- *Recommendation:* A now, B with the realtime work.

**SM-D11 — "Current Shift": remove or wire to the roster?**
- A. Remove the label; the header already shows the branch. Effort S.
- B. Derive it from today's scheduled shifts for the branch. Effort M.
- C. Keep a hardcoded three-shift label, corrected to match its own cut-offs.
  Effort S, but still not the company's real shifts.
- *Recommendation:* B. Scheduled shifts exist; presenting an invented one next to
  a roster that knows better undermines the page.

---

## 8. Safe demo path

Use this path when showing the console to a prospect. It touches only real data.

1. Open **Operations** and launch **Store Manager** for a branch with orders
   seeded today.
2. Show the five KPI cards and explain each one in business terms.
3. In the fulfilment queue, filter by **All Orders**, search a customer name,
   open the order.
4. Scroll to **Shelf Replenishment Requisitions** and open a stock row.
5. Show the **On-Duty Shift Roster** and open **Manage Shift Attendance**.

**Do not demo:**

- Any of the six header tabs other than **Store Overview**.
- **Daily Shift Report**, **Float Audit**, or **Diagnostics**.
- The **Footfall & Conversion** panel beyond saying "no sensor connected yet".
- The register names, the "Current Shift" label, or the hourly chart.
- The "Cloud Sync Active" and "Fully Operational" pills as if they were real.
- A fresh company with no orders today: every KPI reads zero and the queue is
  empty, which makes the console look broken rather than quiet.

---

## 9. Engineering appendix

**Route:** `GET /companies/:company_id/operations/store_manager/:operation_id`
(HTML shell + same-URL `.json`).

**Backend:** `Companies::Operations::StoreManagerController#show`, inheriting
`Companies::Operations::BaseController` — resolves the operation, the active
branch appointment, and the role gate before rendering.

**Payload builder:** `StoreManager::ConsoleService.call(company:, appointment:)`.

**Frontend:** `app/javascript/controllers/companies/operations/store_manager/show_controller.js`
(`Companies_Operations_StoreManager_ShowController`). Mobile mounts the same
controller.

**Constants:** `ORDER_LIMIT = 8`, `REPLENISHMENT_LIMIT = 8`, `STAFF_LIMIT = 8`,
`OPEN_HOUR = 8`, `CLOSE_HOUR = 18`, `LOW_STOCK_THRESHOLD = 10`.

**Source tables:** `orders`, `order_product_appointments`,
`order_service_appointments`, `order_product_group_appointments`,
`order_service_group_appointments`, `order_subscription_plan_appointments`,
`stocks`, `employees`, `branches`, `operations`.

**Known code-level issues behind §5:**

- `registers_payload` groups today's orders by employee and calls
  `register_name(index)` — names are positional, not stored.
- `hourly_payload` uses `order.created_at.hour` (UTC) against a branch-local
  `currentHour`; the server timezone is UTC and branch time is applied through
  `LocalTime`.
- `footfall_payload` returns `connected: false`; the panel renders em dashes.
- `currentShift` is computed in the frontend from `Helpers.locationNow(...).hour()`
  with thresholds at 12 and 17.
- No cache; every load recomputes. `orders_scope` caps the query at 200 rows.

**Proof:** `spec/features/companies/operations/store_manager_spec.rb`,
`spec/features/mobile/store_manager_spec.rb`,
`spec/requests/companies/operations/store_manager_spec.rb`,
`spec/services/store_manager/console_service_spec.rb`.

**Not covered by tests:** the six dead tabs, the hourly UTC bucketing, the
register naming, and the static status pills.
