# Skycom Sidebar System

> **Status**: Live (2026-09-22). Sidebar control is **FE-only** — per-company favourites and
> group open-state live in the browser's localStorage. Static structure lives in
> `sidebar_items.js`; company-level **custom groups** (dynamic sidebar) live in a
> company `Setting` and render from the client cache (§7).

## 1. Architecture

| File | Responsibility |
|------|----------------|
| `app/javascript/controllers/companies/sidebar_items.js` | Registry — `SIDEBAR_GROUPS` + `SIDEBAR_ITEMS` are the static structural source of truth (render order, icons, hrefs, `comingSoon`/`locked` flags) |
| `app/javascript/controllers/companies/sidebar_custom.js` | Reader — custom groups from the client-cache `Setting` (`DYNAMIC_SIDEBAR_CODE`), key namespacing (`custom_` / `custom_item_`), `javascript:` URL rejection |
| `app/javascript/controllers/companies/sidebar_storage.js` | localStorage helpers — favourites + open-group state, per company |
| `app/javascript/controllers/companies/sidebars/show_controller.js` | Renderer — Favourites section + custom groups (above static) + collapsible `<details>` static groups + star toggles (`Companies_Sidebars_ShowController`, identifier `companies--sidebars--show`) |
| `app/javascript/controllers/companies/settings/index_controller.js` | Editor — Dynamic Sidebar group/item CRUD on the Settings page (PATCH `Setting` metadata) |
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

`/companies/:id/settings` hosts the **Dynamic Sidebar editor**
(`Companies_Settings_IndexController`): group add/rename/delete, item
name + URL add/edit/delete, one Save → `PATCH /companies/:id/settings/:id`
(`Companies::SettingsController#update`) → `clearClientCacheAndReload()` so
the sidebar re-renders from the fresh client cache. The old "Sidebar" tab
was removed with the BE config.

## 6. File Reference

| File | Purpose |
|------|---------|
| `app/javascript/controllers/companies/sidebar_items.js` | Static registry |
| `app/javascript/controllers/companies/sidebar_custom.js` | Dynamic reader (`DYNAMIC_SIDEBAR_CODE`, key namespacing) |
| `app/javascript/controllers/companies/sidebar_storage.js` | localStorage helpers |
| `app/javascript/controllers/companies/sidebars/show_controller.js` | Renderer (custom groups above static) |
| `app/javascript/controllers/companies/settings/index_controller.js` | Dynamic Sidebar editor |
| `app/javascript/controllers/companies/layout_controller.js` | Mount point |
| `app/models/setting.rb` | `store_accessor :metadata, :sidebar_groups` + shape validation + `dynamic_sidebar` scope |
| `app/controllers/companies/settings_controller.rb` | Index (Shell-First JSON) + update (dynamic sidebar metadata JSON) |
| `app/controllers/client_cache_controller.rb` | Includes `settings` in the company payload |
| `config/initializers/constants.rb` | `DYNAMIC_SIDEBAR_CODE` |
| `spec/features/companies/layouts/sidebar_spec.rb` | E2E (favourites, groups, persistence, per-company scoping) |
| `spec/features/companies/layouts/dynamic_sidebar_spec.rb` | E2E (custom groups above static, pasted URLs, custom stars) |
| `spec/features/companies/settings/dynamic_sidebar_editor_spec.rb` | E2E (editor CRUD → sidebar reflects) |
| `spec/services/seed/dynamic_sidebar_init_spec.rb` | Init record + Admin/Manager grants (retail/hospital/hotel) |
| `docs/CACHE.md` §6 | localStorage key inventory + client-cache payload |

## 7. Dynamic Sidebar (custom groups)

Company-level shortcuts that render **above** the static groups, next to the
built-in sidebar — the user builds their own sidebar without touching code.

### Storage

One `Setting` per company (`appoint_to` = Company, `business_type: :company`,
`code = DYNAMIC_SIDEBAR_CODE`, enforced unique per company):

```jsonc
// metadata
{ "sidebar_groups": [
  { "key": "quick-links", "name": "Quick Links", "items": [
    { "key": "pending-orders", "name": "Pending Orders", "url": "/companies/<id>/orders?workflow_status=pending" }
  ] }
] }
```

- `Setting#sidebar_groups` (`store_accessor`) defaults to `[]`; the model
  validates the shape (groups need names, items need name + URL,
  `javascript:` URLs rejected).
- Created empty by every init service (`create_default_dynamic_sidebar`);
  the retail enricher fills one sample group for development. Owners edit it
  on the Settings page; `Setting` CRUD policies + Admin/Manager grants ship
  with `Company::DEFAULT_RESOURCE_NAMES`.

### Render

`sidebar_custom.js` reads the record from `currentSettings()` (client cache),
filters invalid entries, and maps them to the static item shape
(`{ key, group, icon: "link", label, href: (cid) => url, custom: true }`):

- Group keys are namespaced `custom_<slug>`, item keys `custom_item_<slug>` —
  favourites + open-group localStorage entries can never collide with static
  keys, so custom items star/unstar exactly like normal items (same
  `data-sidebar-star` button, same Favourites section).
- Labels + hrefs are `escapeHtml`'d at render (user-controlled strings);
  `markCurrentPath()` compares pathnames only, so pasted query params never
  break highlighting. Corrupt metadata renders as no custom groups.

### Editing

The Settings-page editor keeps group/item state locally (inputs sync on
`input`, structure re-renders on add/remove so focus is never lost) and saves
with `PATCH Setting` (`FormData` with indexed
`setting[metadata][sidebar_groups][i]…` brackets, normalized server-side like
the TableConfig JSONB pattern) → `clearClientCacheAndReload()` with the
server's message. `Setting touch: true` bumps `company.updated_at`, so the
version cookie resyncs the cache on reload.

---

*See also: `docs/CACHE.md` (localStorage conventions), `docs/LANGUAGE.md` (translate rules).*
