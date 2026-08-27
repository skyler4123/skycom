# Skycom Agent Guidelines

## Quick Commands
- `bin/dev` - Start dev server (web + css + job via foreman)
- `bin/rubocop` - Lint Ruby code
- `bin/brakeman` - Security scan
- `bin/rails` - Standard Rails commands

## Pre-Commit Checklist
- **Update** `docs/MODEL_CALLBACKS.md` if model/concern callbacks were added or modified
- **Constants** — All app-wide constants must be in `config/initializers/constants.rb`, never hardcoded inline. See `docs/CONSTANTS.md`.
- **Client cache** — If any mutation affects data stored in `currentCompany()` (branches, roles, categories, permissions, features, etc.), call `clearClientCacheAndReload()` after the server confirms the change, OR call `clearClientCache()` followed by a page reload.
- **BE↔FE link** — When you add, remove, or change an endpoint, update the file-header link comments in **both** the BE controller (`Serves Stimulus:`) and the FE Stimulus controller (`Depends on BE:` / `Endpoints:`). See the template in `V1Controller`, `OrdersController`, `PagesController`, `MockQrGatewayController`, `RetailCashierController`. Links are living — remove stale pairs, add new ones per feature.

## Architecture
- **Type**: Rails 8+ multi-tenant platform with Hybrid SPA (Stimulus + Tailwind)
- **Data Flow**: JSON API, avoid server-side HTML partials
- **Frontend**: Importmap (no node_modules), ES6 template literals in `contentHTML()`

## Critical Conventions

### Rails Controllers
- Nested route naming: `/companies/:company_id/employees` → `Companies::EmployeesController`
- Use `find_by!`/`find!` when record must exist

### JavaScript
- **ALWAYS** use `window.Helpers.fetchJson()` and `Helpers.form()` — never native `fetch()` or `<form>` tags
- Controllers: `app/javascript/controllers/companies/employees/index_controller.js` → `Companies_Employees_IndexController`
- Import via importmap name: `import Controller from "controllers/companies/layout_controller"` (not relative path)
- Use JSDoc types from `app/javascript/types.js`

### Forms & AJAX
- Input names must use bracket notation: `name="employee[email]"` (required for Rails strong params nesting)
- Use `Helpers.form()` for all form submissions (handles CSRF + method spoofing)
- Listen for `form:success` events to refresh parent UI
- **API Errors** — Backend must return `errors` (plural array) key, never `error` (singular). See `docs/API_ERROR_FORMAT.md`.
- **Toast messages** — Never use generic hardcoded messages. Always use the server's response (e.g., `response.message` for success, `error.errors` for failure). The message must describe the exact action completed so the client knows what happened. Prefer messages returned from the Backend (BE).

## Database
- Check `db/schema.rb` first for columns/indexes
- Use `includes`/`eager_load`/`preload` to prevent N+1

## Model Structure
- All `app/models/*.rb` follow the canonical order in `docs/MODEL_STRUCTURE.md` (concerns → constants → attributes → enums → macros → associations → scopes → validations → callbacks → methods). Run `bin/rubocop` to verify.

## Kredis (Cache Store) Rule
- **Never** use low-level `Kredis.redis` or kredis proxy built-ins (`.value`, `.increment`, ...) in services/controllers/jobs. The owning model wraps them behind domain-named methods (e.g., `Stock#available_count`, `Company#record_credit_usage!`) so the backend can swap Kredis ↔ DB without changing callers. See `docs/KREDIS.md`.

## BE↔FE Documentation
- Headers are the source of truth for which Stimulus controller calls which BE action. Keep them accurate; delete entries when an endpoint/pair is removed. See `V1Controller`, `OrdersController`, `PagesController`, `MockQrGatewayController`, `RetailCashierController` for the template.

## Full Guidelines
See `README.md` for detailed coverage of:
- Stimulus naming conventions & inheritance
- Global Helpers (fetchJson, form, openModal, toast, editable, tooltip)
- Type definitions (JSDoc patterns)
- Reactive UI & inline editing patterns
- Form engine lifecycle
