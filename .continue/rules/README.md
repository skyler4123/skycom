---
name: Skycom Project Guidelines
description: Complete architecture, Rails conventions, and Skycom-specific rules
---

# Skycom Project Guidelines

## 1. Ruby on Rails Project Guidelines

This is a standard Ruby on Rails application (likely Rails 7+).

### Project Structure
- `app/models/` - ActiveRecord models
- `app/controllers/` - Controllers (JSON API style)
- `app/views/` - ERB or other templates
- `app/services/` or `app/interactors/` - Business logic
- `app/jobs/` - Background jobs (Sidekiq, etc.)
- `app/mailers/` - Mailers
- `config/routes.rb` - All routes
- `db/schema.rb` or `db/structure.sql` - Database schema
- `app/api/` or `app/graphql/` - If using Grape, GraphQL, etc.

### Coding Conventions
- Follow Rails conventions (plural table names, etc.)
- Use strong parameters in controllers
- Prefer service objects for complex logic
- Write tests in `test/` or `spec/` (RSpec/Minitest)
- Use `frozen_string_literal: true` when possible

### Database & Models
- Always check `db/schema.rb` for current columns and indexes
- Models inherit from `ApplicationRecord`
- Use scopes for common queries
- Prefer `includes` / `eager_load` / `preload` to avoid N+1 queries

### When Editing Code
- Always respect existing style and patterns
- Prefer `find_by!` / `find!` when record must exist
- Use `present?` / `blank?` instead of checking nil + empty

---

## 2. Skycom Architecture Manifesto (Hybrid SPA)

Skycom is a **multi-tenant business management platform**. It uses a non-traditional Rails architecture designed for speed and a desktop-app feel, bypassing heavy server-side HTML rendering.

### Core Principles
1. **Shell-First Rendering**: Initial HTML returns an empty shell; Stimulus hydrates the page.
2. **JSON-Only Data Flow**: Rails Controllers handle `.json` requests for data.
3. **Client-Side Templating**: Rendering happens in `contentHTML()` via ES6 Template Literals.

### Tech Stack
- **Backend**: Ruby on Rails (JSON-only API style)
- **Frontend**: Stimulus + Tailwind CSS + ES6 Template Literals
- **Import System**: Importmap (no node_modules, no webpack/vite bundler)
- **Styling**: Tailwind CSS classes everywhere
- **Database Setup**:
  - **Primary database**: PostgreSQL
  - **Solid Cable**: SQLite (for Action Cable / WebSockets)
  - **Solid Cache**: SQLite (for caching)
  - **Solid Queue**: PostgreSQL (for background jobs / Active Job)

### Importmap Usage (Important)
- All JavaScript imports must use the **importmap** style.
- Correct example:  
  `import Companies_LayoutController from "controllers/companies/layout_controller"`
- Never suggest relative paths (`./...`) or npm-style imports.

### Stimulus Naming & Inheritance (CRITICAL)
1. **Class Naming**: Use **Pascal_Snake_Case** (e.g., `Companies_Branches_EmployeesController`).
2. **Identifier**: `Companies_LayoutController` → `companies--layout`. Use `window.identifier(Class)` to generate.
3. **Inheritance**: Child controllers inherit all `static targets` from parents. Do **not** redefine them.

### Advanced Global Helpers (window.*) — AI MUST Prioritize These
1. **`fetchJson(url|options, options)`**:
   - **Smart Default**: If `url` is omitted, it fetches from the CURRENT `window.location.href`.
   - **Security**: Automatically injects `X-CSRF-Token`.
   - **Auto-JSON**: Stringifies object bodies and sets `Content-Type: application/json` automatically.
   - Usage: `const data = await fetchJson({ params: { status: 'active' } })`

2. **`form({ action, method, dataAction, className, html })`**:
   - **Smart Default Action**: Defaults to `pathname()` (current URL).
   - **Rails Method Spoofing**: Automatically adds `<input type="hidden" name="_method">` for PATCH and DELETE.
   - **Security**: Automatically injects CSRF `authenticity_token`.
   - Usage: `form({ method: 'PATCH', html: fields })`

3. **URL Helpers**:
   - `pathname()`: Returns `window.location.pathname`.
   - `href()`: Returns `window.location.href`.

4. **Security Helpers**:
   - `csrfToken()`: Fetches from meta tag.
   - `formPostSecurityTags()` / `formPatchSecurityTags()`: For manual form building.

### Modeling & Code Organization Style
- **Heavy use of Concerns**: Many models are kept small by extracting behavior into concerns (`AddressConcern`, `RoleConcern`, `PermissionConcern`, `TagConcern`, `SystemSubscription::ResourceConcern`, etc.).
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

  has_many :employee_group_appointments, as: :appoint_to, dependent: :destroy
  has_many :employee_groups, through: :employee_group_appointments

  has_many :department_appointments, as: :appoint_to, dependent: :destroy
  has_many :departments, through: :department_appointments

  has_many :tag_appointments, as: :appoint_to, dependent: :destroy
  has_many :tags, through: :tag_appointments

  has_many :bookings, as: :appoint_from, dependent: :destroy, class_name: "Booking"

  enum :business_type, { full_time: 0, part_time: 1, contractor: 2, intern: 3 }
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
end