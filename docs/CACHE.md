# Skycom Cache System

## 1. Overview

Skycom uses a **3-tier server-side caching strategy** plus a **browser client cache** for frontend performance. The key architectural shift is that cross-instance cache consistency is achieved via **local reads + Redis pub/sub invalidation**, not per-request global reads.

### Server Cache Tiers

| Tier | Store | Backend | Scope | Consistency |
|------|-------|---------|-------|-------------|
| **Local Cache** | `Rails.local_cache` | Solid Cache (SQLite) | Per-server | No sync |
| **Sync Cache** | `Rails.sync_cache` | Solid Cache + Redis pub/sub | Cross-cluster | Reads: local; writes/delete: pub/sub invalidation |
| **Global Cache** | `Rails.global_cache` | Redis | Cross-cluster | Always consistent (centralized) |

### Client Cache

| Store | Backend | Scope |
|-------|---------|-------|
| `localStorage` | Browser | Per-device |

### Architecture Diagram

```
┌────────────────────────────────────────────────────────────┐
│                      Application                            │
│                                                             │
│  local_cache (SQLite)    sync_cache (SQLite+Redis)  global_cache (Redis)
│  ┌──────────────────┐   ┌──────────────────────┐   ┌──────────────┐
│  │  Solid Cache      │   │  Solid Cache (read)   │   │  Redis        │
│  │  (no sync)        │   │  + Redis pub/sub      │   │  (counters,   │
│  │                   │   │  (write/delete sync)  │   │   locks,      │
│  └──────────────────┘   └──────────────────────┘   │   limits)      │
│                                                     └──────────────┘
│         │                        │                        │
│         ▼                        ▼                        ▼
│  Per-server only          Cross-cluster via        Cross-cluster
│                           invalidation channel     (always Redis)
└────────────────────────────────────────────────────────────┘
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

**All reads hit local SQLite cache — no per-request Redis calls.** When a write or delete occurs, `sync_cache` broadcasts a lightweight invalidation message to a shared Redis pub/sub channel. All subscribed server instances evict the stale key from their local cache. This means:

- Every authenticated request does **zero** Redis calls for cache reads
- Cross-instance consistency is maintained via pub/sub, not polling
- Redis is only contacted on **cache mutations** (creates, updates, deletes), which are far less frequent than reads
- No `global_session_cache`, no per-request `exist?` checks

---

## 2. Tier 1: `Rails.local_cache`

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

**When to use**: Only when you are certain the cached data does not need to be consistent across server instances. Most application code should prefer `Rails.sync_cache`.

**API**: Standard `ActiveSupport::Cache::Store` interface — `read`, `write`, `delete`, `fetch`, `exist?`, `clear`.

---

## 3. Tier 2: `Rails.sync_cache` (The Core Pattern)

**Backend**: Solid Cache (SQLite) for reads + Redis pub/sub for write/delete invalidation.

**Purpose**: The default server-side cache. Records cached by `Cache::RecordsConcern` (Session, User, Company, Employee, RoleAppointment) use this tier, as do permissions hashes and billing dashboard data.

### 3.1 The SyncCache Class

**File**: `config/initializers/cache.rb`

```ruby
class SyncCache
  CHANNEL = "sync_cache:invalidation".freeze

  # Reads from local_cache only. No Redis call.
  def read(key)
    Rails.local_cache.read(key)
  end

  # Fetches from local_cache, caching the block result. No Redis call.
  def fetch(key, expires_in: nil, &block)
    Rails.local_cache.fetch(key, expires_in: expires_in, &block)
  end

  # Writes to local_cache and publishes invalidation (unless sync: false).
  def write(key, value, expires_in: nil, sync: true)
    Rails.local_cache.write(key, value, expires_in: expires_in)
    publish_invalidation("write", key) if sync
  end

  # Deletes from local_cache and publishes invalidation (unless sync: false).
  def delete(key, sync: true)
    Rails.local_cache.delete(key)
    publish_invalidation("delete", key) if sync
  end

  # Called by background listener when another instance publishes.
  def handle_invalidation(payload)
    data = JSON.parse(payload) rescue nil
    return unless data && data["key"]
    Rails.local_cache.delete(data["key"])
  end

  private

  def publish_invalidation(action, key)
    payload = { action: action, key: key }.to_json
    Kredis.redis.publish(CHANNEL, payload)
  end
end
```

### 3.2 Pub/Sub Background Listener

A background thread subscribes to the Redis invalidation channel and runs on Puma server processes (skipped in tests and rake tasks):

```ruby
if (defined?(Rails::Server) || defined?(Puma)) && !Rails.env.test?
  Thread.new do
    Rails.application.config.after_initialize do
      Kredis.redis.subscribe(SyncCache::CHANNEL) do |on|
        on.message do |_channel, message|
          Rails.sync_cache.handle_invalidation(message)
        end
      end
    rescue => e
      Rails.logger.error("[SyncCache Listener] Connection lost: #{e.message}")
      sleep 5
      retry
    end
  end
end
```

The listener is resilient — if the Redis connection drops, it logs the error, sleeps 5 seconds, and retries.

### 3.3 The `sync:` Parameter

Both `write` and `delete` accept a `sync:` keyword argument (default: `true`). Set `sync: false` to suppress pub/sub for local-only operations (e.g., bulk cache clearing during maintenance).

### 3.4 Cache::RecordsConcern Integration

**File**: `app/models/concerns/cache/records_concern.rb`

All ActiveRecord models that include `Cache::RecordsConcern` (Session, User, Company, Employee, RoleAppointment) automatically use `sync_cache` for both reads and writes:

```ruby
module Cache::RecordsConcern
  included do
    after_commit :write_attribute_cache, on: [ :create, :update ]
    after_commit :remove_attribute_cache, on: :destroy
  end

  class_methods do
    def cached_find(id, expires_in: DEFAULT_CACHE_EXPIRY)
      cache_key = "#{model_name.plural}_#{id}"
      attributes = Rails.sync_cache.fetch(cache_key, expires_in: expires_in) do
        find_by(id: id)&.attributes
      end
      return nil if attributes.blank?
      normalize_enum_attributes!(attributes)
      instantiate(attributes)
    end

    def cached_where(**filters)
      # ... similar pattern with query-hash cache key ...
      Rails.sync_cache.fetch(cache_key, expires_in: expires_in) do
        relation.map(&:attributes)
      end
    end
  end

  # Instance methods trigger cross-instance invalidation via sync_cache
  def write_attribute_cache
    Rails.sync_cache.write(cache_key, attributes)
  end

  def remove_attribute_cache
    Rails.sync_cache.delete(cache_key)
  end
end
```

When a model record is **created or updated**, the `after_commit` callback calls `Rails.sync_cache.write(...)`, which:
1. Writes attributes to the local SQLite cache
2. Publishes an invalidation message to Redis

When a model record is **destroyed**, the `after_commit` callback calls `Rails.sync_cache.delete(...)`, which:
1. Deletes from the local SQLite cache
2. Publishes an invalidation message to Redis

Other instances receive the invalidation message and evict only the stale key from their local cache. When they next read it, they fetch from the database and repopulate.

### 3.5 Session Authentication Flow

The old pattern required a Redis `exist?` check on every request. The new pattern reads only from `sync_cache`:

```ruby
def set_current_session
  token = cookies.signed[:session_token]
  return unless token

  # Pure L1 read (Local Cache + Pub/Sub invalidation on destroy/logout)
  session_record = Session.cached_find(token, expires_in: SESSION_CACHE_EXPIRY)

  unless session_record
    cleanup_invalid_session(token)
    return
  end

  Current.session = session_record
end
```

**Authentication requires zero Redis calls per request.** If the session was destroyed on another instance, the invalidation message already evicted it from this instance's local cache.

### 3.6 Cross-Instance Invalidation Scenarios

#### Scenario: User signs out on Instance A

```
Instance A                      Redis Pub/Sub                  Instance B
─────────                       ──────────────                  ──────────
session.destroy
  │
  └─ Cache::RecordsConcern
       remove_attribute_cache
         └─ Rails.sync_cache.delete("sessions_<id>")
              │
              ├─ local_cache.delete (Instance A)
              │
              └─ Redis PUBLISH "sync_cache:invalidation"
                   { action: "delete", key: "sessions_<id>" }
                                      │
                                      │  SUBSCRIBED
                                      ▼
                                 handle_invalidation(message)
                                   └─ local_cache.delete(key)
                                                             (milliseconds later)
                                                             AJAX request arrives
                                                               └─ Session.cached_find(token)
                                                                   └─ sync_cache MISS
                                                                   └─ DB query → nil
                                                                   └─ cleanup_invalid_session
```

#### Scenario: Session created on Instance A, request hits Instance B

```
Instance A                      Redis Pub/Sub                  Instance B
─────────                       ──────────────                  ──────────
session.create
  │
  └─ Cache::RecordsConcern
       write_attribute_cache
         └─ Rails.sync_cache.write("sessions_<id>", attrs)
              │
              ├─ local_cache.write (Instance A)
              │
              └─ Redis PUBLISH "sync_cache:invalidation"
                   { action: "write", key: "sessions_<id>" }
                                      │
                                      │  SUBSCRIBED
                                      ▼
                                 handle_invalidation(message)
                                   └─ local_cache.delete(key)
                                                             First request for this session
                                                               └─ Session.cached_find(token)
                                                                   └─ sync_cache MISS
                                                                   └─ DB query → found
                                                                   └─ cached locally + synced
```

The write-side invalidation ensures Instance B evicts any stale (pre-creation) value. If Instance B never had the key, the eviction is a no-op — no harm done.

### 3.7 Session Lifecycle

| Event | What Happens | Cache Effect |
|-------|-------------|--------------|
| **Sign in** | `user.sessions.create!` → `after_commit` fires | `sync_cache.write("sessions_<id>", attrs)` → local write + pub/sub |
| **Request** | `Session.cached_find(token)` | Pure local read — zero Redis calls |
| **Sign out** | `session.destroy` → `after_commit` fires | `sync_cache.delete("sessions_<id>")` → local delete + pub/sub |
| **TTL expiry** | `SESSION_CACHE_EXPIRY` (1 hour) passes | Local entry evicted automatically |

---

## 4. Tier 3: `Rails.global_cache`

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
# Order processing — atomic stock reservation via Kredis (backed by global_cache)
stock.available_counter.value = [ quantity - reserved_quantity, 0 ].max
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

## 5. Cache Constants

**File**: `config/initializers/constants.rb`

| Constant | Value | Purpose |
|----------|-------|---------|
| `DEFAULT_CACHE_EXPIRY` | 5 minutes | Default TTL for `cached_find` / `cached_where` |
| `SESSION_CACHE_EXPIRY` | 1 hour | Session record cache TTL (longer — sessions rarely change) |
| `PERMISSIONS_CACHE_EXPIRY` | 1 minute | Permissions hash cache TTL |
| `COOKIE_EXPIRY` | 1 day | Session and client cache cookie lifetime |

---

## 6. Client Cache (Browser)

Skycom also caches company data in the browser's `localStorage` for fast frontend access across all Stimulus controllers. This avoids repeated API calls for commonly used data.

### 6.1 What Gets Cached

The client cache stores: User, Companies, Branches, Departments, Roles, Enums, Employees, and Billing Contract Summary (enabled features for frontend gating).

### 6.2 Storage Keys

| Key | Description |
|-----|-------------|
| `client_cache_data` | JSON blob containing all cached data |
| `client_cache_version` | Version string for cache invalidation |
| `client_cache_sync_count` | Auto-sync counter (max 1, resets on version match) |

### 6.3 Backend Endpoint

**Route**: `GET /client_cache`

Returns `{ user, companies[], enums, employees[] }` and sets a `client_cache_version` cookie.

### 6.4 Frontend Controller

**File**: `app/javascript/controllers/client_cache_controller.js`

On page load:
1. Reads `client_cache_version` cookie and compares with localStorage
2. If mismatch or no cache → fetches `/client_cache`, stores in localStorage, reloads page
3. Max 1 auto-sync per page session (prevents loops)

### 6.5 Cache Helpers (`auth_helpers.js`)

| Helper | Description |
|--------|-------------|
| `currentUser()` | Current user object or null |
| `currentCompany()` | Active company or null |
| `currentBranches()` | Branches of current company |
| `currentRoles()` | Roles of current company |
| `Enums()` | All enum definitions |
| `featureEnabled(key)` | Checks if a feature is in `enabled_features` |
| `clearClientCache()` | Clears localStorage cache |

### 6.6 Manual Invalidation

**Frontend**: `clearClientCacheAndReload({ type: "success", message: "..." })` — clears cache and reloads page. Use after mutations that affect cached data (branch create, role change, feature toggle, etc.).

**Backend**: `company.invalidate_client_cache!` — bumps `company.updated_at`, changes the `client_cache_version` cookie, triggering a frontend re-sync on next page load.

### 6.7 Cookie Expiration

All cookies use 1-day expiration (`COOKIE_EXPIRY`):

| Cookie | Expiry | Purpose |
|--------|--------|---------|
| `session_token` | 1 day (HTTP-only, signed) | Rails session |
| `is_signed_in` | 1 day | Public auth state flag |
| `client_cache_version` | 1 day | Version stamp for cache comparison |

When cookies expire, the user must sign in again, which creates fresh cookies and a fresh cache.

### 6.8 How Model Changes Propagate to Client

```
PropertyMapping.create/update/destroy
  → belongs_to :company, touch: true
    → company.touch → company.updated_at changes
      → sync_client_cache_version updates cookie
        → ClientCacheController.sync() detects mismatch
          → re-fetches /client_cache → localStorage refreshed → page reloaded
```

Models with `belongs_to :company, touch: true`: Branch, Department, Category, PropertyMapping, TableConfig, Role.

---

## 7. Configuration

### 7.1 Initializer

**File**: `config/initializers/cache.rb`

Defines `Rails.local_cache`, `Rails.sync_cache`, and `Rails.global_cache`. Also starts the background pub/sub listener thread.

### 7.2 Redis Configuration

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

## 8. Comparison: When to Use Which

| Use Case | Cache Tier | Reason |
|----------|-----------|--------|
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

## 9. Testing

### 9.1 sync_cache Spec

**File**: `spec/system/sync_cache_spec.rb`

Tests cover:
- Basic write/read lifecycle
- Pub/sub invalidation on delete
- Incoming invalidation handling
- `Cache::RecordsConcern` integration (cached_find, auto-update, auto-evict)

### 9.2 Cache Helper

**File**: `spec/cache_helper.rb`

Clears all cache stores before each test:

```ruby
Rails.cache.clear
Rails.local_cache.clear
Rails.global_cache.clear
```

---

## 10. Error Handling

| Scenario | Effect | Mitigation |
|----------|--------|------------|
| Redis pub/sub unavailable at write | `publish_invalidation` rescues and logs error | Write still succeeds on local_cache; other instances may serve stale data until their TTL expires |
| Redis pub/sub connection lost (listener) | Background thread rescues, sleeps 5s, retries | Local reads unaffected; invalidation messages may be missed during window |
| Redis unavailable for `global_cache` | `Redis::BaseConnectionError` raised | Handle explicitly in calling code; stock reservation fails safely |
| Local cache (SQLite) unavailable | Solid Cache raises | Rare — indicates disk or database corruption |

### Redis Down — Safe Failure

- **Authentication continues** to work because session reads are local SQLite only
- **Cache writes** still succeed locally even if pub/sub broadcast fails
- **Stock reservations** fail safely (returns error, no incorrect decrements)
- **Invalidation** is best-effort — stale local entries eventually expire via TTL

---

## 11. File Reference

| File | Purpose |
|------|---------|
| `config/initializers/cache.rb` | `Rails.local_cache`, `Rails.sync_cache`, `Rails.global_cache` definitions + SyncCache class + pub/sub listener |
| `config/initializers/constants.rb` | `DEFAULT_CACHE_EXPIRY`, `SESSION_CACHE_EXPIRY`, `PERMISSIONS_CACHE_EXPIRY`, `COOKIE_EXPIRY` |
| `config/redis/shared.yml` | Redis connection configuration per environment |
| `app/models/concerns/cache/records_concern.rb` | `cached_find` / `cached_where` + auto-sync callbacks (uses `sync_cache`) |
| `app/controllers/concerns/application_controller/authentication_concern.rb` | `set_current_session` with `sync_cache` reads |
| `app/controllers/concerns/application_controller/cookie_concern.rb` | Session and client cache version cookies |
| `app/controllers/client_cache_controller.rb` | `/client_cache` JSON endpoint |
| `app/javascript/controllers/client_cache_controller.js` | Frontend client cache sync |
| `app/javascript/controllers/helpers/auth_helpers.js` | `currentUser()`, `currentCompany()`, `featureEnabled()`, etc. |

---

*End of file*
