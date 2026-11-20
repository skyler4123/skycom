# Inventory

> **Last audited:** 2026-11-20 · **Audit scope:** console service, write services,
> web + mobile Stimulus controller, feature/request/model specs.
> **Ship readiness:** 🟢 shippable — every number and control is backed by a
> record; the four warehouse loops (receive, transfer/export, adjust, count)
> finish inside the console.
> **Who this is for:** the warehouse manager or stock controller.
> **Mobile:** same console, mounted through the Hotwire shell.
> **Read first:** [README](README.md) · **Related:** [00-app-overview](00-app-overview.md),
> [06-store-manager](06-store-manager.md)

---

## 1. What this page is for

The Inventory console is the command screen for **one warehouse**: the true stock
ledger, the four KPI cards, open inbound/outbound records, the last cycle count,
and the drawers that finish the work.

A warehouse manager can:

1. See true on-hand, reserved, and available stock.
2. Receive goods and watch on hand rise.
3. Send goods out (transfer to another warehouse, or export out of the company)
   and watch the source drop.
4. Correct a quantity with a reason.
5. Turn a low row into a real purchase draft.
6. Run a cycle count and post the variance.
7. Leave with no number, label, or button that is not backed by a record.

Receiving, transferring, exporting, adjusting, reordering, and counting all
finish on this page. Purchasing after the draft, and approval/receipt of the
purchase, stay on the purchase screens.

**Out of this workflow (not built, not shown):** BOM and work orders, RFID,
dock doors/gates/bays, pallets, cartons, kilograms, zone percent-full, cloud
sync, fulfillment-node role, density, and the six sibling tabs.

---

## 2. Who uses it

**The person:** a warehouse manager, stock controller, or receiving supervisor.

**Their goal:** know what is on hand, what is short, what is arriving or leaving,
and finish the next stock job without navigating away.

**Access:** the Inventory operation must be active at the warehouse and the role
must be allowed by the operation. All write actions run behind the same
Operation-read gate (`Companies::Operations::InventoryPolicy`).

---

## 3. The screen, in words

**Header:** Skycom mark, company, warehouse name and code, the signed-in person
and role, and the platform dark-mode toggle. No cloud pill, no tabs.

**Context row:** `{Warehouse name} · {code} · Last refreshed {warehouse-local
time}`. Buttons: **Receive**, **Transfer out**, **Count** (or **Continue
count** while a session is open).

**KPI strip — four cards, all from this warehouse**

| Card | Shows | Never shows |
|---|---|---|
| Stock rows | Count of stock rows, and total units on hand | “SKUs”, zones, utilization % |
| Needs attention | Rows at or below their reorder point, and how many are at zero available | A decorative progress bar |
| Inbound open | Imports not yet completed, plus units still to receive | Gates, pallets, RFID % |
| Outbound open | Transfers and exports not yet completed, plus units | Cartons, kg, bay numbers |

**Left — Stock ledger.** Title `Stock`, subtitle `On hand, reserved, and
available for {warehouse}`. Search (name, code, location), filters
**All · Low · Out · In stock** with full counts, **Export**, **Refresh**.
Columns: Item · Location · On hand · Reserved · Available · Reorder at · Status ·
Action. Status is only `In stock`, `Low`, or `Out`. Row actions: **Adjust**, and
**Reorder** only when Low or Out (or **Open purchase {code}** when one is already
open). Footer: `Showing {from}–{to} of {total}` with **Previous** / **Next**.

The location is the stock location text, or `No location`. The warehouse name is
never used as a fake bin.

**Right — three stacks**

1. **Inbound** — open imports and incoming transfers, newest first. Each card:
   reference, supplier (or `No supplier`) / source warehouse, date, units, status
   (`Draft` / `Receiving` / `In transit` / `Received`). Open imports can be
   resumed; incoming transfers have **Mark received**. A short `Received` list
   keeps the last five completed records. Empty: `Nothing waiting to receive.`
2. **Outbound** — open transfers and exports. Each card: reference, destination
   or reference note, units, kind (`Transfer` / `Export`), status. Empty:
   `Nothing waiting to leave.` A short `Completed` list keeps the last five.
3. **Last count** — date, who counted, rows counted, net variance, failed-line
   count, and **Start count** / **Continue count**. Before any count:
   `No count recorded · {N} rows in this warehouse.` and **Start count**
   (disabled with a reason when there are no rows). While a session is open:
   `Count in progress · {n} of {m} entered`.

No BOM analyzer, zone map, donut, or Re-optimize.

**Drawers / sheet**

- **Receive** — supplier (optional), item search, quantity, location (optional),
  note. Primary **Post receipt**. Posting creates a `StockImport` and an `add`
  ledger row; on hand rises. An existing open import resumes the same drawer.
- **Transfer out** — two modes. *Another warehouse*: item, quantity, destination
  (required), note; primary **Transfer**. *Leaving the company*: item, quantity,
  reference (required), note; primary **Export**. The transfer uses the domain’s
  two-phase flow: source available drops immediately (hold); the destination
  marks it received and only then does destination on hand rise.
- **Adjust** — item and current on hand read-only, reserved shown, new on hand
  required, reason required (`Count correction`, `Damage`, `Found`, `Other`),
  note. Primary **Post adjustment**. On hand becomes the new number; reserved is
  untouched; a value below reserved is blocked with
  `On hand cannot be less than the {n} reserved.`
- **Reorder** — short-by amount, supplier (product default or picker), quantity
  defaulting to the shortfall. Primary **Create purchase**. Creates a real
  `Purchase` + `PurchaseItem` line (`business_type: stock_reorder`) and reuses
  the open purchase on a second press.
- **Count sheet** — full-screen. Item, location, expected on hand, counted input,
  live variance. Filter to Low or one location. **Save progress**, **Submit
  count**, Close. Saving survives refresh. Submit posts one adjustment per line
  whose counted number differs from the current on hand, reason `Count`; rows
  below reserved are skipped with a named error and the rest post. A zero-variance
  submit still records a count. One open count per warehouse.

After a write, the drawer closes, the KPI strip, side stack, and current ledger
page/filter reload, and one server message states what changed.

**States**

- *No stock rows:* `No stock rows match this view.`
- *Exact code not found:* `Code not found: {q}` (single-token query).
- *No inbound:* `Nothing waiting to receive.`
- *No outbound:* `Nothing waiting to leave.`
- *No count:* `No count recorded · {N} rows in this warehouse.`
- *Load failure:* a full-screen red “Failed to load the inventory console.” with
  the server detail.
- *Responsive:* main and side stack below `lg`; the table scrolls inside its card.

---

## 4. Control inventory

38 interactive controls.

| ID | Area | Control | What it does | Status |
|---|---|---|---|---|
| INV-01 | Header | Skycom logo | Returns to the Operations list | ✅ |
| INV-02 | Header | Dark-mode toggle | Switches theme | ✅ |
| INV-03 | Context | Receive | Opens the Receive drawer | ✅ |
| INV-04 | Context | Transfer out | Opens the Transfer/Export drawer | ✅ |
| INV-05 | Context | Count | Starts a session or continues the open one | ✅ |
| INV-06 | Ledger | Export | Downloads the current search + filter as CSV | ✅ |
| INV-07 | Ledger | Refresh | Reloads the console from the server | ✅ |
| INV-08 | Ledger | Search | Server-side name/code/location search (Meilisearch, exact code via DB) | ✅ |
| INV-09–12 | Ledger | All / Low / Out / In stock | Server-side filters with full counts | ✅ |
| INV-13–14 | Ledger | Previous / Next | 50-row pages | ✅ |
| INV-15 | Row | Adjust | Opens the Adjust drawer | ✅ |
| INV-16 | Row | Reorder | Opens the Reorder drawer on Low/Out rows | ✅ |
| INV-17 | Row | Open purchase | Navigates to the existing open purchase | ✅ |
| INV-18 | Inbound | Open | Resumes an open import in the Receive drawer | ✅ |
| INV-19 | Inbound | Mark received | Receives an incoming transfer at this warehouse | ✅ |
| INV-20 | Last count | Start count | Creates a cycle count session | ✅ |
| INV-21 | Last count | Continue count | Loads the open session | ✅ |
| INV-22 | Receive | Item search | Scoped server-side stock search | ✅ |
| INV-23 | Receive | Quantity | Required whole number > 0 | ✅ |
| INV-24 | Receive | Supplier | Optional company supplier | ✅ |
| INV-25 | Receive | Location | Optional put-away location; saves on the stock row | ✅ |
| INV-26 | Receive | Note | Optional receipt note | ✅ |
| INV-27 | Receive | Post / Cancel | Posts the receipt or closes with no write | ✅ |
| INV-28 | Transfer | Mode switch | Another warehouse / Leaving the company | ✅ |
| INV-29 | Transfer | Destination | Required other warehouse (transfer mode) | ✅ |
| INV-30 | Transfer | Reference | Required reference note (export mode) | ✅ |
| INV-31 | Transfer | Primary / Cancel | Transfers, exports, or closes with no write | ✅ |
| INV-32 | Adjust | New on hand + reason + note | Required target and reason | ✅ |
| INV-33 | Adjust | Post / Cancel | Posts the adjustment or closes | ✅ |
| INV-34 | Reorder | Supplier + quantity | Default supplier or picker; editable quantity | ✅ |
| INV-35 | Reorder | Create purchase / Cancel | Creates/reuses the purchase or closes | ✅ |
| INV-36 | Count sheet | Low / location filters | Filters the loaded count lines | ✅ |
| INV-37 | Count sheet | Save progress | Persists counted values and variance | ✅ |
| INV-38 | Count sheet | Submit count / Close | Posts variances or closes (session stays open) | ✅ |

**Count by status:** ✅ 38 · 🟡 0 · 🗑️ 0 · ⛔ 0.

---

## 5. Numbers on screen

| Claim on screen | Source |
|---|---|
| Stock rows | `stocks` rows for the warehouse, not discarded |
| Units on hand | `SUM(stocks.quantity)` for the warehouse |
| Needs attention | Rows where `quantity - pending <= reorder point` |
| At zero available | Rows where `quantity - pending <= 0` |
| Inbound open / units | `stock_imports` with workflow status not received/completed/cancelled/failed; units from `quantity` or line sum |
| Outbound open / units | same for source `stock_transfers` (draft/pending/initiated) and `stock_exports` (draft/pending/confirmed/in_progress) |
| On hand | `stocks.quantity` |
| Reserved | `stocks.pending` |
| Available | `stocks.quantity - stocks.pending`, clamped at 0 on screen |
| Reorder at | `reorder_rules.min_quantity + safety_stock` when an active rule exists; otherwise `LOW_STOCK_THRESHOLD` (10) |
| Status | Out when available ≤ 0; Low when available ≤ reorder point; otherwise In stock |
| Tab counts | full warehouse counts from the same threshold expression as the rows |
| Showing from–to of total | server pagination (`count`, `from`, `to`) |
| Inbound/outbound card units | document `quantity` or its line sum |
| Last count rows/variance | `stock_count_lines` counted rows and summed stored variance |
| Last refreshed | server `generated_at`, rendered in the warehouse timezone |
| Document codes | the persisted `StockImport` / `StockExport` / `StockTransfer` / `StockCount` / `Purchase` records |
| `Purchase {code} drafted` / `Open purchase {code}` | the open `Purchase` for this product + warehouse |

No fabricated number remains. A zero is a true count; a missing count is `nil` +
an empty state.

---

## 6. Gaps closed (from the previous audit)

| Previous gap | Resolution |
|---|---|
| G1 BOM panel / hardcoded zeros | Removed; no BOM domain, no KPI, no panel |
| G2 Invented zones / 84% fallback | Removed; no zone or utilization payload |
| G3 Gate/bay numbers from record IDs | Removed; cards carry reference, party, date, units, status |
| G4 Export quantity shown as kg | Removed; units only |
| G5 Pallets/cartons from division | Removed |
| G6 RFID labels and fake scan progress | Removed; search is the only finder |
| G7 Writes only navigate away | Receive/transfer/export/adjust/reorder/count finish in the console |
| G8 200-row cap / local search | Server search + 50-row pages + full counts |
| G9 Global 10 threshold unlabeled | Labeled footnote; per-item `ReorderRule` overrides |
| G10 Warehouse name used as bin | Location is the stock location text or `No location` |
| G11 Schedule Count opened the stock list | Real `StockCount` session with save/submit/variance |
| G12 Export ignored the filter | CSV of the current search + filter |
| Audit card was decorative | `Last count` with real completed/open session data |
| No purchase from reorder | `ReorderService` creates/reuses a real purchase draft |

---

## 7. Decisions implemented

- **BOM:** removed (the grocery workflow does not build).
- **Zones/utilization:** removed; no capacity model exists.
- **Docks:** removed; shipment status is the useful part.
- **Packaging/weight:** removed; wrong units are worse than absent ones.
- **Receive:** in-console drawer backed by `StockImport`.
- **Ledger:** server pagination + Meilisearch; exact code lookup stays in the DB.
- **Reorder point:** per-product/warehouse `ReorderRule`, company default 10.
- **Cycle counts:** built on `StockCount`/`StockCountLine`, warehouse-locked to one
  open session, adjustments through `StockAdjustment`.
- **Tabs:** removed from Inventory. Store Manager cleanup remains separate.
- **Static operational claims:** removed (`Cloud Sync`, `Sync: Real-time`,
  `Primary Fulfillment Node`, `Cycle verified`).

---

## 8. Safe demo path / proof

Run this on Grocery VN / Branch 1 Warehouse and stop if any step leaves the
console or shows a number you cannot point at in the database.

1. Open the page. Four KPIs. No BOM, percent-full, gate, or `coming soon`.
2. Search a known SKU past the first page. It appears with on hand, reserved,
   available.
3. Receive 10 of it. On hand is +10. Inbound shows the receipt as Received.
4. Transfer 4 to another warehouse. Source available is −4 and the outbound card
   says In transit. On the destination console, Mark received; source on hand is
   −4 and destination is +4.
5. Adjust one damaged unit with reason Damage. On hand is −1. Reason is stored.
6. Set a row to Out/ Low, press Reorder, create the purchase. A draft exists.
   Pressing the action again opens that purchase instead of creating another.
7. Start a count, change one quantity, submit. Last count shows the counter’s
   name and the variance. The ledger matches.
8. Export Low. The file matches the Low filter only.

The same proof is encoded in `spec/features/companies/operations/inventory_spec.rb`,
the service specs under `spec/services/inventory/`, and the request spec
`spec/requests/companies/operations/inventory_spec.rb`.

---

## 9. Engineering appendix

**Routes**

```
GET    /companies/:company_id/operations/inventory/:operation_id
GET    /companies/:company_id/operations/inventory/:operation_id/ledger
GET    /companies/:company_id/operations/inventory/:operation_id/export
POST   /companies/:company_id/operations/inventory/:operation_id/receipts
POST   /companies/:company_id/operations/inventory/:operation_id/receipts/:receipt_id/post
POST   /companies/:company_id/operations/inventory/:operation_id/transfers
POST   /companies/:company_id/operations/inventory/:operation_id/transfers/:transfer_id/receive
POST   /companies/:company_id/operations/inventory/:operation_id/exports
POST   /companies/:company_id/operations/inventory/:operation_id/adjustments
POST   /companies/:company_id/operations/inventory/:operation_id/reorder
POST   /companies/:company_id/operations/inventory/:operation_id/counts
GET    /companies/:company_id/operations/inventory/:operation_id/counts/:count_id
PATCH  /companies/:company_id/operations/inventory/:operation_id/counts/:count_id
POST   /companies/:company_id/operations/inventory/:operation_id/counts/:count_id/submit
```

**Backend:** `Companies::Operations::InventoryController` (thin shell),
`Inventory::ConsoleService`, `Inventory::LedgerQueryService`,
`Inventory::LedgerCsvService`, `Inventory::ReceiveService`,
`Inventory::TransferService`, `Inventory::ExportService`,
`Inventory::AdjustmentService`, `Inventory::ReorderService`,
`Inventory::CountService`.

**Frontend:** `app/javascript/controllers/companies/operations/inventory/show_controller.js`
(`Companies_Operations_Inventory_ShowController`), shared by web and the mobile
Hotwire shell.

**Payload:** `{ location, currency, generated_at, metrics, stocks, pagination,
counts, search_capped, reorder_default, reorder_rules_present, adjustment_reasons,
inbound, outbound, open_count, last_count, reference }`.

**Source tables:** `stocks`, `reorder_rules`, `stock_imports`, `stock_exports`,
`stock_transfers`, `stock_adjustments`, `stock_transactions`, `stock_counts`,
`stock_count_lines`, `purchases`, `purchase_items`, `purchase_purchase_item_appointments`,
`suppliers`, `warehouses`.

**Known limits:** text search is capped at 1,000 Meilisearch IDs per query (the
payload and UI flag it); the count sheet loads every stock row for the warehouse;
one open count per warehouse is enforced by a warehouse row lock plus a model
validation; an abandoned open count is completed with a zero-variance submit.

**Proof:**
`spec/features/companies/operations/inventory_spec.rb`,
`spec/features/mobile/inventory_spec.rb`,
`spec/services/inventory/console_service_spec.rb`,
`spec/services/inventory/ledger_query_service_spec.rb`,
`spec/services/inventory/write_services_spec.rb`,
`spec/models/stock_count_spec.rb`,
`spec/models/stock_count_line_spec.rb`,
`spec/requests/companies/operations/inventory_spec.rb`,
`spec/requests/mobile/inventory_controller_spec.rb`.
