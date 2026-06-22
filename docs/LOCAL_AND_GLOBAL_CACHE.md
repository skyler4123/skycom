# Skycom Local & Global Cache System

## 1. Overview

Skycom implements a **two-tier server-side caching strategy**:

| Tier | Store | Backend | Scope | Persistence |
|------|-------|---------|-------|-----------|
| **Local Cache** | `Rails.local_cache` | Solid Cache (SQLite) | Per-server | Durable (disk) |
| **Global Cache** | `Rails.global_cache` | Redis (in-memory) | Cross-cluster | Ephemeral (RAM) |

This separation allows per-server cached data (computation results, compiled aggregates) to live in local SQLite, while cross-server state (distributed locks, rate limits, shared counters) lives in Redis.

---

## 2. Architecture

```
┌──────────────────────────────────────────────────────┐
│                    Application                        │
│                                                       │
│   Rails.local_cache         Rails.global_cache        │
│   ┌──────────────────┐     ┌──────────────────┐      │
│   │  Solid Cache      │     │  Redis Cache      │      │
│   │  (SQLite)         │     │  (In-Memory)      │      │
│   │  storage/*.sqlite3│     │  redis://...:6379 │      │
│   └────────┬─────────┘     └────────┬──────────┘      │
│            │                        │                  │
│            ▼                        ▼                  │
│     Single-server only       Shared across cluster     │
└──────────────────────────────────────────────────────┘
```

### Key Principles

- **Local cache first**: Prefer `Rails.local_cache` for any data that doesn't need to be shared across servers
- **Global cache for shared state**: Use `Rails.global_cache` only when data must be consistent across all servers in a cluster
- **No automatic fallback**: If Redis is down, `Rails.global_cache` operations raise errors — handle them explicitly

---

## 3. Configuration

### Initializer

**File**: `config/initializers/local_and_global_cache.rb`

```ruby
module Rails
  class << self
    def local_cache
      @local_cache ||= ActiveSupport::Cache.lookup_store(:solid_cache_store)
    end

    def global_cache
      @global_cache ||= begin
        redis_config = Rails.application.config_for("redis/shared").symbolize_keys
        ActiveSupport::Cache.lookup_store(:redis_cache_store, redis_config)
      end
    end
  end
end
```

Both methods use `||=` memoization, so the cache stores are initialized once per process lifetime.

### Redis Configuration

**File**: `config/redis/shared.yml`

```yaml
production: &production
  url: <%= Rails.application.credentials.dig(:redis_url_production) || "redis://127.0.0.1:6379/0" %>
  timeout: 1

development:
  url: <%= Rails.application.credentials.dig(:redis_url_development) || "redis://127.0.0.1:6379/0" %>
  timeout: 1

test:
  url: <%= Rails.application.credentials.dig(:redis_url_test) || "redis://127.0.0.1:6379/0" %>
  timeout: 1
```

Each environment defaults to `redis://127.0.0.1:6379/0` with optional credentials override.

### Solid Cache (Local)

Solid Cache is configured via the standard Rails database config:
- **Development**: `storage/development_cache.sqlite3`
- **Test**: `storage/test_cache.sqlite3`
- **Production**: `storage/production_cache.sqlite3`

---


## 4. Usage

Both `Rails.local_cache` and `Rails.global_cache` expose the standard `ActiveSupport::Cache::Store` API:

### Read / Write / Delete

```ruby
# Local cache (SQLite)
Rails.local_cache.write("my_key", "hello")
Rails.local_cache.read("my_key")   # => "hello"
Rails.local_cache.delete("my_key")

# Global cache (Redis)
Rails.global_cache.write("shared_key", 42)
Rails.global_cache.read("shared_key")   # => 42
Rails.global_cache.delete("shared_key")
```

### Fetch (Computed Cache)

```ruby
# Block is evaluated and cached if key is missing
result = Rails.local_cache.fetch("expensive_computation", expires_in: 1.hour) do
  perform_expensive_calculation
end
```

### Fetch Multi

```ruby
Rails.local_cache.write("a", 1)
Rails.local_cache.write("b", 2)
Rails.local_cache.fetch_multi("a", "b", "c") do |key|
  key * 10  # only "c" is fresh, computed as 30
end
# => { "a" => 1, "b" => 2, "c" => 30 }
```

### Key Existence

```ruby
Rails.local_cache.write("key", "val")
Rails.local_cache.exist?("key")   # => true
Rails.local_cache.delete("key")
Rails.local_cache.exist?("key")   # => false
```

### Clear Cache

```ruby
Rails.local_cache.clear   # Wipes all local SQLite cache entries
Rails.global_cache.clear  # Wipes all Redis cache entries (use with caution!)
```

---

## 5. When to Use Which

| Use Case | Cache | Reason |
|----------|-------|--------|
| Computation result caching | `local_cache` | Each server computes its own |
| Compiled report data | `local_cache` | Per-server, no need to share |
| Session-scoped ephemeral data | `local_cache` | Tied to a single request/server |
| Cross-server distributed locks | `global_cache` | Must be visible to all servers |
| Rate limiting counters | `global_cache` | Shared across cluster |
| Kredis-backed counters | `global_cache` | Kredis uses Redis natively |
| Shared feature flags | `global_cache` | Consistent state across servers |
| Order stock reservations | `global_cache` (via Kredis) | Atomic DECRBY across processes |

---

## 6. Error Handling

`Rails.global_cache` operations raise `Redis::BaseConnectionError` subclasses when Redis is unavailable. Handle these explicitly:

```ruby
begin
  Rails.global_cache.fetch("key", expires_in: 60) { expensive_call }
rescue Redis::BaseConnectionError => e
  Rails.logger.warn("Redis unavailable: #{e.message}")
  expensive_call  # fallback: compute directly
end
```

`Rails.local_cache` (SQLite via Solid Cache) is more resilient — errors are rare and typically indicate disk or database issues.

---

## 7. Testing

**File**: `spec/system/local_and_global_cache_spec.rb`

System tests verify both cache stores work correctly:
- `Rails.local_cache` read/write/delete lifecycle
- `Rails.global_cache` read/write/delete lifecycle
- `Rails.local_cache.fetch` with block-based computation
- `Rails.global_cache.fetch` with block-based computation
- Store independence (same key in both caches holds different values)
- Key existence checks

### Test Cleanup

Both caches are cleared before each test run in `spec/cache_helper.rb`:

```ruby
Rails.cache.clear
Rails.local_cache.clear
Rails.global_cache.clear
```

---

## 8. Comparison: Client Cache vs Server Cache

| Aspect | Client Cache (browser) | Local Cache (server) | Global Cache (server) |
|--------|-----------------------|---------------------|----------------------|
| **Storage** | `localStorage` | Solid Cache (SQLite) | Redis (RAM) |
| **Scope** | Per-browser | Per-server | Cross-cluster |
| **Access from** | JavaScript (Stimulus) | Ruby (Rails) | Ruby (Rails) |
| **Doc** | `docs/CACHE.md` | `docs/LOCAL_AND_GLOBAL_CACHE.md` | `docs/LOCAL_AND_GLOBAL_CACHE.md` |

---

## 9. Related Documentation

- `docs/CACHE.md` — Client-side browser cache (localStorage)
- `docs/ORDER_PROCESSING_V1.md` — Kredis counters used for stock reservation
- `config/initializers/local_and_global_cache.rb` — Initializer source
- `config/redis/shared.yml` — Redis configuration per environment

---

*End of file*
