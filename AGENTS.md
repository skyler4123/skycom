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

## Full Guidelines
See `README.md` for detailed coverage of:
- Stimulus naming conventions & inheritance
- Global Helpers (fetchJson, form, openModal, toast, editable, tooltip)
- Type definitions (JSDoc patterns)
- Reactive UI & inline editing patterns
- Form engine lifecycle
