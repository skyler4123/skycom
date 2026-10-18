# Skycom Data Import (CompanyMigration)

> **Status**: Live v1. Owner-only, config-driven CSV ingestion. The
> `migration_mapping_config` document tells a generic engine what to write and
> where; nothing touches business tables until a dry run passes and the owner
> approves. Proven end-to-end with `customers`; the engine itself is not
> customer-specific.

---

## 1. Overview

| Concept | Role |
|---------|------|
| `CompanyMigration` | Source of truth — config, counters, audit logs, approve/rollback workflow, and (via `folder_id`) the upload folder |
| `migration_mapping_config` (jsonb) | The program: source options + one or more targets (resource, identity, category, columns, defaults) |
| Migration folder (`Folder` + `StoredFile` chunks) | Root "Data Import" folder holds one child folder per migration; every chunk file is a `StoredFile` attached to the migration |
| `CompanyMigrationLog` | Per-record audit: `created` → rollback destroys, `updated` → rollback restores `previous_state` |
| `CompanyMigrations::ImportJob` / `RollbackJob` | Solid Queue executors; statuses are job-owned |

### Lifecycle

```
draft ──approve──▶ approved ──job──▶ processing ──▶ completed ──rollback──▶ rolling_back ──▶ rolled_back
  ▲                                                 │
  │                                                 └──failure──▶ failed ──approve(retry)──▶ approved (resumes)
  └─ chunks upload + config edit + dry runs only while draft/failed
```

- **Approve guards**: status ∈ {draft, failed}; ≥1 chunk; config parses; identity mapped; last dry run passed **and** its `config_digest` equals the current config digest (any config edit clears `dry_run_result`).
- **Rollback guards**: status `completed`; the migration is the company's latest not-rolled-back completed one (rails-style — a later import may reference its records).
- **Retry**: re-approve a `failed` migration; the import skips chunks already marked `import_status = "completed"`. Chunk counters reset per pass, so retries never double-count.

---

## 2. Config schema v1 (normative)

```jsonc
{ "version": 1,
  "source": { "has_header": true },
  "targets": [
    { "resource": "customers",
      "identity":  { "column": "Customer Id" },
      "category":  { "mode": "create_or_reuse",              // or { "mode": "reuse", "category_id": "<uuid>" }
                     "name": "Imported Customers",
                     "properties": { "property_string_1": "Company", "property_string_2": "City" },
                     "visible_columns": ["name", "email", "property_string_1", "property_string_2"] },
      "columns": { "First Name": { "target": "name" },
                   "Email":      { "target": "email" },
                   "Phone 1":    { "target": "phone_number" },
                   "City":       { "target": "property_string_2" },
                   "Website":    { "target": "metadata.website" },
                   "Branch Code": { "target": "branch_id",
                                    "lookup": { "resource": "branches", "by": "external_id" } } },
      "defaults": { "business_type": "individual", "country": "us", "currency": "usd", "lifecycle_status": "active" } }
  ] }
```

Rules:

- `defaults` seed the attrs; a mapped column overrides only when its CSV value is non-blank. Blank-mapped values on updates **keep the existing DB value** (backfill), so a thin CSV can never null out columns it doesn't mention.
- Targets: a real model column, a `property_*` slot (`Seed::CategoryService::PROPERTY_SLOT_KEYS`), `metadata.<key>`, or `{ "target": "<x>_id", "lookup": { "resource": "...", "by": "external_id" } }`. Lookups resolve `[company_id, external_id]`; earlier targets commit first, so `X → Y1 + Y2` chains work when the engine loop is enabled.
- Category `create_or_reuse` reuses `Seed::CategoryService` + `Seed::TableConfigService`, so an import also configures dynamic properties and the table config exactly like seeding does. The dry run creates the category too (config-level prep; never a target row).
- Validation lives in `CompanyMigrations::Config` (see `spec/services/company_migrations/config_spec.rb` for the accepted/rejected matrix).

---

## 3. Security rails

| Rail | Detail |
|------|--------|
| **Excluded resources** | `MIGRATION_IMPORT_EXCLUDED_RESOURCES` — the permission/auth machinery (Role, Policy, PermissionLog, *RoleAppointment*, RoleTagAppointment) plus User/Session. Configs targeting them are rejected. |
| **Forced company scope** | `company_id` comes from the session; it is a forbidden target and always written by the engine. Only models with a `company_id` column can be targets. |
| **Forbidden targets** | `id`, `company_id`, `created_at`, `updated_at`, `discarded_at`, `permission_resource_name`, `property_mapping_id`, `external_id` (identity only). |
| **Identity index preflight** | Every target table must carry a unique index on `[company_id, external_id]` (upsert conflict key). Dry run fails with "…is missing a unique index on [company_id, external_id]" otherwise. v1 ships this index for `customers` only. |
| **Owner-only access** | `Companies::CompanyMigrationsPolicy` checks `record.owner_role?` on every action. Deliberately NOT registered in `Company::DEFAULT_RESOURCE_NAMES` — seeding would auto-grant Admin/Manager. |

> **Hazard — money/stock targets**: per the owner's decision any company-scoped
> table (other than the excluded set above) may be named by a config, including
> orders/invoices/stock rows. A plain column import of those **bypasses**
> `docs/MONEY_FLOW.md` derivations and the `docs/STOCK.md` single write path
> (ledger rows, holds, counters). Do not ship a client config against them
> without designing the special mechanism first (e.g. stocks ⇒ an opening
> `StockImport` document + ledger rows).

---

## 4. Counters, progress, notifications

- Chunk metadata (`StoredFile.metadata`): `chunk_index`, `row_count`, `import_status`, `processed_rows`, `created_rows`, `updated_rows`, `failed_rows`.
- Migration counters are always recomputed as Σ chunk counters (`CompanyMigration#recompute_counters!`), so `processed_rows/total_rows` is resume-safe. `error_samples` (capped at `MIGRATION_ERROR_SAMPLES_LIMIT`) stores `{ source_row, chunk_index, errors }` samples.
- WebSocket events (company channel; see `docs/WEBSOCKET.md`):
  - `company_migration_progress` — `{ id, phase: "import"|"rollback", status, processed_rows, total_rows, created_rows, updated_rows, failed_rows }` (published per batch).
  - `company_migration_finished` — `{ id, status, created_rows, updated_rows, failed_rows }` (published by the jobs).
- Owner notifications (system tag `MIGRATION_NOTIFICATION_TAG`, subscribed to the owner, throttled per migration) on finished / failed / rollback-completed.

---

## 5. Endpoints & frontend

Routes under `companies` (`config/routes.rb`):

| Route | Action | Notes |
|-------|--------|-------|
| `GET /companies/:company_id/company_migrations(.json)` | `index` | List + create modal data |
| `POST …/company_migrations.json` | `create` | `SetupService`: root "Data Import" folder + per-migration folder + draft record |
| `GET …/company_migrations/:id(.json)` | `show` | Full payload: counters, chunks, preview, config, dry-run result, `chunk_max_bytes`, `can_approve`, `can_rollback`, `config_locked` |
| `POST …/:id/chunks` | `chunks` | Multipart `file` + `chunk_index`; strict order, header must match chunk 0, size ≤ `MIGRATION_CHUNK_MAX_BYTES` |
| `PATCH …/:id/update_config` | `update_config` | Validates the config, clears `dry_run_result`, denormalizes `target_resource` |
| `POST …/:id/dry_run` | `dry_run` | Sample rehearsal; stores result + config digest |
| `POST …/:id/approve` | `approve` | Guarded; enqueues `ImportJob` |
| `POST …/:id/rollback` | `rollback` | Guarded; enqueues `RollbackJob` |
| `DELETE …/:id` | `destroy` | Draft-only; destroys chunks → migration → folder (order matters: folder FK) |

Frontend (Shell-First; all strings via `translate()`):

- `Companies_CompanyMigrations_IndexController` — migration table, New Import modal, guarded draft delete.
- `Companies_CompanyMigrations_NewModalController` — name-only create; redirects to the show page.
- `Companies_CompanyMigrations_ShowController` — file picker → `splitCsvChunks()` (quote-aware; each chunk repeats the header, BOM only on chunk 0) → sequential `POST chunks` starting at `total_chunks` (re-pick the same file to resume); chunks list; raw preview (first rows); JSON config editor; Run dry run; Approve (disabled until a passing dry run); Rollback; live progress via WebSocket.
- Sidebar item **Data Import** (`platform` group), dictionary entries in English + Vietnamese.

---

## 6. Constants (`config/initializers/constants.rb`)

| Constant | Value | Use |
|----------|-------|-----|
| `MIGRATION_CHUNK_MAX_BYTES` | 4 MB | FE split size + BE chunk guard (stay under `STORED_FILE_MAX_SIZES_BY_TYPE[:text]`, 5 MB). Set to `100.kilobytes` locally to watch the split with `faker/files/customers-1000.csv`. |
| `MIGRATION_PREVIEW_ROW_LIMIT` | 10 | Raw preview + dry-run sample rows |
| `MIGRATION_IMPORT_BATCH_SIZE` | 500 | Rows per upsert batch (import + rollback) |
| `MIGRATION_ERROR_SAMPLES_LIMIT` | 20 | Stored error samples |
| `MIGRATION_NOTIFICATION_TAG` | "Data Import" | Owner notification tag |
| `MIGRATION_IMPORT_EXCLUDED_RESOURCES` | see §3 | Config denylist |

---

## 7. Testing

| Spec | Coverage |
|------|----------|
| `spec/models/company_migration_spec.rb`, `company_migration_log_spec.rb` | enums, counters recompute, guards, log uniqueness |
| `spec/services/company_migrations/config_spec.rb` | schema accept/reject matrix, stable digest |
| `spec/services/company_migrations/category_resolver_spec.rb`, `row_mapper_spec.rb` | category/property/table-config creation; mapping + coercion + lookups on the real fixture |
| `spec/services/company_migrations/dry_run_service_spec.rb` | pass/fail rehearsal, create/update classification, stored result |
| `spec/services/company_migrations/import_service_spec.rb` | upsert + previous_state, blank-keep, dedup logs, failed-row caps, resume, multi-target refusal |
| `spec/services/company_migrations/rollback_service_spec.rb` | destroy created, restore updated, tolerate deletions, idempotent |
| `spec/services/company_migrations/notify_owner_service_spec.rb`, `spec/jobs/company_migrations/*` | status transitions, notifications, rescuers |
| `spec/policies/companies/company_migrations_policy_spec.rb`, `spec/requests/companies/company_migrations_controller_spec.rb` | owner-only policy; every endpoint's success + `errors` failure |
| `spec/features/companies/company_migrations/{index,show}_spec.rb` | real-browser E2E: modal create, BOM upload, 32 KB chunk split of customers-1000, dry run → approve → completed counters, rollback |

Run (parallel runner, see `docs/PARALLEL_TESTS.md`):

```
bundle exec parallel_rspec -n 14 spec/models/company_migration* spec/services/company_migrations \
  spec/jobs/company_migrations spec/policies/companies/company_migrations_policy_spec.rb \
  spec/requests/companies/company_migrations_controller_spec.rb spec/features/companies/company_migrations
```

### Manual demo checklist (dev)

1. `bin/dev`; sign in as the company owner; sidebar → **Data Import** → New Import.
2. Upload `faker/files/customers-10.csv`; check the preview shows the 10 rows.
3. Paste the §2 config into the editor, Save, Run dry run → Passed, Approve.
4. Watch `processed/total` move to 10/10; open the Customers dashboard.
5. Rollback → customers disappear (only the latest completed import is rollback-able).
6. To watch the FE split: temporarily set `MIGRATION_CHUNK_MAX_BYTES = 100.kilobytes`, restart `bin/dev`, upload `faker/files/customers-1000.csv` (several chunks), then restore the constant.

---

## 8. Non-goals (v1)

AI-assisted config generation (and the editor's "AI" button), structured click-editor, presigned/direct-to-storage uploads, multi-target imports (the engine refuses >1 target loudly), special mechanisms for money/stock targets, import cancellation, and appointment/link-row imports.

---

*See also: `docs/STORAGE.md` (folder/stored-file storage), `docs/WEBSOCKET.md` (events),
`docs/CONSTANTS.md`, `docs/API_ERROR_FORMAT.md`, `docs/KREDIS.md` (why counters are DB columns, not Kredis).*
