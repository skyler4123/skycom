# Skycom Authentication System

## 1. Architecture

Skycom's authentication session caching uses the **`sync_cache` pattern**: local SQLite reads for all requests, with Redis pub/sub only for write/delete invalidation across instances.

### Cache Tiers

| Tier | Store | Backend | Scope | What It Stores |
|------|-------|---------|-------|----------------|
| **Sync cache** | `Rails.sync_cache` | Solid Cache + Redis pub/sub | Cross-cluster | Session/User/Company/Employee record objects |

### Data Flow Diagram

```
                    ┌──────────────────────────────────────────┐
                    │         Rails.sync_cache                 │
                    │  (Solid Cache SQLite + Redis pub/sub)    │
                    │                                          │
                    │  - Session cached_find (pure local read) │
                    │  - User cached_find (pure local read)    │
                    │  - Company cached_find (pure local read) │
                    │  - Employee cached_find (pure local read)│
                    │  - Permissions hashes                    │
                    └──────────────────┬───────────────────────┘
                                       │ cached_find / cached_where
                                       ▼
                             ┌─────────────────┐
                             │   PostgreSQL DB  │  (fallback for sync_cache misses)
                             └─────────────────┘
```

### How It Works

1. **`Rails.sync_cache`** (Solid Cache SQLite) is the **performance layer**. It stores the actual `Session`, `User`, `Company`, and `Employee` records as serialized attribute hashes, avoiding DB queries on every request.
2. On each request, the system **reads from sync_cache only** — zero Redis calls per request.
3. When a session is created or destroyed, `Cache::RecordsConcern` callbacks fire, writing to or deleting from `sync_cache`. A Redis pub/sub message broadcasts the invalidation to all other server instances so they evict the stale key from their local SQLite cache.

---

## 2. Request Authentication Flow

Every authenticated request goes through this pipeline:

```
HTTP Request
    │
    ▼
set_current_request_details
    └─ Current.user_agent = request.user_agent
    └─ Current.ip_address = request.ip
    │
    ▼
set_current_session                                    ←── KEY METHOD
    │
    ├─ Read cookies.signed[:session_token] (HTTP-only, signed)
    │
    ├─ Pure sync_cache read (no Redis call)
    │   └─ Session.cached_find(token, expires_in: SESSION_CACHE_EXPIRY)
    │       └─ Rails.sync_cache.fetch("sessions_<uuid>", expires_in: 1.hour) do
    │            find_by(id: token)&.attributes   ← DB query (rare)
    │          end
    │       ├─ nil (session deleted, local cache already evicted via pub/sub)
    │       │   └─ cleanup_invalid_session(token)
    │       │   └─ return (not authenticated)
    │       │
    │       └─ Session record → continue
    │
    └─ Current.session = session_record
    │
    ▼
authenticate
    └─ cookies[:is_signed_in].present? AND Current.session.present?
        ├─ FALSE → redirect_to root_path
        └─ TRUE  → proceed to controller action
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| No per-request Redis calls | All reads hit local SQLite. Redis pub/sub only on session create/destroy. |
| Cache::RecordsConcern handles sync | Session model callbacks write/delete from `sync_cache` which broadcasts pub/sub invalidation |
| TTL via local cache expiry | `SESSION_CACHE_EXPIRY` (1 hour) — stale entries are evicted automatically by Solid Cache |

---

## 3. Session Lifecycle

### Creation (Sign-in)

When a user signs in:

```
1. user.sessions.create!(single_access_token: SecureRandom.hex(20))
     │
     └─ after_commit callback fires
         └─ Cache::RecordsConcern#write_attribute_cache
             └─ Rails.sync_cache.write("sessions_<id>", attrs)
                 ├─ local_cache.write (this instance)
                 └─ Redis PUBLISH "sync_cache:invalidation"
                     (other instances evict stale key)

2. update_cookie(session:, user:)
     └─ cookies.signed[:session_token] = { value: session.id, httponly: true, expires: 1.day }
     └─ cookies[:is_signed_in] = { value: true, expires: 1.day }
     └─ cookies[:client_cache_version] = { value: cache_version(user:), expires: 1.day }
```

### Destruction (Sign-out)

When a user signs out (via `SessionsController#destroy` — DELETE `/sessions/:id`):

```
1. @session.destroy  (Session record is deleted from PostgreSQL)
     │
     └─ after_commit(on: :destroy) callback fires
         └─ Cache::RecordsConcern#remove_attribute_cache
             └─ Rails.sync_cache.delete("sessions_<id>")
                 ├─ local_cache.delete (this instance)
                 └─ Redis PUBLISH "sync_cache:invalidation"
                     (other instances evict their local copy)

2. cookies.clear
```

The sync_cache key is immediately removed locally and the invalidation message evicts it from all other instances. Any subsequent request will miss the cache, fall back to the DB, find nothing, and be rejected.

> **Note:** The `sign_out` GET endpoint (`/sign_out`) currently skips `set_current_session` and does not destroy the session record. The `destroy` DELETE endpoint (`DELETE /sessions/:id`) is the reliable sign-out path.

---

## 4. Cross-Instance Invalidation

This is the primary problem sync_cache solves with its pub/sub layer.

### Scenario: User signs out on Instance A

```
Instance A                      Redis Pub/Sub                  Instance B
─────────                       ──────────────                  ──────────
session.destroy
  │
  └─ remove_attribute_cache
       └─ sync_cache.delete(id)
            │
            ├─ local_cache delete
            │
            └─ PUBLISH "sync_cache:invalidation"
                 { action: "delete", key: "sessions_<id>" }
                                    │
                                    │  SUBSCRIBED
                                    ▼
                               local_cache.delete(key)
                                                           (milliseconds later)
                                                           AJAX request arrives
                                                             └─ Session.cached_find(token)
                                                                 └─ sync_cache MISS
                                                                 └─ DB query → nil
                                                                 └─ cleanup_invalid_session
```

The user is logged out instantly across all server instances — no TTL wait, no stale cache.

### Scenario: Session created on Instance A, request hits Instance B

```
Instance A                      Redis Pub/Sub                  Instance B
─────────                       ──────────────                  ──────────
session.create
  │
  └─ write_attribute_cache
       └─ sync_cache.write(id, attrs)
            │
            ├─ local_cache write
            │
            └─ PUBLISH "sync_cache:invalidation"
                 { action: "write", key: "sessions_<id>" }
                                    │
                                    │  SUBSCRIBED
                                    ▼
                               local_cache.delete(key)
                                                           First request for this session
                                                             └─ Session.cached_find(token)
                                                                 └─ sync_cache MISS
                                                                 └─ DB query → found
                                                                 └─ cached locally
```

The write-side invalidation ensures Instance B evicts any stale pre-creation value. If Instance B never had the key, the eviction is a no-op.

---

## 5. Component Reference

| Component | File | Responsibility |
|-----------|------|----------------|
| `Cache::RecordsConcern` | `app/models/concerns/cache/records_concern.rb` | `cached_find` / `cached_where` using `Rails.sync_cache` (Solid Cache + pub/sub). Included by Session, User, Company, Employee, RoleAppointment. |
| `ApplicationController::AuthenticationConcern` | `app/controllers/concerns/application_controller/authentication_concern.rb` | `set_current_session` with sync_cache read, `authenticate` redirect guard, `current_user`, `current_session`. |
| `ApplicationController::CookieConcern` | `app/controllers/concerns/application_controller/cookie_concern.rb` | Sets `session_token` (signed, HTTP-only), `is_signed_in`, and `client_cache_version` cookies. |
| `Companies::Authorizable` | `app/controllers/concerns/companies/authorizable.rb` | Pundit-based authorization on top of authentication. Checks `current_employee.can?(:action, Resource)`. |
| `cache.rb` | `config/initializers/cache.rb` | Defines `Rails.local_cache`, `Rails.sync_cache`, `Rails.global_cache`. |

---

## 6. Error Handling

### Redis Down

| Scenario | Effect |
|----------|--------|
| Redis pub/sub unavailable at write | `publish_invalidation` rescues and logs error. Write still succeeds on local_cache. Other instances may serve stale data until their TTL expires. |
| Redis connection lost (listener) | Background thread rescues, sleeps 5s, retries. Local reads unaffected. Invalidation messages may be missed during the window. |

When Redis is down, **authentication continues to work** because session reads are local SQLite only. This is a safe pattern — no request is incorrectly authenticated or rejected due to Redis unavailability.

### Session Record Deleted Out-of-Band

If a session record is deleted directly (console, rake task, data cleanup), the `after_commit` callback does not fire (no ActiveRecord lifecycle). The sync_cache entry persists with its TTL (1 hour).

The TTL provides the safety net: the stale entry expires after 1 hour at most. Users whose session was manually deleted would also lack the cookie (since the cookie was set at sign-in), so they can't present the session ID.

---

## 7. Backward Compatibility

When sync_cache was introduced, existing session cache entries in `Rails.local_cache` from the old pattern were automatically handled — Solid Cache's TTL naturally expires them within their configured window. No backfill or migration was needed.

---

## 8. See Also

- `docs/CACHE.md` — Complete cache documentation (local_cache, sync_cache, global_cache, client cache)
- `docs/MODEL_CALLBACKS.md` — Cache::RecordsConcern callback reference
- `docs/ABAC.md` — Permission-based authorization (Pundit on top of auth)
- `config/initializers/cache.rb` — Cache store definitions
- `config/initializers/constants.rb` — `PERMISSIONS_CACHE_EXPIRY`

---

*End of file*
