# Inventory

> **Last audited:** 2026-11-19 · **Audit scope:** frontend controller, console
> service, backend controller, feature and service specs. No live browser run.
> **Ship readiness:** 🔴 not shippable — a BOM panel built on hardcoded zeros, an
> invented zone-occupancy model, a hardcoded 84% fallback, and dock data derived
> from record IDs.
> **Who this is for:** the warehouse manager or stock controller.
> **Mobile:** same console, mounted through the Hotwire shell.
> **Read first:** [README](README.md) · **Related:** [00-app-overview](00-app-overview.md),
> [06-store-manager](06-store-manager.md)

---

## 1. What this page is for

The Inventory console is the warehouse command screen: the stock ledger for the
warehouse, what is low or out, what freight is at the dock, how full the zones
are, and whether an audit has been done.

"Done" means the controller can see stock truth for one warehouse and jump to the
screen that changes it.

The page is read-only by design. Receiving, transfers, and adjustments happen in
the stock screens; this console is the overview that tells you which one to open.

---

## 2. Who uses it

**The person:** a warehouse manager, stock controller, or receiving supervisor.

**Their goal:** know what is on hand, what is short, and what is arriving or
leaving today.

**What they can do here today:**

- Read the stock ledger for one warehouse: on hand, allocated, available, min
  safe, status.
- Filter by low / critical / in stock, and search by SKU, name, or bin.
- Export the ledger as CSV.
- Jump to a stock row to adjust or transfer.
- Open the receiving and transfer forms.
- See recent inbound and outbound records.
- See the audit empty state.

**What they must do elsewhere:**

- Receive, transfer, or adjust stock — the stock screens.
- Create a purchase order — the purchase screens.
- Run or schedule a cycle count — nothing exists.
- See batch, lot, or expiry — not modelled.

**Access:** the Inventory operation must be active at the warehouse and the role
must be allowed by the operation.

---

## 3. The screen, in words

**Header:** Skycom mark, company, warehouse name and code, a "Cloud Sync Active"
pill, dark mode, and the user. Below it, seven tabs shared with Store Manager
(Store Overview … BOM & Procurement), with **Inventory & Stock Ledger** active.

**Context bar:** warehouse name with a "Primary Fulfillment Node" pill, tenant,
"Sync: Real-time", two telemetry pills (Stock Row Utilization, Freight Gates),
and four quick actions: Receive Inbound, Outbound Transfer, Scan RFID, Audit
Cycle Count.

**KPI strip (five cards):** Total SKUs Active, Stock Criticality, Inbound Gate
Intake, Outbound Freight, BOM Line Shortage.

**Main column:** the stock ledger (Export CSV, Density, Refresh, search, four
status tabs, an eight-column table, a footer count, and a link to the stock
ledger), then the BOM Line Shortage Analyzer.

**Side column:** Active Freight Docks (inbound and outbound cards), Zone Capacity
Map (bars plus a global utilization donut and Re-optimize), and Audit & RFID
Integrity.

**States**

- *No stock rows:* "No stock rows match this view."
- *No inbound:* "No inbound shipments are docked."
- *No outbound:* "No outbound dispatches are scheduled."
- *No zones:* "No warehouse zones are configured."
- *No audit:* an honest "No audit recorded" with the line count.
- *Load failure:* a full-screen red "Failed to load the inventory console."
- *Responsive:* the side column stacks; the table scrolls horizontally.

---

## 4. Control inventory

29 interactive controls.

| ID | Area | Control | What it does today | Status | If shipped as-is |
|---|---|---|---|---|---|
| INV-01 | Top bar | Skycom logo | Returns to the Operations list | ✅ | — |
| INV-02 | Tabs | Store Overview | Toast: "… is coming soon." | 🗑️ | Six of seven tabs are promises |
| INV-03 | Tabs | Counter & POS Terminals | Toast: "… is coming soon." | 🗑️ | Same |
| INV-04 | Tabs | Orders & Fulfillment | Toast: "… is coming soon." | 🗑️ | Same |
| INV-05 | Tabs | Store Replenishment | Toast: "… is coming soon." | 🗑️ | Same |
| INV-06 | Tabs | Warehouse Transfers | Toast: "… is coming soon." | 🗑️ | Same |
| INV-07 | Tabs | BOM & Procurement | Toast: "… is coming soon." | 🗑️ | Same |
| INV-08 | Tabs | Inventory & Stock Ledger | Active tab; does nothing | ✅ | — |
| INV-09 | Top bar | Dark-mode toggle | Switches theme | ✅ | — |
| INV-10 | Context bar | Receive Inbound | Opens the stock-import form | ✅ | Leaves the console |
| INV-11 | Context bar | Outbound Transfer | Opens the stock-transfer form | ✅ | Leaves the console |
| INV-12 | Context bar | Scan RFID | Focuses the search box; shows a toast | 🟡 | No RFID reader exists |
| INV-13 | Context bar | Audit Cycle Count | Opens the stock list | 🟡 | No count flow exists |
| INV-14 | Ledger | Export CSV | Downloads the stock list | ✅ | Exports all stocks, not the filtered view |
| INV-15 | Ledger | Density | Toast: "Density controls are not connected yet." | 🗑️ | Decorative |
| INV-16 | Ledger | Refresh | Reloads the payload | ✅ | — |
| INV-17 | Ledger | Stock search | Filters loaded rows by name, code, bin, status | ✅ | Only the 200 loaded rows |
| INV-18 | Ledger | All tab | Shows all loaded rows | ✅ | — |
| INV-19 | Ledger | Low Stock tab | Filters low, critical, and reorder rows | ✅ | Count is global; rows are capped |
| INV-20 | Ledger | Critical tab | Filters zero-available rows | ✅ | — |
| INV-21 | Ledger | In Stock tab | Filters healthy rows | ✅ | — |
| INV-22 | Row | PO Reorder | Opens the stock row | ✅ | Creates no purchase order |
| INV-23 | Row | Transfer | Opens the stock row | ✅ | Starts no transfer |
| INV-24 | Row | Adjust balance (pencil) | Opens the stock row | ✅ | — |
| INV-25 | Footer | Open stock ledger | Opens the stock list | ✅ | — |
| INV-26 | BOM | Auto-Generate Bulk POs | Toast: "No BOM shortages to order for this warehouse." | 🗑️ | Always says the same, because the data is fake |
| INV-27 | Zones | Re-optimize | Toast: "Zone re-optimization is not connected yet." | 🗑️ | Decorative |
| INV-28 | Audit | View Full Audit Log | Opens the stock list | ✅ | There is no audit log |
| INV-29 | Audit | Schedule Count | Opens the stock list | 🟡 | Schedules nothing |

**Count by status:** ✅ 17 · 🟡 3 · 🗑️ 9 · ⛔ 0. Fabricated figures are in §5.

---

## 5. Numbers on screen

| Claim on screen | What it appears to mean | Where it actually comes from | Verdict |
|---|---|---|---|
| Total SKUs Active | Distinct products in the warehouse | Count of stock rows scoped to the warehouse | ✅ stock rows, not distinct products |
| "Across N facility zones" | Warehouse zones | Number of **warehouses** for the branch | 🟡 warehouses are not zones |
| Stock Criticality | SKUs at or below the threshold | Stock rows where quantity − pending ≤ 10 | ✅ |
| Zero-Stock Outages | SKUs with nothing available | Stock rows where quantity − pending ≤ 0 | ✅ |
| Inbound Gate Intake | Shipments arriving | The four most recent stock imports | ✅ count of recent records, not today's |
| Inbound Units / Docked | Units arriving | Sum of import quantities; count in received/in-progress/confirmed | ✅ |
| Outbound Freight | Dispatches | The four most recent stock exports | ✅ |
| Outbound Cartons | Boxes shipped | Sum of export quantities ÷ 5 | 🔢 no carton data exists |
| "N kg" on an outbound card | Shipment weight | The export **quantity** rendered as kilograms | 🔢 units are presented as weight |
| "N pallets" on an inbound card | Pallets received | Import quantity ÷ 10 | 🔢 no pallet data exists |
| "Gate 3" / "Bay 5" | A real dock door | `record.id` bytes modulo 8, plus 1 | 🔢 invented dock numbers |
| "QC RFID Gate Scan N% offloaded" | RFID read progress | Workflow status mapped to 15/35/65/100 | 🔢 no RFID scan exists |
| "Stock Row Utilization N%" | How full the warehouse is | Average of the invented zone occupancies; **84** when there are no zones | 🔢 |
| Zone name "Zone A: Main" | A real zone | Warehouses listed with letters by position | 🔢 no zone model exists |
| Zone "N% Full" | Zone occupancy | `stock rows × 5`, clamped between 5 and 98 | 🔢 invented formula |
| BOM Line Shortage | Work orders short of parts | Hardcoded `0` | 🔢 there is no BOM model; this claims "no shortages" |
| "Missing Vital Parts" | Missing components | Hardcoded `0` | 🔢 same |
| "No BOM shortages right now." | Production is clear | Always displayed | 🔢 |
| Min Safe | Reorder threshold per product | Global constant 10 for every product | 🟡 |
| "Showing N of M line items" | Coverage of the ledger | M is capped at 200; there is no pagination | 🟡 |
| "Cycle verified against <warehouse>" | Audit coverage | Static footer text | 🔢 |
| "No audit recorded" | No audit exists | `available: false` with the real line count | 💤 honest gap |
| "Cloud Sync Active" / "Sync: Real-time" / "RFID Live Mode" | Live integrations | Static text | 🔢 |
| "Primary Fulfillment Node" | This warehouse's role | Static pill on every warehouse | 🔢 |
| KPI progress bars | Progress toward a target | Arbitrary formulas (94%, count × 10, count × 20) | 🔢 no target exists |

---

## 6. Gaps by user job

### G1 — "Which parts are short for production?"
The BOM panel is a mock. The KPI reports 0 work orders, the panel always says
"no shortages", and the button always refuses. Nothing reads a bill of materials
because none is modelled.

- Smallest real version: remove the BOM card and KPI (S).
- Better: mark it as "not connected" like the audit card (S).
- Full version: BOM model and shortage calculation (L).

### G2 — "How full is the warehouse?"
Zones are warehouses with invented letters, and occupancy is a formula on the
stock-row count. The global figure averages those inventions and returns 84 when
there is nothing to average.

- Smallest real version: remove the zone map and global utilization (S).
- Better: show stock rows per warehouse as a bar chart, labelled as rows (M).
- Full version: real zones with capacity and bin assignment (L).

### G3 — "Which dock is this truck at?"
Gate and bay numbers are derived from the record ID. Two shipments can share a
gate; the number means nothing.

- Smallest real version: remove gate/bay labels (S).
- Full version: dock doors as a real resource (M).

### G4 — "How much does this shipment weigh?"
The outbound card prints the export **quantity** followed by "kg". A shipment of
12 units is shown as 12 kg.

- Smallest real version: remove the kg label (S).
- Full version: capture weight on the export (M).

### G5 — "How many pallets and cartons?"
Both are quantity divided by a constant, with a minimum of one.

- Smallest real version: remove both (S).
- Full version: record packaging on the shipment (M).

### G6 — "I scanned an RFID tag."
There is no RFID reader. "RFID Live Mode" and "QC RFID Gate Scan" are labels on
a search field and a workflow percentage.

- Smallest real version: remove the RFID claims (S).
- Full version: barcode/RFID integration (L).

### G7 — "Let me receive stock from here."
Every write sends the user to another screen. There is no receiving, transfer,
adjustment, or count in the console.

- Smallest real version: accept the navigation and label the buttons "Open
  receiving" (S).
- Better: a receive drawer that captures quantity and supplier (M).

### G8 — "I have more than 200 stock rows."
The ledger stops at 200 with no pagination, and the search only covers the loaded
rows. Low-stock counts are global, so the tab count can exceed the rows shown.

- Smallest real version: show the cap (S).
- Better: server-side pagination and search (M).

### G9 — "This product needs a different minimum."
Min safe is a single global constant of 10 for every product in every company.

- Smallest real version: accept the global threshold and label it (S).
- Full version: per-product reorder point (M).

### G10 — "Which shelf is it on?"
"Bin Location" is a free-text property on the stock row, falling back to the
warehouse name. There is no bin model, no zone, and no shelf capacity.

- Smallest real version: label it "Location" (S).
- Full version: bins and locations (L).

### G11 — "Schedule a cycle count."
The button opens the stock list. There is no audit record, no count sheet, no
variance approval.

- Smallest real version: remove the button (S).
- Full version: audit domain with count and variance (L).

### G12 — "Export exactly what I filtered."
Export downloads all stocks, ignoring the tab and search.

- Smallest real version: export the filtered set (S).

---

## 7. Decisions for the BA

**INV-D1 — The BOM panel: remove, label, or build?**
- A. Remove the KPI and the panel. Effort S.
- B. Keep the panel but render "Not connected" like the audit card. Effort S.
- C. Build BOM and shortage analysis. Effort L.
- *Recommendation:* B if manufacturing customers are in the target market, A
  otherwise. Never ship a hardcoded "0 shortages".

**INV-D2 — Zone capacity: remove or replace?**
- A. Remove the zone map and global utilization. Effort S.
- B. Replace with stock rows per warehouse, honestly labelled. Effort M.
- C. Build zones, bins, and capacity. Effort L.
- *Recommendation:* B. It answers the real question without inventing a model.

**INV-D3 — Dock identity: remove or model?**
- A. Remove gate and bay numbers. Effort S.
- B. Model dock doors and assign shipments. Effort M.
- *Recommendation:* A. Dock scheduling is a niche need; the shipment status is the
  useful part.

**INV-D4 — Packaging and weight: capture or drop?**
- A. Drop pallets, cartons, and kg. Effort S.
- B. Capture weight and package count on imports and exports. Effort M.
- *Recommendation:* A for v1. Wrong units are worse than absent ones.

**INV-D5 — Should the console gain a receive action?**
- A. Keep navigation only. Effort S.
- B. Add a receive drawer. Effort M.
- *Recommendation:* B if warehouse staff work from a tablet at the dock; A if they
  use the desktop receiving screen.

**INV-D6 — Ledger pagination?**
- A. Show the 200 cap honestly. Effort S.
- B. Server-side pagination and search. Effort M.
- *Recommendation:* B for warehouses above a few hundred rows.

**INV-D7 — Per-product reorder point?**
- A. Keep the global 10. Effort S.
- B. Add a reorder point per product/warehouse. Effort M.
- *Recommendation:* B. A global threshold guarantees false alerts in a real
  warehouse.

**INV-D8 — Cycle counts: in scope?**
- A. Remove Schedule Count. Effort S.
- B. Build audit sessions with count and variance. Effort L.
- *Recommendation:* B is the strongest differentiator on this page, but it is a
  project of its own. Do A now, B when a customer asks.

**INV-D9 — Remove the six dead tabs here too?**
- A. Remove them from both Inventory and Store Manager. Effort S.
- B. Keep them as a roadmap hint. Effort S. Risk: two consoles look unfinished.
- *Recommendation:* A, with the decisions recorded in `06-store-manager.md` (SM-D1).

**INV-D10 — Static operational claims?**
- A. Remove "Cloud Sync Active", "Sync: Real-time", "Primary Fulfillment Node",
  and "Cycle verified against…". Effort S.
- B. Replace them with a real last-synced time and a real node role. Effort M.
- *Recommendation:* A now. The page already has a real "Refreshed at" pattern to
  copy later if a health signal is built.

---

## 8. Safe demo path

1. Open **Operations** → **Inventory** for a warehouse with stock seeded.
2. Show the KPI strip: SKUs, criticality, inbound, outbound.
3. Filter **Low Stock**, search a SKU, open a row.
4. Show the inbound and outbound dock cards as **record lists**, not as live
   dock telemetry.
5. Show the audit card: "No audit recorded — N line items ready for the first
   count."

**Do not demo:**

- The BOM panel or its KPI — it always reports zero.
- The zone capacity map, the donut, or Re-optimize.
- Gate and bay numbers, pallet or carton counts, or the kg weight.
- "RFID Live Mode", "Scan RFID", "QC RFID Gate Scan".
- The six header tabs other than Inventory.
- The density button, "Schedule Count", or "View Full Audit Log".
- Export as "your filtered list" — it exports everything.

---

## 9. Engineering appendix

**Route:** `GET /companies/:company_id/operations/inventory/:operation_id`
(HTML + `.json`), optional `warehouse_id`.

**Backend:** `Companies::Operations::InventoryController#show` (payload only);
`Inventory::ConsoleService`.

**Frontend:** `app/javascript/controllers/companies/operations/inventory/show_controller.js`
(`Companies_Operations_Inventory_ShowController`).

**Payload:** `{ location, currency, metrics, stocks, low_stock_count, docks,
zones, global_utilization, audit, generated_at }`.

**Known code-level issues behind §5 and §6:**

- `metrics_payload` sets `bom_shortage_work_orders: 0` and
  `bom_missing_parts: 0` unconditionally.
- `zones_payload` maps warehouses to `"Zone #{letter}: #{warehouse.name}"` and
  computes `occupancy = [stock_count * 5, 5].max.clamp(5, 98)`.
- `global_utilization` returns `84` when there are no zones.
- `inbound_dock_payload` computes `pallets = [quantity / 10, 1].max` and
  `gate = "Gate #{id.bytes.sum % 8 + 1}"`; `outbound_dock_payload` does the same
  for cartons and `weight = quantity`.
- `dock_progress` maps workflow statuses to 15/35/65/100.
- `audit_payload` honestly returns `available: false`.
- `stocks_payload` is capped at `STOCK_LIMIT = 200`; `low_stock_count` is a
  separate global count.
- `bin_location` falls back to the warehouse name when the property is blank.
- The KPI progress bars use arbitrary formulas in the frontend.

**Source tables:** `stocks`, `stock_imports`, `stock_exports`, `warehouses`,
`products`, `branches`. There is no BOM, zone, bin, dock, or audit table.

**Proof:** `spec/features/companies/operations/inventory_spec.rb`,
`spec/requests/companies/operations/inventory_spec.rb`,
`spec/services/inventory/console_service_spec.rb`.

**Not covered by tests:** BOM zeros, zone occupancy, utilization fallback, gate
numbers, packaging conversions, and the audit empty state beyond its shape.
