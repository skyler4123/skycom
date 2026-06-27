# Admin Companies Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build admin companies index (table) and show (detail) pages under `/admin/companies` accessible only to super_admin and admin users.

**Architecture:** Shell-First pattern — Rails returns empty HTML, Stimulus controllers hydrate via JSON API. Admin has its own `Admin_LayoutController` (separate from company-specific layout). Backend `Admin::CompaniesController` inherits from `Admin::ApplicationController` which guards by system_role.

**Tech Stack:** Rails 7+, Stimulus, Tailwind CSS, Pagy, Importmap (no bundler)

---

### Task 1: URL Helpers

**Files:**
- Modify: `app/javascript/controllers/helpers/url_helpers.js`

- [ ] **Step 1: Add admin URL helpers**

Add these two exports at the top of the file (after the imports/head):

```javascript
export const admin_companies_path = () => `/admin/companies`
export const admin_company_path = (companyId) => `/admin/companies/${companyId}`
```

Place them right after the `sign_out_path` line so they're grouped with system-level paths.

- [ ] **Step 2: Verify the file reads correctly**

Run: `node -e "const m = require('./app/javascript/controllers/helpers/url_helpers.js'); console.log('MUST FAIL - ES module')"` 2>&1 || echo "OK — ES module, can't verify via Node but syntax is simple"

---

### Task 2: Backend Controller

**Files:**
- Modify: `app/controllers/admin/companies_controller.rb`

- [ ] **Step 1: Implement controller with index and show**

```ruby
# app/controllers/admin/companies_controller.rb

class Admin::CompaniesController < Admin::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = Company.all
        @pagy, @companies_results = pagy(:offset, scope.order(created_at: :desc), jsonapi: true)

        render json: {
          companies: format_companies(@companies_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    company = Company.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { company: format_company(company) } }
    end
  end

  private

  def format_company(company)
    company.as_json(only: [
      :id, :name, :description, :code,
      :business_type, :lifecycle_status, :workflow_status,
      :ownership_type, :currency_code, :timezone,
      :email, :phone_number, :website,
      :city, :country_code, :employee_count,
      :registration_number, :vat_id, :tax_id,
      :created_at, :updated_at
    ]).merge(
      user: company.user&.as_json(only: [ :id, :name, :email ])
    )
  end

  def format_companies(companies)
    companies.map { |c| format_company(c) }
  end

  def company_params
    params.permit(:name, :description, :code, :business_type, :workflow_status, :email, :phone_number)
  end
end
```

- [ ] **Step 2: Verify syntax**

Run: `bin/rubocop app/controllers/admin/companies_controller.rb`

---

### Task 3: Admin Layout Controller

**Files:**
- Create: `app/javascript/controllers/admin/layout_controller.js`

- [ ] **Step 1: Create Admin_LayoutController**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class Admin_LayoutController extends Controller {
  static targets = ["content"]

  connect() {
    this.id = randomId()
    this.element.id = this.id

    poll(() => {
      if (currentUser()) {
        this.renderLayout()
        return true
      }
      return false
    })
  }

  renderLayout() {
    this.element.className = "min-h-screen bg-slate-50 dark:bg-slate-950"
    this.element.innerHTML = this.layoutHTML()
  }

  renderContent() {
    if (!this.hasContentTarget) return
    this.contentTarget.innerHTML = this.contentHTML()
  }

  layoutHTML() {
    const user = currentUser()
    const isActive = (path) => window.location.pathname.startsWith(path) ? 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400' : 'text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800'

    return `
      <div class="flex h-screen overflow-hidden">
        <!-- Sidebar -->
        <aside class="w-64 bg-white dark:bg-slate-900 border-r border-slate-200 dark:border-slate-800 flex flex-col shrink-0">
          <div class="h-16 flex items-center px-6 border-b border-slate-200 dark:border-slate-800">
            <span class="text-lg font-bold text-slate-900 dark:text-white">Skycom Admin</span>
          </div>
          <nav class="flex-1 overflow-y-auto p-4 space-y-1">
            <a href="/admin/companies"
              class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors cursor-pointer ${isActive('/admin/companies')}">
              <span class="material-symbols-outlined text-[20px]">business</span>
              Companies
            </a>
            <a href="#"
              class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-400 cursor-not-allowed">
              <span class="material-symbols-outlined text-[20px]">group</span>
              Users
              <span class="text-[10px] px-1.5 py-0.5 bg-slate-100 dark:bg-slate-800 rounded text-slate-400 ml-auto">Soon</span>
            </a>
          </nav>
          <div class="p-4 border-t border-slate-200 dark:border-slate-800">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center shrink-0">
                <span class="text-sm font-bold text-blue-600 dark:text-blue-400">${(user?.name || 'A')[0].toUpperCase()}</span>
              </div>
              <div class="min-w-0 flex-1">
                <p class="text-sm font-medium text-slate-900 dark:text-white truncate">${user?.name || 'Admin'}</p>
                <p class="text-xs text-slate-500 truncate">${user?.email || ''}</p>
              </div>
            </div>
            <a href="/sign_out"
              class="mt-3 flex items-center gap-2 px-3 py-2 text-sm text-slate-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors cursor-pointer">
              <span class="material-symbols-outlined text-[18px]">logout</span>
              Sign out
            </a>
          </div>
        </aside>

        <!-- Main content -->
        <div class="flex-1 flex flex-col overflow-hidden">
          <header class="h-16 bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between px-6 shrink-0">
            <h1 class="text-lg font-bold text-slate-900 dark:text-white" data-${this.identifier}-target="title"></h1>
          </header>
          <main class="flex-1 overflow-y-auto" data-${this.identifier}-target="content"></main>
        </div>
      </div>
    `
  }
}
```

- [ ] **Step 2: Verify Stimulus auto-registration**

Run: `ls -la app/javascript/controllers/admin/` — confirm `layout_controller.js` is there alongside the `companies/` subdirectory.

The importmap (`config/importmap.rb`) uses `pin_all_from "app/javascript/controllers", under: "controllers"` — new files are auto-discovered. No manual registration needed.

---

### Task 4: Index Page Controller

**Files:**
- Modify: `app/javascript/controllers/admin/companies/index_controller.js`

- [ ] **Step 1: Implement index controller**

```javascript
import Admin_LayoutController from "controllers/admin/layout_controller"

export default class Admin_Companies_IndexController extends Admin_LayoutController {
  static targets = ["companiesList"]

  /** @type {Array} */ companies = []
  /** @type {Object} */ pagination = {}

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(admin_companies_path())
      this.companies = response.companies || []
      this.pagination = response.pagination || {}
    } catch (error) {
      toast({ type: "error", message: "Failed to load companies" })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  contentHTML() {
    const columns = [
      { key: "name", label: "Company Name" },
      { key: "code", label: "Code" },
      { key: "business_type", label: "Type" },
      { key: "email", label: "Email" },
      { key: "phone_number", label: "Phone" },
      { key: "owner", label: "Owner" },
      { key: "workflow_status", label: "Status" },
      { key: "created_at", label: "Created" }
    ]

    return `
      <div class="p-6">
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <div class="flex items-center justify-between px-6 py-4 border-b border-slate-200 dark:border-slate-800">
            <h2 class="text-base font-bold text-slate-900 dark:text-white">All Companies</h2>
            <span class="text-sm text-slate-500">${this.companies.length} total</span>
          </div>
          <div class="overflow-x-auto">
            ${table({
              rows: this.companies,
              columns,
              identifier: this.identifier,
              target: "companiesList",
              mappingLookup: {},
              renderers: {
                name: (value, record) => `
                  <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center shrink-0">
                      <span class="material-symbols-outlined text-emerald-600 dark:text-emerald-400 text-[18px]">business</span>
                    </div>
                    <a href="${admin_company_path(record.id)}"
                      class="font-medium text-slate-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 transition-colors cursor-pointer">
                      ${value || 'Unnamed'}
                    </a>
                  </div>
                `,
                code: (value) => `<span class="font-mono text-xs bg-slate-100 dark:bg-slate-800/60 px-2 py-0.5 rounded text-slate-600 dark:text-slate-300 font-medium">${value || '—'}</span>`,
                business_type: (value) => {
                  const colors = {
                    retail: 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
                    restaurant: 'bg-orange-50 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400',
                    hospital: 'bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-400',
                    education: 'bg-purple-50 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
                    hotel: 'bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
                    fitness: 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                  }
                  const colorClass = colors[value] || 'bg-slate-50 text-slate-700 dark:bg-slate-800 dark:text-slate-300'
                  return `<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${colorClass} capitalize">${value || '—'}</span>`
                },
                email: (value) => value ? `<span class="text-sm text-slate-600 dark:text-slate-400">${value}</span>` : '<span class="text-slate-300 dark:text-slate-700">—</span>',
                phone_number: (value) => value ? `<span class="text-sm text-slate-600 dark:text-slate-400">${value}</span>` : '<span class="text-slate-300 dark:text-slate-700">—</span>',
                owner: (value, record) => record.user?.name || '<span class="text-slate-300 dark:text-slate-700">—</span>',
                workflow_status: (value) => `${Helpers.statusBadge(value)}`,
                created_at: (value) => value ? `<span class="text-sm text-slate-500">${new Date(value).toLocaleDateString()}</span>` : '—'
              },
              renderActions: (record) => `
                <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                  <a href="${admin_company_path(record.id)}"
                    class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer">
                    <span class="material-symbols-outlined text-[20px]">visibility</span>
                  </a>
                </td>`
            })}
          </div>
          <div class="flex justify-center py-4 border-t border-slate-200 dark:border-slate-800">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}
```

- [ ] **Step 2: Verify syntax**

Run: `bin/rubocop` — should only check Ruby. No JS linter available via bin/rubocop.

---

### Task 5: Show Page Controller

**Files:**
- Create: `app/javascript/controllers/admin/companies/show_controller.js`

- [ ] **Step 1: Create show controller**

```javascript
import Admin_LayoutController from "controllers/admin/layout_controller"

export default class Admin_Companies_ShowController extends Admin_LayoutController {
  /** @type {Object|null} */ company = null

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const companyId = pathParts[pathParts.length - 1]

    try {
      const response = await fetchJson(`${admin_company_path(companyId)}.json`)
      this.company = response.company
    } catch (error) {
      toast({ type: "error", message: "Failed to load company" })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  contentHTML() {
    const c = this.company
    if (!c) return '<div class="p-8 text-center text-slate-500">Company not found.</div>'

    const businessTypeColors = {
      retail: 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
      restaurant: 'bg-orange-50 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400',
      hospital: 'bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-400',
      education: 'bg-purple-50 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
      hotel: 'bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
      fitness: 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400'
    }

    const detailFields = [
      { label: "Business Type", value: c.business_type, type: "badge", badgeClass: businessTypeColors[c.business_type] || 'bg-slate-50 text-slate-700' },
      { label: "Email", value: c.email, type: "link", href: `mailto:${c.email}` },
      { label: "Phone", value: c.phone_number, type: "link", href: `tel:${c.phone_number}` },
      { label: "Website", value: c.website, type: "link", href: c.website },
      { label: "City", value: c.city },
      { label: "Country", value: c.country_code?.toUpperCase() },
      { label: "Employee Count", value: c.employee_count != null ? String(c.employee_count) : null },
      { label: "Registration Number", value: c.registration_number },
      { label: "Tax ID", value: c.tax_id },
      { label: "VAT ID", value: c.vat_id },
      { label: "Ownership", value: c.ownership_type ? c.ownership_type.replace('_', ' ') : null },
      { label: "Currency", value: c.currency_code?.toUpperCase() },
      { label: "Timezone", value: c.timezone ? `UTC${c.timezone > 0 ? '+' : ''}${c.timezone}` : null },
      { label: "Description", value: c.description, type: "full" }
    ]

    return `
      <div class="p-6">
        <a href="/admin/companies"
          class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 mb-6 cursor-pointer">
          <span class="material-symbols-outlined text-[18px]">arrow_back</span>
          Back to Companies
        </a>

        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden">
          <!-- Header -->
          <div class="px-6 py-5 border-b border-slate-200 dark:border-slate-800">
            <div class="flex items-start justify-between">
              <div class="flex items-center gap-4">
                <div class="w-12 h-12 rounded-xl bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center shrink-0">
                  <span class="material-symbols-outlined text-emerald-600 dark:text-emerald-400 text-[24px]">business</span>
                </div>
                <div>
                  <h2 class="text-xl font-bold text-slate-900 dark:text-white">${c.name || 'Unnamed Company'}</h2>
                  <div class="flex items-center gap-2 mt-1">
                    ${c.code ? `<span class="font-mono text-xs bg-slate-100 dark:bg-slate-800 px-2 py-0.5 rounded text-slate-500">${c.code}</span>` : ''}
                    ${Helpers.statusBadge(c.workflow_status)}
                  </div>
                </div>
              </div>
              <div class="text-right text-xs text-slate-400">
                <div>Created ${c.created_at ? new Date(c.created_at).toLocaleDateString() : '—'}</div>
                <div class="mt-0.5">Updated ${c.updated_at ? new Date(c.updated_at).toLocaleDateString() : '—'}</div>
              </div>
            </div>
          </div>

          <!-- Detail Grid -->
          <div class="p-6">
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              ${detailFields.map(field => {
                if (field.value == null || field.value === '') return ''

                switch (field.type) {
                  case 'badge':
                    return `
                      <div>
                        <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase mb-1">${field.label}</p>
                        <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium capitalize ${field.badgeClass}">${field.value}</span>
                      </div>`
                  case 'link':
                    return `
                      <div>
                        <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase mb-1">${field.label}</p>
                        <a href="${field.href}" class="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 cursor-pointer">${field.value}</a>
                      </div>`
                  case 'full':
                    return `
                      <div class="sm:col-span-2 lg:col-span-3">
                        <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase mb-1">${field.label}</p>
                        <p class="text-sm text-slate-700 dark:text-slate-300">${field.value}</p>
                      </div>`
                  default:
                    return `
                      <div>
                        <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase mb-1">${field.label}</p>
                        <p class="text-sm font-medium text-slate-900 dark:text-white">${field.value}</p>
                      </div>`
                }
              }).join('')}
            </div>
          </div>

          <!-- Owner Section -->
          ${c.user ? `
            <div class="px-6 py-4 border-t border-slate-200 dark:border-slate-800">
              <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase mb-3">Owner</p>
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                  <span class="text-sm font-bold text-blue-600 dark:text-blue-400">${(c.user.name || '?')[0].toUpperCase()}</span>
                </div>
                <div>
                  <p class="text-sm font-medium text-slate-900 dark:text-white">${c.user.name || 'Unknown'}</p>
                  <p class="text-sm text-slate-500">${c.user.email || ''}</p>
                </div>
              </div>
            </div>
          ` : ''}
        </div>
      </div>
    `
  }
}
```

- [ ] **Step 2: Verify syntax**

Check the file was created: `ls -la app/javascript/controllers/admin/companies/show_controller.js`

---

### Task 6: Verify

- [ ] **Step 1: Run the dev server and verify no errors**

```bash
bin/dev
```

Then open the browser to `/admin/companies` and check the JS console for errors. Also check that:
- Non-admin users get redirected to root
- The index page shows the companies table with correct data
- Clicking a company name navigates to the show page
- The show page displays all company details

- [ ] **Step 2: Run RuboCop**

```bash
bin/rubocop --autocorrect-all
```
