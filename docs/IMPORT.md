# Skycom Import (user-prepared CSV)

> **Status**: Live v1. Owner-only, allowlisted CSV ingestion for companies whose
> operators already know the target schema. One import = one target table + one
> category + one uploaded file, with a full-file dry run, approve → background
> run, and audit-log based rollback.
>
> **Deliberately separate from `docs/DATA_MIGRATION.md`.** Import has its own
> tables (`imports`, `import_logs`), its own `Imports::` service namespace, its
> own controller/policy, and its own FE. Do not share code with
> `CompanyMigrations::*`.

---

## 1. Overview

| Concept | Role |
|---------|------|
| `Import` | Source of truth — target table, one category, uploaded file, dry-run result, counters, lifecycle |
| `imports` | One row per import attempt (`workflow_status` is the import lifecycle; there is no `lifecycle_status` column) |
| `import_logs` | Per-record audit: one `created` row per record this import created; rollback replays it |
| `Folder` + `StoredFile` | Root **"Imports"** folder, one child folder per import, one CSV `StoredFile` (polymorphic `attachable`) |
| `Imports::RunJob` / `Imports::RollbackJob` | Solid Queue executors; statuses are job-owned |

### Lifecycle

```
draft ──approve──▶ approved ──job──▶ processing ──▶ completed ──rollback──▶ rolling_back ──▶ rolled_back
                                                       └─fatal error──▶ failed ──rollback──▶ rolled_back
draft ──edit / upload / dry run──▶ draft
draft ──delete──▶ gone
```

- **Approve guards**: `draft`; source file present; target table + category present; the last dry run `passed`; its `schema_digest` matches the *current* resolved category schema; its `source_digest` matches the uploaded file.
- **Failed is terminal**: no re-approve (already-created rows would be duplicated). Roll back the partial run and create a new import.
- **Rollback guards**: `completed` or `failed`; not already `rolled_back`.
- **Delete**: draft only (folder + file removed).

---

## 2. Target tables

`IMPORTABLE_RESOURCES` in `config/initializers/constants.rb` is the security
allowlist. The FE picker mirrors it in
`app/javascript/controllers/helpers/import_tables.js`; **the backend re-validates
every submitted `target_table`**, so a tampered request cannot reach an
unlisted model. A spec asserts both key sets stay equal.

v1 is master/reference data only:

```ruby
branches brands customer_profiles customer_subprofiles customers departments
employee_profiles employee_subprofiles employees facilities products services
suppliers warehouses
```

Excluded: every permission/auth table (`Role`, `Policy`, `PermissionLog`, all
`*RoleAppointment`, `User`, `Session`), platform schema (`Category`,
`PropertyMapping`, `TableConfig`), all order/invoice/payment/credit tables, all
`stock_*` tables, `Document`, and money-bearing `Membership`.

Adding a table = update **both** allowlists (and run the sync spec).

---

## 3. Header contract

A CSV header is one of:

1. **An exact model column name** — `name`, `email`, `code`, `business_type`,
   `price_cents`, `brand_id`, `customer_id`, …
2. **A category property display name** — e.g. `Skin Type Suitability` →
   `property_string_1`. Raw slot names such as `property_string_1` are rejected.

Rules:

- The user picks **one category** on the show page. Its `PropertyMapping`
  supplies the property headers; every imported row gets that `category_id` and
  `property_mapping_id`.
- Exact, case-sensitive match after trimming. A leading BOM is stripped.
  Duplicate/empty headers and unknown headers are rejected with the full expected
  list in the error.
- Excluded columns (engine-owned): `id`, `company_id`, `category_id`,
  `property_mapping_id`, `created_at`, `updated_at`, `discarded_at`,
  `permission_resource_name`, `metadata`, `type`, `lock_version`. JSON/JSONB
  columns are also excluded.
- **`business_type` is required by every target model**, so it is importable.
  `lifecycle_status`, `workflow_status`, `expiration_date`, `external_id`, and
  `*_id` foreign keys are importable too.
- Enum columns accept labels (`physical`, `active`, `us`) or the numeric value.
  The schema payload lists enum labels when there are 30 or fewer.
- `*_id` values must be well-formed UUIDs **and** resolve inside the same
  company. Cross-tenant IDs are rejected before the row is built. The rest of
  the association contract follows normal model validation.
- `metadata` (JSONB) is **not** importable in v1.
- Blank cells are omitted (create-only, so this is simply `nil`).
- `price_cents` is the raw minor-unit integer; the import does not convert
  currencies.

### Resolved schema payload

```jsonc
{
  "target_table": "products",
  "target_model": "Product",
  "category_id": "…",
  "digest": "sha256…",
  "headers": [
    { "header": "name", "attribute": "name", "kind": "column", "type": "string",
      "required": true, "enum": null, "association": null },
    { "header": "brand_id", "attribute": "brand_id", "kind": "column", "type": "uuid",
      "required": false, "enum": null,
      "association": { "model": "Brand", "foreign_key": "brand_id", "company_scoped": true } },
    { "header": "Skin Type Suitability", "attribute": "property_string_1",
      "kind": "property", "type": "string", "required": true, "enum": null, "association": null }
  ]
}
```

`required` is informational: model presence validations, non-null DB columns,
and required `belongs_to` foreign keys.

---

## 4. Dry run

`Imports::DryRunService` validates the whole file synchronously (≤ `IMPORT_MAX_ROWS`):

1. Header row check (unknown/duplicate/empty; exact expected list in the error).
2. Every data row through `Imports::RowMapper` + `model.new(attrs).valid?`.
3. Stores `schema_snapshot`, `dry_run_result`, and `total_rows`.

```jsonc
{
  "passed": false,
  "checked_at": "…",
  "schema_digest": "…",
  "source_digest": "…",
  "total_rows": 120,
  "valid_rows": 118,
  "invalid_rows": 2,
  "header_errors": [],
  "row_errors": [{ "row": 17, "errors": ["Volume (ml): cannot parse 'abc'"] }]
}
```

- **Nothing is written** to target tables.
- `passed` requires zero header errors, zero invalid rows, and at least one row.
- `Approval` requires the dry run to have passed **for the current schema and source digests**. Changing the table/category or re-uploading clears the result.
- Rows are validated with `skip_property_auto_population = true`, so blank
  property cells stay blank; the seed-time random populator never invents import
  data.

---

## 5. Execution and rollback

`Imports::RunService` streams the CSV in `IMPORT_BATCH_SIZE` chunks:

- Each valid row: `model.new(attrs)` → `skip_property_auto_population = true` → `save!`.
- One `ImportLog` (`created`, `record_type`, `record_id`, `source_row`) per created record, inserted in batches.
- Invalid rows and DB failures count as `failed_rows`, are sampled (≤ `IMPORT_ERROR_SAMPLES_LIMIT`), and never abort the run.
- Progress is published per batch; counters are `processed_rows`, `created_rows`, `failed_rows`.
- The service is guarded by status + `processed_rows` (double calls fail with
  `Import is already running`).

`Imports::RollbackService` replays the logs newest-first and
`destroy_all`s only the records this import created (scoped to the company).
Missing records are tolerated; logs are kept as audit.

---

## 6. Endpoints

Under `companies` in `config/routes.rb`:

| Route | Action | Notes |
|-------|--------|-------|
| `GET/POST /companies/:id/imports(.json)` | `index`, `create` | list + New Import modal; create opens the "Imports" folder root |
| `GET/PATCH/DELETE /companies/:id/imports/:id` | `show`, `update`, `destroy` | show returns schema + sample; update persists table/category (clears dry run on change); delete is draft-only |
| `POST …/imports/:id/source_file` | `source_file` | multipart, ≤ `IMPORT_MAX_FILE_BYTES`, replaces the previous file, clears dry run |
| `POST …/imports/:id/dry_run` | `dry_run` | full-file validation |
| `POST …/imports/:id/approve` | `approve` | guarded; enqueues `Imports::RunJob` |
| `POST …/imports/:id/rollback` | `rollback` | guarded; enqueues `Imports::RollbackJob` |

All failures use `{ errors: [...] }` (`docs/API_ERROR_FORMAT.md`). Policy
`Companies::ImportsPolicy` checks `record.owner_role?` on every action. No
`DEFAULT_RESOURCE_NAMES` change and no permission backfill.

---

## 7. Frontend

- Sidebar item **Imports** in the `platform` group.
- `Companies_Imports_IndexController` — list, New Import modal, guarded draft delete.
- `Companies_Imports_NewModalController` — name + description, redirects to show.
- `Companies_Imports_ShowController` — the whole workflow:
  1. Step-by-step instructions card.
  2. Setup: target table (FE allowlist mirror) + category (company categories
     filtered by `resource_name`), "Save setup & load sample".
  3. Expected headers table (header, maps-to slot, type, required, notes) and
     "Copy headers".
  4. Sample table: latest 10 records for the table + category, under the same
     friendly headers.
  5. Upload: single CSV; a browser-side header pre-check blocks unknown/duplicate
     headers and missing required headers before uploading (new
     `helpers/csv_headers.js`). The BE remains the authority.
  6. Dry run result panel (passed/failed counts, header errors, row error table).
  7. Approve; live progress via `import_progress` / `import_finished`.
  8. Rollback.
- All strings are in `dictionary.js` (EN + VI); semantic colors only
  (`bin/check_colors --strict`).

---

## 8. Data model

`imports` (key columns):

```
company_id, folder_id, creator_id -> employees (nullable, on_delete: nullify), category_id
name, description, target_table, target_model
schema_snapshot, dry_run_result, error_samples
source_filename, source_file_size, source_digest
total_rows, processed_rows, created_rows, failed_rows
workflow_status            # IMPORT_WORKFLOW_STATUS — the import lifecycle
approved_at, completed_at, rolled_back_at
business_type, expiration_date, metadata, discarded_at, permission_resource_name
timestamps
```

The creator is required by a model validation at creation time, but the FK is
nullable with `on_delete: :nullify` so deleting an employee does not delete or
block their historical imports. The category FK also nullifies, leaving the
import historical (and unapprovable until re-set).

**No `lifecycle_status` column** — `workflow_status` is the import lifecycle, per
the feature decision. The source CSV is `import.source_file`
(`has_one :source_file, as: :attachable, class_name: "StoredFile"`).

`import_logs`:

```
import_id, company_id, record_type, record_id, action (created),
source_row, previous_state, resource
workflow_status, business_type, expiration_date, metadata, discarded_at,
permission_resource_name, timestamps
```

Unique index `[import_id, record_type, record_id]`.

---

## 9. Constants (`config/initializers/constants.rb`)

| Constant | Value | Use |
|----------|-------|-----|
| `IMPORT_WORKFLOW_STATUS` | draft…rolled_back | imports.workflow_status |
| `IMPORT_ROOT_FOLDER_NAME` | `"Imports"` | shared storage root |
| `IMPORT_MAX_FILE_BYTES` | 5 MB | single-file cap (stays at the StoredFile text limit) |
| `IMPORT_MAX_ROWS` | 20,000 | row cap (dry run validates all) |
| `IMPORT_BATCH_SIZE` | 500 | log/progress batch |
| `IMPORT_PREVIEW_ROW_LIMIT` | 10 | sample rows |
| `IMPORT_ERROR_SAMPLES_LIMIT` | 50 | stored row errors |
| `IMPORT_NOTIFICATION_TAG` | `"Imports"` | creator notification tag |
| `IMPORT_ENGINE_COLUMNS` | see §3 | never importable |
| `IMPORTABLE_RESOURCES` | see §2 | target allowlist |

---

## 10. Security rails

| Rail | Detail |
|------|--------|
| Allowlist | `IMPORTABLE_RESOURCES`; never `constantize` user input |
| Forced company scope | `company_id` is engine-owned; target must have a `company_id` column |
| Tenant-safe FKs | `*_id` values must resolve in the same company |
| Engine-owned columns | `id`, `company_id`, `category_id`, `property_mapping_id`, timestamps, discard, permission name, metadata, JSON |
| Owner-only | `Companies::ImportsPolicy` — every action checks `owner_role?` |
| File rails | CSV only, `IMPORT_MAX_FILE_BYTES`, `StoredFile` MIME/size validations, company/folder match |
| No seed auto-fill | `skip_property_auto_population` on every imported record |
| Dry run binding | approve requires matching schema **and** source digests |

---

## 11. Testing

| Spec | Coverage |
|------|----------|
| `spec/models/import_spec.rb`, `import_log_spec.rb` | lifecycle enum, guards, digest binding, log uniqueness |
| `spec/services/imports/schema_resolver_spec.rb` | allowlist, headers, required/enum/association metadata, FE-map sync |
| `spec/services/imports/row_mapper_spec.rb` | coercion, enums, UUIDs, tenant-safe FKs |
| `spec/services/imports/dry_run_service_spec.rb` | pass/fail, header checks, no writes, no auto-population |
| `spec/services/imports/run_service_spec.rb` | creates records + logs, partial failures, double-run guard |
| `spec/services/imports/rollback_service_spec.rb` | destroy created, tolerate deletions, idempotent |
| `spec/services/imports/file_ingest_service_spec.rb` | replace file, size/extension/row caps, clears dry run |
| `spec/services/imports/setup_service_spec.rb` | root/child folders, draft record |
| `spec/services/imports/notify_creator_service_spec.rb`, `spec/jobs/imports/*` | status transitions, notifications, rescuers |
| `spec/policies/companies/imports_policy_spec.rb` | owner-only |
| `spec/requests/companies/imports_controller_spec.rb` | every endpoint success + `errors` failure |
| `spec/features/companies/imports/{index,show,full_journey}_spec.rb` | real-browser E2E incl. header pre-check, dry-run failure/recovery, approve → run → rollback |

Run:

```
bundle exec parallel_rspec -n 14 spec/features/companies/imports spec/models/import* \
  spec/services/imports spec/jobs/imports spec/policies/companies/imports_policy_spec.rb \
  spec/requests/companies/imports_controller_spec.rb
```

The shared `DynamicValidationConcern` opt-out is additive (default off); run the
existing `spec/features/companies/company_migrations` suite as a regression
check after touching it.

---

## 12. v1 non-goals

Upserts/updates, per-row categories, association name lookups (only raw `*_id`
UUIDs), `metadata` JSON import, chunked uploads, background dry run, importing
money/stock/order tables, AI-generated CSV, scheduling/recurring imports, and
automatic FK creation.

## 13. Differences from Data Migration

| | Import | Data Migration |
|---|---|---|
| Input | User-prepared CSV with exact headers | Config-driven mapping (`migration_mapping_config`) |
| Schema knowledge | Required from the user | Encoded in the config |
| Targets | Allowlisted master data | Any company-scoped model minus a denylist |
| Write mode | Create-only | Upsert on `[company_id, external_id]` |
| Upload | Single file | Browser-split chunks |
| Category | One selected category | Config-defined reuse/create |
| Rollback | Destroy records this import created | Destroy created + restore updated `previous_state` |
| Status field | `workflow_status` only | `workflow_status` + `lifecycle_status` |
| Code | `Imports::` namespace | `CompanyMigrations::` namespace |
