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
| `connect()` | Auto-syncs cache on page load |
| `sync()` | Checks version and refreshes if needed |
| `refreshCache(newVersion)` | Fetches fresh data from `/client_cache` |
| `clearClientCache()` | Removes localStorage cache |

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
4. **Global Event**: Dispatches `client-cache:updated` after refresh

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

### Listen for Updates
Other controllers can listen to the global event:

```javascript
window.addEventListener('client-cache:updated', (event) => {
  console.log('Cache updated:', event.detail)
  // Re-fetch data from Helpers if needed
})
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

*End of file*