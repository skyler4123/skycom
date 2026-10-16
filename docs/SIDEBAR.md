# Skycom Sidebar System

> **Status**: Live. Sidebar control is **FE-only** — per-employee favourites and
> group open-state live in the browser's localStorage. Static structure lives in
> `sidebar_items.js`; company-level **custom groups** live in the company's
> active sidebar `CompanySetting` and render from the client cache (§7).

## 1. Architecture

| File | Responsibility |
|------|----------------|
| `app/javascript/controllers/companies/sidebar_items.js` | Registry — `SIDEBAR_GROUPS` + `SIDEBAR_ITEMS` are the static structural source of truth (render order, icons, hrefs, `comingSoon`/`locked` flags) |
| `app/javascript/controllers/companies/sidebar_custom.js` | Reader — custom groups from the client-cache active sidebar `CompanySetting` (`business_type: sidebar_groups`), key namespacing (`custom_` / `custom_item_`), `javascript:` URL rejection |
| `app/javascript/controllers/companies/sidebar_storage.js` | localStorage helpers — favourites + open-group state, per employee (company + user) |
| `app/javascript/controllers/companies/sidebars/show_controller.js` | Renderer — Favourites section + custom groups (above static) + collapsible `<details>` static groups + star toggles (`Companies_Sidebars_ShowController`, identifier `companies--sidebars--show`) |
| `app/javascript/controllers/companies/settings/index_controller.js` | Editor — sidebar group/item CRUD (company form → PATCH `CompanySetting`) on the Settings page |
| `app/javascript/controllers/companies/layout_controller.js` | Mounts the sidebar controller inside the `<aside>`; owns the header |

## 2. Slack-style UX

- **Favourites** — always-open section at the top. An item appears here AND in its
  original group (star = shortcut, not a move). Empty state shows the hint
  "Click the star on any item to pin it here".
- **Star toggle** — trailing star button on regular items: filled yellow
  (`font-variation-settings: 'FILL' 1`) when favourited, grey outline otherwise.
  Regular = not `comingSoon` and not in a `locked` (System) group.
- **Groups** — every group renders as `<details>/<summary>` (label + item count),
  collapsed by default; open state persists per employee.
- **Coming-soon** groups/items keep the amber badge + tooltip; no star.
- **System group** — `locked: true`; no stars; still collapsible.

## 3. Storage (localStorage)

| Key | Content |
|-----|---------|
| `sidebar_favourites_<company_id>_<user_id>` | JSON array of item keys, e.g. `["products","orders"]` |
| `sidebar_open_groups_<company_id>_<user_id>` | JSON array of open group keys, e.g. `["catalog"]` |

- Legacy per-company keys (`sidebar_favourites_<company_id>`) are migrated once
  on first read when the per-employee key is empty.
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

`/companies/:id/company_settings` hosts the **sidebar editor**
(`Companies_CompanySettings_IndexController`): group add/rename/delete, item
name + URL add/edit/delete, one Save → `PATCH /companies/:id/company_settings/:id`
(`Companies::CompanySettingsController#update`) → `clearClientCacheAndReload()` so
the sidebar re-renders from the fresh client cache.

## 6. File Reference

| File | Purpose |
|------|---------|
| `app/javascript/controllers/companies/sidebar_items.js` | Static registry |
| `app/javascript/controllers/companies/sidebar_custom.js` | Dynamic reader (active `sidebar_groups` record, key namespacing) |
| `app/javascript/controllers/companies/sidebar_storage.js` | localStorage helpers |
| `app/javascript/controllers/companies/sidebars/show_controller.js` | Renderer (custom groups above static) |
| `app/javascript/controllers/companies/settings/index_controller.js` | Dynamic Sidebar editor |
| `app/javascript/controllers/companies/layout_controller.js` | Mount point |
| `app/models/company_setting.rb` | `store_accessor :metadata, :sidebar_groups` + shape validation + `active_sidebar` scope + single-active validation |
| `app/controllers/companies/company_settings_controller.rb` | Index (Shell-First JSON) + update (sidebar metadata JSON) |
| `app/controllers/client_cache_controller.rb` | Includes `company_settings` in the company payload |
| `spec/features/companies/layouts/sidebar_spec.rb` | E2E (favourites, groups, persistence, per-employee scoping) |
| `spec/features/companies/layouts/dynamic_sidebar_spec.rb` | E2E (custom groups above static, pasted URLs, custom stars) |
| `spec/features/companies/settings/dynamic_sidebar_editor_spec.rb` | E2E (editor CRUD → sidebar reflects) |
| `spec/services/seed/dynamic_sidebar_init_spec.rb` | Init record + Admin/Manager grants (retail/hospital/hotel) |
| `docs/CACHE.md` §7 | localStorage key inventory + client-cache payload |

## 7. Dynamic Sidebar (custom groups)

Company-level shortcuts that render **above** the static groups, next to the
built-in sidebar — the user builds their own sidebar without touching code.

### Storage

One active `CompanySetting` per company per `business_type` (`business_type:
:sidebar_groups`, `workflow_status: :active`, unique `name` per company,
single-active enforced by model validation + partial unique index):

```jsonc
// metadata
{ "sidebar_groups": [
  { "key": "quick-links", "name": "Quick Links", "items": [
    { "key": "pending-orders", "name": "Pending Orders", "url": "/companies/<id>/orders?workflow_status=pending" }
  ] }
] }
```

- `CompanySetting#sidebar_groups` (`store_accessor`) defaults to `[]`; the model
  validates the shape (groups need names, items need name + URL,
  `javascript:` URLs rejected).
- Created empty by every init service (`create_default_dynamic_sidebar`);
  the retail enricher fills one sample group for development. Owners edit it
  on the Settings page; `CompanySetting` CRUD policies ship
  with `Company::DEFAULT_RESOURCE_NAMES`, but `update` is owner-only
  (`CompanySettingsPolicy#update?` → `owner_role?`; Admin/Manager `update`
  grants are `inactive`). A company may hold several sidebar
  records (e.g. drafts) but only the `active` one renders.

### Render

`sidebar_custom.js` reads the active sidebar record from `currentSettings()`
(`company_settings` client-cache payload), filters invalid entries, and maps them
to the static item shape (`{ key, group, icon: "link", label, href: (cid) => url, custom: true }`):

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
with `PATCH CompanySetting` (`FormData` with indexed
`company_setting[metadata][sidebar_groups][i]…` brackets, normalized server-side like
the TableConfig JSONB pattern) → `clearClientCacheAndReload()` with the
server's message. `CompanySetting touch: true` bumps `company.updated_at`, so the
version cookie resyncs the cache on reload — every employee sees the new
Quick Links.

---

*See also: `docs/CACHE.md` (localStorage conventions), `docs/LANGUAGE.md` (translate rules).*
