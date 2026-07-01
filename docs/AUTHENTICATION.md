# Skycom Authentication System

## 1. Architecture

Skycom uses a **dual-cache authentication system** that balances cross-instance security with per-instance performance.

### Cache Tiers

| Tier | Store | Backend | Scope | What It Stores |
|------|-------|---------|-------|----------------|
| **Global cache** | `Rails.global_session_cache` | Redis (in-memory) | Cross-cluster | Active session ID keys (no value — just existence) |
| **Local cache** | `Rails.local_cache` | Solid Cache (SQLite) | Per-server | Session/User/Company/Employee record objects |

### Data Flow Diagram

```
                   ┌────────────────────────────┐
                   │   Rails.global_session_cache │  (Redis)
                   │   KEY: session_uuid → true   │
                   │   TTL: 1 day, extended per   │
                   │   request                    │
                   └───────────┬────────────────┘
                               │ exist?(session_id)
                               │ write/delete
                               ▼
     ┌─────────────────────────────────────────────┐
     │         Rails.local_cache (Solid Cache)      │  (SQLite)
     │  Cache::RecordsConcern stores full records:  │
     │  - Session, User, Company, Employee          │
     │  - Permissions hashes                        │
     └───────────────────┬─────────────────────────┘
                         │ cached_find / cached_where
                         ▼
               ┌─────────────────┐
               │   PostgreSQL DB  │  (fallback for local cache misses)
               └─────────────────┘
```

### How It Works

1. **Global cache (Redis)** is the **source of truth** for session existence. A key in Redis means "this session is active." No key means "logged out or expired."
2. **Local cache (Solid Cache SQLite)** is the **performance layer**. It stores the actual `Session`, `User`, `Company`, and `Employee` records as serialized attribute hashes, avoiding DB queries on every request.
3. On each request, the system **checks global first, then local**, falling back to the DB only when needed.

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
    ├─ [STEP 1] Global cache check
    │   └─ Rails.global_session_cache.exist?(token)
    │       ├─ NO  → cleanup_invalid_session(token)
    │       │        └─ Rails.local_cache.delete("sessions_#{token}")
    │       │        └─ cookies.delete(:session_token)
    │       │        └─ cookies.delete(:is_signed_in)
    │       │        └─ return (not authenticated)
    │       │
    │       └─ YES → proceed to Step 2
    │
    ├─ [STEP 2] Local cache / DB fallback
    │   └─ Session.cached_find(token)
    │       └─ Rails.local_cache.fetch("sessions_<uuid>", expires_in: 5.min) do
    │            find_by(id: token)&.attributes   ← DB query (rare)
    │          end
    │       ├─ nil (record deleted but global key persisted)
    │       │   └─ Rails.global_session_cache.delete(token)
    │       │   └─ cleanup_invalid_session(token)
    │       │   └─ return (not authenticated)
    │       │
    │       └─ Session record → proceed to Step 3
    │
    ├─ [STEP 3] Extend global cache TTL
    │   └─ Rails.global_session_cache.write(token, true, expires_in: COOKIE_EXPIRY)
    │   └─ (same pattern as sync_client_cache_version for cookies)
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
| Redis stores only key existence, not values | Keeps Redis lightweight (O(1) memory lookup). Heavy record objects stay in per-server SQLite. |
| Global check BEFORE local cache | Prevents stale local cache from serving deleted sessions. If a session is destroyed on Instance A, Instance B sees the global miss immediately. |
| TTL extended on every request | Active users refresh their 1-day window. Inactive users' entries expire naturally. Matches the existing `sync_client_cache_version` cookie pattern. |
| Cleanup on global miss | When global cache says "no session," we purge the local cache entry + cookies to prevent any stale state from persisting. |

---

## 3. Session Lifecycle

### Creation (Sign-in)

When a user signs in (via `SessionsController#create`, `RegistrationsController#create`, passwordless, or OmniAuth):

```
1. user.sessions.create!(single_access_token: SecureRandom.hex(20))
     │
     └─ after_create_commit callback fires
         └─ Session::GlobalCacheConcern#write_session_to_global_cache
             └─ Rails.global_session_cache.write(session.id, true, expires_in: COOKIE_EXPIRY)

2. update_cookie(session:, user:)
     └─ cookies.signed[:session_token] = { value: session.id, httponly: true, expires: 1.day }
     └─ cookies[:is_signed_in] = { value: true, expires: 1.day }
     └─ cookies[:client_cache_version] = { value: cache_version(user:), expires: 1.day }
```

The global cache key is set at creation and persists for `COOKIE_EXPIRY` (1 day).

### TTL Extension (Active Usage)

On every authenticated request, Step 3 of `set_current_session` refreshes the global cache TTL:

```ruby
Rails.global_session_cache.write(token, true, expires_in: COOKIE_EXPIRY)
```

This uses `write` instead of `expire` because `ActiveSupport::Cache::RedisCacheStore` does not expose an `expire` method. Writing the same value with a fresh `expires_in` achieves the same effect.

### Destruction (Sign-out)

When a user signs out (via `SessionsController#destroy` — DELETE `/sessions/:id`):

```
1. @session.destroy  (Session record is deleted from PostgreSQL)
     │
     └─ after_commit(on: :destroy) callback fires
         └─ Session::GlobalCacheConcern#remove_session_from_global_cache
             └─ Rails.global_session_cache.delete(session.id)

2. cookies.clear
```

The global cache key is immediately removed. Any subsequent request (even on different server instances) will fail the Step 1 global cache check and be rejected.

> **Note:** The `sign_out` GET endpoint (`/sign_out`) currently skips `set_current_session` and does not destroy the session record. The `destroy` DELETE endpoint (`DELETE /sessions/:id`) is the reliable sign-out path.

---

## 4. Cross-Instance Invalidation

This is the primary problem the global cache solves.

### Scenario: User signs out on Instance A

```
Instance A                      Global Cache (Redis)        Instance B
─────────                       ───────────────────         ──────────
session.destroy
  │
  └─ global_cache.delete(id)
                                  KEY session_id
                                  │
                                  └─── DELETED
                                                            (milliseconds later)
                                                            AJAX request arrives
                                                              │
                                                              └─ global_cache.exist?(id)?
                                                                  └─ NO (deleted)
                                                                  └─ cleanup_invalid_session
                                                                  └─ authenticate → redirect
```

The user is logged out instantly across all server instances — no TTL wait, no stale cache.

### Scenario: Session created on Instance A, request hits Instance B

```
Instance A                      Global Cache (Redis)        Instance B
─────────                       ───────────────────         ──────────
session.create
  │
  └─ after_create_commit
      └─ global_cache.write(id)
                                  KEY session_id (new)
                                  │
                                  └─── WRITTEN
                                                            First request for this session
                                                              │
                                                              └─ global_cache.exist?(id)?
                                                                  └─ YES
                                                                  └─ Session.cached_find(id)
                                                                      └─ local_cache MISS
                                                                      └─ DB query → found
                                                                      └─ cached locally (5min)
                                                                  └─ global_cache.write(id) again
                                                                      (TTL extended)
                                                                  └─ authenticated
```

---

## 5. Component Reference

| Component | File | Responsibility |
|-----------|------|----------------|
| `Session::GlobalCacheConcern` | `app/models/concerns/session/global_cache_concern.rb` | Model callbacks: writes session ID to Redis on `after_create_commit`, removes on `after_commit(on: :destroy)`. |
| `ApplicationController::AuthenticationConcern` | `app/controllers/concerns/application_controller/authentication_concern.rb` | `set_current_session` with global cache check, `authenticate` redirect guard, `current_user`, `current_session`. |
| `ApplicationController::CookieConcern` | `app/controllers/concerns/application_controller/cookie_concern.rb` | Sets `session_token` (signed, HTTP-only), `is_signed_in`, and `client_cache_version` cookies. |
| `Cache::RecordsConcern` | `app/models/concerns/cache/records_concern.rb` | `cached_find` / `cached_where` using `Rails.local_cache` (Solid Cache SQLite). Included by Session, User, Company, Employee, RoleAppointment. |
| `Companies::Authorizable` | `app/controllers/concerns/companies/authorizable.rb` | Pundit-based authorization on top of authentication. Checks `current_employee.can?(:action, Resource)`. |
| `multi_cache_store.rb` | `config/initializers/multi_cache_store.rb` | Defines `Rails.local_cache`, `Rails.global_cache`, `Rails.global_session_cache`. |

### Cache Store Definitions

| Method | Backend | Purpose |
|--------|---------|---------|
| `Rails.local_cache` | Solid Cache (SQLite) | Per-server record caching (Session, User, Company, Employee via `Cache::RecordsConcern`; billing dashboard JSON; permissions hashes) |
| `Rails.global_cache` | Redis | Cross-cluster general purpose cache (currently unused in production; placeholder) |
| `Rails.global_session_cache` | Redis (same as global_cache) | Session ID existence checks for cross-instance auth invalidation. Can be split to its own Redis cluster in the future. |

---

## 6. Error Handling

### Redis Down

| Scenario | Effect |
|----------|--------|
| Redis unavailable at request time | `Rails.global_session_cache.exist?(token)` raises `Redis::BaseConnectionError`. The application returns a 500 error. |
| Redis restored after outage | Session ID keys with remaining TTL resume working. Keys that expired during the outage are naturally cleaned up. |

When Redis is down, authentication fails. This is a **safe failure** — no request is incorrectly authenticated.

### Session Record Deleted Out-of-Band

If a session record is deleted directly (console, rake task, data cleanup), the `after_commit(on: :destroy)` callback does not fire (no ActiveRecord lifecycle). The global cache entry persists with its TTL.

The TTL provides the safety net: the stale entry expires after 1 day at most. Users whose session was manually deleted would also lack the cookie (since the cookie was set at sign-in), so they can't present the session ID.

---

## 7. Backward Compatibility

When the global cache was introduced, existing sessions had no global cache entry. On their first request post-deploy, `global_cache.exist?(token)` returned `false`, and the user was redirected to sign in.

No backfill was needed because:
1. The `session_token` cookie has a 1-day TTL (`COOKIE_EXPIRY`)
2. Most sessions expire naturally within 24 hours
3. Users sign in again, which creates a fresh global cache entry

---

## 8. See Also

- `docs/LOCAL_AND_GLOBAL_CACHE.md` — Server-side cache tiers (Solid Cache + Redis)
- `docs/CACHE.md` — Client-side browser cache (localStorage, cookies, daily re-auth)
- `docs/MODEL_CALLBACKS.md` — Session::GlobalCacheConcern callback reference
- `docs/ABAC.md` — Permission-based authorization (Pundit on top of auth)
- `config/initializers/multi_cache_store.rb` — Cache store definitions
- `config/initializers/constants.rb` — `COOKIE_EXPIRY`, `DEFAULT_CACHE_EXPIRY`, `PERMISSIONS_CACHE_EXPIRY`
