# Skycom Data Migration (CompanyMigration)

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
| Migration folder (`Folder` + `StoredFile` chunks) | Root "Migrations" folder holds one child folder per migration; every chunk file is a `StoredFile` attached to the migration |
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

## 2. Config schema v1 — complete reference

> `migration_mapping_config` is the whole program: nothing about the import is
> inferred from the CSV beyond column names. `CompanyMigrations::Config`
> validates §2.1–§2.9 at save time and again at preflight; §2.10 lists every
> exact message. `version` must be exactly `1`.

### 2.1 Document anatomy

```jsonc
{
  "version": 1,                       // integer — must equal 1
  "source":  { "has_header": true },  // the CSV's first row holds the header names
  "targets": [ { …one target… } ]     // v1 imports exactly one target (see §2.13)
}
```

| Field | Type | Required | Rules |
|---|---|---|---|
| `version` | integer | yes | Must be `1`; anything else → `version must be 1`. |
| `source` | object | yes | Only `has_header` is supported and must be truthy → `source.has_header is required`. Header mode is required: the browser-side splitter repeats the header row in every chunk, and the importer parses with `headers: true`. |
| `targets` | array | yes | At least one object → `at least one target is required`. **v1 accepts exactly one** — a second target fails preflight (§2.13). |
| `targets[i]` | object | yes | `resource`, `identity`, `category`, `columns` are required; `defaults` is optional. Each target object has the same shape (the engine loop is reserved for a later version). |

### 2.2 Worked example — the `faker/files/customers-10.csv` demo

The fixture's header row is:
`Index,Customer Id,First Name,Last Name,Company,City,Country,Phone 1,Phone 2,Email,Subscription Date,Website`

```jsonc
{ "version": 1,
  "source": { "has_header": true },
  "targets": [
    { "resource": "customers",                              // → Customer
      "identity":  { "column": "Customer Id" },             // row's Customer Id → customers.external_id (the upsert key)
      "category":  { "mode": "create_or_reuse",
                     "name": "Imported Customers",
                     "properties": { "property_string_1": "Company",   // slot 1's meaning for this category
                                     "property_string_2": "City" },    // slot 2's meaning
                     "visible_columns": ["name", "email", "property_string_1", "property_string_2"] },
      "columns": { "First Name": { "target": "name" },
                   "Email":      { "target": "email" },
                   "Phone 1":    { "target": "phone_number" },
                   "Company":    { "target": "property_string_1" },    // CSV "Company" → the slot named "Company"
                   "City":       { "target": "property_string_2" },
                   "Website":    { "target": "metadata.website" },     // whole-column → metadata JSON, stored as string
                   "Branch Code": { "target": "branch_id",             // FK resolved by the branch's external_id
                                    "lookup": { "resource": "branches", "by": "external_id" } } },
      "defaults": { "business_type": "individual",             // applied to every row unless a mapped value overrides
                    "country": "us", "currency": "usd",        // enum labels are fine in defaults (cast by AR)
                    "lifecycle_status": "active" } }
  ] }
```

Reading it back:

- `Index`, `Last Name`, `Phone 2`, `Subscription Date`, `Country`… are simply not mentioned → ignored.
- `Customer Id` never appears in `columns` — it is consumed by `identity` (mapping it as a target is forbidden, §2.6).
- `Company`/`City` land in `property_string_1`/`property_string_2`; the category's `properties` hash is what gives those slots human names and carries their dynamic validations.
- `Website` lands in `customers.metadata` as `{"website": "http://…"}` (metadata values are always strings).
- `Branch Code` is a foreign key: each row's value is looked up against `branches.external_id` within the company.

### 2.3 `resource` — which table gets written

`resource` is the plural, snake_case form of a Skycom model. The engine resolves it with `classify.safe_constantize` (`customers` → `Customer`, `customer_profiles` → `CustomerProfile`, `stocks` → `Stock`) and then requires:

1. the model exists → else `targets[i]: unknown model '<resource>'`;
2. the model is not in `MIGRATION_IMPORT_EXCLUDED_RESOURCES` → else `targets[i]: '<resource>' is not importable`;
3. the table has a `company_id` column → else `targets[i]: '<resource>' is not company-scoped`.

`company_id` itself is never mapped — the engine writes the session company on every row (§2.9). Anything the config targets must ultimately pass the model's own validations during the dry run.

### 2.4 `identity` — the `external_id` bridge

| Rule | Detail |
|---|---|
| Shape | `{ "column": "<CSV header>" }` — required → `targets[i]: identity.column is required`. |
| Effect | Every row's value at that header is written to the target's `external_id`. |
| Upsert key | `[company_id, external_id]` — this is how re-imports update instead of duplicating. |
| Per-row | A blank value fails that row: `<column>: identity value is required`. Values are exact strings (case-sensitive). |
| Table requirement | The target table must own a **unique index on `[company_id, external_id]`** — preflight refuses otherwise: `<resource> is missing a unique index on [company_id, external_id] — add it before importing`. v1 ships this index for `customers` only; adding a table = one additive migration. |
| Forbidden elsewhere | `external_id` cannot also be a `columns`/`defaults` target (§2.6). |

### 2.5 `category` — where rows live (and their dynamic schema)

`category` is required (`targets[i]: category is required`) and has two modes:

| Mode | Required keys | Behavior |
|---|---|---|
| `reuse` | `category_id` | Uses an existing company category (and its property mapping/table config) as-is. Unknown id → the category resolver fails the dry run/import. |
| `create_or_reuse` | `name` | Finds a category by `[company, name, resource_name]`; if missing, creates it through `Seed::CategoryService.create` — i.e. exactly like seeding. Idempotent across re-runs. |

Optional keys (both modes):

- `properties` — `{ "<slot>": "<display name>" }`, e.g. `{ "property_string_1": "Company" }`. Written into the category's PropertyMapping as `property_metadata`, **and this is where dynamic validations come from**: a slot whose property carries `"presence"` will fail rows that don't fill it (the dry run shows this per row). Use it to name every slot your `columns` map.
- `visible_columns` — array of column keys/slots for the category's TableConfig. `property_*` entries must use the same display name as the PropertyMapping (that's the TableConfig validation), so keep them in sync with `properties`.

Two dry-run side effects worth knowing: the category (and its property mapping / table config) **is created during the dry run** — it is config-level prep, not a target-row write — and nothing is rolled back if you later abandon the migration.

### 2.6 `columns` — CSV header → target

`columns` is an object whose **keys are exact CSV header names** (case-sensitive; a header that doesn't exist in the file is silently skipped) and whose values are mapping objects:

```jsonc
"columns": {
  "Email":       { "target": "email" },                         // plain model column
  "Website":     { "target": "metadata.website" },              // metadata.<key>
  "Company":     { "target": "property_string_1" },             // property_* slot
  "Branch Code": { "target": "branch_id",                       // FK via lookup
                   "lookup": { "resource": "branches", "by": "external_id" } }
}
```

Every mapping object needs a `target` → else `targets[i].columns['<Header>']: target is required`. The target string is one of four forms:

| Form | Example | Validated against |
|---|---|---|
| Model column | `email`, `branch_id`, `name` | Must exist on the model → `'<x>' is not a column of <Model>`. |
| Property slot | `property_string_1` … `property_datetime_10` | Must be one of the 60 slots (§2.7) → `unknown property slot '<x>'`. |
| Metadata key | `metadata.website` | Non-empty key after the prefix → `metadata key is required`. |
| FK via `lookup` | `{ "target": "branch_id", "lookup": { … } }` | See below. |

**Lookup** (FK resolution): `{ "resource": "<plural model>", "by": "external_id" }`. `by` must be exactly `"external_id"` → else `lookup must be { resource, by: 'external_id' }`; the resource must resolve to a model → else `unknown lookup model '<x>'`. At runtime each value is resolved with `lookup_model.where(company_id:, external_id: value).pick(:id)` (memoized per value for the whole run). A value with no match fails that row: `<resource>: no record with external_id '<value>'`. The referenced record must already exist (or belong to the same import run — earlier targets commit first when the multi-target loop ships).

**Forbidden targets** — the engine owns these, wherever they appear (columns or defaults): `id`, `company_id`, `created_at`, `updated_at`, `discarded_at`, `permission_resource_name`, `property_mapping_id`, `external_id` → else `'<x>' cannot be imported`.

**Duplicate mappings**: if two CSV columns target the same field, the **last one in document order wins** — map each target once.

### 2.7 Property slots — the full list

Property slots live on every dynamic resource (`customers`, `products`, …) and get their meaning from the category's PropertyMapping:

| Type | Slots | Coerced as |
|---|---|---|
| String | `property_string_1` … `property_string_10` | as-is |
| Integer | `property_integer_1` … `property_integer_20` | integer (§2.8) |
| Decimal | `property_decimal_1` … `property_decimal_10` | decimal |
| Boolean | `property_boolean_1` … `property_boolean_10` | boolean |
| Datetime | `property_datetime_1` … `property_datetime_10` | datetime |

`property_string_11` or `property_integer_21` → `unknown property slot '<x>'`.

### 2.8 Per-row runtime semantics

Applied to every data row, in this order:

1. **Defaults seed the row** — each key in `defaults` is set on the attrs (metadata defaults merge into the metadata hash).
2. **Mapped columns override only when non-blank** — a blank (`nil`/`""`) CSV value is skipped entirely, so the default stays; on an update, the **existing DB value is kept** (never nulled out). This means a thin CSV can never erase columns it doesn't mention.
3. **Values are coerced by the destination column type:**

| Column type | Parsing | Failure |
|---|---|---|
| string/text | as-is | — |
| integer | `Integer(value.strip)` | `<target>: cannot parse '<value>'` |
| decimal | `BigDecimal(value.strip)` | `<target>: cannot parse '<value>'` |
| boolean | true iff the value (case-insensitive, trimmed) is `1`, `true`, `yes`, `y`, or `on`; **everything else is false** | — (no error) |
| datetime/date | `Time.zone.parse` | `<target>: cannot parse '<value>'` |
| anything else | raw string | — |

> **The enum trap.** Enum-backed columns (`country`, `currency`, `timezone`, `workflow_status`, `lifecycle_status`, `business_type`) are integer-typed at the row mapper. A mapped text value like `"us"` therefore fails with `country: cannot parse 'us'` — mapped enum values must be the numeric value. **Labels (`"us"`, `"active"`) only work in `defaults`**, where ActiveRecord casts them (that's why the demo config puts them there). Labels in `metadata.*` are fine too — metadata is text.

4. **`metadata.<key>` values are always stored as strings.** Two mappings into the same metadata key: last wins (same rule as columns).
5. **Errors are per-column and don't stop the row's other columns** — a failed lookup or bad number contributes an error for that field while the remaining mappings still apply; the row then goes through model validation and, if anything fails, is counted as a failed row (import keeps going).

### 2.9 Import-time semantics (what config authors should know)

- **Upsert key** is `[company_id, external_id]`: unknown ids are created, known ids are updated. Created vs updated is decided by a pre-upsert read of the batch.
- **Updates are non-destructive**: only mapped/defaulted columns are written; changed columns are captured in the audit log (`previous_state`), unchanged rows produce **no log at all** (a rollback can't undo a no-op).
- **Duplicate `external_id` within one batch**: the last row wins (a single Postgres statement can't touch the same conflict row twice). Logs are deduplicated per record, keeping the **first touch** (a record created then re-updated in one import stays `created` → rollback destroys it).
- **Failed rows never abort the run**: they increment `failed_rows` and are sampled (up to `MIGRATION_ERROR_SAMPLES_LIMIT`) with `{ source_row, chunk_index, errors }`; every other row still imports.
- **Engine-owned attrs**: `company_id`, `category_id` (resolved category), `property_mapping_id` (its default mapping) are written on every row; `external_id` comes from `identity`.
- **Resume**: re-approving a failed migration skips chunks already marked completed, so retries are cheap and counters don't double-count.
- **Rollback** replays the audit log: created → destroy, updated → restore `previous_state` (newest first; only the company's latest not-rolled-back import is rollback-able).

### 2.10 Message reference

**Save-time / preflight (static)** — `i` is the target index:

| Message (abridged prefix shown as `…`) | Meaning → fix |
|---|---|
| `version must be 1` | Wrong/missing `version` → set `"version": 1`. |
| `source.has_header is required` | Missing `source.has_header` → set `true`. |
| `at least one target is required` | Empty/missing `targets` → add a target object. |
| `targets[i]: must be an object` | Target entry isn't a JSON object. |
| `targets[i]: resource is required` | Missing `resource`. |
| `targets[i]: unknown model '<x>'` | `resource` doesn't resolve to a Skycom model. |
| `targets[i]: '<x>' is not importable` | Target is on the exclusion list (§2.13). |
| `targets[i]: '<x>' is not company-scoped` | Model has no `company_id` column. |
| `targets[i]: identity.column is required` | Missing `identity.column`. |
| `targets[i]: category is required` | Missing `category`. |
| `targets[i]: category.mode must be one of reuse, create_or_reuse` | Bad/absent `mode`. |
| `targets[i]: category.category_id is required for reuse` | `reuse` without `category_id`. |
| `targets[i]: category.name is required for create_or_reuse` | `create_or_reuse` without `name`. |
| `targets[i]: columns must be an object` | `columns` isn't a map. |
| `targets[i]: defaults must be an object` | `defaults` isn't a map. |
| `targets[i].columns['<H>']: target is required` | A mapping without `target`. |
| `…: metadata key is required` | `metadata.` with an empty key. |
| `…: '<x>' cannot be imported` | Forbidden target (§2.6). |
| `…: unknown property slot '<x>'` | Not one of the 60 slots (§2.7). |
| `…: '<x>' is not a column of <Model>` | Not a real column of the target model. |
| `…: lookup must be { resource, by: 'external_id' }` | Lookup shape/`by` wrong. |
| `…: unknown lookup model '<x>'` | Lookup `resource` doesn't resolve. |
| `no chunks uploaded yet` | Dry run/import before any chunk upload. |
| `<resource> is missing a unique index on [company_id, external_id] — add it before importing` | Table not import-ready (§2.4). |
| `multiple targets are not supported yet` | v1 accepts one target (§2.13). |

**Per-row (runtime, shown in the dry-run rows and import error samples):**

| Message | Meaning → fix |
|---|---|
| `<target>: cannot parse '<value>'` | Wrong type — check the coercion table (§2.8), including the enum trap. |
| `<identity column>: identity value is required` | Row's identity cell is blank. |
| `<resource>: no record with external_id '<value>'` | Lookup found nothing — import the referenced rows first, or fix the value. |
| *model validation messages* (`Name can't be blank`, `Email has already been taken`, property-rule messages…) | The row is invalid for the destination table — the dry run reports these verbatim. |

### 2.11 Digest & dry-run binding

`Config#digest` is a SHA-256 over the **deep-sorted** document: key order is irrelevant, any value change produces a new digest. A passing dry run stores the digest it validated; **saving the config clears `dry_run_result`**, and approve requires `dry_run_result.config_digest == config.digest`. The dry-run result itself is:

```jsonc
{ "passed": true, "checked_at": "…", "config_digest": "…", "sample_size": 10,
  "created": 10, "updated": 0,
  "rows": [ { "row": 1, "action": "create", "values": { …mapped attrs… }, "errors": [] } ],
  "errors": [] }
```

`passed` is true only when **every sampled row** has no errors and there are no global errors; `sample_size` is `min(rows in the first chunk, MIGRATION_PREVIEW_ROW_LIMIT)`.

### 2.12 Example B — reuse mode + FK lookup + metadata default

For a returning client whose categories already exist and whose rows reference branches by code:

```jsonc
{ "version": 1,
  "source": { "has_header": true },
  "targets": [
    { "resource": "customers",
      "identity": { "column": "Customer Id" },
      "category": { "mode": "reuse", "category_id": "8b7c…-existing-category-uuid" },
      "columns": {
        "First Name":  { "target": "name" },
        "Email":       { "target": "email" },
        "Branch Code": { "target": "branch_id",
                         "lookup": { "resource": "branches", "by": "external_id" } }
      },
      "defaults": { "country": "us", "metadata.import_source": "legacy-crm" } } ] }
```

Every row: name/email mapped, branch resolved by `branches.external_id` (a miss fails only that row), and `metadata.import_source = "legacy-crm"` stamped for later filtering.

### 2.13 Limits, gotchas, and what v1 refuses

- **One target per migration.** A second target fails preflight (`multiple targets are not supported yet`) — dry run and import agree.
- **Lookups only support `by: "external_id"`** and only company-scoped models.
- **Identity index is per table.** Only `customers` ships the unique `[company_id, external_id]` index; wiring a new table means an additive migration, and the dry run says so until it exists.
- **Excluded resources** (`MIGRATION_IMPORT_EXCLUDED_RESOURCES`): `Role`, `Policy`, `PermissionLog`, `PolicyRoleAppointment`, `RoleTagAppointment`, `CustomerRoleAppointment`, `CustomerGroupRoleAppointment`, `DepartmentRoleAppointment`, `EmployeeRoleAppointment`, `EmployeeGroupRoleAppointment`, `User`, `Session`.
- **Forbidden targets**: `id`, `company_id`, `created_at`, `updated_at`, `discarded_at`, `permission_resource_name`, `property_mapping_id`, `external_id`.
- **CSV shape**: header row required; UTF-8 (a leading BOM is tolerated and stripped); the browser splitter repeats the header in every chunk and never splits a row or quoted field.
- **Memory**: the browser loads the whole file as text before splitting — fine for tens/hundreds of MB, not for GB-scale exports.
- **Money/stock targets are permitted by config but bypass domain mechanisms** — see the hazard note in §3 before writing one.
- **`defaults` keys accept the same grammar minus `lookup`** — a constant can't be a foreign key; use a `columns` lookup for FKs.

### 2.14 Machine-readable shape — Appendix A

Appendix A holds a JSON-Schema-style **shape guide**. It encodes the static
structure (required fields, enums, the four target forms, forbidden names);
it cannot know the models' real columns, the property slots, or the exclusion
list — those stay engine-side, and §2.10 is the message contract they enforce.

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
| `POST …/company_migrations.json` | `create` | `SetupService`: root "Migrations" folder + per-migration folder + draft record |
| `GET …/company_migrations/:id(.json)` | `show` | Full payload: counters, chunks, preview, config, dry-run result, `chunk_max_bytes`, `can_approve`, `can_rollback`, `config_locked` |
| `POST …/:id/chunks` | `chunks` | Multipart `file` + `chunk_index`; strict order, header must match chunk 0, size ≤ `MIGRATION_CHUNK_MAX_BYTES` |
| `PATCH …/:id/update_config` | `update_config` | Validates the config, clears `dry_run_result`, denormalizes `target_resource` |
| `POST …/:id/dry_run` | `dry_run` | Sample rehearsal; stores result + config digest |
| `POST …/:id/approve` | `approve` | Guarded; enqueues `ImportJob` |
| `POST …/:id/rollback` | `rollback` | Guarded; enqueues `RollbackJob` |
| `DELETE …/:id` | `destroy` | Draft-only; destroys chunks → migration → folder (order matters: folder FK) |

Frontend (Shell-First; all strings via `translate()`):

- `Companies_CompanyMigrations_IndexController` — migration table, New Migration modal, guarded draft delete.
- `Companies_CompanyMigrations_NewModalController` — name-only create; redirects to the show page.
- `Companies_CompanyMigrations_ShowController` — file picker → `splitCsvChunks()` (quote-aware; each chunk repeats the header, BOM only on chunk 0) → sequential `POST chunks` starting at `total_chunks` (re-pick the same file to resume); chunks list; raw preview (first rows); JSON config editor; Run dry run; Approve (disabled until a passing dry run); Rollback; live progress via WebSocket.
- Sidebar item **Migrations** (`platform` group), dictionary entries in English + Vietnamese.

---

## 6. Constants (`config/initializers/constants.rb`)

| Constant | Value | Use |
|----------|-------|-----|
| `MIGRATION_CHUNK_MAX_BYTES` | 4 MB | FE split size + BE chunk guard (stay under `STORED_FILE_MAX_SIZES_BY_TYPE[:text]`, 5 MB). Set to `100.kilobytes` locally to watch the split with `faker/files/customers-1000.csv`. |
| `MIGRATION_PREVIEW_ROW_LIMIT` | 10 | Raw preview + dry-run sample rows |
| `MIGRATION_IMPORT_BATCH_SIZE` | 500 | Rows per upsert batch (import + rollback) |
| `MIGRATION_ERROR_SAMPLES_LIMIT` | 20 | Stored error samples |
| `MIGRATION_NOTIFICATION_TAG` | "Migrations" | Owner notification tag |
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
| `spec/features/companies/company_migrations/full_journey_spec.rb` | the perfect-case journey end-to-end: index → create → upload → preview → config → dry run → approve → import → Customers dashboard → rollback, UI + DB at every step |
| `spec/smoke/app_requires_spec.rb` | bundled-gem guard: every `app/**/*.rb` that uses `CSV.` must `require "csv"` (the suite preloads csv, so only this catches a dev/prod NameError) |

Run (parallel runner, see `docs/PARALLEL_TESTS.md`):

```
bundle exec parallel_rspec -n 14 spec/smoke spec/models/company_migration* spec/services/company_migrations \
  spec/jobs/company_migrations spec/policies/companies/company_migrations_policy_spec.rb \
  spec/requests/companies/company_migrations_controller_spec.rb spec/features/companies/company_migrations
```

### Manual demo checklist (dev)

1. `bin/dev`; sign in as the company owner; sidebar → **Migrations** → New Migration.
2. Upload `faker/files/customers-10.csv`; check the preview shows the 10 rows.
3. Paste the §2 config into the editor, Save, Run dry run → Passed, Approve.
4. Watch `processed/total` move to 10/10; open the Customers dashboard.
5. Rollback → customers disappear (only the latest completed import is rollback-able).
6. To watch the FE split: temporarily set `MIGRATION_CHUNK_MAX_BYTES = 100.kilobytes`, restart `bin/dev`, upload `faker/files/customers-1000.csv` (several chunks), then restore the constant.

---

## 8. Non-goals (v1)

AI-assisted config generation (and the editor's "AI" button), structured click-editor, presigned/direct-to-storage uploads, multi-target imports (the engine refuses >1 target loudly), special mechanisms for money/stock targets, import cancellation, and appointment/link-row imports.

---

## Appendix A — machine-readable shape guide (JSON Schema 2020-12)

> **Boundary**: this encodes the *static* document shape only. Model-column
> existence, the 60 property slots, the excluded-resource list and the
> forbidden targets are enforced engine-side (`CompanyMigrations::Config`,
> see §2.10 for the exact messages). Treat the engine — not this schema — as
> the source of truth; the schema exists for editors, tooling, and future
> AI-generated configs.

```jsonc
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "skycom/migration_mapping_config/v1",
  "type": "object",
  "required": ["version", "source", "targets"],
  "additionalProperties": false,
  "properties": {
    "version": { "const": 1 },
    "source": {
      "type": "object",
      "required": ["has_header"],
      "additionalProperties": false,
      "properties": { "has_header": { "const": true } }
    },
    "targets": {
      "type": "array",
      "minItems": 1,
      "maxItems": 1, // v1: exactly one target (engine refuses >1, §2.13)
      "items": { "$ref": "#/$defs/target" }
    }
  },
  "$defs": {
    "target": {
      "type": "object",
      "required": ["resource", "identity", "category", "columns"],
      "additionalProperties": false,
      "properties": {
        "resource": { "type": "string", "pattern": "^[a-z][a-z0-9_]*$" },
        "identity": {
          "type": "object",
          "required": ["column"],
          "additionalProperties": false,
          "properties": { "column": { "type": "string", "minLength": 1 } }
        },
        "category": {
          "oneOf": [
            { "$ref": "#/$defs/categoryReuse" },
            { "$ref": "#/$defs/categoryCreate" }
          ]
        },
        "columns": {
          "type": "object",
          "additionalProperties": { "$ref": "#/$defs/columnMapping" }
        },
        "defaults": {
          "type": "object",
          "propertyNames": { "$ref": "#/$defs/targetField" },
          "additionalProperties": { "type": ["string", "number", "boolean", "null"] }
        }
      }
    },
    "categoryReuse": {
      "type": "object",
      "required": ["mode", "category_id"],
      "additionalProperties": false,
      "properties": {
        "mode": { "const": "reuse" },
        "category_id": { "type": "string", "format": "uuid" }
      }
    },
    "categoryCreate": {
      "type": "object",
      "required": ["mode", "name"],
      "additionalProperties": false,
      "properties": {
        "mode": { "const": "create_or_reuse" },
        "name": { "type": "string", "minLength": 1 },
        "properties": {
          "type": "object",
          "additionalProperties": { "type": "string", "minLength": 1 },
          "propertyNames": { "$ref": "#/$defs/propertySlot" }
        },
        "visible_columns": {
          "type": "array",
          "items": { "type": "string", "minLength": 1 }
        }
      }
    },
    "columnMapping": {
      "type": "object",
      "required": ["target"],
      "additionalProperties": false,
      "properties": {
        "target": { "$ref": "#/$defs/targetField" },
        "lookup": {
          "type": "object",
          "required": ["resource", "by"],
          "additionalProperties": false,
          "properties": {
            "resource": { "type": "string", "pattern": "^[a-z][a-z0-9_]*$" },
            "by": { "const": "external_id" }
          }
        }
      }
    },
    "targetField": {
      "type": "string",
      "not": {
        "enum": [ "id", "company_id", "created_at", "updated_at", "discarded_at",
                  "permission_resource_name", "property_mapping_id", "external_id" ]
      },
      "anyOf": [
        { "pattern": "^metadata\\.[A-Za-z0-9_]+$" },
        { "$ref": "#/$defs/propertySlot" },
        { "pattern": "^[a-z][a-z0-9_]*$" } // model column — existence checked engine-side
      ]
    },
    "propertySlot": {
      "pattern": "^property_(string_([1-9]|10)|integer_([1-9]|1[0-9]|20)|decimal_([1-9]|10)|boolean_([1-9]|10)|datetime_([1-9]|10))$"
    }
  }
}
```

---

*See also: `docs/STORAGE.md` (folder/stored-file storage), `docs/WEBSOCKET.md` (events),
`docs/CONSTANTS.md`, `docs/API_ERROR_FORMAT.md`, `docs/KREDIS.md` (why counters are DB columns, not Kredis).*
