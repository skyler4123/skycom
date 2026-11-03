# Skycom Operating Pages System

## 1. Overview

Operating Pages are dedicated full-screen interfaces for specific operational roles
(POS cashier, store manager, restaurant waiter, etc.). Each page type is defined by a
`Page` record with a `target_role` enum value and gets its own Stimulus controller for
the frontend UI.

Every company gets the catalog for its `Company#business_type`, once per target
resolution. A page record is therefore always **company + branch + role + resolution**.
The `retail_cashier` desktop page is the reference implementation — a multi-customer
POS with product/service grid, cart management, and payment flow. All other catalog
pages render the shared **Coming soon** screen until their real UI is built.

---

## 2. Architecture

Each operating page touches 6 layers:

| Layer | File | Responsibility |
|-------|------|----------------|
| **Model** | `app/models/page.rb` | Catalog lookup, role/resolution enums, name suffix, placeholder predicate |
| **Route** | `config/routes.rb` | Member routes under `resources :pages` (`retail_cashier`, `launch`) |
| **Controller** | `app/controllers/companies/pages_controller.rb` | Shell-First actions, device filtering, counts, launch dispatch |
| **Policy** | `app/policies/companies/pages_policy.rb` | `launch?` / `retail_cashier?` → `Page` read |
| **URL Helper** | `app/javascript/controllers/helpers/url_helpers.js` | JS paths for index, launch, and the real POS |
| **Stimulus** | `app/javascript/controllers/companies/pages/{name}_controller.js` | Full SPA frontend for the page |

Mobile has a server-rendered counterpart:

| Layer | File | Responsibility |
|-------|------|----------------|
| **Controller** | `app/controllers/mobile/companies/operations_controller.rb` | Mobile page list + counts |
| **Controller** | `app/controllers/mobile/companies/pages_controller.rb` | Mobile page detail / Coming soon |
| **Policy** | `app/policies/mobile/companies/pages_policy.rb` | Page read |
| **Views** | `app/views/mobile/companies/{operations,pages}/` | Server-rendered mobile UI |

---

## 3. Page Catalog

`PAGE_CATALOG` in `config/initializers/constants.rb` is the single source of truth
for which page types each business type exposes. `Page.target_roles_for`,
`Page.label_for`, and `Page.implemented?` read from it.

| Business type | Page types (`target_role`) |
|---|---|
| Retail | `retail_cashier`, `retail_store_manager` |
| Restaurant | `restaurant_cashier`, `restaurant_waiter`, `restaurant_kitchen_staff` |
| Hospital | `hospital_receptionist`, `hospital_doctor`, `hospital_nurse` |
| Education | `education_receptionist`, `education_teacher`, `education_manager` |
| Hotel | `hotel_receptionist`, `hotel_housekeeping`, `hotel_manager` |
| Fitness | `fitness_receptionist`, `fitness_trainer`, `fitness_manager` |

Each catalog entry has a display name (`"Retail POS"`, `"Restaurant Waiter"`, …) and
an `implemented` list of resolutions. `Page#placeholder?` is true unless the entry
marks the current resolution as implemented.

Today only `retail_cashier` + `desktop` is implemented. Everything else — including
`retail_cashier` + `mobile` — is a placeholder.

---

## 4. Resolution and Device Split

`Page#target_resolution` has exactly two values:

```ruby
enum :target_resolution, { mobile: 10, desktop: 20 }, prefix: true, default: :desktop
```

- `mobile` covers phones and tablets.
- `desktop` covers desktop browsers.

The desktop Pages index lists only `desktop` records. The mobile Operations tab lists
only `mobile` records. Both surfaces show company-wide counts:

```json
{ "total": 4, "desktop": 2, "mobile": 2 }
```

When `branch_id` is present on the desktop index, both the list and counts are scoped
to that branch. Without it, counts roll up across the company. Counts are advisory and
cached for one day (`Page.counts_for` / `PAGE_COUNT_CACHE_EXPIRY`), so they may lag
page changes by up to a day.

Page names carry a resolution suffix so the two records are distinguishable:
`"Retail POS Desktop"`, `"Retail POS Mobile"`. `Page` enforces the suffix in a
`before_validation` callback, and swaps it when the resolution changes.

---

## 5. Launch Flow

Every page row links to one stable action:

```
GET /companies/:company_id/pages/:id/launch
```

- **Implemented page** — `launch` redirects to its real screen (currently the
  `retail_cashier` desktop POS). JSON responses include `launch_path`.
- **Placeholder page** — `launch` renders the Shell-First layout. The
  `Companies_Pages_LaunchController` fetches `launch.json` and renders the shared
  “Coming soon” card with the page name, branch, role, and resolution.

On mobile, cards in the Operations tab link to:

```
GET /mobile/companies/:company_id/pages/:id
```

`Mobile::Companies::PagesController#show` renders the mobile Coming soon screen for
placeholders. When a mobile page is implemented, this is the surface that gains its
real UI.

---

## 6. Adding a New Operating Page

### Step 1: Add the catalog entry

**File**: `config/initializers/constants.rb`

```ruby
PAGE_CATALOG = {
  retail: [
    { target_role: :retail_cashier, name: "Retail POS", implemented: %i[desktop] },
    { target_role: :retail_store_manager, name: "Retail Store Manager", implemented: [] }
  ]
  # ...
}
```

Add the new `target_role` enum value in `app/models/page.rb` if it does not exist.
Values are grouped by business type (retail: 100s, restaurant: 200s, hospital: 300s,
education: 400s, hotel: 500s, fitness: 600s) and spaced by 10s.

### Step 2: Add code prefix to seed service

**File**: `app/services/seed/page_service.rb`

```ruby
CODE_PREFIXES = {
  retail_cashier: "RCSH",
  retail_store_manager: "RMGR",
  new_role: "NEW"  # <-- Add prefix for auto-code generation
}.freeze
```

### Step 3: Add member route

**File**: `config/routes.rb`

```ruby
resources :pages do
  member do
    get :retail_cashier
    get :launch
    get :new_role  # <-- Add new action when it gets a real screen
  end
end
```

### Step 4: Add controller action

**File**: `app/controllers/companies/pages_controller.rb`

Follow the Shell-First pattern. Scope data to `page.branch_id`.

### Step 5: Add policy method

**File**: `app/policies/companies/pages_policy.rb`

The policy method name must match the action name with a `?` suffix (auto-derived by
`Companies::Authorizable`).

### Step 6: Add URL helper

**File**: `app/javascript/controllers/helpers/url_helpers.js`

```javascript
export const new_role_company_page_path = (companyId, pageId) =>
  `/companies/${companyId}/pages/${pageId}/new_role`
```

### Step 7: Create Stimulus controller

**File**: `app/javascript/controllers/companies/pages/new_role_controller.js`

Use the standard `Companies_Pages_*` identifier and the Shell-First lifecycle:
`connect()` → fetch JSON → `renderContent()` → `contentHTML()`.

### Step 8: Mark the resolution implemented

Flip the resolution in the catalog entry’s `implemented` list, then update
`Companies::PagesController#launch_path_for` so `launch` redirects to the new
screen.

### Step 9: Update docs

Update this file, `docs/MOBILE.md` / `docs/MOBILE_FEATURE_MATRIX.md` if mobile
behavior changed, and `docs/MODEL_CALLBACKS.md` if callbacks changed.

---

## 7. Seed Defaults

`Seed::PageService.ensure_defaults_for_branch!(branch)` creates every catalog page
for the branch’s company, once per resolution. It is idempotent and is called from
`Branch#after_create` (skipped when `Company.skip_init` is on, i.e. in specs).

A fresh seed therefore creates the full page list. Branch creation and the seed
services are the only creation paths.

---

## 8. Database

The `pages` table has a unique composite index:

```ruby
t.index ["branch_id", "target_role", "target_resolution", "code"],
  unique: true,
  name: "idx_on_branch_id_target_role_target_resolution_code_6c16dc00fe"
```

The model additionally enforces one record per branch + role + resolution.

---

*End of documentation*
