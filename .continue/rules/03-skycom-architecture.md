---
name: Skycom Architecture Manifesto
---

# Project Context: Skycom (Hybrid SPA Architecture)

Skycom is a multi-tenant business management platform. It uses a non-traditional Rails architecture designed for speed and a desktop-app feel, bypassing heavy server-side HTML rendering.

## Core Principles:
1. **Shell-First Rendering**: Initial HTML returns an empty shell; Stimulus hydrates the page.
2. **JSON-Only Data Flow**: Rails Controllers handle `.json` requests for data.
3. **Client-Side Templating**: Rendering happens in `contentHTML()` via ES6 Template Literals.

## Tech Stack:
- **Backend**: Ruby on Rails (JSON-only API style)
- **Frontend**: Stimulus + Tailwind CSS + ES6 Template Literals
- **Import System**: Importmap (no node_modules, no webpack/vite bundler)
- **Styling**: Tailwind CSS classes everywhere
- **Database Setup**:
  - **Primary database**: PostgreSQL
  - **Solid Cable**: SQLite (for Action Cable / WebSockets)
  - **Solid Cache**: SQLite (for caching)
  - **Solid Queue**: PostgreSQL (for background jobs / Active Job)

## Importmap Usage (Important):
- All JavaScript imports must use the **importmap** style.
- Correct example:  
  `import Companies_LayoutController from "controllers/companies/layout_controller"`
- Never suggest relative paths (`./...`) or npm-style imports.

## Stimulus Naming & Inheritance (CRITICAL):
1. **Class Naming**: Use **Pascal_Snake_Case** (e.g., `Companies_Branches_EmployeesController`).
2. **Identifier**: `Companies_LayoutController` → `companies--layout`. Use `window.identifier(Class)` to generate.
3. **Inheritance**: Child controllers inherit all `static targets` from parents. Do **not** redefine them.

## Advanced Global Helpers (window.*):
**AI MUST prioritize these over native implementations**:

1. **`fetchJson(url|options, options)`**:
   - Smart default: If `url` is omitted, fetches from current `window.location.href`.
   - Automatically injects `X-CSRF-Token` and handles JSON.
   - Usage: `const data = await fetchJson({ params: { status: 'active' } })`

2. **`form({ action, method, dataAction, className, html })`**:
   - Smart default action: `pathname()`.
   - Handles Rails method spoofing (`_method`) and CSRF automatically.
   - Usage: `form({ method: 'PATCH', html: fields })`

3. **URL Helpers**: `pathname()`, `href()`
4. **Security Helpers**: `csrfToken()`, `formPostSecurityTags()`, `formPatchSecurityTags()`

## Modeling & Code Organization Style (Very Important):
- **Heavy use of Concerns**: Many models are kept small by extracting behavior into concerns (e.g. `AddressConcern`, `TagConcern`, `RoleConcern`, `PermissionConcern`, `SystemSubscription::ResourceConcern`, etc.).
- **Service Objects**: Only used for **global / complex cross-cutting logic**. Most business logic should stay in models or concerns.
- **Associations**: Extensive use of **has_many through** + **polymorphic associations** via appointment-style join tables.

Example:

```ruby
class Employee < ApplicationRecord
  include AddressConcern
  include RoleConcern
  include PermissionConcern
  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :user, optional: true

  has_many :role_appointments, as: :appoint_to, dependent: :destroy
  has_many :roles, through: :role_appointments

  has_many :service_appointments, as: :appoint_to, dependent: :destroy
  has_many :services, through: :service_appointments

  # ... more polymorphic has_many through ...

  has_many :bookings, as: :appoint_from, dependent: :destroy, class_name: "Booking"

  enum :business_type, { full_time: 0, part_time: 1, contractor: 2, intern: 3 }
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
end