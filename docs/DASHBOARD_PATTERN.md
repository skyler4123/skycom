# Skycom Resource Dashboard Pattern

This document describes how resource dashboards work in Skycom and how to add new dashboards. The Products dashboard is the canonical reference implementation.

## Overview

Each resource has a dedicated set of pages at `/companies/:company_id/{resource}`. All pages follow the Shell-First pattern — the server returns a minimal HTML shell, JavaScript fetches JSON and renders content client-side.

---

## Architecture

### Route Structure

All resource routes are defined in `config/routes.rb`:

```ruby
resources :companies do
  scope module: :companies do
    resources :products
    # Add new resources here
  end
end
```

This generates standard RESTful routes with four view actions:

| Path | Action | Purpose |
|------|--------|---------|
| `GET /companies/:id/products` | `index` | List with dynamic table |
| `GET /companies/:id/products/new` | `new` | Creation form |
| `GET /companies/:id/products/:id` | `show` | Read-only detail view |
| `GET /companies/:id/products/:id/edit` | `edit` | Edit form |

### File Structure

Each resource has 4 JavaScript controllers:

```
app/javascript/controllers/companies/{resource}/
├── index_controller.js    # List view — table with dynamic columns, category filter
├── new_controller.js      # Creation form — type-aware dynamic property fields
├── show_controller.js     # Read-only detail — type-aware value display
└── edit_controller.js     # Edit form — type-aware fields, full-page PATCH
```

Controllers are auto-registered via `pin_all_from` in `config/importmap.rb`. Creating a file at the correct path is sufficient — no manual registration needed.

**Important**: After adding or deleting a Stimulus controller file, run `bin/rails assets:clobber` to clear the stale compiled asset cache.

---

## Backend Implementation

### Controller Pattern

Each GET action uses Shell-First (`format.html` + `format.json`). Mutation actions (`create`, `update`) are HTML-only with server redirects.

```ruby
# app/controllers/companies/products_controller.rb
class Companies::ProductsController < Companies::ApplicationController
  # GET — Shell-First (render empty layout, serve JSON)
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.products
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
        @pagy, @results = pagy(:offset, scope, jsonapi: true)
        render json: { products: format_products(@results), pagination: @pagy.data_hash }
      end
    end
  end

  def show
    product = current_company.products.find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { product: format_product(product) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    product = current_company.products.find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { product: format_product(product) } }
    end
  end

  # POST/PATCH — HTML-only, server redirects on success/error
  def create
    product = current_company.products.new(product_params)
    if product.save
      redirect_to company_product_path(current_company, product), notice: "Product created successfully"
    else
      redirect_to new_company_product_path(current_company),
        alert: product.errors.full_messages.to_sentence
    end
  end

  def update
    product = current_company.products.find(params[:id])
    if product.update(product_params)
      redirect_to company_product_path(current_company, product), notice: "Product updated successfully."
    else
      redirect_to edit_company_product_path(current_company, product),
        alert: product.errors.full_messages.to_sentence
    end
  end

  private

  # Each GET action needs a format_{resource} method that includes all property_* columns
  def format_product(product)
    product.as_json(only: [
      :id, :name, :description, :code, :category_id,
      :lifecycle_status, :workflow_status, :business_type,
      :created_at, :updated_at,
      # Include ALL property_* columns for the frontend
      :property_string_1, :property_string_2, # ... through 10
      :property_text_1, :property_text_2,      # ... through 5
      :property_integer_1, :property_integer_2, # ... through 20
      :property_decimal_1, :property_decimal_2, # ... through 10
      :property_boolean_1, :property_boolean_2, # ... through 10
      :property_datetime_1, :property_datetime_2 # ... through 10
    ]).merge(
      category: product.category&.as_json(only: [ :id, :name ])
    )
  end

  # Strong params must permit all property_* columns
  def product_params
    property_keys = (1..10).map { |i| "property_string_#{i}" } +
                    (1..5).map { |i| "property_text_#{i}" } +
                    (1..20).map { |i| "property_integer_#{i}" } +
                    (1..10).map { |i| "property_decimal_#{i}" } +
                    (1..10).map { |i| "property_boolean_#{i}" } +
                    (1..10).map { |i| "property_datetime_#{i}" }

    params.require(:product).permit(
      :name, :description, :business_type, :workflow_status, :category_id,
      *property_keys
    )
  end
end
```

### Policy Methods

Every view action needs a corresponding policy method. `edit?` maps to `update` permission, `new?` maps to `create`:

```ruby
# app/policies/companies/products_policy.rb
class Companies::ProductsPolicy < ApplicationPolicy
  def index?;  record.can?(:read,   Product) end
  def show?;   record.can?(:read,   Product) end
  def new?;    record.can?(:create, Product) end
  def create?; record.can?(:create, Product) end
  def edit?;   record.can?(:update, Product) end
  def update?; record.can?(:update, Product) end
end
```

---

## URL Helpers (No Hardcoded Paths)

All paths must use helpers from `app/javascript/controllers/helpers/url_helpers.js`. These are available globally as `Helpers.*`.

| Helper | Returns |
|--------|---------|
| `Helpers.company_products_path(companyId)` | `/companies/:id/products` |
| `Helpers.new_company_product_path(companyId)` | `/companies/:id/products/new` |
| `Helpers.company_product_path(companyId, productId)` | `/companies/:id/products/:id` |
| `Helpers.edit_company_product_path(companyId, productId)` | `/companies/:id/products/:id/edit` |
| `Helpers.create_company_products_path(companyId)` | `/companies/:id/products` |

Add new helpers to `url_helpers.js` when adding a new resource. Never hardcode `/companies/...` paths in controller HTML templates.

---

## Index Controller Pattern

The index controller renders a dynamic table with category filtering, client-side column configuration, and navigation links.

```javascript
// app/javascript/controllers/companies/products/index_controller.js
import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Products_IndexController extends Companies_LayoutController {
  static targets = ["categorySelect", "productsList"]

  /** @type {(Product & { name: string })[]} */
  products = []

  async connect() {
    super.connect()

    // Resolve category from URL param or default
    this.categoryIdValue = new URLSearchParams(window.location.search).get('category_id')
      || this.defaultFilterCategory()?.id

    // Resolve PropertyMapping from client cache
    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryIdValue)
    if (propertyMapping) this.propertyMappingIdValue = propertyMapping.id

    // Resolve TableConfig from client cache (by property_mapping_id)
    const tableConfig = currentTableConfigs().find(c => c.property_mapping_id === this.propertyMappingIdValue)
    if (tableConfig) this.tableConfigIdValue = tableConfig.id

    try {
      const response = await fetchJson({ params: { category_id: this.categoryIdValue } })
      this.products = response.products || []
      this.pagination = response.pagination || {}
    } catch (error) {
      toast({ type: "error", message: "Failed to load products" })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  productsCategories() {
    return currentCategories().filter(c => c.resource_name === "products")
  }

  defaultFilterCategory() {
    return this.productsCategories()[0]
  }

  contentHTML() {
    const categoryFilter = this.productsCategories()
    const categoryValue = this.categoryIdValue || this.defaultFilterCategory()?.id
    const propertyMapping = this.currentPropertyMapping()

    const mappingLookup = (propertyMapping?.property_metadata || []).reduce((acc, field) => {
      acc[field.key] = field
      return acc
    }, {})

    const fallbackColumns = [
      { key: "name", label: "Product Name" },
      { key: "code", label: "Product Code" },
      { key: "workflow_status", label: "Status" }
    ]

    const rawColumns = this.currentTableConfig()?.columns_metadata || fallbackColumns
    const visibleColumns = rawColumns.filter(col => col.visible !== false)

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <!-- Filter + Add -->
          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end justify-between gap-4 w-full">
              <div class="flex flex-wrap items-center gap-3 w-full lg:w-auto">
                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Category</label>
                  <select
                    name="category_id"
                    class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300"
                  >
                    ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), categoryValue)}
                  </select>
                </div>
                <div class="flex gap-2 mt-auto">
                  <button type="submit" class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm flex items-center gap-2">
                    <span class="material-symbols-outlined text-[18px]">search</span>
                    Search
                  </button>
                </div>
              </div>

              <a href="${Helpers.new_company_product_path(currentCompany().id)}"
                class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm whitespace-nowrap cursor-pointer">
                <span class="material-symbols-outlined text-[20px]">add</span>
                Add
              </a>
            </form>
          </div>

          <!-- Dynamic Table -->
          <div class="overflow-x-auto">
            ${table({
              rows: this.products,
              columns: visibleColumns,
              identifier: this.identifier,
              target: "productsList",
              mappingLookup,
              renderers: {
                name: (value, record) => `
                  <div class="flex items-center gap-4">
                    <div class="w-8 h-8 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center shrink-0">
                      <span class="material-symbols-outlined text-emerald-600 dark:text-emerald-400 text-[18px]">inventory_2</span>
                    </div>
                    <a href="${Helpers.company_product_path(currentCompany().id, record.id)}"
                      class="font-medium text-slate-900 dark:text-white overflow-visible whitespace-normal hover:text-blue-600 dark:hover:text-blue-400 transition-colors cursor-pointer">
                      ${value || 'Unnamed Product'}
                    </a>
                  </div>
                `,
                code: (value) => `<span class="font-mono text-xs bg-slate-100 dark:bg-slate-800/60 px-2 py-0.5 rounded text-slate-600 dark:text-slate-300 font-medium">${value || '—'}</span>`
              },
              renderActions: (record) => `
                <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                  <a href="${Helpers.edit_company_product_path(currentCompany().id, record.id)}"
                    class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer">
                    <span class="material-symbols-outlined text-[20px]">edit</span>
                  </a>
                </td>`
            })}
          </div>

          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}
```

### Key Patterns

| Pattern | Purpose |
|---------|---------|
| `extends Companies_LayoutController` | Inherits layout, sidebar, `contentTarget`, `renderContent()` |
| `static targets = [..."productsList"]` | DOM target for table body |
| `fetchJson({ params: { category_id } })` | Fetches data with query params |
| `table()` helper | Renders dynamic column table with `mappingLookup` |
| `renderActions` callback | Renders the "Edit" column with links to `/edit` |
| Name `<a>` link | Each record name links to the show page |
| `productsCategories()` / `defaultFilterCategory()` | Category helpers scoped to resource |

### Category Filter Rules

- No "All Categories" option — every product belongs to a category, and dynamic columns have no meaning without one
- First category is the default filter (from `defaultFilterCategory()`)
- `selectOptionsHTML` is called **without** a default label (3rd arg omitted)

---

## New Page Controller Pattern

The new page renders a creation form with type-aware dynamic property fields. The form submits as traditional HTML (`data-turbo="false"`), and the server redirects on success or error.

```javascript
// app/javascript/controllers/companies/products/new_controller.js
import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Products_NewController extends Companies_LayoutController {
  /** @type {string | null} */
  categoryId = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  connect() {
    super.connect()

    this.categoryId = new URLSearchParams(window.location.search).get('category_id')
      || this.defaultFilterCategory()?.id || null

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.property_metadata || []

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  productsCategories() { /* same as index — filter by resource_name */ }
  defaultFilterCategory() { /* same as index */ }

  onCategoryChange(event) {
    this.categoryId = event.target.value
    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.property_metadata || []
    const dynamicDiv = this.element.querySelector('#dynamic-fields')
    if (dynamicDiv) {
      dynamicDiv.innerHTML = this.dynamicFieldsHTML()
    }
  }

  renderField({ key, label, type }) {
    // Type-aware input rendering
    switch (type) {
      case 'boolean':
        return `
          <div class="flex items-center gap-3 py-2">
            <input type="hidden" name="product[${key}]" value="false">
            <input type="checkbox" name="product[${key}]" value="true"
              class="h-5 w-5 rounded border-slate-300 text-blue-600 cursor-pointer">
            <span class="text-sm text-slate-900 dark:text-white">${label}</span>
          </div>
        `
      case 'integer':
        return `<input type="number" step="1" name="product[${key}]" placeholder="${label}" class="...">`
      case 'decimal':
        return `<input type="number" step="0.01" name="product[${key}]" placeholder="${label}" class="...">`
      case 'datetime':
        return `<input type="datetime-local" name="product[${key}]" class="...">`
      case 'text':
        return `<textarea name="product[${key}]" rows="3" placeholder="${label}" class="..."></textarea>`
      default:
        return `<input type="text" name="product[${key}]" placeholder="${label}" class="...">`
    }
  }

  dynamicFieldsHTML() {
    if (this.propertyMetadata.length === 0) return ''
    return `
      <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">Properties</h3>
        <div class="grid grid-cols-2 gap-4">
          ${this.propertyMetadata.map(f => this.renderField(f)).join('')}
        </div>
      </div>
    `
  }

  contentHTML() {
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">New Product</h2>

        <div class="space-y-1">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Category</label>
          <select name="product[category_id]" data-action="change->${this.identifier}#onCategoryChange"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
            ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), this.categoryId)}
          </select>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">Name</label>
            <input type="text" name="product[name]" required placeholder="e.g. Premium Widget"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">Type</label>
            <select name="product[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${(Enums()?.product?.business_types || []).map(t =>
                `<option value="${t.value}">${t.name}</option>`
              ).join('')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">Description</label>
            <textarea name="product[description]" rows="3"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm"></textarea>
          </div>
        </div>

        <div id="dynamic-fields">${this.dynamicFieldsHTML()}</div>

        <div class="flex justify-end pt-6 border-t border-slate-200 dark:border-slate-700">
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            Save Product
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.create_company_products_path(currentCompany().id),
          method: "POST",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false"`,
          html: fields
        })}
      </div>
    `
  }
}
```

### Key Patterns

| Pattern | Purpose |
|---------|---------|
| `extends Companies_LayoutController` | Page controller (not modal) — gets sidebar |
| `form()` helper | Wraps fields with CSRF + method spoofing |
| `data-turbo="false"` | Disables Turbo — full page POST |
| `name="resource[field]"` | Bracket notation for Rails Strong Params |
| `onCategoryChange()` | Client-side swap of dynamic property fields |
| `renderField({ key, label, type })` | Type-aware input rendering (6 types) |
| Server redirects | Success → show page; Error → new page with flash |

---

## Show Page Controller Pattern

The show page is a read-only detail view that fetches a single record's JSON and renders it with type-aware formatting.

```javascript
// app/javascript/controllers/companies/products/show_controller.js
import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Products_ShowController extends Companies_LayoutController {
  /** @type {Product | null} */
  product = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const productId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_product_path(companyId, productId)}.json`)
      this.product = response.product

      if (this.product?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.product.category_id)
        this.propertyMetadata = propertyMapping?.property_metadata || []
      }

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      poll(() => {
        if (this.hasContentTarget) {
          this.contentTarget.innerHTML = '<div class="p-8 text-center text-red-600">Failed to load product.</div>'
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    return this.showHTML()
  }

  formatDisplayValue(value, type) {
    if (value === null || value === undefined) return '<span class="text-slate-300 dark:text-slate-700">—</span>'
    switch (type) {
      case 'boolean':
        return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md ${value ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-50 text-slate-700'}">${value ? 'Yes' : 'No'}</span>`
      case 'integer':
        return `<span class="font-mono text-slate-900 dark:text-slate-100">${Number(value).toLocaleString()}</span>`
      case 'decimal':
        return `<span class="font-mono font-medium text-blue-600 dark:text-blue-400">${Number(value).toFixed(2)}</span>`
      case 'datetime':
        return `<span class="text-sm text-slate-900 dark:text-white">${new Date(value).toLocaleString()}</span>`
      default:
        return `<span class="text-sm text-slate-900 dark:text-white">${value}</span>`
    }
  }

  showHTML() {
    const p = this.product
    if (!p) return '<div class="p-8 text-center">Product not found.</div>'

    const companyId = window.location.pathname.split("/")[2]
    const category = currentCategories().find(c => c.id === p.category_id)

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase mb-4">Properties</h3>
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => `
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600">
                <span class="material-symbols-outlined text-[20px]">${field.type === 'boolean' ? 'check_circle' : field.type === 'datetime' ? 'calendar_month' : 'text_fields'}</span>
              </div>
              <div class="min-w-0 flex-1">
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${field.label}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${this.formatDisplayValue(p[field.key], field.type)}</p>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    ` : ''

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_products_path(companyId)}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 mb-6">
            <span class="material-symbols-outlined text-[18px]">arrow_back</span>
            Back to Products
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl bg-emerald-100 dark:bg-gray-800 flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-emerald-600">inventory_2</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-slate-900 dark:text-white">${p.name}</h2>
              <p class="font-semibold text-emerald-600">${p.description || ''}</p>
              <span class="inline-flex items-center rounded-lg bg-emerald-100 px-3 py-1 text-xs font-bold text-emerald-700 uppercase mt-2">${p.code || 'N/A'}</span>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-6 sm:grid-cols-2">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600">
                <span class="material-symbols-outlined">category</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500">Type</p>
                <p class="text-sm font-semibold text-slate-900">${Helpers.capitalize(p.business_type || 'physical')}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600">
                <span class="material-symbols-outlined">toggle_on</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500">Status</p>
                <p class="text-sm font-semibold">${Helpers.statusBadge(p.workflow_status)}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600">
                <span class="material-symbols-outlined">folder</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500">Category</p>
                <p class="text-sm font-semibold text-slate-900">${category?.name || 'N/A'}</p>
              </div>
            </div>
          </div>

          ${dynamicFields}

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-slate-200 dark:border-gray-800">
            <a href="${Helpers.edit_company_product_path(companyId, p.id)}"
              class="inline-flex items-center px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer">
              Edit Product
            </a>
          </div>
        </div>
      </div>
    `
  }
}
```

### Key Patterns

| Pattern | Purpose |
|---------|---------|
| `extends Companies_LayoutController` | Gets sidebar + content rendering |
| `fetchJson(JSON url)` | Fetches single record (`.json` suffix) |
| `formatDisplayValue(value, type)` | Type-aware read-only rendering |
| `propertyMetadata` from cache | Resolved from `currentPropertyMappings()` |
| "Edit Product" `<a>` link | Navigates to `/edit` page |
| "Back to Products" `<a>` link | Navigates back to index |

---

## Edit Page Controller Pattern

The edit page renders a pre-filled form with the same type-aware dynamic property fields as the new page. Submits as traditional HTML PATCH, server redirects on success or error.

```javascript
// app/javascript/controllers/companies/products/edit_controller.js
import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Products_EditController extends Companies_LayoutController {
  /** @type {Product | null} */
  product = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const productId = pathParts[4] // /companies/:id/products/:id/edit
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_product_path(companyId, productId)}.json`)
      this.product = response.product

      if (this.product?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.product.category_id)
        this.propertyMetadata = propertyMapping?.property_metadata || []
      }

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) { /* show error message */ }
  }

  contentHTML() {
    const p = this.product
    if (!p) return '<div class="p-8 text-center">Product not found.</div>'

    const companyId = window.location.pathname.split("/")[2]
    const businessTypes = Enums()?.product?.business_types || []
    const workflowStatuses = Enums()?.product?.workflow_statuses || []

    // Dynamic property fields — same type-aware rendering as new page
    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase mb-4">Properties</h3>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => {
            const value = p[field.key]
            let inputHTML = ''
            switch (field.type) {
              case 'boolean':
                inputHTML = `
                  <input type="hidden" name="product[${field.key}]" value="false">
                  <input type="checkbox" name="product[${field.key}]" value="true" ${value ? 'checked' : ''}
                    class="rounded border-slate-300 text-blue-600 cursor-pointer">`
                break
              case 'integer':
                inputHTML = `<input type="number" step="1" name="product[${field.key}]" value="${value ?? ''}" class="...">`
                break
              case 'decimal':
                inputHTML = `<input type="number" step="0.01" name="product[${field.key}]" value="${value ?? ''}" class="...">`
                break
              case 'datetime':
                inputHTML = `<input type="datetime-local" name="product[${field.key}]" value="${value ?? ''}" class="...">`
                break
              case 'text':
                inputHTML = `<textarea name="product[${field.key}]" rows="3" class="...">${value ?? ''}</textarea>`
                break
              default:
                inputHTML = `<input type="text" name="product[${field.key}]" value="${value ?? ''}" class="...">`
            }
            return `
              <div>
                <label class="text-xs font-medium text-slate-500">${field.label}</label>
                ${inputHTML}
              </div>
            `
          }).join('')}
        </div>
      </div>
    ` : ''

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">Edit Product</h2>
        <p class="text-sm text-slate-500">${p.name}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500">Name</label>
            <input type="text" name="product[name]" value="${p.name || ''}" required class="...">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500">Description</label>
            <textarea name="product[description]" rows="2" class="...">${p.description || ''}</textarea>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500">Type</label>
            <select name="product[business_type]" class="...">
              ${selectOptionsHTML(businessTypes, p.business_type || 'physical')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500">Status</label>
            <select name="product[workflow_status]" class="...">
              ${selectOptionsHTML(workflowStatuses, p.workflow_status)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500">Category</label>
            <input type="text" value="${currentCategories().find(c => c.id === p.category_id)?.name || ''}" disabled class="...">
            <input type="hidden" name="product[category_id]" value="${p.category_id}">
          </div>
        </div>

        ${dynamicFields}

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_product_path(companyId, p.id)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
            Cancel
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            Save Changes
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_product_path(companyId, p.id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
```

### Key Patterns

| Pattern | Purpose |
|---------|---------|
| `extends Companies_LayoutController` | Page controller with sidebar |
| `form()` with `method: "PATCH"` | Rails method spoofing for update |
| `data-turbo="false"` | Full-page submission |
| `novalidate` | Allows server-side validation to fire |
| `selectOptionsHTML(enums, value)` | Enum dropdown with current value pre-selected |
| Category disabled input | Read-only display with hidden field for submission |
| Cancel link | Returns to show page |
| Server redirects | Success → show page; Error → edit page with flash |

---

## Adding a New Resource Dashboard

### Step 1: Add Route

```ruby
# config/routes.rb
resources :companies do
  scope module: :companies do
    resources :products
    resources :my_new_resource
  end
end
```

### Step 2: Create JavaScript Controllers

```
app/javascript/controllers/companies/my_new_resource/
├── index_controller.js   # extends Companies_LayoutController
├── new_controller.js     # extends Companies_LayoutController
├── show_controller.js    # extends Companies_LayoutController
└── edit_controller.js    # extends Companies_LayoutController
```

### Step 3: Add URL Helpers

```javascript
// app/javascript/controllers/helpers/url_helpers.js
export const company_my_new_resources_path = (companyId) => `/companies/${companyId}/my_new_resources`
export const new_company_my_new_resource_path = (companyId) => `/companies/${companyId}/my_new_resources/new`
export const company_my_new_resource_path = (companyId, id) => `/companies/${companyId}/my_new_resources/${id}`
export const edit_company_my_new_resource_path = (companyId, id) => `/companies/${companyId}/my_new_resources/${id}/edit`
export const create_company_my_new_resources_path = (companyId) => `/companies/${companyId}/my_new_resources`
```

### Step 4: Create Backend Controller

```ruby
# app/controllers/companies/my_new_resources_controller.rb
class Companies::MyNewResourcesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { my_new_resources: format_collection(scope) } }
    end
  end

  def show
    record = scope.find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { my_new_resource: format_record(record) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    record = scope.find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { my_new_resource: format_record(record) } }
    end
  end

  def create
    record = scope.new(resource_params)
    if record.save
      redirect_to url_for([:company, record]), notice: "Created"
    else
      redirect_to new_polymorphic_path([:company, record.class]),
        alert: record.errors.full_messages.to_sentence
    end
  end

  def update
    record = scope.find(params[:id])
    if record.update(resource_params)
      redirect_to url_for([:company, record]), notice: "Updated"
    else
      redirect_to edit_polymorphic_path([:company, record]),
        alert: record.errors.full_messages.to_sentence
    end
  end

  private

  def scope
    current_company.my_new_resources
  end
end
```

### Step 5: Create Policy

```ruby
# app/policies/companies/my_new_resources_policy.rb
class Companies::MyNewResourcesPolicy < ApplicationPolicy
  def index?;  record.can?(:read,   MyNewResource) end
  def show?;   record.can?(:read,   MyNewResource) end
  def new?;    record.can?(:create, MyNewResource) end
  def create?; record.can?(:create, MyNewResource) end
  def edit?;   record.can?(:update, MyNewResource) end
  def update?; record.can?(:update, MyNewResource) end
end
```

### Step 6: Add Sidebar Link

```javascript
// app/javascript/controllers/companies/layout_controller.js
${sidebarItem({
  icon: "inventory_2",
  label: translate("My Resources"),
  href: Helpers.company_my_new_resources_path(currentCompany().id)
})}
```

### Step 7: Create Test Fixtures

When writing feature tests, seed the client cache in localStorage:

```ruby
before do
  page.execute_script("localStorage.clear()")

  company_data = JSON.parse(company.to_json).merge(
    "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
    "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
    "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
    "branches" => [], "departments" => [], "roles" => []
  )

  page.execute_script("localStorage.setItem('client_cache_data', arguments[0])",
    { user: owner.as_json, companies: [ company_data ], enums: enums_data, employees: [] }.to_json)

  page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
  page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
end
```

Three critical steps:
1. **`.reset`** associations before serializing to JSON
2. **Lock cookie version** — prevents `ClientCacheController` from overwriting
3. **Seed enums explicitly** — `localStorage` pre-seed doesn't include enums unless you add them

---

## Global Helpers Reference

| Helper | Usage | Purpose |
|--------|-------|---------|
| `fetchJson(url)` | `const data = await fetchJson()` | Fetch JSON with CSRF token injection |
| `form({ action, method, attributes, html })` | `form({ action: "...", method: "POST", attributes: "...", html: fields })` | Generate form with CSRF + method spoofing |
| `table({ rows, columns, identifier, target, mappingLookup, renderers, renderActions })` | `table({ rows, columns, ...renderActions })` | Render dynamic column table |
| `Helpers.statusBadge(value)` | `${Helpers.statusBadge(p.workflow_status)}` | Render status badge |
| `selectOptionsHTML(array, selected, defaultLabel)` | `${selectOptionsHTML(enums, value)}` | Render select options |
| `pagination(data)` | `${pagination(this.pagination)}` | Render pagination links |
| `poll(callback)` | `poll(() => this.hasContentTarget && this.renderContent())` | Wait for DOM ready |
| `cloneNewKey(array, from, to)` | `cloneNewKey(categories, "id", "value")` | Rename object key |

---

## Existing Dashboards

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
