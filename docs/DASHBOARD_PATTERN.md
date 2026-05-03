# Skycom Resource Dashboard Pattern

This document describes how resource dashboards work in Skycom and how to add new dashboards for additional resources.

## Overview

Each resource (Branch, Employee, Product, etc.) has a dedicated dashboard page accessible at `/companies/:company_id/{resource}`. Dashboards follow the Shell-First pattern — server returns minimal HTML shell, JavaScript fetches JSON and renders content client-side.

## Architecture

### Route Structure

All resource routes are defined in `config/routes.rb`:

```ruby
resources :companies do
  scope module: :companies do
    resources :branches
    resources :employees
    resources :products
    # Add new resources here
  end
end
```

This generates standard RESTful routes:
- `GET /companies/:company_id/branches` — Index (list)
- `GET /companies/:company_id/branches/new` — New form (if needed)
- `GET /companies/:company_id/branches/:id` — Show details

### File Structure

Each dashboard has 3 JavaScript files:

```
app/javascript/controllers/companies/{resource}/
├── index_controller.js       # Main list view, filtering, search, table rendering
├── new_modal_controller.js  # Create form modal
└── show_modal_controller.js # Edit/view form modal
```

| File | Responsibility |
|------|----------------|
| `index_controller.js` | Loads data from API, renders table, handles filters/search |
| `new_modal_controller.js` | Renders form for creating new record |
| `show_modal_controller.js` | Renders form for editing/viewing existing record |

## Index Controller Pattern

The index controller is the main controller for a resource dashboard. It extends `Companies_LayoutController`.

```javascript
// app/javascript/controllers/companies/branches/index_controller.js

import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_Branches_NewModalController from "controllers/companies/branches/new_modal_controller";
import Companies_Branches_ShowModalController from "controllers/companies/branches/show_modal_controller";

export default class Companies_Branches_IndexController extends Companies_LayoutController {
  static targets = ["branchesList"]

  /** @type {(Branch & { city: string, country_code: string })[]} */
  branches = []

  async connect() {
    super.connect()
    
    // Listen for inline edit updates
    addAction(this.element, `editable:updateBranch@window->${this.identifier}#handleUpdate`)
    
    try {
      // Fetch data from API
      const response = await fetchJson()
      this.branches = response.branches || []
      this.pagination = response.pagination || {}

      // Render after DOM is ready
      window.poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })

    } catch (error) {
      toast({ type: "error", message: "Failed to load branches" })
    }
  }

  openNewModal() {
    openModal({ html: `<div data-controller="${identifier(Companies_Branches_NewModalController)}"></div>` })
  }

  openShowModal(event) {
    event.preventDefault()
    const { branchId } = event.params
    window.currentBranch = findById(this.branches, branchId)
    openModal({ html: `<div data-controller="${identifier(Companies_Branches_ShowModalController)}"></div>` })
  }

  handleUpdate(event) {
    const { data } = event.detail
    const newBranch = data.branch

    if (!newBranch) return

    this.branches = mergeObjectArrays(this.branches, [newBranch], "id")

    if (window.currentBranch?.id === newBranch.id) {
      window.currentBranch = newBranch
    }

    this.renderContent()
  }

  contentHTML() {
    // Get filter options from enums
    const typeFilter = Enums()?.branch?.business_types || []
    const workflowStatusFilter = Enums()?.branch?.workflow_statuses || []

    const urlParams = new URLSearchParams(window.location.search)

    return `
      <div class="p-4 overflow-y-auto" data-action="filter:changed@window->${this.identifier}#handleFilter">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <!-- Filter + Search Form -->
          <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end justify-between gap-4 mb-6 w-full">
            <div class="flex flex-wrap items-center gap-3">
              <!-- Business Type Filter -->
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Type</label>
                <select name="business_type" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg">
                  ${selectOptionsHTML(typeFilter, urlParams.get('business_type'), "All Types")}
                </select>
              </div>

              <!-- Workflow Status Filter -->
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Status</label>
                <select name="workflow_status" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg">
                  ${selectOptionsHTML(workflowStatusFilter, urlParams.get('workflow_status'), "All Statuses")}
                </select>
              </div>

              <!-- Search Button -->
              <button type="submit" class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm">
                <span class="material-symbols-outlined text-[18px]">search</span>
                Search
              </button>
            </div>

            <!-- Add Button -->
            <button
              type="button"
              data-action="click->${this.identifier}#openNewModal"
              class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm"
            >
              <span class="material-symbols-outlined text-[20px]">add</span>
              Add
            </button>
          </form>

          <!-- Data Table -->
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Branch Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Type</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">City</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="branchesList">
                ${this.branches.map(branch => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td class="py-4 px-6 text-sm">
                      <div class="flex items-center gap-4">
                        <div class="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                          <span class="material-symbols-outlined text-blue-600 dark:text-blue-400">store</span>
                        </div>
                        <div>
                          <p class="font-medium text-slate-900 dark:text-white">${branch.name}</p>
                        </div>
                      </div>
                    </td>
                    <td class="py-4 px-6 text-sm">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        branch.business_type === 'storefront' ? 'bg-green-100 text-green-800' :
                        branch.business_type === 'warehouse' ? 'bg-purple-100 text-purple-800' :
                        'bg-blue-100 text-blue-800'
                      }">
                        ${Helpers.capitalize(branch.business_type?.replace('_', ' ') || 'storefront')}
                      </span>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${branch.city || 'N/A'}</td>
                    <td class="py-4 px-6 text-sm">
                      ${Helpers.statusBadge(branch.workflow_status)}
                    </td>
                    <td class="py-4 px-6 text-sm text-right">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer"
                        data-action="click->${this.identifier}#openShowModal"
                        data-${this.identifier}-branch-id-param="${branch.id}"
                      >
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                    </td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>

          <!-- Pagination -->
          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}
```

### Key Patterns in Index Controller

| Pattern | Purpose |
|---------|---------|
| `extends Companies_LayoutController` | Inherits layout, content rendering |
| `static targets = ["branchesList"]` | DOM target for table body |
| `async connect()` | Load data on page load |
| `fetchJson()` | Fetch data from API |
| `contentHTML()` | Render full page HTML |
| `openNewModal()` | Trigger create modal |
| `openShowModal(event)` | Trigger edit modal with ID param |
| `handleUpdate(event)` | Handle inline edit updates |
| `Helpers.statusBadge()` | Render status badge |
| `selectOptionsHTML()` | Render select options |
| `pagination()` | Render pagination |

## New Modal Controller Pattern

Creates new records via a modal form.

```javascript
// app/javascript/controllers/companies/branches/new_modal_controller.js

import { Controller } from "@hotwired/stimulus"

export default class Companies_Branches_NewModalController extends Controller {
  connect() {
    this.element.innerHTML = this.modalHTML()
  }

  modalHTML() {
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">New Branch</h2>
        
        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Branch Name</label>
            <input type="text" name="branch[name]" required placeholder="e.g. Main Store"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Type</label>
            <select name="branch[business_type]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="storefront">Storefront</option>
              <option value="warehouse">Warehouse</option>
              <option value="headquarters">Headquarters</option>
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">City</label>
            <input type="text" name="branch[city]" placeholder="e.g. Ho Chi Minh City"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->modal#close" 
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg">
            Cancel
          </button>
          <button type="submit" 
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm">
            Save Branch
          </button>
        </div>
      </div>
    `

    return form({
      action: pathname(),
      method: "POST",
      dataAction: `submit->form#submit`,
      className: "p-8 bg-white dark:bg-slate-900 rounded-2xl w-[500px] shadow-2xl",
      html: fields
    })
  }
}
```

### Key Patterns in New Modal Controller

| Pattern | Purpose |
|---------|---------|
| `extends Controller` | Standalone controller (not layout) |
| `connect()` | Render modal on open |
| `this.element.innerHTML = this.modalHTML()` | Inject HTML |
| `form()` helper | Wrap fields with CSRF + method spoofing |
| `name="branch[field]"` | Bracket notation for Rails params |

## Show Modal Controller Pattern

View/edit existing records.

```javascript
// app/javascript/controllers/companies/branches/show_modal_controller.js

import { Controller } from "@hotwired/stimulus"

export default class Companies_Branches_ShowModalController extends Controller {
  branch = null

  connect() {
    this.branch = /** @type {any} */ (window.currentBranch)
    
    if (this.branch) {
      this.element.innerHTML = this.html()
    }
  }

  html() {
    const b = this.branch

    return `
      <div class="flex items-center justify-center">
        <div class="relative w-full max-w-[640px] overflow-hidden rounded-xl bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 shadow-2xl">
          
          <div class="flex items-center justify-between border-b border-slate-200 dark:border-gray-800 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-900 dark:text-white">Branch Details</h3>
            <button data-action="click->${this.identifier}#close" class="rounded-full p-2 text-slate-500">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          <div class="p-6">
            <form method="PATCH" action="${Helpers.company_branch_path(currentCompany().id, b.id)}" class="space-y-4">
              <div>
                <label class="text-[10px] font-bold text-slate-400 uppercase">Name</label>
                <input type="text" name="branch[name]" value="${b.name}"
                  class="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm">
              </div>

              <div>
                <label class="text-[10px] font-bold text-slate-400 uppercase">Type</label>
                <select name="branch[business_type]" class="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm">
                  <option value="storefront" ${b.business_type === 'storefront' ? 'selected' : ''}>Storefront</option>
                  <option value="warehouse" ${b.business_type === 'warehouse' ? 'selected' : ''}>Warehouse</option>
                  <option value="headquarters" ${b.business_type === 'headquarters' ? 'selected' : ''}>Headquarters</option>
                </select>
              </div>

              <div>
                <label class="text-[10px] font-bold text-slate-400 uppercase">City</label>
                <input type="text" name="branch[city]" value="${b.city || ''}"
                  class="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm">
              </div>

              <div class="flex justify-end gap-3 pt-4">
                <button type="submit" 
                  class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm">
                  Save Changes
                </button>
              </div>
            </form>
          </div>
          
        </div>
      </div>
    `
  }

  close(event) {
    event.preventDefault()
    window.closeModal()
  }
}
```

### Key Patterns in Show Modal Controller

| Pattern | Purpose |
|---------|---------|
| `window.currentBranch` | Store globally before opening modal |
| `findById(array, id)` | Find record in local array |
| `form({ action, method: "PATCH" })` | Edit form with method spoofing |
| `window.closeModal()` | Close modal programmatically |

## How to Add New Resource Dashboard

### Step 1: Add Route

In `config/routes.rb`:

```ruby
resources :companies do
  scope module: :companies do
    resources :branches
    resources :my_new_resource  # Add here
  end
end
```

### Step 2: Create JavaScript Controllers

Create directory and files:

```
app/javascript/controllers/companies/my_new_resource/
├── index_controller.js
├── new_modal_controller.js
└── show_modal_controller.js
```

### Step 3: Implement Index Controller

Follow the pattern above, customizing:
- Data properties (`this.branches = []`)
- Filter fields (based on resource's enums)
- Table columns (based on resource's fields)
- Modal params (`data-{identifier}-new-resource-id-param`)

### Step 4: Add Navigation Link

In sidebar layout (`app/javascript/controllers/companies/layout_controller.js`), add navigation item:

```javascript
${sidebarItem({
  icon: "inventory_2",
  label: translate("Products"),
  href: Helpers.company_products_path(currentCompany().id)
})}
```

### Step 5: Add Enums (if needed)

In `app/controllers/client_cache_controller.rb`, add enum definitions:

```ruby
my_new_resource: {
  lifecycle_statuses: LIFECYCLE_STATUS.keys.map { |s| { name: s.to_s.humanize, value: s.to_s } },
  workflow_statuses: WORKFLOW_STATUS.keys.map { |s| { name: s.to_s.humanize, value: s.to_s } },
  business_types: MyNewResource.business_types.keys.map { |t| { name: t.to_s.humanize, value: t.to_s } }
}
```

## Global Helpers

### fetchJson()
Fetch data from API with automatic CSRF injection.

```javascript
const response = await fetchJson()
// or with URL
const response = await fetchJson(`/companies/${companyId}/branches`)
```

### openModal()
Open SweetAlert2 modal with controller.

```javascript
openModal({ html: `<div data-controller="${identifier(Companies_Branches_NewModalController)}"></div>` })
```

### form()
Generate form with CSRF and method spoofing.

```javascript
form({
  action: pathname(),
  method: "POST",  // or "PATCH", "DELETE"
  html: fieldsHTML
})
```

### Helpers.statusBadge()
Render status badge.

```javascript
${Helpers.statusBadge(branch.workflow_status)}
```

### selectOptionsHTML()
Render select options.

```javascript
${selectOptionsHTML(optionsArray, selectedValue, defaultLabel)}
```

## Existing Dashboards Reference

| Resource | Route | Index File |
|----------|-------|------------|
| Dashboards | `/companies/:id/dashboards` | `dashboards/index_controller.js` |
| Branches | `/companies/:id/branches` | `branches/index_controller.js` |
| Departments | `/companies/:id/departments` | `departments/index_controller.js` |
| Products | `/companies/:id/products` | `products/index_controller.js` |
| Services | `/companies/:id/services` | `services/index_controller.js` |
| Orders | `/companies/:id/orders` | `orders/index_controller.js` |
| Bookings | `/companies/:id/bookings` | `bookings/index_controller.js` |
| Customers | `/companies/:id/customers` | `customers/index_controller.js` |
| Invoices | `/companies/:id/invoices` | `invoices/index_controller.js` |
| Employees | `/companies/:id/employees` | `employees/index_controller.js` |
| Permissions | `/companies/:id/permissions` | `permissions/index_controller.js` |
| Policies | `/companies/:id/policies` | `policies/index_controller.js` |

---

*End of documentation*