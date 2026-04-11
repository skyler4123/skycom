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


# 4. JavaScript Type Definitions (JSDoc)

To maintain a "Desktop-App" feel with high reliability, Skycom uses **JSDoc** for static type checking and IDE autocompletion. All core business entities and shared structures are defined in a central location.

### Central Type Registry
- **Path**: `app/javascript/types.js`
- **Purpose**: This file contains only JSDoc `@typedef` blocks. It is not imported at runtime (since Importmap handles logic), but it is used by the AI and IDEs to understand the data structures returned by the Rails JSON API.

### Standard Type Definitions
1.  **Core Entities**: Models like `Employee`, `Branch`, `Department`, and `Role` must match the Rails `db/schema.rb` columns exactly.
2.  **Intersection Types (Hydration)**: When a controller returns a record with associations, use inline intersections or named types to represent the "Hydrated" state.
    - *Pattern*: `/** @type {Employee & { branch: Branch, roles: Role[] }} */`
3.  **Enums**: The `Enums()` helper structure must be typed to ensure valid lookup keys.
    - *Example*: `/** @type {keyof EmployeeEnums} */`

### Type Usage in Stimulus
1.  **Property Annotations**: Always annotate the initial state of a controller property.
    - *Correct*: `/** @type {Employee | null} */ employee = null`
2.  **Response Casting**: When using `fetchJson()`, explicitly cast the response to the expected type to ensure downstream logic is type-safe.
    - *Example*: `/** @type {{ employees: Employee[] }} */ const data = await fetchJson()`
3.  **Global Objects**: Global variables like `window.currentEmployee` or `window.client_cache_data` must be cast to their respective types from `types.js` before use.

### Coding Standard
- **Null-Safety**: Initialize object properties as `null` rather than `{}`.
- **Optional Chaining**: Use `?.` when accessing associations (e.g., `this.employee?.branch?.name`) to prevent UI crashes if data is missing or eager loading failed.

# 5. Reactive UI & Inline Editing Pattern

Skycom utilizes a **State-to-Template** reactivity model. Instead of manual DOM manipulation (finding IDs and updating innerText), we update the local instance state and trigger a re-render of the component. This provides a React-like experience while staying within the Stimulus/Rails ecosystem.

### 5.1 The `editable` Helper
To maintain clean templates, use the `editable` helper. This helper is **tag-agnostic** and wraps any HTML element in a Stimulus `editable` controller. It ensures that typography and styling are preserved when switching between view and edit modes.

**Implementation Example:**
```javascript
${Helpers.editable({
  resource: "employee",
  name: "name",
  id: employee.id,
  value: employee.name,
  url: Helpers.edit_company_employee_path(currentCompany().id, employee.id),
  dispatch: "updateEmployee",
  html: `<span class="text-xl font-bold text-slate-900">${employee.name}</span>`
})}
```
### 5.2 Event-Driven Synchronization
When an update is successful, the `editable` controller dispatches a custom event. The parent controller (e.g., an Index or Table controller) must listen for this event to update its local data store.

**Global Event Protocol:**
* **Event Name:** `editable:[dispatchName]` (e.g., `editable:updateEmployee`).
* **Payload (`event.detail`):**
    * `resource`: The name of the resource (e.g., "employee").
    * `data`: The full JSON response from the server (Source of Truth).
    * `value`: The new value updated.
    * `previousValue`: The value before the edit (useful for rollbacks).

### 5.3 Data Merging & Re-rendering
Parent controllers must use the `mergeObjectArrays` helper to synchronize local state. This ensures that nested data (like roles or departments) is updated automatically in the UI without a full page refresh.

**Standard Update Handler:**
```javascript
handleUpdate(event) {
  const { resource, data } = event.detail
  const newObject = data[resource] || data // Source of Truth

  if (!newObject) return

  // 1. Merge into the local collection (replaces item with same ID)
  this.employees = mergeObjectArrays(this.employees, [newObject], "id")

  // 2. Refresh the UI via the Shell-First render pattern
  this.renderContent()
}
```
### 5.4 Design Principles for Inline Editing
1.  **Tag Agnosticism**: The controller does not hardcode `<span>` or `<div>`. It targets the `firstElementChild` of the wrapper to preserve the developer's intended HTML structure.
2.  **Typography Inheritance**: The generated `input` or `select` element must inherit the CSS classes from the original display element (e.g., `text-2xl`, `font-black`) to prevent layout "jumps" during editing.
3.  **Explicit Resource Mapping**: Always pass the `resource` name via the helper to ensure the event payload is correctly mapped to the parent's data arrays.
4.  **Optimistic Logic**: While the UI updates after the server response, the `previousValue` is maintained in the event detail to allow for audit logging or error recovery.