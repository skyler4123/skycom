# Dashboard Migration: Modal → Page Pattern

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate 10 resource dashboards from the old modal-based pattern (SweetAlert2 openModal) to the new Shell-First page pattern (separate /show, /new, /edit pages with sidebar).

**Architecture:** Each resource gets 4 dedicated Stimulus page controllers (index, new, show, edit) instead of 1 index + 2 modal controllers. Ruby controllers gain `show`/`new`/`edit` Shell-First actions and HTML-only `create`/`update` with server redirects. Policies get `show?`/`new?`/`edit?` methods.

**Tech Stack:** Rails 7+, Stimulus, Tailwind, Importmap, Pundit, RSpec (Capybara + Selenium), Pagy

---

## 1. Reference: Products Implemented Pattern

The Products dashboard is the canonical reference. Key files:

| File | What it shows |
|------|---------------|
| `app/javascript/controllers/companies/products/index_controller.js` | `table()` helper, name links to show, edit links, `onCategoryChange()` |
| `app/javascript/controllers/companies/products/new_controller.js` | Form with category + dynamic property fields |
| `app/javascript/controllers/companies/products/show_controller.js` | `formatDisplayValue()`, back link, edit link |
| `app/javascript/controllers/companies/products/edit_controller.js` | Pre-filled form, PATCH via `form()`, `data-turbo="false"` |
| `app/controllers/companies/products_controller.rb` | Shell-First `show`/`new`/`edit`, HTML-only `create`/`update` |
| `app/policies/companies/products_policy.rb` | `show?`, `new?`, `edit?` methods |
| `spec/features/companies/products/index_spec.rb` | localStorage cache seeding + dynamic table tests |
| `spec/features/companies/products/new_spec.rb` | Form rendering + creation with redirect |
| `spec/features/companies/products/show_spec.rb` | Detail view assertions |
| `spec/features/companies/products/edit_spec.rb` | Edit form + update + validation error |
| `spec/features/companies/products/permissions_spec.rb` | Permission scenarios |

---

## 2. Resource Inventory

### All 10 resources to migrate

| # | Resource | Tests? | Extra Fields | Notes |
|---|----------|--------|-------------|-------|
| 1 | Branches | ✅ | address, phone, email, country_code | Pilot |
| 2 | Departments | ✅ | email | Simple |
| 3 | Brands | ✅ | phone, email (has debug `Rails.logger.warn`) | Remove debug lines |
| 4 | Services | ✅ | none | Simplest |
| 5 | Employees | ✅ Max | user, branch, roles, departments | Most complex, has Discard |
| 6 | Customers | ✅ | email | |
| 7 | Orders | ❌ | currency_code, customer_id | |
| 8 | Invoices | ❌ | currency, code, total_price, due_date, order_id | Has `number`→`code` bug |
| 9 | Facilities | ❌ | branch_id, phone, email, code | |
| 10 | Categories | ❌ | resource_name (filters by type) | Admin tool, lowest priority |

### Not affected (already clean):
Stocks, Stock imports, Stock exports, Stock transfers, Policies, Permissions, Dashboards

---

## 3. Per-Resource File Changes

Each resource follows the same pattern. Template code is in the Product files — copy and adapt.

### 3.1 DEPARTMENTS (example — same pattern as all)

Files to **delete**:
- `app/javascript/controllers/companies/departments/new_modal_controller.js`
- `app/javascript/controllers/companies/departments/show_modal_controller.js`

Files to **create**:
- `app/javascript/controllers/companies/departments/new_controller.js`
- `app/javascript/controllers/companies/departments/show_controller.js`
- `app/javascript/controllers/companies/departments/edit_controller.js`

Files to **modify**:
- `app/javascript/controllers/companies/departments/index_controller.js` — remove modal imports, replace with `table()` helper + `Helpers.new_company_department_path()` + `Helpers.company_department_path()` + `Helpers.edit_company_department_path()`
- `app/controllers/companies/departments_controller.rb` — add `show`, `new`, `edit` actions; convert `create`/`update` to HTML redirect
- `app/policies/companies/departments_policy.rb` — add `show?`, `new?`, `edit?`
- `app/javascript/controllers/helpers/url_helpers.js` — add `new_company_department_path`, `company_department_path`

Test files to **rewrite** (old tests use modal pattern):
- `spec/features/companies/departments/index_spec.rb`
- `spec/features/companies/departments/permissions_spec.rb`

Test files to **create**:
- `spec/features/companies/departments/new_spec.rb`
- `spec/features/companies/departments/show_spec.rb`
- `spec/features/companies/departments/edit_spec.rb`

### 3.2 Per-Resource Variables

| Resource | Plural slug | Class prefix | Icon | Extra permitted params |
|----------|------------|--------------|------|----------------------|
| Branches | branches | Branches | store | country_code, phone_number, email |
| Departments | departments | Departments | groups | email |
| Brands | brands | Brands | diamond | phone_number, email, code |
| Services | services | Services | medical_services | — |
| Employees | employees | Employees | badge | branch_id, department_id, role_id, role_ids: [] |
| Customers | customers | Customers | person | email |
| Orders | orders | Orders | receipt_long | currency_code, customer_id |
| Invoices | invoices | Invoices | receipt | currency_code, code, total_price, due_date |
| Facilities | facilities | Facilities | warehouse | branch_id, phone_number, email, code |
| Categories | categories | Categories | category | resource_name |

---

## 4. URL Helpers to Add

All go in `app/javascript/controllers/helpers/url_helpers.js`:

```javascript
// Show page paths (singular, following Products naming convention)
export const company_branch_path = (companyId, branchId) => `/companies/${companyId}/branches/${branchId}`
export const company_department_path = (companyId, departmentId) => `/companies/${companyId}/departments/${departmentId}`
export const company_brand_path = (companyId, brandId) => `/companies/${companyId}/brands/${brandId}`
export const company_service_path = (companyId, serviceId) => `/companies/${companyId}/services/${serviceId}`
export const company_employee_path = (companyId, employeeId) => `/companies/${companyId}/employees/${employeeId}`
export const company_customer_path = (companyId, customerId) => `/companies/${companyId}/customers/${customerId}`
export const company_order_path = (companyId, orderId) => `/companies/${companyId}/orders/${orderId}`
export const company_invoice_path = (companyId, invoiceId) => `/companies/${companyId}/invoices/${invoiceId}`
export const company_facility_path = (companyId, facilityId) => `/companies/${companyId}/facilities/${facilityId}`

// New page paths (singular, following Products naming convention)
export const new_company_branch_path = (companyId) => `/companies/${companyId}/branches/new`
export const new_company_department_path = (companyId) => `/companies/${companyId}/departments/new`
export const new_company_brand_path = (companyId) => `/companies/${companyId}/brands/new`
export const new_company_service_path = (companyId) => `/companies/${companyId}/services/new`
export const new_company_employee_path = (companyId) => `/companies/${companyId}/employees/new`
export const new_company_customer_path = (companyId) => `/companies/${companyId}/customers/new`
export const new_company_order_path = (companyId) => `/companies/${companyId}/orders/new`
export const new_company_invoice_path = (companyId) => `/companies/${companyId}/invoices/new`
export const new_company_facility_path = (companyId) => `/companies/${companyId}/facilities/new`
```

---

## 5. Implementation Order

| Step | Resource | Why This Order |
|------|----------|----------------|
| 1 | **Branches** | Has tests, simpler than Products, validates pattern |
| 2 | **Departments** | Similar to Branches, tests exist |
| 3 | **Brands** | Tests exist, has debug lines to remove |
| 4 | **Services** | Simplest (no extra fields) |
| 5 | **Customers** | Tests exist, similar to Services |
| 6 | **Orders** | No tests — first "from scratch" resource |
| 7 | **Invoices** | No tests, has `number`→`code` bug fix |
| 8 | **Facilities** | No tests, has branch_id association |
| 9 | **Employees** | Most complex — associations, Discard, Seed service |
| 10 | **Categories** | Lowest priority — admin-only, different filter pattern |

---

## 6. Key Per-Resource Details

### Branches
- **Existing controller**: `app/controllers/companies/branches_controller.rb` — already has `index`, `create`, `update`. Needs `show`, `new`, `edit` added.
- **format_branch** includes `address` (via `branch.address` concern). Keep this.
- **Old index has** `categoryFilter`, `business_type` badges (storefront/warehouse/headquarters), status badges
- **Tests to rewrite**: `spec/features/companies/branches/index_spec.rb` (remove modal tests, add page link tests), `spec/features/companies/branches/permissions_spec.rb` (remove editable/modal assertions)

### Departments
- **Existing controller**: `app/controllers/companies/departments_controller.rb` — JSON only. Needs `show`, `new`, `edit`.
- **Extra in new form**: email field
- **Old index has** `handleFilter` data-action, category filter, type badges

### Brands
- **Existing controller**: `app/controllers/companies/brands_controller.rb` — has debug `Rails.logger.warn` lines. Remove those. Needs `show`, `new`, `edit`.
- **create action** auto-generates `code ||= "BR-#{SecureRandom.hex(4).upcase}"` — keep this logic
- **Old index has** category filter, type badges, "Brand Name" column

### Services
- **Existing controller**: `app/controllers/companies/services_controller.rb` — JSON only. Needs `show`, `new`, `edit`.
- **Simplest resource** — name, description, code, business_type, workflow_status
- **Old index has** category, type badges, status badges

### Customers
- **Existing controller**: `app/controllers/companies/customers_controller.rb` — JSON only. Needs `show`, `new`, `edit`.
- **Extra**: email field
- **Old index has** email column, category filter

### Orders
- **Existing controller**: `app/controllers/companies/orders_controller.rb` — JSON only. Needs `show`, `new`, `edit`.
- **Extra**: currency_code (shown in index), customer_id
- **Old index has** "Order Name" column, type badges (online/in_store), currency display, status

### Invoices
- **Existing controller**: `app/controllers/companies/invoices_controller.rb` — JSON only. Needs `show`, `new`, `edit`.
- **EXTRA FIX**: Old index uses `invoice.number` but column is `code` in schema. Change all `number` → `code` in the new index controller.
- **Extra fields**: currency_code, total_price, due_date, code
- **Old index has** "Invoice #" column (was reading `.number`), amount, type badges

### Facilities
- **Existing controller**: `app/controllers/companies/facilities_controller.rb` — JSON only. Needs `show`, `new`, `edit`.
- **Extra**: branch_id (shown as branch name in index), phone_number, email
- **Old index format_facility** includes `branch` association. Keep this.

### Employees
- **Existing controller**: `app/controllers/companies/employees_controller.rb` — JSON `create` uses `Seed::EmployeeService`. Has `destroy` action (Discard). Needs `show`, `new`, `edit`.
- **Important**: Keep the `destroy` action. Keep `Seed::EmployeeService` for creation.
- **format_employees** includes `user`, `branch`, `roles`, `departments` + `category`. Keep all.
- **Old index** shows all these associations in the table.
- **Most complex** — the new_controller must handle the Seed service, the edit must handle role_ids.

---

## 7. Test Migration Pattern

### Old test → New test transformation

**Old (modal-based) — assertions to remove:**
```ruby
find('[data-action*="openNewModal"]').click
find('[data-action*="openShowModal"]').click
expect(page).to have_selector('.swal2-container')
expect(page).to have_selector('form[data-action*="handleSubmit"]')
expect(page).to have_selector('[data-controller="editable"]')
editable_name_field.find('.editable-input').fill_in(with: '...')
accept_confirm { ... }
```

**New (page-based) — what to replace with:**
```ruby
# "Add" button links to /new page
expect(page).to have_selector("a[href*='/{resource}/new']", text: 'Add')

# Edit button links to /edit page
edit_link = find("a[href*='/{resource}/#{record.id}']", match: :first)
expect(edit_link).to be_present

# Name links to show page
expect(page).to have_selector("a[href*='/{resource}/#{record.id}']", text: record.name)

# Creator creates via /new page (not modal)
visit new_company_{resource}_path(company)
fill_in '{resource}[name]', with: 'Created by Creator'
click_button "Save {Resource}"
expect(page).to have_content('Created by Creator', wait: 10)

# Editor edits via /edit page
visit edit_company_{resource}_path(company, record)
fill_in '{resource}[name]', with: 'Updated'
click_button "Save Changes"
expect(page).to have_content('Updated', wait: 10)
```

### Permissions spec specific changes:
- `"read-only employee can see Add link in UI"` — assert `<a>` to /new, not `<button>` with `openNewModal`
- `"employee with create permission can open create modal"` — change to visit /new page
- `"editor with update permission can see edit buttons"` — change to see `<a>` to /edit or name `<a>` to /show
- `"update branch name via editable"` — remove entire scenario (editable is gone, replaced by edit page)
- `"employee without create permission cannot create"` — change: visit /new page, expect "not authorized"
- `"employee without update permission cannot edit"` — change: visit /edit page, expect "not authorized"

---

## 8. Verification

After each resource migration:

1. Run `bin/rubocop --autocorrect-all`
2. Run the resource's tests:
   ```bash
   bundle exec rspec spec/features/companies/{resource}/
   ```
3. Run `bin/brakeman` for security
4. Verify the page loads manually (or via test)

Before claiming completion, run the verification skill.
