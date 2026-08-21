# Skycom Atomic Purpose Pattern

> The credit system's architecture guide. Follow this pattern for any new
> money/credit/usage model.

## The Principle

**A model owns exactly ONE responsibility and never mutates itself — its state
changes only through relation-business models.**

Two consequences:

1. **One purpose per model** — documented in a header comment. If a model is
   doing two jobs, split it.
2. **No self-mutation** — business code never calls `record.update!(...)` to
   drive a money flow. State transitions happen through the chain below.

## The Chain

Money events flow strictly top-down. Each record is mutated only by the record
above it:

```
CompanyTransaction  (money movement / gateway entry — created externally)
        │  after_create / after_destroy :sync_invoice_payment_status
        ▼
CompanyInvoice      (the bill — payment_status DERIVED from transaction sum, never set directly)
        │  after_update :complete_order_if_paid! (only when status BECAME paid)
        ▼
CompanyOrder        (the deal — money tier → credits; complete! guarded/idempotent)
        │  wallet.update!(walletable:) + wallet.add_credits!(...)
        ▼
CompanyWallet       (stores balance NUMBERS only — main/promo/debt — no business logic)
```

Rules:

- **Callbacks only for rare money events.** The chain above is the ONLY place
  callbacks are allowed. The hot usage path NEVER uses callbacks.
- **Every link is idempotent-guarded.** `CompanyOrder#complete!` no-ops when
  already completed; the invoice only completes once (`saved_change_to_payment_status?`).
- **Wallet atomicity.** Every mutation uses a per-balance conditional UPDATE
  (`SET <balance> = <balance> - ?, lock_version = lock_version + 1
   WHERE id = ? AND <balance> >= ?`) so concurrent deductions can never
  overdraw. `lock_version` provides optimistic locking.
- **Usage deduction flows through `Deduct::*` services** (see `docs/CREDIT_DEDUCTION.md`).
  The chain above handles money IN; the `Deduct::BaseService` hierarchy handles
  credit OUT (deduct promo → main → debt), triggered by an `after_action` filter
  at the controller action level — never inline in actions.

## The Hot Path Rule (usage tracking)

Per-action credit consumption is too hot for DB writes:

```
Service → company.record_credit_usage!(10)     Kredis INCR (unsynced delta)
CompanyUsageSyncJob (periodic)                 drain counter → DB → reset to 0
Reads: today = DB total + Redis delta; past = DB only
```

- One counter per company, declared with the **`kredis_counter` DSL** (never raw
  `Kredis.counter`, no hardcoded keys — the DSL generates
  `companies:<id>:credit_usage`):
  ```ruby
  kredis_counter :credit_usage
  ```
- The counter is a **plain accumulator — it only counts and resets**. It is
  agnostic to the sync job's period: whatever accumulated since the last run is
  drained into the DB (CompanyDailyUsage h<drain hour>, CompanyMonthlyUsage
  d<drain day>) and reset to 0. A coarser schedule (2h, 4h, …) only coarsens
  hour-slot attribution — it never loses or double-counts data; the DB is
  always cumulative (e.g. drain at 2H: counter 500 → DB 500; drain at 6H:
  counter 400 → DB 900).
- Recording/reading goes through the model helpers:
  `company.record_credit_usage!(credits)` and `company.credit_usage_delta`.
- `CompanyDailyUsage`/`CompanyMonthlyUsage` persist snapshots; their metadata is
  accessed ONLY through `hour_usage`/`day_usage` helpers (store_accessor), and
  their `total_credits` column (a denormalized slot sum, maintained by the
  helpers) is the debug aid for verifying drained totals.
- Counters are DELTAS since the last sync — after draining, reset with
  `counter.decrement(by: delta)` (never `reset`/`del`, which could wipe a delta
  written by another process in between).

## Conventions (all credit tables)

| Rule | Detail |
|------|--------|
| System Fields block | `lifecycle_status`, `workflow_status`, `business_type`, `expiration_date`, `metadata`, `discarded_at` (indexed), `permission_resource_name` |
| One jsonb column | `metadata` only — never add a second jsonb column |
| BIGINT amounts | All money/credit columns are `t.bigint` |
| Constants | Multi-file constants in `config/initializers/constants.rb`; single-file at usage site |

## How to Extend

| Task | What to do |
|------|------------|
| New credit cost action | Add key to `CREDIT_USAGE_RATES` (e.g. `create_export: 5`) |
| New deduction point | Create a `Deduct::*` service subclass + declare it via `deduct_credits_for` (see `docs/CREDIT_DEDUCTION.md` §6) |
| New purchase tier | Add `{ money_cents => credits }` entry to `CREDIT_RATES[country]` |
| New money flow | Place the model in the chain with ONE purpose; wire it through the model above it |
| New usage metric | Add a Kredis counter key + a persisted usage model with store_accessor helpers |
| Turn on live credit inspection | `company.company_wallet.enable_usage_logging!` — detail rows for 5 minutes (see `CompanyUsageLog`) |
