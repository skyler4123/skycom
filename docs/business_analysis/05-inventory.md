# Inventory

> **Last audited:** 2026-11-20 · **Audit scope:** frontend controller, console
> service, ledger scope, CSV export, stock-row screen, feature/request/service
> specs. No live browser run.
> **Ship readiness:** 🟠 **shippable with gaps** — no fabricated figures and no
> dead controls remain. The only visible gap is the cycle-count card (`💤`),
> which states plainly that counts are not available.
> **Who this is for:** the warehouse manager or stock controller.
> **Mobile:** the same console, mounted through the Hotwire shell.
> **Read first:** [README](README.md) · **Related:** [00-app-overview](00-app-overview.md),
> [06-store-manager](06-store-manager.md)

---

## 1. What this page is for

The Inventory console answers three questions for **one warehouse**:

1. What is on hand right now?
2. What is short?
3. What arrived or left recently?

It is read-only by design. Receiving, transfers, and adjustments happen on the
stock screens; this console tells the operator which one to open and which row
to look at.

"Done" means every figure comes from a `stocks`, `stock_imports`, or
`stock_exports` record, and every control either does what its label says or is
not on the page.

---

## 2. Who uses it

**The person:** a warehouse manager, stock controller, or receiving supervisor.

**Their goal:** spot what needs attention (low or out), check a specific row,
and see the last receipts and dispatches without leaving the console.

**What they can do here today:**

- Read the four KPIs: stock rows, low or out, recent inbound units, recent
  outbound units.
- Search the warehouse by product name, code, or location text.
- Switch between four disjoint views: All, Low, Out, In stock.
- Export the current view (tab + search) as CSV.
- Open a stock row to see its quantities, location, price, and recent movements.
- Open the receiving form, the transfer form, or the full stock list.
- Refresh the payload; the `Updated` line shows the new server time.

**What they must do elsewhere:**

- Receive, transfer, or adjust stock — the stock screens.
- Create a purchase order — the purchase screens.
- Run or schedule a cycle count — nothing exists.
- See per-product reorder points, bins, batch/lot, or expiry — not wired.

**Access:** the Inventory operation must be active at the warehouse and the
role must be allowed by the operation (read access to `Operation`).

---

## 3. The screen, in words

**Header:** Skycom mark, title `Inventory`, warehouse name and code, branch,
company, the signed-in person, dark mode, and a line `Updated {time}` with a
refresh control. The time is the server clock rendered in the warehouse's
timezone. There are no tabs and no integration chrome.

**Actions:** three links — `Open receiving`, `Open transfer`, `Open stock list`.
The console itself saves nothing.

**KPI row (four cards, no progress bars):**

| Card | Shows |
|---|---|
| Stock rows | How many stock rows this warehouse has |
| Low or out | How many rows are at or under the minimum, with `N out` underneath |
| Recent inbound | How many recent receipts, and the sum of their quantities in **units** |
| Recent outbound | How many recent dispatches, and the sum of their quantities in **units** |

"Recent" means the four newest records for this warehouse — the same records the
side lists show, not "today" and not "docked".

**Main column — Stock ledger.** Subtitle states the rule:
"On hand, reserved, and available in {warehouse}. A row is low when available is
10 or less. That minimum is the same for every product."

- Search: `Search name, code, or location` — covers the whole warehouse.
- Tabs: `All`, `Low`, `Out`, `In stock`, each with a count. The three buckets are
  disjoint and add up to All.
- Columns: Product (name, code, price in the company currency), Location,
  On hand, Reserved, Available, Minimum, Status, and one action `Open`.
- Location is the text stored on the row (the first text property slot), or `—`
  when blank — never the warehouse name.
- Minimum is `10` on every row; the page never implies a per-product reorder
  point.
- Footer: `Showing X of Y`. When more rows match than the 200-row cap, the
  footer says `This list is capped.` and links to `Open stock list`.

**Side column:**

- **Recent inbound** — one record per receipt: code, workflow status in words,
  quantity in units, date. Empty: `No recent receipts.`
- **Recent outbound** — same shape for dispatches. Empty: `No recent dispatches.`
- **Cycle counts** — text only: `Cycle counts are not available yet.` and
  `{N} stock rows are in this warehouse. Skycom does not record a count or a
  variance.` No buttons, no links.

Nothing on the page says real-time, live, or RFID. Refresh is explicit.

**States**

- *No stock rows:* "No stock rows match this view."
- *No receipts / dispatches:* the two empty sentences above.
- *Capped list:* the footer note plus the stock-list link.
- *Cycle counts:* the honest two-sentence note with the real row count.
- *Load failure:* a full-screen red "Failed to load the inventory console."
- *Search failure:* an error toast; the last rows stay on screen (never silently
  unfiltered results).
- *Responsive:* the ledger stacks above the side column in portrait; tables
  scroll inside their card.

**Stock-row screen** (`/companies/:company_id/stocks/:id`): product name, code,
status, on hand, reserved, available, minimum, price, location, warehouse,
branch, and that row's recent ledger entries (date, type, quantity, document
code), with links to the stock list, receiving, and transfer.

---

## 4. Control inventory

14 interactive controls. Every one works end to end.

| ID | Area | Control | What it does today | Status | If shipped as-is |
|---|---|---|---|---|---|
| INV-01 | Header | Skycom mark | Returns to the Operations list | ✅ | — |
| INV-02 | Header | Refresh | Reloads the payload and rewrites `Updated {time}` | ✅ | — |
| INV-03 | Header | Dark-mode toggle | Switches theme | ✅ | — |
| INV-04 | Actions | Open receiving | Opens the stock-import form | ✅ | Leaves the console |
| INV-05 | Actions | Open transfer | Opens the stock-transfer form | ✅ | Leaves the console |
| INV-06 | Actions | Open stock list | Opens the full stock list | ✅ | — |
| INV-07 | Ledger | Export CSV | Downloads the current tab + search as CSV | ✅ | Attachment filename carries the warehouse code |
| INV-08 | Ledger | Search | Filters the warehouse by name, code, or location | ✅ | Server-side (Meilisearch), not the loaded page |
| INV-09 | Ledger | All tab | Shows every matching row (capped at 200) | ✅ | Count is a warehouse total |
| INV-10 | Ledger | Low tab | Rows with available 1–10 | ✅ | Disjoint from Out |
| INV-11 | Ledger | Out tab | Rows with available 0 or less | ✅ | Disjoint from Low |
| INV-12 | Ledger | In stock tab | Rows with available more than 10 | ✅ | — |
| INV-13 | Row | Open | Opens that stock row | ✅ | Read-only screen |
| INV-14 | Footer | Open stock list | Shown only when the list is capped; opens the stock list | ✅ | — |

**Count by status:** ✅ 14 · 🟡 0 · 🗑️ 0 · 💤 1 (cycle-count block, no control) · ⛔ 0.

**Removed in this pass (were 🗑️/🔢):** the six dead tabs, BOM KPI and analyzer,
Auto-Generate Bulk POs, zone capacity map, utilization donut, Re-optimize, dock
cards, gate/bay labels, pallets, cartons, kilograms, dock progress bars, Scan
RFID, RFID Live Mode, QC RFID Gate Scan, Audit Cycle Count, View Full Audit Log,
Schedule Count, Density, `Cloud Sync Active`, `Sync: Real-time`, `Primary
Fulfillment Node`, `Stock Row Utilization`, `Freight Gates`, and the static
`Cycle verified against…` footer.

---

## 5. Numbers on screen

| Claim on screen | What it appears to mean | Where it actually comes from | Verdict |
|---|---|---|---|
| Stock rows | Rows tracked in this warehouse | Count of `stocks` for the warehouse (`discarded_at` nil) | ✅ |
| Low or out | Rows at or under the minimum | `stocks` where `quantity - pending <= 10` | ✅ |
| `N out` | Rows with nothing available | `stocks` where `quantity - pending <= 0` | ✅ |
| Recent inbound | Receipts to review | The four newest `stock_imports` for the warehouse | ✅ |
| Inbound units | Units arriving | `sum(quantity)` of those four records | ✅ |
| Recent outbound | Dispatches to review | The four newest `stock_exports` for the warehouse | ✅ |
| Outbound units | Units leaving | `sum(quantity)` of those four records — no carton conversion | ✅ |
| On hand | Units on the shelf | `stocks.quantity` | ✅ |
| Reserved | Units promised | `stocks.pending` | ✅ |
| Available | Sellable now | `quantity - pending`; never floored, so a row can read negative and be `Out` | ✅ |
| Minimum | Reorder point | `LOW_STOCK_THRESHOLD` (10) for every row | ✅ |
| Status | Availability bucket | `Out` ≤ 0 · `Low` 1–10 · `In stock` > 10 | ✅ |
| Price | Unit price | Stock price, else the product price, in the company currency | ✅ |
| Location | Where the row sits | The row's first text property; `—` when blank | ✅ |
| `Showing X of Y` | Coverage of the view | Rendered rows vs matching rows in the warehouse | ✅ |
| `Updated {time}` | Freshness | Server `generated_at`, rendered in the warehouse timezone | ✅ |
| Cycle counts | Count / variance history | Not modelled; the card says so and shows the real row count | 💤 |

---

## 6. Gaps by user job

### G1 — "This product needs a different minimum"
Every row shows the same global minimum (10). A `reorder_rules` table exists
(product × warehouse min/max, safety stock, lead time) but nothing writes or
reads it yet.

- Smallest real version: keep the global rule and state it (done).
- Full version: wire `ReorderRule` into the ledger and the bucket queries (M).

### G2 — "Show me the count and the variance"
The cycle-count card is honest text. `stock_counts` and `stock_count_lines`
exist (expected vs counted vs variance) but there is no screen, service, or
route that creates a count.

- Smallest real version: the honest card (done).
- Full version: count session, count sheet, variance approval (L).

### G3 — "Which shelf exactly?"
`Location` is the first text property on the stock row. There is no bin model in
use (`storage_locations` exists but nothing writes it, and `stocks` has no
location column).

- Smallest real version: label it `Location` and show `—` when blank (done).
- Full version: bins and locations per warehouse (L).

### G4 — "I have more than 200 stock rows"
The ledger stops at 200 and says so. Search and tab counts already cover the
whole warehouse, so the operator can always find a row.

- Smallest real version: the honest cap footer (done).
- Better: server-side pagination (M).

### G5 — "Which dock is the truck at? How much does it weigh?"
There is no dock model, no package count, and no weight. The cards show the
record: code, status, units, date.

- Full version: dock doors and shipment packaging (M) — not requested.

### G6 — "Let me receive stock from here"
The console navigates to the receiving form; it saves nothing.

- Better: a receive drawer (M) — deliberately not built.

### G7 — "Can I count by scanning?"
There is no RFID or barcode reader. Nothing on the page claims one.

---

## 7. Decisions for the BA

All ten original decisions are **decided**; two new ones were taken in this pass.

| ID | Decision | Choice taken | Consequence |
|---|---|---|---|
| INV-D1 | BOM panel | **A. Remove** the KPI and the analyzer | No "0 shortages" claim; BOM is a future product |
| INV-D2 | Zone capacity | **A. Remove** the map and the utilization donut | No invented occupancy; real bins are G3 |
| INV-D3 | Dock identity | **A. Remove** gate and bay labels | No fake dock numbers |
| INV-D4 | Packaging and weight | **A. Drop** pallets, cartons, kg | Units are units; no false conversions |
| INV-D5 | Receive action | **A. Navigation only** | The console stays read-only |
| INV-D6 | Ledger pagination | **A. Show the 200 cap honestly** | Search and counts still cover the warehouse |
| INV-D7 | Per-product reorder point | **A. Keep the global 10, state the rule** | One minimum for every product until `ReorderRule` is wired |
| INV-D8 | Cycle counts | **A. Remove Schedule Count; keep the honest note** | Counts are a future project |
| INV-D9 | Dead tabs | **A. Removed from Inventory** | Store Manager keeps its own tabs (separate audit) |
| INV-D10 | Static operational claims | **A. Removed** | `Updated {time}` is the only freshness claim |
| INV-D11 | Where does ledger `Open` go? | **Build the stock-row screen** | The action lands on the row; read-only |
| INV-D12 | How is the CSV produced? | **Server-rendered attachment** | The file is the filtered view, testable in a request spec |

---

## 8. Safe demo path

1. Open **Operations → Inventory** for a warehouse that has stock, at least one
   receipt, and one dispatch.
2. Read the four KPIs. Outbound units equal the dispatch quantities.
3. Filter **Out** or **Low**; the tab count matches the rows. Click **Export
   CSV** and open the file.
4. Search a code that is not on the first screen of results; it still appears.
5. Click **Open** on a row; you land on that stock row.
6. Read a receipt card: code, status, units, date — no door, no percent.
7. Read the cycle-count note: counts are not available; there is no button.

**Do not demo:** anything about docks, pallets, cartons, weight, zones,
utilization, RFID, BOM, or cycle counts — none of it is on the page.

---

## 9. Engineering appendix

**Routes**

| Method | Path | Controller#action |
|---|---|---|
| GET | `/companies/:company_id/operations/inventory/:operation_id` | `Companies::Operations::InventoryController#show` (HTML + JSON) |
| GET | `/companies/:company_id/operations/inventory/:operation_id/ledger` | `Companies::Operations::InventoryController#ledger` (CSV) |
| GET | `/companies/:company_id/stocks/:id` | `Companies::StocksController#show` (HTML + JSON) |

**Backend**

- `Inventory::ConsoleService` — payload: `location`, `branch`, `currency`,
  `generated_at`, `kpis`, `ledger`, `recent_inbound`, `recent_outbound`,
  `cycle_counts`.
- `Inventory::LedgerScope` — warehouse/branch scope, Meilisearch search,
  disjoint buckets via `Stock` scopes, tab counts, 200-row cap
  (`LEDGER_LIMIT`), uncapped export rows.
- `Inventory::LedgerCsv` — CSV text for the current view.
- `Stocks::RowPresenter` — the one ledger-row hash (also used by the stock-row
  screen).
- `Stock` — `available_quantity`, `availability_status`, and the
  `out_of_stock` / `low_stock` / `in_stock` / `low_or_out` scopes;
  `STOCK_AVAILABILITY_LABELS` lives in `config/initializers/constants.rb`.

**Search**

- `Stock.ms_raw_search(q, filter: 'company_id = "…" AND warehouse_id = "…"',
  matching_strategy: "all", attributes_to_search_on: [name, code,
  property_string_1])`.
- `warehouse_id` is filterable because `Stock.ms_extra_filterable_columns`
  includes it; deploy note: `bin/rails meilisearch:reindex[Stock]` once after
  the change.
- The hit list is capped at 1,000 ids by Meilisearch; the ledger's own cap
  (200) is lower, so no reachable row is hidden today.

**CSV**

- Same scope as the page, all matching rows (not just the 200 shown), capped at
  `EXPORT_MAX_RECORDS` with `{ errors: [...] }` above it.
- Filename: `inventory-<warehouse-code>-<bucket>-<location-date>.csv`.
- Columns: Product, Code, Price (CUR), Location, On hand, Reserved, Available,
  Minimum, Status.

**Payload example**

```json
{
  "location": { "id": "…", "name": "WH-01 Central", "code": "WH-01", "kind": "warehouse",
                "timezone": "utc", "utc_offset": 0 },
  "branch": { "id": "…", "name": "Central Hub", "code": "BR-01" },
  "currency": "usd",
  "generated_at": "2026-11-20T09:00:00Z",
  "kpis": { "stock_rows": 3, "low_or_out": 2, "out": 1, "minimum": 10,
            "recent_inbound": { "count": 2, "units": 150 },
            "recent_outbound": { "count": 2, "units": 52 } },
  "ledger": { "bucket": "all", "q": "", "limit": 200, "total": 3, "capped": false,
              "counts": { "all": 3, "low": 1, "out": 1, "in_stock": 1 }, "rows": [ … ] },
  "recent_inbound": [ { "id": "…", "code": "IMP-TEST-002", "status": "received",
                        "status_label": "Received", "quantity": 30,
                        "occurred_at": "2026-11-20T08:00:00Z" } ],
  "recent_outbound": [ … ],
  "cycle_counts": { "available": false, "stock_rows": 3 }
}
```

**Source tables:** `stocks`, `stock_imports`, `stock_exports`,
`stock_transactions`, `warehouses`, `branches`, `products`. Unused skeletons not
wired to this page: `reorder_rules`, `stock_counts`, `stock_count_lines`,
`storage_locations`.

**Known limits (documented, not defects):**

- `Location` is the row's first text property; some categories name it
  "Material" (retail raw materials), and it renders under the `Location`
  heading until bins exist.
- The minimum is global (10) by decision INV-D7.
- Search matches every typed token (Meilisearch `matching_strategy: "all"`) and
  only name, code, and location.

**Proof:**

- `spec/features/companies/operations/inventory_spec.rb` (web walkthrough)
- `spec/features/mobile/inventory_spec.rb` (mobile, four viewports)
- `spec/features/companies/stocks/show_spec.rb` (stock-row screen)
- `spec/models/stock_spec.rb` (bucket vocabulary)
- `spec/services/stocks/row_presenter_spec.rb`
- `spec/services/inventory/ledger_scope_spec.rb`
- `spec/services/inventory/console_service_spec.rb`
- `spec/services/inventory/ledger_csv_spec.rb`
- `spec/requests/companies/operations/inventory_spec.rb` (JSON contract, errors,
  CSV, cap, search beyond the page)
- `spec/requests/companies/stocks/show_spec.rb`
- `spec/requests/mobile/inventory_controller_spec.rb`

---

## 10. Out of scope for this pass

Do not build these until a customer asks; each is a new product, not a cleanup:

- Per-product reorder point (wire `ReorderRule`).
- Cycle count, count sheet, variance (wire `StockCount` / `StockCountLine`).
- Dock doors, pallets, cartons, weight.
- Zones, bins, capacity (wire `StorageLocation`).
- BOM and shortages.
- RFID or barcode hardware.
- Receiving or adjusting inside the console.
- Ledger pagination beyond the honest cap.
