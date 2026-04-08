---
name: Skycom Project Guidelines - Part 1
description: Ruby on Rails Project Guidelines & Backend Standards
---

# 1. Ruby on Rails Project Guidelines

This is a standard Ruby on Rails 7+ application configured as a multi-tenant business management platform.

### Project Structure
- `app/models/` - ActiveRecord models (Heavy use of Concerns).
- `app/controllers/` - Controllers (JSON API style).
- `app/services/` - Global/complex cross-cutting business logic.
- `app/jobs/` - Background jobs using **Solid Queue** (PostgreSQL).
- `db/schema.rb` - Always check this first for columns and indexes.
- `app/javascript/controllers/` - Stimulus controllers (Frontend logic).

### Coding Conventions
- **Rails Conventions**: Stick to plural table names and standard RESTful routing.
- **Strict Logic Placement**: 
  - Business logic stays in **Models** or **Concerns** (e.g., `AddressConcern`, `RoleConcern`).
  - **Service Objects** are reserved for complex operations involving multiple models.
- **Data Flow**: Controllers handle `.json` requests. Avoid server-side HTML partials where possible; prefer JSON payloads for the Stimulus "Shell-First" architecture.
- **Safety**: Use `frozen_string_literal: true` and prefer `find_by!` or `find!` when a record is expected to exist.

### Database & Models
- **Database Setup**: PostgreSQL (Primary/Solid Queue), SQLite (Solid Cable/Solid Cache).
- **Associations**: Extensive use of **has_many through** + **polymorphic associations** via appointment-style join tables (e.g., `Employee` belongs to `Department` through `DepartmentAppointment`).
- **N+1 Prevention**: Use `includes`, `eager_load`, or `preload` by default for associated data.

### Rails Controller Naming Convention
Rails controllers must follow the URL nesting structure exactly:
- **URL**: `/companies/:company_id/employees`
- **Controller**: `class Companies::EmployeesController < Companies::ApplicationController`
- **Path**: `app/controllers/companies/employees_controller.rb`

---
name: Skycom Project Guidelines - Part 2
description: Hybrid SPA Architecture & Stimulus Naming Conventions
---

# 2. Skycom Architecture Manifesto (Hybrid SPA)

Skycom uses a **Shell-First Rendering** approach. The server returns a layout shell, and Stimulus controllers hydrate the page using JSON data.

### Tech Stack
- **Backend**: Rails (JSON API)
- **Frontend**: Stimulus + Tailwind CSS + ES6 Template Literals.
- **No Bundler**: Uses **Importmap** (no `node_modules`). Imports must use the importmap name, never relative paths.
  - *Correct*: `import Controller from "controllers/companies/layout_controller"`

### Stimulus Naming & Mapping (CRITICAL)
We maintain a strict mapping between Rails routes and Stimulus controllers to ensure architectural clarity.

1.  **Main Page Controllers**: 
    - A Rails `controller#action` should have a corresponding Stimulus controller.
    - **Naming**: Use **Pascal_Snake_Case**.
    - **Example**: For URL `/companies/:id/employees`, the controller in `app/javascript/controllers/companies/employees/index_controller.js` should be named `Companies_Employees_IndexController`.
2.  **Inheritance**:
    - Page controllers usually inherit from a Layout controller.
    - *Example*: `export default class Companies_EmployeesController extends Companies_LayoutController`
3.  **Support Controllers (Modals/Components)**:
    - Dedicated controllers handle specific UI actions within a view.
    - **Example**: `app/javascript/controllers/companies/employees/new_modal_controller.js` defines `Companies_Employees_NewModalController`.
    - **Backend Link**: This modal must map to a specific Rails action (e.g., `Companies::EmployeesController#create`).

### Stimulus Identifiers
- Generated via `window.identifier(Class)`.
- `Companies_Employees_IndexController` → `companies--employees--index`.
- Child controllers inherit all `static targets` from parents. **Do not redefine them.**

---
name: Skycom Project Guidelines - Part 3
description: Global JS Helpers and AI Prioritization Rules
---

# 3. Global JavaScript Helpers (window.*)

**AI MUST NOT suggest native `fetch()`, `$.ajax`, or plain `<form>` tags.** Use the global `window.Helpers` exposed in `app/javascript/application.js`.

### Core AJAX & Forms
1.  **`fetchJson(url|options, options)`**:
    - Automatically injects `X-CSRF-Token`.
    - Sets `Content-Type: application/json`.
    - Default URL is `window.location.href`.
2.  **`form({ action, method, dataAction, className, html })`**:
    - Defaults `action` to current `pathname()`.
    - Handles Rails **Method Spoofing** (PATCH/DELETE).
    - Injects CSRF `authenticity_token`.
3.  **Security Tags**:
    - `formPostSecurityTags()` / `formPatchSecurityTags()`: For manual HTML strings.

### Utility & UI Helpers
The following are available globally via the `Helpers` object:
- **Context**: `currentCompany`, `currentBranches`, `currentUser`, `isSignedIn`.
- **Navigation/URL**: `pathname()`, `href()`, `pagination(data)`.
- **UI**: `openModal(html)`, `closeModal()`, `openPopover()`, `toast(message, type)`.
- **Data Handling**: `isPresent(val)`, `isEmpty(val)`, `each(collection, callback)`, `map()`, `sort()`.
- **Storage**: `Cookie.set(name, value)`, `Cookie.get(name)`.

### Development Principles
- **Rendering**: Happens client-side in `contentHTML()` using ES6 Template Literals.
- **Encapsulation**: Use `new_modal_controller.js` to isolate logic for creation forms, ensuring they point back to the correct Rails RESTful action.
- **Identifiers**: Always use the underscored naming convention for file structure that matches the Pascal_Snake_Case class names.