# Store Manager

> **Last audited:** 2026-11-21 · **Audit scope:** frontend controller, console
> and write services, backend controller, feature, service, model and request
> specs, including headless browser feature runs.
> **Ship readiness:** 🟢 shippable — no fabricated status, no dead tab, no
> toast-only workflow.
> **Who this is for:** the store manager or shift lead on duty at one branch.
> **Mobile:** same console, mounted through the Hotwire shell.
> **Read first:** [README](README.md) · **Related:** [00-app-overview](00-app-overview.md),
> [05-inventory](05-inventory.md), [02-pos](02-pos.md)

---

## 1. What this page is for

The Store Manager console is the branch-level command screen for one retail day.
A manager opens it to answer four questions at a glance: how much have we sold,
what still has to be handed to a customer, what is nearly empty on the shelf, and
who is working. It is also where the manager closes the shift.

"Done" means one of three endings:

1. **Handover** — an order leaves the open queue, or remains with a real
   fulfilment state.
2. **Shelf** — a low row has a transfer or purchase document, and pressing the
   action again opens that same document.
3. **Shift** — expected cash, counted cash, variance and a note are stored, and
   the printed report matches those figures.

Payment, void and warehouse counting stay on POS and Inventory. This page does
not copy them.

---

## 2. Who uses it

**The person:** a store manager, shift lead, or duty supervisor responsible for
one branch during one shift. They are on their feet, often on a tablet, and they
check this screen between serving customers.

**Their goal:** a fast, trustworthy picture of the branch day, and a short path
to the one thing that needs attention.

**What they can do here:**

- Read today's or a past day's sales, fulfilment, shelf-stock and staffing
  numbers.
- Search the whole day's fulfilment queue by order code, customer, channel or
  status; page through it 50 rows at a time.
- Mark a fulfilment order ready and hand it over.
- Start a real stock transfer or purchase draft from a low shelf row and reopen
  that document.
- See who is actually checked in on a scheduled shift.
- Close the shift with a cash count, variance, note and printable report.
- Refresh on demand; the page also refreshes every 60 seconds while no sheet is
  open.

**What they must do elsewhere:**

- Take a payment, void a sale, or open the cash drawer — POS operation.
- Edit order lines or cancel an order — the order page / POS.
- Receive a transfer, count stock, or adjust stock — Inventory.

**Access:** the Store Manager operation must be active at the branch, and the
employee's role must be allowed by the operation's role configuration.

---

## 3. The screen, in words

**Top bar:** the Skycom mark (links back to the Operations list), the company
name, the branch name and code, a dark-mode toggle, and the signed-in user's name
and role. No cloud-sync pill.

**Page heading:** **Store overview**, with the branch and selected date.

**Context row:** branch name, real shift chip (for example
`Morning · 08:00–17:00 · 6 checked in`, or `No shift scheduled`), a date control
(default today, past dates read-only), and the day actions: New Store Order,
Show low stock, Stock Adjustment, Close shift. On a past date with a saved close,
the only action is View close report.

**KPI strip (five cards):** Gross sales, Cashiers, To hand over, Shelf alerts,
On duty. Every card number equals the list it summarises.

**Main column:** the fulfilment queue (tabs, search, barcode-focus button, table,
pagination), then Shelf replenishment (SKU, shelf stock, min, warehouse
available, stage, floor action).

**Side column:** Cashiers (person, role, sales, orders), Hourly orders on the
branch clock, On-duty roster with a real checked-in status, and one footfall line
(`No door sensor · 4 buyers`).

**Footer:** `Refreshed 5:52 AM` (or `Update failed` with the last successful
time) and the operation code. Nothing else.

**Sheets**

- **Close shift** is an in-page sheet: sales by tender, order count, discounts,
  tax, opening float, expected cash, counted cash, computed variance, still to
  hand over (with the open order codes listed), shelf rows short, checked-in
  staff, note, Save and close, Print.
- **Replenishment** is an in-page sheet: quantity, source warehouse for a
  transfer or supplier for a purchase, explicit Confirm.

**States**

- *Loading:* the page is blank until the JSON payload returns.
- *Load error:* a full-screen red message with the server's error text.
- *Refresh error:* current numbers stay; footer says `Update failed`.
- *Empty orders:* `No orders are waiting for handover.`
- *Empty completed:* `No orders have been handed over for this date.`
- *Empty search:* `No orders match this search.`
- *Empty shelves:* `No shelf stock is below the minimum threshold.`
- *Missing past snapshot:* `No shelf snapshot was saved for this date.`
- *Empty cashiers:* `No paid orders yet for this date.`
- *Empty roster:* `No one is checked in right now.` / `No one was checked in on this date.`
- *Responsive:* two columns on desktop become one on phones and tablets; wide
  tables scroll inside their card.

---

## 4. Control inventory

35 interactive controls. Row actions are counted once per action type.

| ID | Area | Control | What it does | Status |
|---|---|---|---|---|
| SM-01 | Top bar | Skycom logo | Returns to the Operations list | ✅ |
| SM-02 | Top bar | Dark-mode toggle | Switches theme | ✅ |
| SM-03 | Context | Date control | Re-scopes the page; past dates read-only | ✅ |
| SM-04 | Context | New Store Order | Opens the new-order screen | ✅ |
| SM-05 | Context | Show low stock | Scrolls to the shelf table | ✅ |
| SM-06 | Context | Stock Adjustment | Opens the stock-adjustment list | ✅ |
| SM-07 | Context | Close shift | Opens the close sheet (today only) | ✅ |
| SM-08 | Context | View close report | Opens a saved past close read-only | ✅ |
| SM-09 | Queue | Refresh now | Reloads the console; skipped while a sheet is open | ✅ |
| SM-10 | Queue | Open orders | Opens the orders list | ✅ |
| SM-11 | Queue | All Orders tab | Server filter: open orders | ✅ |
| SM-12 | Queue | Click & Collect tab | Server filter: open click-and-collect orders | ✅ |
| SM-13 | Queue | Local Delivery tab | Server filter: open delivery orders | ✅ |
| SM-14 | Queue | Completed tab | Server filter: handed over on that day | ✅ |
| SM-15 | Queue | Search | Matches code, customer, channel, status on the full day set | ✅ |
| SM-16 | Queue | Barcode-focus button | Focuses search; placeholder says `Scan or type a code` | ✅ |
| SM-17 | Queue | View order | Opens the order detail page | ✅ |
| SM-18 | Queue | Mark ready | Stores fulfilment status `ready` | ✅ |
| SM-19 | Queue | Hand over | Stores `handed_over` + timestamp; requires payment | ✅ |
| SM-20 | Queue | Previous page | Previous 50-row page | ✅ |
| SM-21 | Queue | Next page | Next 50-row page | ✅ |
| SM-22 | Shelf | Floor action | Request transfer, Create purchase, or open the existing document | ✅ |
| SM-23 | Shelf | Open stock ledger | Opens the stock list | ✅ |
| SM-24 | Roster | Manage shift attendance | Opens the attendance months list | ✅ |
| SM-25 | Close sheet | Close | Closes the sheet without saving | ✅ |
| SM-26 | Close sheet | Opening float | Stores the float used by expected cash | ✅ |
| SM-27 | Close sheet | Counted cash | Stores the manager's count | ✅ |
| SM-28 | Close sheet | Note | Stores the variance explanation | ✅ |
| SM-29 | Close sheet | Print | Prints only the close sheet | ✅ |
| SM-30 | Close sheet | Save and close | Upserts the stored close | ✅ |
| SM-31 | Replenishment sheet | Close | Closes the sheet without writing | ✅ |
| SM-32 | Replenishment sheet | Quantity | Defaults to the shortfall / source availability | ✅ |
| SM-33 | Replenishment sheet | Supplier | Purchase only; defaults to the product supplier | ✅ |
| SM-34 | Replenishment sheet | Cancel | Closes the sheet without writing | ✅ |
| SM-35 | Replenishment sheet | Confirm | Creates or reuses one document | ✅ |

Removed controls: the six dead tabs, Cloud Sync Active, Store Open • Fully
Operational, Live data synced from the regional cloud, Diagnostics, Float Audit,
Daily Shift Report, named registers and “Synced” chips.

---

## 5. Numbers on screen

| Claim on screen | Where it comes from | Verdict |
|---|---|---|
| Gross sales | Sum of paid invoice totals for the branch's calendar day (tax and order-level adjustments included) | ✅ |
| +N% vs yesterday | Same invoice formula for the previous day; blank when yesterday had no sales | ✅ |
| Cashiers | Distinct employees credited with at least one paid order today | ✅ |
| N paid orders | Distinct orders with a paid invoice today; equals the sum of cashier order counts plus any uncredited note | ✅ |
| To hand over | Fulfilment orders not handed over by the end of the selected day | ✅ |
| Click & Collect / Local Delivery / Phone Hold | Stored `orders.fulfillment_channel`, never inferred from `business_type` | ✅ |
| Shelf alerts | Branch stock rows at or below the product/warehouse reorder point | ✅ |
| Min | `ReorderRule.min_quantity + safety_stock`, or 10 with `Default minimum: 10` | ✅ |
| Warehouse available | Available units for the same product in other warehouses | ✅ |
| Stage | The open transfer or purchase document code; otherwise `Not requested` | ✅ |
| On duty | Employees checked in on a scheduled shift covering now, excluding approved leave | ✅ |
| Current shift | Real scheduled shift name and hours; `No shift scheduled` when none covers now | ✅ |
| Hourly orders | Orders bucketed on the branch clock; window is the day's first–last order; peak uses that series | ✅ |
| N buyers | Distinct customers with a paid order on the day | ✅ |
| Refreshed at | Server timestamp of the last successful payload | ✅ |
| Expected cash | Opening float + cash received − change given | ✅ |
| Counted cash | Typed by the manager and stored | ✅ |
| Variance | Counted cash − expected cash; computed, not typed | ✅ |
| Still to hand over / shelf rows short | Counts stored on the close at save time | ✅ |
| No door sensor | Honest gap; the buyer count is real | 💤 |

---

## 6. Gaps by user job

No open gaps for the three endings. Honest limitations:

- **No door sensor.** The page says so; it does not invent visitors or
  conversion.
- **No shift-open flow.** The opening float is captured in the close sheet and
  defaults to 0.
- **Historical shelf requires a saved close.** Without a close, the page says no
  snapshot was saved rather than showing today's stock as if it were history.
- **Multi-currency sale aggregation** uses the company currency; currency
  conversion is not applied here.
- **No realtime push.** The page polls every 60 seconds.
- **No terminal identity.** Cashier cards name people, not hardware.

---

## 7. Decisions for the BA

All decisions from the 2026-11-19 audit are resolved:

| Decision | Resolution |
|---|---|
| SM-D1 dead tabs | Removed; one page, title **Store overview**. |
| SM-D2 date selector | Added; past dates are read-only. |
| SM-D3 shift report | Built as a stored shift close with print. |
| SM-D4 terminals | No terminal model; cashier cards name people. |
| SM-D5 staff status | Derived from scheduled shifts + attendance. |
| SM-D6 restock | Creates a real transfer or purchase and reopens it. |
| SM-D7 hourly chart | Branch clock; first–last order window. |
| SM-D8 footfall | Collapsed to one honest line. |
| SM-D9 queue cap | Removed; server-filtered 50-row pages. |
| SM-D10 live claims | Removed; last-refreshed time + quiet polling. |
| SM-D11 current shift | Derived from real scheduled shifts. |

---

## 8. Safe demo path

1. Open **Operations** and launch **Store Manager** for a branch with paid orders
   today (cash and QR), a scheduled shift covering now, and at least one low
   stock row.
2. Show the five KPI cards and point at the invoice behind Gross sales and the
   cashier card behind Cashiers.
3. In the fulfilment queue, page to a later order, search its code, mark it
   ready, then hand it over. Show the count drop and the Completed tab.
4. Scroll to **Shelf replenishment**, request a transfer or create a purchase,
   and show the stage code; press the stage link to open the same document.
5. Show the real shift chip, the On-duty roster, and **Manage shift
   attendance**.
6. Click **Close shift**, enter float and counted cash, show the variance, save,
   print, reload and show the same variance.
7. Switch the date to yesterday and show the saved close read-only.

**Do not demo:** a door sensor, named POS hardware, cloud-sync status, BOM, dock
doors, or a payment button on this page.

---

## 9. Engineering appendix

**Route:** `GET /companies/:company_id/operations/store_manager/:operation_id`
(HTML shell + same-URL `.json`).

**Additional endpoints:**

- `GET  …/queue`
- `POST …/orders/:order_id/mark_ready`
- `POST …/orders/:order_id/hand_over`
- `POST …/replenishments`
- `POST …/shift_close`

**Backend:** `Companies::Operations::StoreManagerController#show`, inheriting
`Companies::Operations::BaseController` — resolves the operation, the active
branch appointment, and the role gate before rendering.

**Services:**

- `StoreManager::ConsoleService` — payload orchestrator.
- `StoreManager::SalesSummaryService` — invoice totals, tender split, cashier
  grouping.
- `StoreManager::QueueQueryService` — whole-day queue, search, pagination,
  open/completed state.
- `StoreManager::ShelfQueryService` — low stock, reorder points, open documents,
  past snapshot.
- `StoreManager::DutyRosterService` — real shift chip and checked-in roster.
- `StoreManager::OrderFulfillmentService` — mark ready / hand over.
- `StoreManager::ReplenishmentService` — transfer or purchase, reused.
- `StoreManager::ShiftCloseService` — build/save the close and snapshots.

**Frontend:** `app/javascript/controllers/companies/operations/store_manager/show_controller.js`
(`Companies_Operations_StoreManager_ShowController`). Mobile mounts the same
controller.

**Data:**

- Orders gain `fulfillment_channel`, `fulfillment_status`, `handed_over_at`, and
  a real `code` assigned on create.
- `shift_closes` stores one close per branch/business date with the report
  figures, staff names and shelf snapshot.
- Reorder points use `Stock.reorder_point_expression` shared with Inventory.

**Constants:** `LOW_STOCK_THRESHOLD` (default 10), `QueueQueryService::PAGE_SIZE`
(50), `SEARCH_MAX_IDS` (1,000), 60-second client refresh.

**Proof:** `spec/features/companies/operations/store_manager_spec.rb`,
`spec/features/mobile/store_manager_spec.rb`,
`spec/requests/companies/operations/store_manager_spec.rb`,
`spec/services/store_manager/*`, `spec/models/order_spec.rb`,
`spec/models/shift_close_spec.rb`.
