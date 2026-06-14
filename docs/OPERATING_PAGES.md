# Skycom Operating Pages System

## 1. Overview

Operating Pages are dedicated full-screen interfaces for specific operational roles (POS cashier, store manager, restaurant waiter, etc.). Each page type is defined by a `Page` record with a `target_role` enum value and gets its own Stimulus controller for the frontend UI.

The `retail_cashier` page is the reference implementation — a multi-customer POS with product/service grid, cart management, and payment flow.

---

## 2. Architecture

Each operating page touches 6 layers:

| Layer | File | Responsibility |
|-------|------|----------------|
| **Model** | `app/models/page.rb` | `target_role` enum value defines the page type |
| **Route** | `config/routes.rb` | Member route under `resources :pages` |
| **Controller** | `app/controllers/companies/pages_controller.rb` | Shell-First action returning JSON scoped to the page's branch |
| **Policy** | `app/policies/companies/pages_policy.rb` | Authorization method for the action |
| **URL Helper** | `app/javascript/controllers/helpers/url_helpers.js` | JS helper for the route path |
| **Stimulus** | `app/javascript/controllers/companies/pages/{name}_controller.js` | Full SPA frontend for the page |

---

## 3. Existing Pages

| `target_role` | Value | Action | Stimulus Controller | Route Path |
|---|---|---|---|---|
| `retail_cashier` | 110 | `retail_cashier` | `retail_cashier_controller.js` | `GET /pages/:id/retail_cashier` |
| `retail_store_manager` | 120 | — | — | — |
| `restaurant_cashier` | 210 | — | — | — |
| `restaurant_waiter` | 220 | — | — | — |
| `restaurant_kitchen_staff` | 230 | — | — | — |
| `hospital_receptionist` | 310 | — | — | — |
| `hospital_doctor` | 320 | — | — | — |
| `hospital_nurse` | 330 | — | — | — |

---

## 4. Step-by-Step: Adding a New Operating Page

Use the `retail_cashier` pattern. Each step shows the exact code to add.

### Step 1: Add `target_role` enum value

**File**: `app/models/page.rb`

```ruby
enum :target_role, {
  # Retail Roles
  retail_cashier: 110,
  retail_store_manager: 120,
  new_role: 130,  # <-- Add here (130 = next retail slot)

  # Restaurant Roles
  restaurant_cashier: 210,
  # ...
}
```

Values are grouped by business type (retail: 100s, restaurant: 200s, hospital: 300s) and spaced by 10s.

### Step 2: Add code prefix to seed service

**File**: `app/services/seed/page_service.rb`

```ruby
CODE_PREFIXES = {
  cashier: "CSH",
  store_manager: "MGR",
  new_role: "NEW"  # <-- Add prefix for auto-code generation
}.freeze
```

### Step 3: Add member route

**File**: `config/routes.rb`

```ruby
resources :pages do
  member do
    get :retail_cashier
    get :new_role  # <-- Add new action
  end
end
```

### Step 4: Add controller action

**File**: `app/controllers/companies/pages_controller.rb`

Follow Shell-First pattern. Scope data to `page.branch_id`:

```ruby
def new_role
  page = current_company.pages.includes(:branch).find(params[:id])

  respond_to do |format|
    format.html { render html: "", layout: true }
    format.json do
      # Fetch data scoped to the page's branch
      products = current_company.products.where(branch_id: page.branch_id).limit(50).map { |p|
        price = p.price
        { id: p.id, name: p.name, code: p.code,
          price: price&.to_f || 0,
          currency: price&.currency.iso_code || "USD",
          image_url: p.image_attachments.first&.variant(:thumb)&.processed&.url }
      }
      services = current_company.services.where(branch_id: page.branch_id).limit(50).map { |s|
        { id: s.id, name: s.name, code: s.code,
          price: 0, currency: "usd",
          image_url: s.image_attachments.first&.variant(:thumb)&.processed&.url }
      }

      render json: {
        page: format_page(page),
        products: products,
        services: services
      }
    end
  end
end
```

### Step 5: Add policy method

**File**: `app/policies/companies/pages_policy.rb`

The policy method name must match the action name with a `?` suffix (auto-derived by `Companies::Authorizable`):

```ruby
def new_role?
  record.can?(:read, Page)
end
```

### Step 6: Add URL helper

**File**: `app/javascript/controllers/helpers/url_helpers.js`

```javascript
export const new_role_company_page_path = (companyId, pageId) =>
  `/companies/${companyId}/pages/${pageId}/new_role`
```

### Step 7: Create Stimulus controller

**File**: `app/javascript/controllers/companies/pages/new_role_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class Companies_Pages_NewRoleController extends Controller {
  /** @type {any | null} */ page = null
  /** @type {any[]} */ products = []
  /** @type {any[]} */ services = []

  async connect() {
    const pathParts = window.location.pathname.split("/")
    const companyId = pathParts[2]
    const pageId = pathParts[4]

    const url = `${Helpers.new_role_company_page_path(companyId, pageId)}.json`
    const response = await fetchJson(url)
    this.page = response.page
    this.products = response.products || []
    this.services = response.services || []

    this.renderContent()
  }

  renderContent() {
    this.element.innerHTML = this.contentHTML()
  }

  contentHTML() {
    // Render your operating page UI here
    // See retail_cashier_controller.js for the full POS pattern
  }
}
```

### Step 8: Update docs/MODEL_CALLBACKS.md

If the new page action adds any new callbacks or changes existing ones, update `docs/MODEL_CALLBACKS.md`.

---

## 5. Stimulus Controller Pattern

All operating page controllers follow this structure:

| Method | Purpose |
|--------|---------|
| `connect()` | Extract companyId/pageId from URL, fetch JSON via URL helper, set instance data, render |
| `renderContent()` | Set `this.element.innerHTML = this.contentHTML()` |
| `contentHTML()` | Return full page HTML string (Shell-First) |
| Custom methods | Business logic (addToCart, switchTab, etc.) |

**Identifier naming** follows the standard convention:

| File | Class | Identifier |
|------|-------|------------|
| `retail_cashier_controller.js` | `Companies_Pages_RetailCashierController` | `companies--pages--retail-cashier` |

---

## 6. Controller Action Pattern

All operating page controller actions follow Shell-First:

```ruby
def retail_cashier
  page = current_company.pages.includes(:branch).find(params[:id])

  respond_to do |format|
    format.html { render html: "", layout: true }
    format.json do
      # Fetch data scoped to page.branch_id
      # Return: { page: {...}, products: [...], services: [...] }
    end
  end
end
```

**JSON response includes `image_url`** (first attached image's `thumb` variant) for both products and services. Returns `null` when no image is attached — the frontend renders a gradient+icon fallback.

**Policy auto-discovery**: The `Companies::Authorizable` concern auto-derives the query method `"retail_cashier?"` from the action name `"retail_cashier"`. Every operating page action must have a corresponding policy method.

---

## 7. Seed Service & Factory

Pages are created via `Seed::PageService`, which auto-generates a `code` from the role prefix + branch ID + random hex (e.g., `CSH-abc12345-1A2B`).

**FactoryBot** (for specs):

```ruby
factory :page do
  association :company
  branch { association :branch, company: company }
  target_role { :retail_cashier }

  initialize_with do
    Seed::PageService.new(
      company: company, branch: branch,
      target_role: target_role
    )
  end
end
```

---

## 8. Database

The `pages` table has a unique composite index:

```ruby
t.index ["branch_id", "target_role", "target_resolution", "code"],
  unique: true,
  name: "idx_on_branch_id_target_role_target_resolution_code_6c16dc00fe"
```

This ensures only one page per branch + role + resolution + code combination.

---

*End of documentation*
