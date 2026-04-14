# Skycom Agent Guidelines

## Quick Commands
- `bin/dev` - Start dev server (web + css + job via foreman)
- `bin/rubocop` - Lint Ruby code
- `bin/brakeman` - Security scan
- `bin/rails` - Standard Rails commands

## Architecture
- **Type**: Rails 7+ multi-tenant platform with Hybrid SPA (Stimulus + Tailwind)
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

## CI Commands (Docker)
- `docker compose -f docker-compose.seed-test.yml up` - Seed test suite
- `docker compose -f docker-compose.rspec-test.yml up` - RSpec test suite