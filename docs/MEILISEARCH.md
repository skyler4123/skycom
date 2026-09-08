# Skycom Meilisearch Integration

> **Status**: Live (2026-08-29). Meilisearch powers backend search for every dynamic-property model. Live consumers since 2026-09-06: the **Products** and **Customers** index dynamic search/filter (`DynamicSearch::BaseQueryService` subclasses) — per-page rollout recipe: `docs/DYNAMIC_TABLE.md` §8.

---

## 1. Overview

Skycom uses **Meilisearch** (open-source typo-tolerant search engine) to index business records so a future "search" feature can query and filter them. Every **dynamic-property model** — a model that includes `PropertyMappingConcern` (products, branches, employees, customers, ...) — is made searchable by a single shared concern.

### What Gets Indexed

| Group | Columns | Role |
|-------|---------|------|
| Standard | `name`, `description`, `code` (only when the table has them) | **searchable** |
| Tenant / scope | `company_id`, `category_id`, `branch_id`, `workflow_status`, `business_type` | **filterable** |
| Dynamic strings | `property_string_1` … `property_string_10` | searchable + indexed |
| Dynamic numbers | `property_integer_1..20`, `property_decimal_1..10` | searchable + **filterable** (native numeric — range filters work) |
| Dynamic booleans | `property_boolean_1..10` | filterable |
| Dynamic datetimes | `property_datetime_1..10` | filterable (RFC3339) |
| Primary key | `id` | Meilisearch primary key (gem default) |

**Attribute names are the raw column keys** (`property_string_1`), never the PropertyMapping display name ("Skin Type Suitability"). Why:

- Index settings (`searchable_attributes` / `filterable_attributes`) are static — they must match stable keys.
- Renaming a property in `PropertyMapping.property_metadata` never breaks the index.
- The frontend maps keys → display names at query/render time (later work).

### Multi-Tenant Isolation

One index per model **per environment** (index UID = `ClassName_<env>`, e.g. `Product_development` / `Product_test` — via the gem's `per_environment: true` in `config/initializers/meilisearch.rb`, so local rspec `ms_clear_index!` can never wipe dev data). Tenant isolation is done at **query time** with a filter, not per-company indexes:

```ruby
Product.ms_raw_search("face cream", filter: "company_id = #{company.id}")
```

This keeps index count == model count (46) and avoids per-company index management.

---

## 2. Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  Model (Product, Branch, ... )                                   │
│    include DynamicSearchConcern                                  │
│      include Meilisearch::Rails                                  │
│      meilisearch(synchronous: false, enqueue: proc) { ... }      │
└──────────────────────────────────────────────────────────────────┘
        │  after_commit :ms_perform_index_tasks  (create/update)
        │  after_commit(on: :destroy) :ms_enqueue_remove_from_index!
        ▼
┌──────────────────────────────────────────────────────────────────┐
│  enqueue proc → MeilisearchIndexJob.perform_later(               │
│                    record.class.name, record.id, remove)         │
│                                                                  │
│  MeilisearchIndexJob (Solid Queue, queue_as :meilisearch)        │
│    ├── record found → record.ms_index!(true) / .ms_remove_from_index!(true)   │
│    └── record gone  → klass.ms_remove_from_index!(klass.new(id:))│
│        (destroyed-record removal without AR load)                │
└──────────────────────────────────────────────────────────────────┘
        │  synchronous .await (waits for Meilisearch task)
        ▼
   Meilisearch server (docker compose service, port 7700)
         └── one index per model per env: Product_development, Branch_test, ...
```

### The Files

| File | Responsibility |
|------|----------------|
| `app/models/concerns/dynamic_search_concern.rb` | Declares the `meilisearch` block for every included model; computes attributes/settings per-model from `column_names` |
| `app/jobs/meilisearch_index_job.rb` | Async index/remove job (receives `model_name + id`, never a serialized record, so it survives destroy) |
| `app/models/concerns/user/search_concern.rb` | User — static field set (not a dynamic-property model), but same async pipeline: `synchronous: false` + `enqueue:` → `MeilisearchIndexJob` |
| `config/initializers/meilisearch.rb` | `Meilisearch::Rails.configuration` (URL + API key) |
| `docker-compose.yml` / `docker-compose.rspec-test.yml` | Meilisearch v1.53.1 service |

### The Concern (core logic)

`app/models/concerns/dynamic_search_concern.rb`:

```ruby
included do
  include Meilisearch::Rails

  standard_columns  = column_names & STANDARD_COLUMNS
  string_columns    = column_names & PROPERTY_STRING_COLUMNS
  number_columns    = column_names & (PROPERTY_INTEGER_COLUMNS + PROPERTY_DECIMAL_COLUMNS)
  boolean_columns   = column_names & PROPERTY_BOOLEAN_COLUMNS
  datetime_columns  = column_names & PROPERTY_DATETIME_COLUMNS

  indexed_attributes = standard_columns + string_columns + number_columns + boolean_columns + datetime_columns
  searchable_columns = (standard_columns & %w[name description code]) + string_columns + number_columns
  filterable_columns = (standard_columns & %w[company_id category_id branch_id workflow_status business_type]) +
    number_columns + boolean_columns + datetime_columns

  meilisearch(
    synchronous: false,
    enqueue: ->(record, remove) { MeilisearchIndexJob.perform_later(record.class.name, record.id, remove) }
  ) do
    attribute(*indexed_attributes)

    searchable_attributes searchable_columns
    filterable_attributes filterable_columns
  end
end
```

How it works:

- `column_names` is read on the **model class** when the concern is included; the local variables are captured by the settings block (`instance_exec`'d later by the gem). No per-model configuration needed.
- Models whose tables lack some columns (e.g. `Article` has no `property_*` columns at all) are handled automatically by the intersection — nothing extra to do.
- `synchronous: false` + the `enqueue:` proc route all indexing through `MeilisearchIndexJob`. This is the gem's documented `enqueue: :trigger_job` pattern.
- Typed values index natively: integers/decimals stay numeric (range filters like `property_integer_1 >= 30` work), booleans filter, datetimes filter as RFC3339 strings.

---

## 3. How Records Stay in Sync

Auto-sync is provided by the gem's callbacks, installed when the concern is included:

| Lifecycle event | Gem callback | What happens |
|-----------------|--------------|--------------|
| `create` / `update` (committed) | `after_commit :ms_perform_index_tasks` | Enqueues `MeilisearchIndexJob(model, id, remove: false)` |
| `destroy` (committed) | `after_commit(on: :destroy) :ms_enqueue_remove_from_index!` | Enqueues `MeilisearchIndexJob(model, id, remove: true)` |

`MeilisearchIndexJob` then:

1. `safe_constantize`s the model name (rejects unknown/non-AR names with `ArgumentError`).
2. If the record still exists → `record.ms_index!(true)` or `record.ms_remove_from_index!(true)`.
3. If the record was already destroyed → `klass.ms_remove_from_index!(klass.new(id: id), true)` — talks to the index directly, never loads from AR.

The `true` argument makes the call **synchronous** (`.await` on the Meilisearch task). Inside a background job this is correct — it guarantees the document exists before the job finishes (the record could be indexed then re-searched in the same request flow). The public commit path stays async (no request blocking).

> **Queue**: `queue_as :meilisearch`. `config/queue.yml` workers run `queues: "*"`, so no queue config change was needed.

### 3.1 Seed-time index wipe (`Seed::ApplicationService`)

Seeding wipes the DB with `delete_all`, which bypasses AR callbacks — the gem's auto-remove-from-index never fires, so stale docs from the previous seed would survive. The seeder therefore drops **every** Meilisearch index up front (right after `eager_load!`, before any record is created) and recreates each one empty:

```ruby
meili_client = Meilisearch::Rails.client
ApplicationRecord.descendants.select { |m| m.respond_to?(:ms_index_uid) }.each do |model|
  uid = model.ms_index_uid
  meili_client.delete_index(uid).await
  meili_client.create_index(uid, { primary_key: "id" }).await
  model.instance_variable_set(:@ms_indexes, nil) # forget the dropped index so the gem rebuilds it fresh
rescue StandardError => e
  Rails.logger.warn("[Seed] Meilisearch index delete failed for #{model}: #{e.message}")
end
```

- The awaited recreate is deliberate: the gem's own recreation (`SafeIndex.new`) is a fire-and-forget task whose **primary key is never awaited** — combined with a racing first write it can leave an index with `primaryKey: null`, and every document add then fails with `index_primary_key_multiple_candidates_found` (this bit the dev instance once). An empty recreated index is still fully "cleared"; the gem syncs settings (searchable/filterable) via `update_settings_if_changed` on the first write anyway.
- Failures per model are rescued + logged — a down Meilisearch never blocks seeding.
- Models covered = everything that includes `DynamicSearchConcern` **or** `User::SearchConcern` (anything responding to `ms_index_uid`).

---

## 4. Searching

All Meilisearch methods are available on any included model via the `ms_` prefix (the gem also aliases plain `search`, `index`, `reindex!`, `clear_index!`, `remove_from_index!` when no conflict exists).

### Basic search (returns AR objects)

```ruby
Product.ms_search("face cream")                       # typo-tolerant
Product.ms_search("face", filter: "company_id = #{company.id}")
Product.ms_search("", filter: "company_id = #{company.id} AND property_integer_1 >= 30")
Product.ms_search("face", sort: ["name:asc"])         # requires sortable_attributes (not set yet)
```

### Raw JSON hits (no AR load)

```ruby
Product.ms_raw_search("face cream")["hits"]           # array of document hashes
Product.ms_raw_search("", filter: "company_id = #{company.id}")["hits"]
```

### Multi-model search

```ruby
Meilisearch::Rails.multi_search(
  Product => { q: "face cream", filter: "company_id = #{company.id}" },
  Service => { q: "face cream", filter: "company_id = #{company.id}" }
)
```

### Tenant scoping is mandatory

Always pass `filter: "company_id = <id>"` — the indexes are shared across all companies. The `filterable_attributes` set already includes `company_id`, `category_id`, `branch_id`, `workflow_status`, `business_type`.

### Live caller: dynamic search/filter (Products + Customers, 2026-09-06)

`DynamicSearch::BaseQueryService` (`app/services/dynamic_search/base_query_service.rb`) is the request-path
consumer core; each wired page adds a 3-line subclass (`self.model`, `self.fallback_resource_name`) —
`Products::SearchQueryService`, `Customers::SearchQueryService`. Flow:

1. Reads the active TableConfig for the requested category and **whitelists** `q` + `filters[key]` params against the columns' `search`/`filter` settings (`docs/DYNAMIC_TABLE.md` §2.5). Disabled filters (`active: false`) never match the whitelist.
2. Builds the Meilisearch filter string (always `company_id`-scoped; half-open numeric/year buckets `key >= a AND key < b`, `key = true/false` for booleans, PM option values for enum ints).
3. Restricts keyword search to the configured columns via `attributes_to_search_on` (verified working through meilisearch-rails 0.16 → client 0.32, which camelizes the option).
4. Returns ids in relevance order; the controller feeds them into the existing pagy flow via `Model.where(id: ids).in_order_of(:id, ids)` — zero changes to the pagination contract. No `q`/`filters` params → the plain DB path (Meilisearch never called).
5. `Meilisearch::Error` → 503 `{ errors: [...] }` — never silent unfiltered results.

Specs: shared contract in `spec/support/shared_examples/dynamic_search_service.rb` (consumed by
`spec/services/{products,customers}/search_query_service_spec.rb`), page wiring in
`spec/requests/companies/{products,customers}_controller_spec.rb`, E2E in
`spec/features/companies/{products,customers}/search_filter_spec.rb`. Design:
`docs/superpowers/specs/2026-09-06-dynamic-search-filter-design.md`.

---

## 5. Updating the Index Schema (How To Change Settings)

The index schema is **derived from the concern** — there is no separate migration. The gem applies settings lazily on first index access and detects drift (`update_settings_if_changed` compares server settings with the block's settings on every `ms_ensure_init`).

### 5.1 Add a new searchable/filterable column

**Case A — a new `property_*` or standard column is added to tables**: no code change. `column_names & ...` picks it up automatically on the next sync.

**Case B — change *which* settings a model gets**: edit the concern's `searchable_columns` / `filterable_columns` computation.

**Case C — per-model overrides**: give the model its own `meilisearch` block after the concern include (the gem allows one block per model; the concern's block and the model's block combine via `additional_indexes` only if you use `add_index` — otherwise the model's own block replaces the settings for the primary index). Simpler: extend the concern with a configurable hook if you need variance.

Example — make a property sortable:

```ruby
# app/models/concerns/dynamic_search_concern.rb — inside the meilisearch block
sortable_attributes sortable_columns   # add a sortable_columns computation
```

### 5.2 Apply settings changes to Meilisearch

Settings live in the index, not the DB. After changing the concern:

```bash
bin/rails meilisearch:reindex[Product]   # gem rake task — recreates index settings + re-adds all docs
# or in code
Product.ms_reindex!                      # class-level, async
Product.ms_clear_index!                  # wipe index (settings persist)
```

The gem also auto-applies drifted settings on the next index touch (first write after a code change), but a `reindex!` is the reliable way to refresh settings + documents together.

### 5.3 Backfill existing records

Auto-sync only covers records created/updated **after** the concern ships. Existing rows must be reindexed once on deploy:

```bash
bin/rails meilisearch:reindex[Product]      # one class
bin/rails meilisearch:reindex               # all meilisearch models
```

or in a runner:

```ruby
DYNAMIC_SEARCH_MODELS.each { |klass| klass.ms_reindex! }
```

---

## 6. Testing

**File**: `spec/models/concerns/dynamic_search_concern_spec.rb` (+ `spec/support/shared_examples/dynamic_search.rb`, `spec/jobs/meilisearch_index_job_spec.rb`)

The suite requires a **running Meilisearch** (docker compose dev + CI both provide it). A `before(:all)` health check raises if the server is unreachable.

Key patterns:

- **Explicit indexing** — transactional fixtures suppress `after_commit`, so specs call `record.ms_index!(true)` directly instead of relying on auto-sync.
- **Index isolation** — `model_class.ms_clear_index!` in before/after hooks (Meilisearch lives outside the DB transaction).
- **Per-model coverage** — a shared example iterates all 46 dynamic models with a factory builder lambda, asserting: search by a dynamic property term + company-scoped filter isolation, numeric range filter, update-reflects-after-reindex, destroy-removes-document.
- **Jobs** — `MeilisearchIndexJob.perform_now` covers index via the enqueue path, destroyed-record removal, and unknown-model rejection.

```bash
bundle exec rspec spec/models/concerns/dynamic_search_concern_spec.rb spec/jobs/meilisearch_index_job_spec.rb
```

---

## 7. Making a New Model Searchable

1. The model must include `PropertyMappingConcern` (all dynamic models do). If it's a new model, add `include PropertyMappingConcern` **and** `include DynamicSearchConcern` (order: CategoryConcern → PropertyMappingConcern → DynamicSearchConcern).
2. That's it — settings, auto-sync, and job wiring come from the concern.
3. Add the model to `DYNAMIC_SEARCH_MODELS` in the spec with a record builder.
4. Reindex existing rows: `bin/rails meilisearch:reindex[NewModel]`.

To opt a model **out** of searchable: do not include the concern (or add `meilisearch auto_index: false, auto_remove: false` in the model's own block).

---

## 8. Configuration Reference

| Item | Value |
|------|-------|
| Gem | `meilisearch-rails` 0.16.0 (`Gemfile`) |
| Server | Meilisearch v1.53.1 (`docker-compose.yml`, port 7700) |
| URL | `MEILISEARCH_HOST` / credentials `meilisearch_host`, default `http://localhost:7700` |
| API key | `MEILISEARCH_API_KEY` / credentials `meilisearch_api_key`, default `skycom_master_key_password_2026` |
| Index UID | `ClassName_<env>` (e.g. `Product_development`) — `per_environment: true` |
| Queue | `meilisearch` (Solid Queue, `queues: "*"`) |
| `raise_on_failure` | not set (default false — failures log, don't raise) |

---

## 9. File Reference

| File | Purpose |
|------|---------|
| `app/models/concerns/dynamic_search_concern.rb` | The concern — meilisearch block + schema derivation |
| `app/jobs/meilisearch_index_job.rb` | Async index/remove job |
| `app/models/concerns/user/search_concern.rb` | User search — static attributes (email/username/name/first_name/last_name/phone_number searchable; system_role/country/workflow_status/business_type filterable), async via `MeilisearchIndexJob` |
| `config/initializers/meilisearch.rb` | Client configuration |
| `docker-compose.yml` (:143) / `docker-compose.rspec-test.yml` (:77) | Meilisearch services |
| `spec/models/concerns/dynamic_search_concern_spec.rb` | Connection + settings + 46-model search coverage |
| `spec/support/shared_examples/dynamic_search.rb` | Shared per-model search examples |
| `spec/jobs/meilisearch_index_job_spec.rb` | Job behaviors |
| `app/services/products/search_query_service.rb` | First live caller — TableConfig-driven search/filter query translation |
| `app/services/dynamic_search/base_query_service.rb` | Generic search/filter core (whitelist + filter-string building); pages subclass it — rollout: `docs/DYNAMIC_TABLE.md` §8 |
| `app/services/customers/search_query_service.rb` | Customers subclass (proof of the 3-line rollout) |
| `spec/support/shared_examples/dynamic_search_service.rb` | Shared behavioral contract for every subclass |
| `spec/services/products/search_query_service_spec.rb` | Whitelist + filter-string building + ms integration |
| `spec/requests/companies/products_controller_spec.rb` | Search path wiring (DB path unchanged, 503 on ms down) |
| `spec/features/companies/products/search_filter_spec.rb` | E2E: configured columns → input/dropdowns → results |
| `docs/MODEL_CALLBACKS.md` | `DynamicSearchConcern` callback documentation |
| `docs/superpowers/specs/2026-08-29-meilisearch-dynamic-search-design.md` | Design spec (uncommitted, gitignored) |
| `docs/superpowers/plans/2026-08-29-meilisearch-dynamic-search.md` | Implementation plan (uncommitted, gitignored) |

---

## 10. Common Pitfalls

| Pitfall | Explanation / Fix |
|---------|-------------------|
| Search returns nothing right after `ms_index!` | Async task not finished — use `ms_index!(true)` or re-search after the task completes. In jobs we always pass `true`. |
| Search for a partial term returns empty | Meilisearch matches whole words + prefix of the **last** word. Search the full stored token, or use `prefix`-friendly queries. |
| Filter on a non-filterable attribute errors | The attribute must be in `filterable_attributes` (computed from the concern). |
| Destroyed record still in index | The `enqueue:` proc passes `remove: true`; the job removes via `klass.ms_remove_from_index!(klass.new(id:))` without AR load. |
| Meilisearch down in dev | `docker compose up -d meilisearch`; tests raise a clear health-check error. |
| Adding a new property doesn't appear | Property column keys already indexed — just reindex (`ms_reindex!`) if you changed settings; data syncs automatically for new/updated records. |
| Document adds fail with `index_primary_key_multiple_candidates_found` | The index exists with `primaryKey: null` (created outside the gem, or by a racing recreation). Drop + recreate the index with a primary key, or re-seed (the seed wipe now does this). |

---

*End of document*