# Skycom Agent Guidelines

## Working Mode (mandatory — overrides conflicting skill/workflow guidance)

- **Work on the current branch, in the current working directory.** Never create a new branch or worktree, and never move the session elsewhere, unless the user explicitly asks for it.
- **Default to native (inline) execution.** Never dispatch subagents — for implementation, review, or anything else — unless the user explicitly asks for subagent mode.
- These rules take precedence over any installed skill/workflow guidance (e.g. superpowers) that says otherwise.

## Doc Map — read before you code (mandatory)

This file and `README.md` are always in context. Everything in `docs/` is on-demand: when your task matches a row, **read the doc before writing code**. The one-line "why" is usable alone; the doc has the exact contract.

### Contracts (backend responses, shared conventions)

| When your task involves… | Read first |
|---|---|
| Returning JSON from any controller/service action, success or failure | `docs/API_ERROR_FORMAT.md` — failures **must** be `{ errors: [...] }` (plural array) with `:unprocessable_content`; singular `error:` breaks the frontend toast |
| Adding an app-wide constant | `docs/CONSTANTS.md` — belongs in `config/initializers/constants.rb`, never hardcoded inline |
| Touching counters or cached state (Kredis) | `docs/KREDIS.md` — owning model wraps storage behind domain-named methods; never low-level `Kredis.redis` in services/controllers/jobs |
| Adding a jsonb-backed model attribute | `docs/STORE_ACCESSOR.md` — `store_accessor` convention, not a separate column |
| Creating or restructuring `app/models/*.rb` | `docs/MODEL_STRUCTURE.md` — canonical section order |
| Adding or modifying model/concern callbacks | `docs/MODEL_CALLBACKS.md` — callback reference |
| Conflicting migrations after a merge | `docs/MERGE_MIGRATIONS.md` — merge-migration procedure |
| Writing or running any spec | `docs/PARALLEL_TESTS.md` — always `bundle exec parallel_rspec -n 14 [paths]`; feature specs also need `docs/FLAKY_TESTS.md` (never `sleep`) |

### Money, stock, orders (absolute rules)

| When your task involves… | Read first |
|---|---|
| Moving money (invoice, payment, credit, discount, stock) | `docs/MONEY_FLOW.md` — absolute rules + the two money vocabularies |
| Inventory quantities | `docs/STOCK.md` — two numbers + hot counter, single write path, immutable tenets |
| Discounts or promos | `docs/DISCOUNTS.md` — engine + why invoice price is reduced at creation |
| Spending or deducting company credits | `docs/CREDIT_DEDUCTION.md` — `after_action` filter + service hierarchy + wallet seeding in tests |
| Payment methods, branch/company scoping | `docs/PAYMENT_METHODS.md` — two levels + tenant derivation |
| POS checkout / retail cashier flow | `docs/ORDER_PROCESSING_V1.md` — pipeline: FE controller → services → job → Kredis |
| Buy/approval/state-machine processes | `docs/PURCHASE_WORKFLOW.md` — `Workflows::AdvanceService` + ABAC + category bridge |
| QR codes | `docs/QR_CODE.md` — `renderQrCode` helper |
| The events domain | `docs/EVENTS.md` — schema, endpoints, seeding (§7 lists what is not built yet) |
| Credit/usage-tracking tables | `docs/ATOMIC_PURPOSE.md` — atomic purpose pattern + hot-path rule |

### Auth & tenancy

| When your task involves… | Read first |
|---|---|
| Sign-in, sessions, tokens, invalidation | `docs/AUTHENTICATION.md` — request flow + session lifecycle |
| Permissions, roles, policies | `docs/ABAC.md` — matcher logic + backend implementation requirements |
| System companies / multi-tenancy | `docs/SYSTEM_COMPANY.md` — why they exist + security model |

### Frontend (README §§0–6 are always loaded; these cover one system each)

| When your task involves… | Read first |
|---|---|
| Any modal (create / edit / show) | `docs/MODAL_PATTERN.md` — index action + modal controller + `form()` helper |
| Index/table pages with filtering or dynamic properties | `docs/DYNAMIC_TABLE.md` — three resolutions + category filtering + rollout recipe |
| A new operating page end-to-end | `docs/OPERATING_PAGES.md` — seed service, factory, controller patterns |
| Resource dashboard pages | `docs/DASHBOARD_PATTERN.md` — backend implementation, no hardcoded paths |
| Sidebar items, settings, custom groups | `docs/SIDEBAR.md` |
| Marketing homepage, sign-in/up, company page | `docs/HOMEPAGE.md` — caching contract + SEO rules, read before touching |
| Tailwind classes, dark mode, mobile layout | `docs/STYLING_GUIDELINES.md` |
| User-facing strings or translations | `docs/LANGUAGE.md` — `translate()` usage is mandatory + translation policy |
| User avatars | `docs/AVATAR.md` — helper + controller + concerns |
| Seed-driven model validations | `docs/DYNAMIC_VALIDATION.md` — supported validators + affected models |
| Category-bound dynamic properties | `docs/CATEGORY_DYNAMIC_SCHEMA.md` — three-table runtime merge |
| Addresses | `docs/ADDRESS.md` — fingerprint dedup + immutable record pattern |
| HR module (tables, resolution engine, permission matrix) | `docs/HR.md` |
| Per-domain details on Employee/Customer (profiles, personas, histories) | `docs/PROFILE_SUBPROFILE.md` — Profile/SubProfile buckets (full-dynamic resources), not new base-table columns |

### Platform

| When your task involves… | Read first |
|---|---|
| Server- or browser-side caching | `docs/CACHE.md` — `ram_cache` / `local_cache` / `sync_cache` / `global_cache` tiers + client cache |
| Realtime updates | `docs/WEBSOCKET.md` — channel naming + event protocol + add-new-event recipe |
| Search | `docs/MEILISEARCH.md` — sync architecture + making a model searchable |
| External API integration (dev/test) | `docs/MOCK_API.md` — mock server routes + add-new-API template |
| Performance work | `docs/PERFORMANCE.md` — backlog conventions (async preprocessing, pagination, fan-out) |
| Dev environment on an immutable OS | `docs/IMMUTABLE_OS_SETUP.md` — distrobox + docker + VS Code |
| URL/controller structure, Stimulus naming, mandatory table fields | `docs/ARCHITECTURE_GUIDES.md` — technical standards incl. system-fields block |
| A new resource type or pairwise join | `docs/RESOURCES.md` — gem/system/managed/appointment catalog + atomic-pair recipe |
| Company seeding, init, or enrich flow | `docs/INIT_AND_ENRICH.md` |
| Company data import (CSV migration engine) | `docs/DATA_IMPORT.md` — config schema, approve/rollback lifecycle, chunk upload, safe-target rails |

## Quick Commands
- `bin/dev` - Start dev server (web + css + job via foreman)
- `bin/rubocop` - Lint Ruby code
- `bin/brakeman` - Security scan
- `bin/rails` - Standard Rails commands
- `bundle exec parallel_rspec -n 14 [paths]` - Run tests (parallel, 14 workers). See `docs/PARALLEL_TESTS.md`.

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
- Use `Helpers.form()` for the `<form>` wrapper (handles CSRF + method spoofing) with `data-action="submit-><identifier>#handleSubmit"` in `attributes`
- Each controller owns `handleSubmit(event)`: `preventDefault` → `FormData` reads → `fetchJson` → `toast` / `closeModal()` / `reloadThenToast()`. There is no central form controller and no `form:success` event
- **API Errors** — Backend must return `errors` (plural array) key, never `error` (singular). See `docs/API_ERROR_FORMAT.md`.
- **Toast messages** — Never use generic hardcoded messages. Always use the server's response (e.g., `response.message` for success, `error.errors` for failure). The message must describe the exact action completed so the client knows what happened. Prefer messages returned from the Backend (BE).

## Database
- Check `db/schema.rb` first for columns/indexes
- Use `includes`/`eager_load`/`preload` to prevent N+1

## Testing
- **ALWAYS** `bundle exec parallel_rspec -n 14 [paths]` — never bare `parallel_rspec` (raises errors), never `bundle exec rspec` for verification (single process), never `docker exec ... rspec` (compose runs services only, web/job via `bin/dev`). See `docs/PARALLEL_TESTS.md`.
- Docs keep `bundle exec rspec ...` as source of truth (runner-swappable) — that does not change what the agent runs.
- Parallel DBs are already set up locally. Only if worker DBs are missing, run once: `RAILS_ENV=test bundle exec rake "parallel:create"` then `RAILS_ENV=test bundle exec rake "parallel:load_schema"` then `RAILS_ENV=test bundle exec rake "parallel:migrate"`. If `parallel_rspec` fails on migration, see `docs/PARALLEL_TESTS.md` §3.2 for the `drop[14]` → `create[14]` → `load_schema[14]` reset.
- **Paired success + failure cases** — Write specs as normal, but prefer paired `it` blocks per behavior where a failure branch exists: one success `it` asserting the expected data, one failure `it` asserting the failure contract (`{ success: false, errors: [...] }` / `not_to be_valid` / non-2xx + `errors` key) plus no unwanted side-effect. Canonical example: `spec/services/discounts/apply_service_spec.rb` (1 success `reserves...` + 7 `fails...` its). Skip the failure `it` only when no failure branch exists — don't invent artificial failures.

## Model Structure
- All `app/models/*.rb` follow the canonical order in `docs/MODEL_STRUCTURE.md` (concerns → constants → attributes → enums → macros → associations → scopes → validations → callbacks → methods). Run `bin/rubocop` to verify.

## Kredis (Cache Store) Rule
- **Never** use low-level `Kredis.redis` or kredis proxy built-ins (`.value`, `.increment`, ...) in services/controllers/jobs. The owning model wraps them behind domain-named methods (e.g., `Stock#available_count`, `Company#record_credit_usage!`) so the backend can swap Kredis ↔ DB without changing callers. See `docs/KREDIS.md`.

## BE↔FE Documentation
- Headers are the source of truth for which Stimulus controller calls which BE action. Keep them accurate; delete entries when an endpoint/pair is removed. See `V1Controller`, `OrdersController`, `PagesController`, `MockQrGatewayController`, `RetailCashierController` for the template.

## Full Guidelines
`README.md` is auto-loaded into every session alongside this file (via `.opencode/plugins/skycom-context.js`, since OpenCode V2 ignores the `instructions` field in `opencode.json`). It covers:
- Stimulus naming conventions & inheritance
- Global Helpers (fetchJson, form, openModal, toast, tooltip)
- Type definitions (JSDoc patterns)
- Form engine lifecycle
