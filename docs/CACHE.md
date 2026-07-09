# Skycom Client Cache System

## 1. Overview

Skycom caches company data in the browser's `localStorage` for fast frontend access across all Stimulus controllers. This avoids repeated API calls for commonly used data like companies, branches, employees, roles, and enums.

---

## 2. What Gets Cached

The client cache stores:
- **User**: Current logged-in user (id, email, name, avatar, etc.)
- **Companies**: All companies the user has access to
- **Branches**: Branches per company
- **Departments**: Departments per company
- **Roles**: Roles per company
- **Enums**: Lifecycle statuses and other enum values
- **Employees**: Employee records for the current company

---

## 3. Storage Keys

| Key | Description |
|-----|-------------|
| `client_cache_data` | JSON blob containing all cached data |
| `client_cache_version` | Version string for cache invalidation |
| `client_cache_sync_count` | Auto-sync counter (max 1, resets on version match) |

---

## 4. Backend Endpoint

**Route**: `GET /client_cache`

**Response**:
```json
{
  "user": { "id": "...", "email": "...", "name": "...", "avatar": "..." },
  "companies": [
    { "id": "...", "name": "...", "branches": [...], "departments": [...], "roles": [...] }
  ],
  "enums": {
    "employee": { "lifecycle_statuses": [{ "name": "Active", "value": "active" }] }
  },
  "employees": [...]
}
```

The backend also sets a `client_cache_version` cookie with a timestamp.

---

## 5. Frontend Controller

**File**: `app/javascript/controllers/client_cache_controller.js`

### Methods

| Method | Description |
|--------|-------------|
| `connect()` | Guards for signed-in user, then calls `sync()` |
| `sync()` | Checks version, sync counter, and refreshes if needed |
| `refreshCache(newVersion)` | Fetches fresh data from `/client_cache`, stores, logs, increments counter, then reloads page |

### Usage in Layout

```html
<div data-controller="client-cache"></div>
```

Place this in the main layout to ensure cache sync on every page load.

---

## 6. How It Works

1. **Page Load**: `ClientCacheController#connect()` calls `sync()`
2. **Version Check**: Compares `client_cache_version` cookie vs localStorage
3. **If Mismatch or No Cache**: Fetches from `/client_cache`, stores in localStorage
4. **Reload**: Increments `client_cache_sync_count` counter and reloads the current page so all controllers and components get fresh data from localStorage
5. **Sync Guard**: Only runs when signed in. Max 1 auto-sync per page session — the `client_cache_sync_count` counter prevents loops. Resets to 0 when versions match.

---

## 7. How to Update/Invalidate/Refresh

### Automatic Refresh
When the server version (cookie) differs from local version, the cache auto-refreshes on next page load.

### Manual Clear
To force a refresh (e.g., after creating a new company):

```javascript
// Get the controller and call clearClientCache
const controller = application.getControllerForElementAndTarget(
  document.querySelector('[data-controller="client-cache"]'),
  'client-cache'
)
if (controller) {
  controller.clearClientCache()
  controller.refreshCache('manual')
}
```

### Using Cache in Controllers
```javascript
import { currentCompany, currentCompanies, currentUser, Enums } from "controllers/helpers/auth_helpers"

// Get current company
const company = currentCompany()  // → Company | null

// Get all companies
const companies = currentCompanies()  // → Company[]

// Get current user
const user = currentUser()  // → User | null

// Get enums
const enums = Enums()  // → Enums object

// Full cache access
const cache = Helpers.getCache()  // → { user, companies, enums, employees }
```

---

## 8. Cache Helpers (`auth_helpers.js`)

| Helper | Description |
|--------|-------------|
| `currentUser()` | Returns current user object or null |
| `currentCompany()` | Returns active company or null |
| `currentCompanies()` | Returns all accessible companies |
| `currentBranches()` | Returns branches of current company |
| `currentRoles()` | Returns roles of current company |
| `Enums()` | Returns all enum definitions |
| `getCache()` | Returns full cache object |

---

## 9. Example: Permission Check with Cached Roles

```javascript
import { currentRoles } from "controllers/helpers/auth_helpers"

export default class Companies_ProductsIndexController extends Companies_LayoutController {
  async loadData() {
    const roles = currentRoles()
    const canManage = roles.some(r => r.name === 'Manager')
    // Use for UI logic or permission checks
  }
}
```

---

## 10. When to Clear Cache

Clear the cache when:
- User creates a new company
- User switches companies (may need refresh)
- After major data changes that affect cached collections
- User logs out and logs back in (handled automatically)

---

## 11. Cookie Expiration & Daily Re-authentication

All session and cache cookies use a **1-day expiration** to force daily re-authentication.

### Cookie Lifetimes

| Cookie | Expiry | Purpose |
|--------|--------|---------|
| `session_token` | 1 day (HTTP-only, signed) | Rails session — daily expiry forces re-login |
| `is_signed_in` | 1 day | Public flag the frontend reads for auth state |
| `client_cache_version` | 1 day | Version stamp the frontend compares against localStorage |

### Why 1 Day?

- **Security**: Old cookies can't linger indefinitely. User must sign in at least once every 24 hours.
- **Cache freshness**: When `client_cache_version` cookie expires, the frontend sees no server version, detects a mismatch with the localStorage version, and triggers a full `/client_cache` refresh on next page load.
- **No stale data**: Company/employee/role data is re-fetched daily, so mutations (new branches, role changes, etc.) are picked up within 24 hours even if the user doesn't manually clear cache.

### Implementation

**File**: `app/controllers/concerns/application_controller/cookie_concern.rb`

```ruby
def update_cookie(session:, user:)
  cookies.signed[:session_token] = { 
    value: session.id, 
    httponly: true, 
    expires: 1.day 
  }
  cookies[:is_signed_in] = { 
    value: true, 
    expires: 1.day 
  }
  cookies[:client_cache_version] = { 
    value: cache_version(user: user), 
    expires: 1.day 
  }
end
```

`sync_client_cache_version` also extends the cookie lifetime by re-setting `expires: 1.day` whenever the version changes.

### Frontend Effect

In `client_cache_controller.js`:
```javascript
const serverVersion = Cookie('client_cache_version')
```

When the cookie has expired, `serverVersion` is `undefined`. The `sync()` method compares this against `localStorage.getItem('client_cache_version')`. A mismatch triggers `refreshCache()` → full `/client_cache` fetch → `localStorage` is repopulated.

### User Experience

- User logs in → cookies set with 1-day expiry
- Throughout the day → cache serves data from localStorage, no extra API calls
- Next day (or after 24h of inactivity) → cookies expired → user sees login page
- User signs in again → fresh cookies, fresh cache

---

## 12. Client Cache Invalidation

The client cache auto-refreshes when the `client_cache_version` cookie changes on the server side.

### How Invalidation Works

1. **Cookie version** is computed from `user.updated_at` + `Company.maximum(:updated_at)` in `ApplicationController::CookieConcern#cache_version`
2. **`touch: true` propagation**: When a cache-affecting record changes, it touches its parent company, bumping `company.updated_at`
3. **`sync_client_cache_version`** (before_action on every request) detects the version change and updates the `client_cache_version` cookie
4. **Frontend `ClientCacheController.sync()`** (on every page load) reads the cookie and compares with localStorage — if they differ, it re-fetches `/client_cache` and reloads the page

### Models That Auto-Invalidate

These models have `belongs_to :company, touch: true`, so any create/update/destroy propagates to the company's `updated_at`:

| Model | File |
|-------|------|
| `Branch` | `app/models/branch.rb:18` |
| `Department` | `app/models/department.rb:29` |
| `Category` | `app/models/category.rb:4` |
| `PropertyMapping` | `app/models/property_mapping.rb:55` |
| `TableConfig` | `app/models/table_config.rb:12` |
| `Role` | `app/models/role.rb:10` |

### Manual Invalidation

```ruby
company.invalidate_client_cache!  # bumps company.updated_at, triggers refresh
```

This is defined in `app/models/company.rb`.

### The Propagation Chain

```
PropertyMapping.create/update/destroy
  → belongs_to :company, touch: true
    → company.touch → company.updated_at changes
      → sync_client_cache_version updates cookie
        → ClientCacheController.sync() detects mismatch
          → re-fetches /client_cache → localStorage refreshed → page reloaded
```

---

## 13. See Also

- `docs/LOCAL_AND_GLOBAL_CACHE.md` — Server-side dual cache (Solid Cache + Redis) used by Rails backend

---

*End of file*