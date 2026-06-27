# Admin Companies Dashboard Design

## Overview

Create an admin panel under `/admin/companies` with index (table) and show (detail) pages. Only users with `system_role: super_admin` or `system_role: admin` can access.

## Architecture

| Layer | File | Purpose |
|-------|------|---------|
| **Controller** | `app/controllers/admin/companies_controller.rb` | Shell-First: `index` (list) + `show` (detail) |
| **Layout (JS)** | `app/javascript/controllers/admin/layout_controller.js` | `Admin_LayoutController` — nav sidebar + header + content target |
| **Index (JS)** | `app/javascript/controllers/admin/companies/index_controller.js` | Extends `Admin_LayoutController` — table with companies |
| **Show (JS)** | `app/javascript/controllers/admin/companies/show_controller.js` | Extends `Admin_LayoutController` — company detail view |
| **Helpers** | `app/javascript/controllers/helpers/url_helpers.js` | Add `admin_companies_path()` + `admin_company_path(id)` |

## Backend

### Controller Actions

- `GET /admin/companies` — returns `{ companies: [...], pagination: {...} }`
- `GET /admin/companies/:id` — returns `{ company: {...} }`
- Both use Shell-First: `format.html { render html: "", layout: true }` + `format.json`
- Inherits from `Admin::ApplicationController` → checks `system_role_super_admin? || system_role_admin?`

### JSON Response Shape

**Index:**
```json
{
  "companies": [
    {
      "id": "uuid", "name": "Acme Corp", "code": "ACM-001",
      "business_type": "retail", "workflow_status": "active",
      "email": "admin@acme.com", "phone_number": "+1234567890",
      "city": "San Francisco", "country_code": "us",
      "employee_count": 25, "created_at": "2026-01-15T...",
      "user": { "id": "uuid", "name": "John", "email": "john@..." }
    }
  ],
  "pagination": { ... }
}
```

**Show:** Same fields + `description`, `website`, `registration_number`, `vat_id`, `tax_id`, `ownership_type`, `currency_code`, `timezone`, `updated_at`, `address`

## Frontend

### Layout Controller (`Admin_LayoutController`)

- Static targets: `content`
- `connect()`: polls for `currentUser()` then calls `renderLayout()`
- `renderLayout()`: renders sidebar (admin nav) + header (user avatar, sign out) + `<div data-target>`
- `renderContent()`: injects `this.contentHTML()` into content target

### Index Controller

- Extends `Admin_LayoutController`
- Columns: Name (linked to show), Code, Business Type (pill), Email, Phone, Owner (user name), Status (badge), Created, Actions (view link)
- Pagination via `Helpers.pagination()`

### Show Controller

- Extends `Admin_LayoutController`
- Sections: Back link, header (name + code + status), detail grid, owner, address, timestamps

## URL Helpers

```javascript
admin_companies_path = () => `/admin/companies`
admin_company_path = (companyId) => `/admin/companies/${companyId}`
```

## Design Decisions

- **No category filter** — admin sees ALL companies globally
- **No dynamic property columns** — companies aren't categorized that way
- **No Pundit** — the `only_admin_can_access` guard is sufficient for admin-level access
- **Shell-First** — server returns empty HTML shell, Stimulus hydrates client-side
