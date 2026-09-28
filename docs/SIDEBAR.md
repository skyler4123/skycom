# Skycom Sidebar System

> **Status**: Live (2026-09-22). Sidebar control is **FE-only** — per-company favourites and
> group open-state live in the browser's localStorage. There is no backend sidebar config
> (the old `Setting`-based visibility was removed).

## 1. Architecture

| File | Responsibility |
|------|----------------|
| `app/javascript/controllers/companies/sidebar_items.js` | Registry — `SIDEBAR_GROUPS` + `SIDEBAR_ITEMS` are the structural source of truth (render order, icons, hrefs, `comingSoon`/`locked` flags) |
| `app/javascript/controllers/companies/sidebar_storage.js` | localStorage helpers — favourites + open-group state, per company |
| `app/javascript/controllers/companies/sidebars/show_controller.js` | Renderer — Favourites section + collapsible `<details>` groups + star toggles (`Companies_Sidebars_ShowController`, identifier `companies--sidebars--show`) |
| `app/javascript/controllers/companies/layout_controller.js` | Mounts the sidebar controller inside the `<aside>`; owns the header |

## 2. Slack-style UX

- **Favourites** — always-open section at the top. An item appears here AND in its
  original group (star = shortcut, not a move). Empty state shows the hint
  "Click the star on any item to pin it here".
- **Star toggle** — trailing star button on regular items: filled yellow
  (`font-variation-settings: 'FILL' 1`) when favourited, grey outline otherwise.
  Regular = not `comingSoon` and not in a `locked` (System) group.
- **Groups** — every group renders as `<details>/<summary>` (label + item count),
  collapsed by default; open state persists per company.
- **Coming-soon** groups/items keep the amber badge + tooltip; no star.
- **System group** — `locked: true`; no stars; still collapsible.

## 3. Storage (localStorage)

| Key | Content |
|-----|---------|
| `sidebar_favourites_<company_id>` | JSON array of item keys, e.g. `["products","orders"]` |
| `sidebar_open_groups_<company_id>` | JSON array of open group keys, e.g. `["catalog"]` |

- Plain flat keys (same pattern as `open-cache-sidebar` / `languageCode`) — never inside
  `client_cache_data`, so `ClientCacheController.sync()` cannot clobber them.
- **Browser-level by design**: a new browser/laptop starts with empty favourites.
- Corrupt JSON is treated as an empty list (try/catch in `sidebar_storage.js`).

## 4. How to Add a Sidebar Item

1. Add an entry to `SIDEBAR_ITEMS` in `sidebar_items.js` (pick the group, icon, label, href helper).
2. If the group is new, add it to `SIDEBAR_GROUPS` (array order = render order).
3. Add the label (and any new UI strings) to `app/javascript/controllers/helpers/dictionary.js`.
4. Ensure the URL helper exists in `app/javascript/controllers/helpers/url_helpers.js`.
5. Run `bin/rails assets:clobber` and reload.

No backend changes, no routes, no policies — rendering and visibility are FE-only.

## 5. Settings Page

`/companies/:id/settings` remains a **shell** (route `resources :settings, only: [ :index ]`,
`Companies::SettingsController#index`, `Companies_Settings_IndexController` placeholder) for
future settings modules. The old "Sidebar" tab was removed with the BE config.

## 6. File Reference

| File | Purpose |
|------|---------|
| `app/javascript/controllers/companies/sidebar_items.js` | Registry |
| `app/javascript/controllers/companies/sidebar_storage.js` | localStorage helpers |
| `app/javascript/controllers/companies/sidebars/show_controller.js` | Renderer |
| `app/javascript/controllers/companies/layout_controller.js` | Mount point |
| `spec/features/companies/layouts/sidebar_spec.rb` | E2E (favourites, groups, persistence, per-company scoping) |
| `docs/CACHE.md` §6 | localStorage key inventory |

---

*See also: `docs/CACHE.md` (localStorage conventions), `docs/LANGUAGE.md` (translate rules).*
