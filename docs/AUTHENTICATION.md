# Skycom Authentication System

## 1. Architecture

Skycom's authentication session caching uses the **`sync_cache` pattern**: local SQLite reads for all requests, with Redis pub/sub only for write/delete invalidation across instances.

### Cache Tiers

| Tier | Store | Backend | Scope | What It Stores |
|------|-------|---------|-------|----------------|
| **Sync cache** | `Rails.sync_cache` | Solid Cache + Redis pub/sub | Cross-cluster | Miscellaneous cached scalars (e.g., cookie cache version) |

### Data Flow Diagram

```
                    ┌──────────────────────────────────────────┐
                    │         Rails.sync_cache                 │
                    │  (Solid Cache SQLite + Redis pub/sub)    │
                    │                                          │
                                                                                                    │  - Permissions hashes                    │
                    └──────────────────┬───────────────────────┘
                                       ▼
                             ┌─────────────────┐
                             │   PostgreSQL DB  │  (fallback for sync_cache misses)
                             └─────────────────┘
```

### How It Works

1. Authentication now uses **normal database lookups** (`Session.find_by`, `User.find_by`) — the custom `cached_*` attribute-cache layer has been removed.
2. `Rails.sync_cache` is still used for other scalar values (e.g., the cookie cache version in `CookieConcern`), but not for session/user/company/employee records.

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
    ├─ Normal DB lookup
    │   └─ Session.find_by(id: token)
    │       ├─ nil (session deleted / not found)
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
| Normal DB lookups | Session/User records loaded via `find_by` (no custom cached_* layer) |
| TTL via local cache expiry | `CACHE_DEFAULT_EXPIRY` (1 hour) — stale entries are evicted automatically by Solid Cache |

---

## 3. Session Lifecycle

### Creation (Sign-in)

When a user signs in:

```
1. user.sessions.create!(single_access_token: SecureRandom.hex(20))
     │
     └─ session record persisted to PostgreSQL
         (no custom cached_* attribute cache is written)

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
     └─ session record deleted from PostgreSQL
         (no custom cached_* attribute cache is evicted)

2. cookies.clear
```

The session is removed from PostgreSQL. Any subsequent request will not find the session and be rejected.

> **Note:** The `sign_out` GET endpoint (`/sign_out`) currently skips `set_current_session` and does not destroy the session record. The `destroy` DELETE endpoint (`DELETE /sessions/:id`) is the reliable sign-out path.

---

## 4. Cross-Instance Invalidation

Session authentication no longer uses `sync_cache`; records are loaded directly from PostgreSQL, so there is no cross-instance cache invalidation for sessions. (Other features may still use `Rails.sync_cache` independently.)

## 5. Component Reference

| Component | File | Responsibility |
|-----------|------|----------------|

| `ApplicationController::AuthenticationConcern` | `app/controllers/concerns/application_controller/authentication_concern.rb` | `set_current_session` with DB lookup, `authenticate` redirect guard, `current_user`, `current_session`. |
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

- `docs/CACHE.md` — Complete cache documentation (ram_cache, local_cache, sync_cache, global_cache, client cache)
- (Cache::RecordsConcern removed; records are loaded via normal DB queries)
- `docs/ABAC.md` — Permission-based authorization (Pundit on top of auth)
- `config/initializers/cache.rb` — Cache store definitions
- `config/initializers/constants.rb` — `CACHE_DEFAULT_EXPIRY`

---

*End of file*
