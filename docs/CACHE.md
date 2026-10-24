# Skycom Cache System

## 1. Overview

Skycom uses a **4-tier server-side caching strategy** plus a **browser client cache** for frontend performance. The key architectural shift is that cross-instance cache consistency is achieved via **local reads + Redis pub/sub invalidation**, not per-request global reads.

### Server Cache Tiers

| Tier | Store | Backend | Scope | Consistency |
|------|-------|---------|-------|-------------|
| **RAM Cache** | `Rails.ram_cache` | MemoryStore (Ruby heap, 64 MB) | Per-worker | No sync (volatile) |
| **Local Cache** | `Rails.local_cache` | Solid Cache (SQLite) | Per-server | No sync |
| **Sync Cache** | `Rails.sync_cache` | Solid Cache + Redis pub/sub | Cross-cluster | Reads: local; writes/delete: pub/sub invalidation |
| **Global Cache** | `Rails.global_cache` | Redis | Cross-cluster | Always consistent (centralized) |

| Feature | `Rails.ram_cache` (MemoryStore) | `Rails.local_cache` (Solid Cache) |
|---------|---------------------------------|-----------------------------------|
| Backend | Ruby heap / RAM | Local SQLite file |
| Speed | Nanoseconds / microseconds | Milliseconds |
| Persistence | Wiped on restart | Persists across restarts |
| Multi-worker scope | Isolated per worker process | Shared across workers on same host |
| Risk | High RAM consumption / OOM risk | Disk space usage |
| Best used for | Tiny hot-keys, app configs, feature flags, high-frequency boolean checks (e.g. `Employee#owner_role?`, 1.day TTL) | Larger query results, generated fragments, items that shouldn't vanish on deploy |

### Client Cache

| Store | Backend | Scope |
|-------|---------|-------|
| `localStorage` | Browser | Per-device |

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                       Application                                       │
│                                                                                         │
│     ram_cache             local_cache             sync_cache            global_cache    │
│┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐│
││   MemoryStore    │   │   Solid Cache    │   │   Solid Cache    │   │      Redis       ││
││    per-worker    │   │    per-server    │   │ + Redis pub/sub  │   │ counters, locks, ││
││     volatile     │   │     no sync      │   │   invalidation   │   │      limits      ││
││  tiny hot-keys   │   │                  │   │                  │   │                  ││
│└──────────────────┘   └──────────────────┘   └──────────────────┘   └──────────────────┘│
│         │                      │                      │                      │          │
│         ▼                      ▼                      ▼                      ▼          │
│  Per-worker only        Per-server only       Cross-cluster via        Cross-cluster    │
│ (wiped on restart)                               invalidation          (always Redis)   │
│                                                    channel                              │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                              │
                   Redis PUBLISH "sync_cache:invalidation"
                              │
                              ▼
                    ┌─────────────────────┐
                    │  Other Server        │
                    │  Instances           │
                    │  SUBSCRIBE + evict   │
                    └─────────────────────┘
```

### The Core Principle

**All `sync_cache` reads hit the local SQLite cache — no per-request Redis calls.** When a write or delete occurs, `sync_cache` broadcasts a lightweight invalidation message to a shared Redis pub/sub channel. All subscribed server instances evict the stale key from their local cache. This means:

- Every authenticated request does **zero** Redis calls for cache reads
- Cross-instance consistency is maintained via pub/sub, not polling
- Redis is only contacted on **cache mutations** (creates, updates, deletes), which are far less frequent than reads
- No `global_session_cache`, no per-request `exist?` checks

---

## 2. Tier 1: `Rails.ram_cache`

**Backend**: `ActiveSupport::Cache::MemoryStore` (Ruby heap, 64 MB cap) — defined in `config/initializers/cache.rb`.

**Purpose**: The fastest tier — a pure process-level cache for **tiny hot-keys** read on high-frequency paths. No SQLite I/O, no network.

| Property | Value |
|----------|-------|
| Speed | Nanoseconds / microseconds (heap access) |
| Scope | Per Puma worker — workers do **not** share entries |
| Persistence | Wiped on restart / deploy |
| Risk | High RAM consumption — 64 MB cap; keep values tiny |

**When to use**: booleans, feature flags, small configs — any scalar read on every request where per-worker divergence is harmless. Store the *result* of hot computations (bytes), never collections of records.

**When NOT to use**: anything larger than a few KB, or state that must agree across workers/instances — use `local_cache` (Tier 2) or `sync_cache` (Tier 3) instead.

### 2.1 Not wrapped by `sync_cache` — call it directly

`Rails.ram_cache` is deliberately **not** wrapped by `SyncCache` (`config/initializers/cache.rb`): per-worker isolation is acceptable for tiny immutable-ish values, and a pub/sub round-trip on every read would defeat the point. Call `Rails.ram_cache.fetch(...)` / `.delete(...)` directly.

### 2.2 Invalidation model

- **Local eviction**: the code that owns the value deletes its key when the source of truth changes (e.g., `Employee#clear_permissions_cache`).
- **Best-effort cross-worker eviction**: the `sync_cache` pub/sub listener (`SyncCache#handle_invalidation`) also deletes the key from `Rails.ram_cache` — a broadcast `delete` clears the key from both `ram_cache` and `local_cache` on every subscribed instance.
- **TTL backstop**: every entry has an `expires_in`; stale entries die on their own. Restarts/deploys wipe the whole store — safe, because entries rebuild lazily from the block.

### 2.3 Canonical example: `Employee#owner_role?`

**File**: `app/models/concerns/employee/permission_concern.rb`

```ruby
OWNER_ROLE_CACHE_EXPIRY = 1.day

def owner_role?
  Rails.ram_cache.fetch("#{cache_key_with_version}/owner_role", expires_in: OWNER_ROLE_CACHE_EXPIRY) do
    EmployeeRoleAppointment.where(employee_id: id).any? { |ra| ra.business_type == OWNER_BUSINESS_TYPE }
  end
end
```

- Read on **every** `can?` permission check → hot path.
- The value is a single boolean (bytes).
- Owner assignment is immutable after creation, so per-worker divergence is harmless.
- `cache_key_with_version` includes `updated_at` — any `touch` (e.g., role assignment) produces a new key; the old entry ages out via TTL.
- Explicit eviction: `clear_permissions_cache` deletes the key (plus the `local_cache` permission keys) and touches the record.

**API**: standard `ActiveSupport::Cache::Store` interface — `read`, `write`, `delete`, `fetch`, `exist?`, `clear`.

---

## 3. Tier 2: `Rails.local_cache`

**Backend**: Solid Cache (SQLite) — per-server, durable on disk.

**Purpose**: Cached data that doesn't need cross-instance synchronization. Computation results, compiled aggregates, session-scoped ephemeral data.

```ruby
Rails.local_cache.fetch("expensive_report", expires_in: 1.hour) do
  perform_expensive_calculation
end
```

Solid Cache database files per environment:
- Development: `storage/development_cache.sqlite3`
- Test: `storage/test_cache.sqlite3`
- Production: `storage/production_cache.sqlite3`

**When to use**: Only when you are certain the cached data does not need to be consistent across server instances. Tiny hot booleans belong in `Rails.ram_cache` (Tier 1). Most application code should prefer `Rails.sync_cache`.

**API**: Standard `ActiveSupport::Cache::Store` interface — `read`, `write`, `delete`, `fetch`, `exist?`, `clear`.

---

## 4. Tier 3: `Rails.sync_cache` (The Core Pattern)

**Backend**: Solid Cache (SQLite) for reads + Redis pub/sub for write/delete invalidation.

**Purpose**: The default server-side cache. Used for scalar values such as the cookie cache version and other independent cached data. (The custom `Cache::RecordsConcern` record-cache layer has been removed; records are loaded via normal DB queries.)

### 4.1 The SyncCache Class

**File**: `config/initializers/cache.rb`

```ruby
class SyncCache
  CHANNEL = "sync_cache:invalidation".freeze

  # Fetches from local_cache, caching the block result. No Redis call.
  def fetch(key, expires_in: nil, &block)
    Rails.local_cache.fetch(key, expires_in: expires_in, &block)
  end

  # Direct local_cache read. No Redis call.
  def read(key)
    Rails.local_cache.read(key)
  end

  # Writes to local_cache and, when sync: true (default), publishes
  # an invalidation message so other instances evict their stale copy.
  def write(key, value, expires_in: nil, sync: true)
    Rails.local_cache.write(key, value, expires_in: expires_in)
    publish_invalidation("write", key) if sync
  end

  # Deletes from local_cache and, when sync: true (default), publishes
  # an invalidation message so other instances do the same.
  def delete(key, sync: true)
    Rails.local_cache.delete(key)
    publish_invalidation("delete", key) if sync
  end

  # Called by the background listener when an invalidation message arrives
  # from another instance. Evicts the stale key from ram_cache (best-effort,
  # per-worker) and local_cache.
  def handle_invalidation(payload)
    data = JSON.parse(payload) rescue nil
    return unless data && data["key"]

    key = data["key"]
    Rails.ram_cache.delete(key)
    Rails.local_cache.delete(key)
  rescue => e
    Rails.logger.error("[SyncCache] Invalidation handling error: #{e.message}")
  end

  private

  # Publishes a write/delete event to the shared Redis channel.
  def publish_invalidation(action, key)
    payload = { action: action, key: key }.to_json
    Kredis.redis.publish(CHANNEL, payload)
  rescue => e
    Rails.logger.error("[SyncCache] Failed to publish invalidation: #{e.message}")
  end
end
```

> **Note**: `Rails.ram_cache` is deliberately **not** wrapped by `SyncCache` — call it directly for tiny per-worker hot-keys (Tier 1). The invalidation listener still evicts ram_cache keys best-effort, so a broadcast `delete` clears both stores.

### 4.2 Pub/Sub Background Listener

A background thread subscribes to the Redis invalidation channel in web-server processes only (Puma — skipped for tests, console, and rake tasks), using a **dedicated** Redis connection so pub/sub never hijacks the shared app pool:

```ruby
Rails.application.config.after_initialize do
  # Only in web server processes — bypassed for CLI tasks (rake, console, rspec).
  is_server = defined?(Rails::Server) ||
              $PROGRAM_NAME.include?("puma") ||
              $PROGRAM_NAME.include?("bin/rails server")

  is_cli_or_test = Rails.env.test? ||
                   defined?(Rails::Console) ||
                   File.basename($PROGRAM_NAME) == "rake"

  if is_server && !is_cli_or_test
    Thread.new do
      # CRITICAL: dedicated connection — reusing Kredis.redis would hijack
      # the shared app connection pool.
      redis_sub = Kredis.redis.dup

      loop do
        redis_sub.subscribe(SyncCache::CHANNEL) do |on|
          on.message do |_channel, message|
            Rails.sync_cache.handle_invalidation(message)
          end
        end
      rescue => e
        Rails.logger.error("[SyncCache Listener] Connection lost: #{e.message}")
        sleep 5
      end
    end
  end
end
```

The listener is resilient — if the Redis connection drops, it logs the error, sleeps 5 seconds, and retries.

### 4.3 The `sync:` Parameter

Both `write` and `delete` accept a `sync:` keyword argument (default: `true`). Set `sync: false` to suppress pub/sub for local-only operations (e.g., bulk cache clearing during maintenance).

### 4.4 Record cache (replacement for removed Cache::RecordsConcern)

The old `Cache::RecordsConcern` (`cached_find` / `cached_where`) was removed in
commit `8abe53c`. It is replaced by a **record cache** backed by
`Rails.sync_cache`:

- `Session` stores a compact hash (`id`, `user_id`) — no AR needed on the hot
  path.
- `User`, `Company`, and `Employee` store their full `attributes` hash and are
  re-instantiated via `Model.instantiate` on a cache hit, eliminating the
  per-request `User Load` / `Company Load` / `Employee Load` queries. Callers
  keep using ActiveRecord objects/associations unchanged.
- Keys are unversioned (`users_#{id}`, `companies_#{id}`,
  `employees_#{user_id}_#{company_id}`, `sessions_#{id}`); writes overwrite the
  same key and deletes propagate via pub/sub. TTLs: Session 1 hour, others 5
  minutes.
- `after_commit :refresh_cache` / `:remove_cache` on each model keep entries fresh.
- The `cache_version` aggregate (`Company.where(user:).maximum(:updated_at)`) is
  also cached per user under `user_#{id}:companies_max_updated_at` and
  invalidated on Company create/update/destroy.

`Rails.sync_cache` remains available for other scalar cached values (e.g. the
cookie cache version in `CookieConcern`). See `docs/MODEL_CALLBACKS.md` for the
callback list.

### 4.5 Session Authentication Flow

Session authentication now uses a normal DB lookup:

```ruby
session_record = Session.find_by(id: token)
```

No `sync_cache` read or invalidation is involved for sessions.

---

## 5. Tier 4: `Rails.global_cache`
## 5. Tier 4: `Rails.global_cache`

**Backend**: Redis (in-memory, cross-cluster).

**Purpose**: Atomic distributed state that must be consistent across all servers in real time. Used where the cache itself is the source of truth, not a performance layer over a database.

### When to Use

| Use Case | Example |
|----------|---------|
| Distributed locks | Prevent concurrent operations across instances |
| Rate limiting counters | Shared per-IP or per-user counters |
| Kredis-backed stock counters | `Stock.available_counter` for atomic DECRBY |
| Feature flags requiring instant rollback | Immediate propagation across cluster |

### Example

```ruby
# Order processing — atomic reservation via the model wrapper (docs/KREDIS.md)
stock.reserve_stock!(quantity)   # atomic decrement + DB pending increment; false when insufficient
```

### Error Handling

`Rails.global_cache` operations raise `Redis::BaseConnectionError` when Redis is unavailable:

```ruby
begin
  Rails.global_cache.fetch("key", expires_in: 60) { expensive_call }
rescue Redis::BaseConnectionError => e
  Rails.logger.warn("Redis unavailable: #{e.message}")
  expensive_call
end
```

When Redis is down, order processing stock reservations fail safely (no incorrect reservations), while core app reads continue unaffected via `sync_cache` and `local_cache`.

---

## 6. Cache Constants

Per the `docs/CONSTANTS.md` convention, single-file constants live at their usage site. Only multi-file constants remain in `config/initializers/constants.rb`.

| Constant | Value | Defined In | Purpose |
|----------|-------|------------|---------|
| `DEFAULT_CACHE_EXPIRY` | (removed) | `Cache::RecordsConcern` removed | No longer used |
| `SESSION_CACHE_EXPIRY` | 1 hour | `app/controllers/concerns/application_controller/authentication_concern.rb` | Session record cache TTL (longer — sessions rarely change) |
| `PERMISSIONS_CACHE_EXPIRY` | 1 minute | `config/initializers/constants.rb` | Permissions hash cache TTL (used by both permission concerns) |
| `OWNER_ROLE_CACHE_EXPIRY` | 1 day | `app/models/concerns/employee/permission_concern.rb` | `ram_cache` TTL for the `Employee#owner_role?` hot boolean |
| `COOKIE_EXPIRY` | 1 day | `app/controllers/concerns/application_controller/cookie_concern.rb` | Session and client cache cookie lifetime |

---

## 7. Client Cache (Browser)

Skycom also caches company data in the browser's `localStorage` for fast frontend access across all Stimulus controllers. This avoids repeated API calls for commonly used data.

### 7.1 What Gets Cached

The client cache stores: User, Companies, Branches, Departments, Roles, Enums, Employees, Company Settings (incl. the active sidebar record), and Billing Contract Summary (enabled features for frontend gating).

### 7.2 Storage Keys

| Key | Description |
|-----|-------------|
| `client_cache_data` | JSON blob containing all cached data (user, companies, branches, departments, roles, categories, property_mappings, table_configs, employees, company_settings) |
| `client_cache_version` | Version string for cache invalidation |
| `client_cache_sync_count` | Auto-sync counter (max 1, resets on version match) |
| `sidebar_favourites_<company_id>_<user_id>` | Per-employee favourited sidebar item keys (FE-only, `docs/SIDEBAR.md`) |
| `sidebar_open_groups_<company_id>_<user_id>` | Per-employee open sidebar group keys (FE-only, `docs/SIDEBAR.md`) |

### 7.3 Backend Endpoint

**Route**: `GET /client_cache`

Returns `{ user, companies[], employees[] }` and sets a `client_cache_version` cookie. Enums are now static in `app/javascript/controllers/helpers/enums.js`.

### 7.4 Frontend Controller

**File**: `app/javascript/controllers/client_cache_controller.js`

On page load:
1. Reads `client_cache_version` cookie and compares with localStorage
2. If mismatch or no cache → fetches `/client_cache`, stores in localStorage, reloads page
3. Max 1 auto-sync per page session (prevents loops)

### 7.5 Cache Helpers (`auth_helpers.js`)

| Helper | Description |
|--------|-------------|
| `currentUser()` | Current user object or null |
| `currentCompany()` | Active company or null |
| `currentBranches()` | Branches of current company |
| `currentRoles()` | Roles of current company |
| `currentCategories()` | Categories of current company |
| `currentSettings()` | Company settings of current company (active sidebar record) |
| `currentEmployee()` | Current employee (company + user match) or null |
| `ENUMS` | Static enum definitions (from `enums.js`, not client cache) |
| `featureEnabled(key)` | Checks if a feature is in `enabled_features` |
| `clearClientCache()` | Clears localStorage cache |

### 7.6 Manual Invalidation

**Frontend**: `clearClientCacheAndReload({ type: "success", message: "..." })` — clears cache and reloads page. Use after mutations that affect cached data (branch create, role change, feature toggle, etc.).

**Backend**: `company.invalidate_client_cache!` — bumps `company.updated_at`, changes the `client_cache_version` cookie, triggering a frontend re-sync on next page load.

### 7.7 Cookie Expiration

All cookies use 1-day expiration (`COOKIE_EXPIRY`):

| Cookie | Expiry | Purpose |
|--------|--------|---------|
| `session_token` | 1 day (HTTP-only, signed) | Rails session |
| `is_signed_in` | 1 day | Public auth state flag |
| `client_cache_version` | 1 day | Version stamp for cache comparison |

When cookies expire, the user must sign in again, which creates fresh cookies and a fresh cache.

### 7.8 How Model Changes Propagate to Client

```
PropertyMapping.create/update/destroy
  → belongs_to :company, touch: true
    → company.touch → company.updated_at changes
      → sync_client_cache_version updates cookie
        → ClientCacheController.sync() detects mismatch
          → re-fetches /client_cache → localStorage refreshed → page reloaded
```

Models with `belongs_to :company, touch: true`: Branch, Department, Category, PropertyMapping, TableConfig, Role, CompanySetting.

---

## 8. Configuration

### 8.1 Initializer

**File**: `config/initializers/cache.rb`

Defines `Rails.ram_cache`, `Rails.local_cache`, `Rails.sync_cache`, and `Rails.global_cache`. Also starts the background pub/sub listener thread.

### 8.2 Redis Configuration

**File**: `config/redis/shared.yml`

```yaml
production: &production
  url: <%= Rails.application.credentials.dig(:redis_url_production) || "redis://127.0.0.1:6379/0" %>
  timeout: 1

development: &development
  url: redis://127.0.0.1:6379/0
  timeout: 1

test:
  url: redis://127.0.0.1:6379/0
  timeout: 1
```

---

## 9. Comparison: When to Use Which

| Use Case | Cache Tier | Reason |
|----------|-----------|--------|
| `Employee#owner_role?` hot boolean (read on every permission check) | `ram_cache` | Tiny per-worker value; TTL + best-effort pub/sub eviction |
| Tiny hot scalars (flags, configs, booleans) | `ram_cache` | Nanosecond reads; per-worker isolation harmless |
| ActiveRecord record caching (Session, User, Company, Employee) | `sync_cache` | Local reads, pub/sub on mutation |
| Permissions hashes | `sync_cache` | Cross-instance consistency needed |
| Billing dashboard JSON | `sync_cache` | Avoids stale per-server caches |
| Computation results | `local_cache` | Each server computes its own |
| Session-scoped ephemeral data | `local_cache` | No need to share |
| Order stock reservation counters | `global_cache` (Kredis) | Atomic DECRBY across processes |
| Rate limiting | `global_cache` | Shared across cluster |
| Distributed locks | `global_cache` | Must be visible to all servers |
| Frontend company/employee data | `localStorage` (client) | Browser-side access |

---

## 10. Testing

### 10.1 sync_cache Spec

**File**: `spec/system/sync_cache_spec.rb`

Tests cover:
- Basic write/read lifecycle
- Pub/sub invalidation on delete
- Incoming invalidation handling
- (Cache::RecordsConcern integration removed; records load via normal DB queries)

ram_cache coverage: `spec/models/employee_owner_role_spec.rb` — caches `true`/`false` values and evicts on `clear_permissions_cache`.

### 10.2 Cache Helper

**File**: `spec/cache_helper.rb`

Clears all cache stores before each test:

```ruby
Rails.cache.clear              rescue nil
Rails.ram_cache.clear          rescue nil
Rails.local_cache.clear        rescue nil
Rails.global_cache.clear       rescue nil
```

---

## 11. Error Handling

| Scenario | Effect | Mitigation |
|----------|--------|------------|
| Redis pub/sub unavailable at write | `publish_invalidation` rescues and logs error | Write still succeeds on local_cache; other instances may serve stale data until their TTL expires |
| Redis pub/sub connection lost (listener) | Background thread rescues, sleeps 5s, retries | Local reads unaffected; invalidation messages may be missed during window |
| Redis unavailable for `global_cache` | `Redis::BaseConnectionError` raised | Handle explicitly in calling code; stock reservation fails safely |
| Local cache (SQLite) unavailable | Solid Cache raises | Rare — indicates disk or database corruption |
| `ram_cache` wiped on restart/deploy | All per-worker entries lost together | By design — entries rebuild lazily from the block on next read (TTL backstop) |
| Large values stored in `ram_cache` | High Ruby heap usage → OOM risk (64 MB cap) | Keep values tiny (booleans/scalars); use `local_cache` for larger payloads |

### Redis Down — Safe Failure

- **Authentication continues** to work because session reads are local SQLite only
- **Cache writes** still succeed locally even if pub/sub broadcast fails
- **ram_cache reads** are pure local heap access — unaffected by Redis availability
- **Stock reservations** fail safely (returns error, no incorrect decrements)
- **Invalidation** is best-effort — stale local entries eventually expire via TTL

---

## 12. File Reference

| File | Purpose |
|------|---------|
| `config/initializers/cache.rb` | `Rails.ram_cache`, `Rails.local_cache`, `Rails.sync_cache`, `Rails.global_cache` definitions + SyncCache class + pub/sub listener |
| `app/models/concerns/employee/permission_concern.rb` | `Employee#owner_role?` ram_cache usage + `OWNER_ROLE_CACHE_EXPIRY` + `clear_permissions_cache` eviction |
| `spec/models/employee_owner_role_spec.rb` | ram_cache caching + eviction specs |
| `config/initializers/constants.rb` | `PERMISSIONS_CACHE_EXPIRY` |
| `config/redis/shared.yml` | Redis connection configuration per environment |
| (removed) `app/models/concerns/cache/records_concern.rb` | Custom record cache layer removed |
| `app/controllers/concerns/application_controller/authentication_concern.rb` | `set_current_session` with normal DB lookup |
| `app/controllers/concerns/application_controller/cookie_concern.rb` | Session and client cache version cookies + `COOKIE_EXPIRY` |
| `app/controllers/client_cache_controller.rb` | `/client_cache` JSON endpoint |
| `app/javascript/controllers/client_cache_controller.js` | Frontend client cache sync |
| `app/javascript/controllers/helpers/auth_helpers.js` | `currentUser()`, `currentCompany()`, `featureEnabled()`, etc. |

---

*End of file*
