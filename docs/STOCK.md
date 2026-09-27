# Skycom Stock System — The Source of Truth

> **Status**: Live. Stock is the heart of Skycom ERP: every unit on every shelf
> is tracked here, and every movement in the platform lands here. One tenet
> governs it all: **`Stock.quantity` is mutated ONLY by `StockTransaction`'s
> hardened callback** — no direct writes, no background jobs, no exceptions.

---

## 1. The Model — Two Numbers + One Hot Counter

Each `Stock` row tracks one SKU in one warehouse (`warehouse_id` unique per
`product_id`). It carries two DB numbers and one Redis counter
(`app/models/stock.rb`):

| Store | Field | Meaning |
|-------|-------|---------|
| DB | `quantity` | Physical units on the shelf |
| DB | `pending` | Units promised to someone (holds) — reserved but not yet moved |
| Redis | `available_counter` (`stock:<id>:available`) | Hot-path sellable figure; mirrors `quantity − pending` |

**The invariant: `available == quantity − pending`.** Consequences:

- **DB is the source of truth; Redis is a fast mirror.** If Redis is ever
  wrong, the DB heals it — never the reverse.
- **Reads are cheap**: availability checks hit Redis only, zero DB cost.
- **Healing is automatic**: a missing counter key (restart/flush) is rebuilt
  from `quantity − pending` on first read; every `save!` that changes
  `quantity`/`pending` pushes the delta to Redis (`after_save
  :sync_available_counter`).
- **Known caveat**: Redis is mutated inside DB transactions, so a rolled-back
  movement leaves Redis briefly ahead until the next `save!` heals it via
  delta. Small, self-healing window — never the reverse direction.

---

## 2. The Single Write Path

Every movement funnels through `StockMovementService::BaseService`
(`app/services/stock_movement_service/base_service.rb`) — the epic:

```
service (import / export / transfer / purchase / POS finalize)
  │  stock.with_lock → hold-aware floor check → StockTransaction.create!
  ▼
StockTransaction#recalibrate_stock_metrics (app/models/stock_transaction.rb)
  │  find_by!(company, warehouse, product) — a missing row is a programming
  │  error, never a silent zero-quantity creation
  │  with_lock → quantity ± qty → negative? raise StockMovementService::Error
  │  stock.save! → after_save syncs the Redis counter
  ▼
consume_hold? → release_reserved! (pending -= qty, Redis += qty)
```

Rules:

- **One DB transaction** wraps document + lines + ledger + quantity. Any raise
  rolls back everything; controllers translate it to `422 { errors: [...] }`
  (see `docs/API_ERROR_FORMAT.md`).
- **Floor check is hold-aware**: free removals require
  `quantity − pending >= qty`; hold consumption (`consume_hold: true`)
  requires `quantity >= qty` **and** `pending >= qty`.
- **`consume_hold` ownership**: a line carrying the pay-persisted `stock_id`
  proves its hold — consume unconditionally (a missing hold fails fast
  instead of silently overselling). Legacy lines without `stock_id` keep the
  `pending >= qty` heuristic, else free-standing removal under the floor.
- **Document lines reference exact rows**: each movement line table carries a
  concrete `stock_id` + `quantity` — warehouse ambiguity is impossible.

---

## 3. The Read Path & Cache Contract

All stock availability flows through three model wrappers
(`app/models/stock.rb`) — business code never touches the Kredis proxy
(see `docs/KREDIS.md`; enforced by grep):

| Wrapper | Effect |
|---------|--------|
| `available_count` | Read sellable units from Redis; heal from DB when the key is missing |
| `reserve_stock!(qty)` | Atomic Redis decrement + DB `pending += qty`; returns `false` with both stores untouched when insufficient (self-reverting) |
| `release_reserved!(qty)` | Redis increment + DB `pending -= qty` (floored at 0) |

Callers: `CheckAvailabilityService` reads via `available_count`;
`ReserveStockService` heals then reserves per item (first `false` rolls back
prior holds, raises `InsufficientStockError` → 422);
`ReleaseReservedStockService` releases per line (exact `stock_id` first,
branch-then-company fallback, tolerates missing rows).

---

## 4. The Flows

### 4.1 POS sale — checkout → pay → finalize

```
Checkout ─► reads availability (Redis counter; heals from DB if missing)
Pay      ─► reserve_stock!: DECRBY available_counter + DB pending += qty;
             persist exact stock_id on the atomic order line
Finalize ─► remove ledger row per line (consume_hold) + StockExport doc
Cancel   ─► release_reserved! + mark transaction failed
```

- Pay resolves stock against the order's **branch warehouses only** — never a
  company-wide first match. A product stocked only elsewhere is a 422
  availability failure, not a 404.
- Finalize reads the persisted `stock_id` first (warehouse-deterministic),
  falling back to branch-then-company resolution for legacy rows.
- Cash completes synchronously; QR completes via webhook; both derive
  `Invoice.payment_status` from completed transactions
  (see `docs/MONEY_FLOW.md` §4). Full pipeline: `docs/ORDER_PROCESSING_V1.md`.

### 4.2 Manual documents — import / export / adjustment (one-shot)

Build doc + atomic lines from `{ stock_id, quantity }` params, then the
matching `CreateService` writes one ledger row per line (`add` for import /
increase, `remove` for export / decrease) and flips the doc to
`received` / `shipped` / `completed` — all in one transaction via
`Companies::StockMovementConcern`.

### 4.3 Transfers — two-phase (`pending → initiated → received | cancelled`)

- **Initiate**: holds source units (`pending` +, no ledger, no quantity
  change) — POS availability drops instantly. Partial failure rolls back all
  prior holds. Allowed from `draft`/`pending` only; self-transfers rejected.
- **Receive**: two ledger rows per line — `remove` at source (consuming the
  hold, `appoint_from: transfer`) + `add` at destination (row resolved or
  created positively, `appoint_to: transfer`) — inside one transaction, so
  total units conserve (20 moved stays 20). Requires `initiated`.
- **Cancel**: releases holds, no ledger rows (initiate wrote none). Requires
  `initiated`.
- Endpoints: `POST create` (document + lines, no movement), `POST
  initiate|receive|cancel` (member).

### 4.4 Purchase bridge — buy-process completion lands goods

Final workflow approval calls
`StockMovementService::Purchases::CompleteService` **inside the advance
transaction**: resolves destination-warehouse stock rows, builds a `received`
`StockImport` (`business_type: :purchase`, `appoint_from: purchase`) with
`add` ledger rows. Idempotent (skips when the import exists); item-less or
product-less purchases skip. Bridge failures return `{ success: false,
errors }` — the advance never raises for business failures, and the whole
approval rolls back. Requires `purchases.warehouse_id` (destination) and
`purchase_items.product_id` (optional). See `docs/PURCHASE_WORKFLOW.md`.

### 4.5 Holds lifecycle

```
reserve (pay, transfer-initiate) → consume (finalize, transfer-receive)
                                 → release (pay-cancel, transfer-cancel)
```

`pending` moves only through `reserve_stock!` / `release_reserved!` /
hold-consuming ledger rows. Orphan holds are impossible by construction:
every hold is created with its consumer (finalize/receive) or its releaser
(cancel) on a defined path.

### 4.6 Document ↔ line-table map (atomic pairs)

| Document | Line table | Ledger |
|----------|-----------|--------|
| `StockImport` | `stock_import_stock_appointments` | `add` / `import` |
| `StockExport` | `stock_export_stock_appointments` | `remove` / `export` |
| `StockTransfer` | `stock_transfer_stock_appointments` | `remove`+`add` / `transfer` |
| `StockAdjustment` | `stock_adjustment_stock_appointments` | `add`/`remove` / `adjustment` |
| `Order` (POS) | `order_product_appointments` (+ `stock_id` FK) | `remove` / `export` |
| `Purchase` | `purchase_purchase_item_appointments` | via bridge import |

Stock documents themselves keep polymorphic `appoint_from/to/for/by` links
(operator identity, purchase anchor, transfer legs) — only their *lines* and
order/purchase lines are atomic (see `docs/RESOURCES.md` §4).

---

## 5. Tenets (Immutable)

1. **Single mutator.** `Stock.quantity` is written only by
   `StockTransaction#recalibrate_stock_metrics`. No service, controller, or
   job assigns it.
2. **Wrappers only.** Business code reads/reserves/releases through
   `available_count` / `reserve_stock!` / `release_reserved!` — never the
   Kredis proxy, never raw `update_all` on stock columns.
3. **DB leads, Redis follows.** On any disagreement, the DB value wins; Redis
   heals from it.
4. **Exact rows, never guessed warehouses.** Lines carry concrete `stock_id`;
   document-level `warehouse_id` is validated against line rows on create.
5. **All-or-nothing movements.** Document + lines + ledger + quantity commit
   together or not at all; failures surface as `422 { errors: [...] }`,
   never partial state or 500s on business failures.
6. **No orphan holds.** Every reservation names its consumer or releaser;
   `pending` never grows without a path that clears it.

---

## 6. Verification

| Gate | Command | Expectation |
|------|---------|-------------|
| Movement specs | `bundle exec rspec spec/services/stock_movement_service spec/services/order_processing_v1 spec/models/stock_transaction_spec.rb spec/models/stock_transfer_spec.rb` | Green (incl. conservation + rollback E2E) |
| Request specs | `bundle exec rspec spec/requests/companies/stock_* spec/requests/companies/order_processing` | Green (incl. 422 + persist-nothing cases) |
| Lint | `bin/rubocop <touched files>` | No offenses |
| Security | `bin/brakeman` | 0 errors |
| Kredis rule | Greps in `docs/KREDIS.md` § Enforcement | Empty (no raw connections, no proxy use outside models) |

---

## 7. File Reference

| File | Purpose |
|------|---------|
| `app/models/stock.rb` | SKU row (`quantity`/`pending`), `available_counter`, the three wrappers, `sync_available_counter` |
| `app/models/stock_transaction.rb` | Ledger row + the single quantity mutator (`recalibrate_stock_metrics`) |
| `app/models/stock_{import,export,transfer,adjustment}.rb` | Movement documents |
| `app/models/stock_{import,export,transfer,adjustment}_stock_appointment.rb` | Atomic document lines (exact `stock_id` + `quantity`) |
| `app/services/stock_movement_service/base_service.rb` | The epic: lock → floor → ledger → hold release |
| `app/services/stock_movement_service/stock_resolver.rb` | Positive resolve-or-create of destination rows (creation is not a movement) |
| `app/services/stock_movement_service/{imports,exports,adjustments}/create_service.rb` | One-shot document executors |
| `app/services/stock_movement_service/transfers/{initiate,receive,cancel}_service.rb` | Two-phase transfer flow |
| `app/services/stock_movement_service/purchases/complete_service.rb` | Purchase → stock bridge |
| `app/services/order_processing_v1/{check_availability,reserve_stock,initiate_payment,write_stock_ledger,finalize_order,release_reserved_stock}_service.rb` + `cancel_payment_service.rb` | POS pipeline |
| `app/jobs/order_processing_v1/finalize_job.rb` | Async finalize (ledger + export doc; idempotency-guarded) |
| `app/controllers/concerns/companies/stock_movement_concern.rb` | Shared create flow (one transaction, 422 contract, warehouse validation) |
| `app/controllers/companies/stock_{transfers,imports,exports,adjustments}_controller.rb` | Movement endpoints |
| `config/routes.rb` | `stock_transfers` member `initiate/receive/cancel`; `stock_imports/exports/adjustments` create |
| `config/initializers/constants.rb` | `WORKFLOW_STATUS` += `initiated/received/shipped` |
| `docs/ORDER_PROCESSING_V1.md` | POS pipeline detail (stock mechanics summarized in §7) |
| `docs/PURCHASE_WORKFLOW.md` | Purchase process + bridge |
| `docs/MODEL_CALLBACKS.md` | Callback reference (ledger mutator row) |
| `docs/KREDIS.md` | Wrapper rule + enforcement greps |
| `docs/RESOURCES.md` | Table catalog (§4: stock document lines) |

---

*See also: `docs/MONEY_FLOW.md` §4 (payment derivation that triggers finalize),
`docs/ATOMIC_PURPOSE.md` (one-purpose models), `docs/CACHE.md` §4 (global
cache tier), `docs/DYNAMIC_TABLE.md` §2.5 (stock metric filters).*
