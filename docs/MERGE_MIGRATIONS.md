# Skycom Merge Migration

> **Status**: Active (pre-release only). Skycom is not yet released, so we keep the migration history clean by folding follow-up `add_*` / alter migrations back into their original `create_*` migration. This doc defines what "merge migration" means, when it is allowed, and the exact steps.

---

## 1. What Is a "Merge Migration"?

A **merge migration** is *not* a Rails feature. It is a manual housekeeping commit that:

1. **Folds** a later incremental migration (usually `add_*` / `change_*` / `add_index`) inline into the original table-creation migration (`create_*`).
2. **Deletes** the now-redundant incremental migration file(s).
3. **Rewinds** `db/schema.rb`'s `define(version:)` to the newest *surviving* migration timestamp.

Result: the table's full definition lives in **one place**, not scattered across `create_*` + several `add_*` patches. `db/migrate` stays lean (currently 120 files) and readable.

| Before merge | After merge |
|---|---|
| `20260624145819_create_billing_invoices.rb` | `20260624145819_create_billing_invoices.rb` (+ columns inlined) |
| `20260712101603_add_billing_enums_to_invoices.rb` | *(deleted)* |
| `db/schema.rb` version `2026_07_12_101603` | `db/schema.rb` version `2026_07_02_190003` (max surviving timestamp) |

---

## 2. When To Use / When NOT To Use

| Rule | Detail |
|---|---|
| **Allowed** | Pre-release only — while every environment (local dev, CI, staging) can be rebuilt from scratch (`db:migrate:reset` / `db:schema:load`). |
| **Forbidden** | After first production release — any DB that already ran the deleted migration would have a stale row in `schema_migrations` and drift from `schema.rb`. Past that point, use normal additive migrations only. |
| **Safe targets** | `add_column`, `add_index`, `change_column`, `remove_column` (when reverting a mistaken add) that belong to a table created in the same development cycle. |
| **Not for** | Data migrations, backfills, `app/models` logic dependencies, or any migration already applied on a DB you cannot reset. |

If any teammate / CI cache already ran the to-be-deleted migration and you cannot coordinate a reset, **do not merge** — ship the `add_*` as-is.

---

## 3. Procedure (Step by Step)

Use this checklist every time you merge. Work on a feature branch and verify `db/schema.rb` at the end.

### Step 1 — Identify the set

Pick the table's `create_*` migration and all follow-up `add_*` / alter migrations to fold:

```bash
ls db/migrate | grep -E "create_billing_invoices|add_billing_enums"
git log --oneline -- db/migrate/20260712101603_add_billing_enums_to_invoices.rb
```

### Step 2 — Fold columns/indexes into the `create_*` migration

Edit the `create_*` file and add the columns **in their logical position**:

- Business columns go **above** the `# --- System Fields ---` block (`ARCHITECTURE_GUIDES.md` rule).
- System Fields (`lifecycle_status`, `workflow_status`, `business_type`, `expiration_date`, `metadata`, `discarded_at`, `permission_resource_name`) stay last, just above `t.timestamps`.
- Reproduce the exact column definition: type, `null:`, `default:`, `index: true`. For a separate `add_index` with `unique: true`, add `index: true` inline or `add_index` after the `create_table` block — match how `schema.rb` renders it.

Example — folded billing enums (`20260624145819_create_billing_invoices.rb`):

```ruby
create_table :billing_invoices, id: :uuid do |t|
  t.references :company, null: false, foreign_key: true, type: :uuid
  t.references :billing_contract, null: false, foreign_key: true, type: :uuid

  t.string :name
  t.text :description
  t.string :invoice_number, null: false, index: true

  t.integer :movement_type, index: true      # ← folded
  t.integer :target_balance, index: true     # ← folded
  t.integer :created_by, index: true         # ← folded

  t.integer :price_cents, null: false
  # ...
  # --- System Fields ---
  t.integer  :lifecycle_status
  # ...
  t.timestamps
end
```

### Step 3 — Delete the redundant migration file(s)

```bash
rm db/migrate/20260712101603_add_billing_enums_to_invoices.rb
rm db/migrate/20260703223342_add_deficit_to_attendance_months.rb  # if merging multiple
```

### Step 4 (optional) — Rename a feature block into a clean range

When a feature was built as several independent creates (e.g., HR: `shift_templates`, `scheduled_shifts`, `attendance_logs/days/months/policies`), rename them into a sequential timestamp block so ordering is tidy:

```
20260702170000_create_shift_templates.rb
20260702170001_create_scheduled_shifts.rb
20260702180000_create_attendance_logs.rb
20260702181000_create_attendance_days.rb
20260702182000_create_attendance_months.rb
```

Keep the original timestamps otherwise (do not re-stamp to `now`) — the range should still sort after the preceding feature.

### Step 5 — Rewind `db/schema.rb` version

Set the version to the **newest surviving migration timestamp** (it moves *backward* because deleted migrations are gone):

```ruby
# Before
ActiveRecord::Schema[8.0].define(version: 2026_07_12_101603) do
# After
ActiveRecord::Schema[8.0].define(version: 2026_07_02_190003) do
```

Do not hand-edit anything else in `schema.rb` — it is regenerated in the next step. Just update the version line to match `ls db/migrate | sort -r | head -1`.

### Step 6 — Reset and regenerate

```bash
bin/rails db:migrate:reset   # drops, recreates, re-runs all surviving migrations, regenerates schema.rb
# or, for a faster check without dropping:
bin/rails db:migrate
```

`db:migrate:reset` updates `schema_migrations` (removed rows disappear) and rewrites `db/schema.rb` from the folded migrations. The resulting `schema.rb` diff should show **zero unexpected changes** beyond the version line and the intended column placements.

Verify:

```bash
git diff db/schema.rb   # only version line + folded columns in their table should differ
bin/rails db:schema:dump  # no-op if reset already dumped
```

### Step 7 — Notify teammates and CI

Every checkout that already ran the deleted migration(s) must reset:

```bash
bin/rails db:migrate:reset RAILS_ENV=test
bin/rails db:migrate:reset RAILS_ENV=development
```

In CI, clear the DB cache or force `db:schema:load` so `schema_migrations` matches.

---

## 4. Real Examples From History

| Commit | What was merged | Fold target |
|--------|----------------|-------------|
| `c8555d93` (2026-07-05) | `add_deficit_to_attendance_months` (`total_deficit_minutes`) + `add_resolution_strategy_to_attendance_policies` (`resolution_strategy`) | Folded into `create_attendance_months.rb` (+ `total_deficit_minutes` before System Fields) and `create_attendance_policies.rb` (`resolution_strategy` with `default: 0, null: false`). Both `add_*` files deleted. |
| `b8ac8f8e` (2026-07-05) | 5 HR migrations — shift templates, scheduled shifts, attendance logs/days/months | Renamed into clean sequential range `20260702170000..20260702182000`; no columns changed, only filenames. |
| `6e567cd4` (2026-07-13) | `add_billing_enums_to_invoices` (`movement_type`, `target_balance`, `created_by` + indexes) | Folded into `create_billing_invoices.rb` above System Fields; `add_*` deleted, `schema.rb` version rewound `2026_07_12_101603` → `2026_07_02_190003`. |

---

## 5. Gotchas & Verification

| Pitfall | How to avoid |
|---------|-------------|
| Stale `schema_migrations` rows | Any DB that ran a deleted migration **must** `db:migrate:reset` (not just `db:migrate`). Otherwise `SELECT * FROM schema_migrations` still lists the deleted version and future `db:migrate` will skip needed ordering. |
| Version not equal to max surviving file | After merging, `grep "define(version" db/schema.rb` must equal `ls db/migrate | sort -r | head -1` converted to `YYYY_MM_DD_HHMMSS`. If not, CI may think migrations are pending. |
| Column placement drift | Folded columns must sit in the "business columns" area (before System Fields). Placing them after System Fields or inside the wrong table breaks the `ARCHITECTURE_GUIDES.md` convention and makes future merges harder. |
| Index style mismatch | Prefer `t.string :col, index: true` inline when the original was a simple index. For unique/compound indexes (`add_index ..., unique: true`), keep the `add_index` line after `create_table` — `schema.rb` renders it as `t.index` outside the block. |
| Seed / factory drift | Seeds that reference the folded column must still pass after reset. No seed change is needed if the column existed logically before — just verify `bin/rails db:seed` or the relevant enricher still runs. |
| CI cache | If CI caches `db/schema.rb` or the test DB, bust the cache after a merge commit. |

---

## 6. Checklist (copy into your PR description)

```md
- [ ] Folded columns/indexes into the `create_*` migration (above System Fields)
- [ ] Deleted redundant `add_*` migration file(s)
- [ ] (If needed) Renamed feature block into sequential timestamp range
- [ ] `db/schema.rb` version = newest surviving migration timestamp
- [ ] `bin/rails db:migrate:reset` (dev + test) passes; `git diff db/schema.rb` shows only expected changes
- [ ] Teammates notified to reset their DBs
- [ ] Commit message is `merge migrations`
```

---

## 7. File Reference

| File | Role |
|------|------|
| `db/migrate/` | Migration files — the merge source (`create_*`) and deleted targets (`add_*`) |
| `db/schema.rb` | Auto-generated schema — version line `define(version:)` must be rewound after a merge |
| `db/schema_migrations` (table) | Tracks which versions have run — reset removes rows for deleted files |
| `config/database.yml` | DB config for `db:migrate:reset` targets |

---

*End of document*
