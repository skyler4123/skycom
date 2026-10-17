# Skycom Homepage System

> **Status**: Live (2026-10-11). Static SEO marketing page + live multi-tenant
> demo console. Brand is **"Skycom"** (not "Skycom ERP"). English-only.

---

## 1. Overview

The homepage (`/`, `HomeController#index`) is Skycom's public marketing face:
a full landing page (hero, vertical solutions, pricing, social proof, footer)
with a **live demo console** mockup (tenant switcher, metric cards, ApexCharts
chart, action ledger). It is intentionally the only page built this way:

| Property | Homepage | App pages |
|----------|----------|-----------|
| Server HTML | Identical signed-out markup for **everyone** (SEO) | Shell-First shells hydrated per user |
| Auth UI | JS-rendered pages (`/sign_in`, `/sign_up`) + client-side header swap | Server-known session |
| Dynamic numbers | Demo ticker (fake data, visibly a mockup) | Real JSON APIs |
| HTTP caching | Browser-private, 1 hour (§7) | Not cached |

---

## 2. Architecture

```
GET /  →  HomeController#index
  │  static signed-out HTML (both header blocks, §3)
  │  Cache-Control: private, max-age=3600 + Vary: Cookie (§7)
  ▼
Browser
  ├── home--index connects
  │     ├── cookie says signed in? ──yes──▶ hide #header-guest, show #header-signedin
  │     │                                    (avatar paints when client cache arrives)
  │     ├── render ApexCharts velocity chart
  │     └── start 2s demo ticker (sales/txns/credits/pool/latency)
  └── ClientCacheController syncs client_cache_data in the background
```

Rules:

- **No server `is_signed_in?` branching on this page.** The ERB ships both
  header states; the Stimulus controller picks one from the `is_signed_in`
  cookie. This is what makes the response cacheable (§7).
- **No modal auth on this page.** Sign-in/sign-up live on dedicated
  JS-rendered pages (§5). The last modal (`Companies_NewModal`) was moved to
  `/companies/new` (§6); no `*_modal_controller.js` remains under `home/`.
- **All bait CTAs are plain anchors** (`/sign_up`, `/sign_in`) — crawlable
  and working without JS. The only form is the final CTA, a GET to
  `/sign_up?email=` for prefill.

---

## 3. Section Inventory & Anchor Map

| # | Section | Anchor | Notes |
|---|---------|--------|-------|
| 1 | Header | — | `#header-guest` (visible) + `#header-signedin` (`hidden`, §9) |
| 2 | Hero | — | Trust tag (`$0 Base Fee` → `/sign_up`), H1 (single on page), CTA cluster, tick row |
| 3 | Demo console | `#interactive-preview` | Tenant tabs, 3 metric cards, chart + ledger grid (§4) |
| 4 | Vertical solutions | `#solutions` | Retail / Dental / Hotel / Restaurant cards + industry pills + schema strip |
| 5 | Multi-tenant core | — | 3 cards (switcher, credit pool, provisioning) |
| 6 | Operational pillars | `#platform` | 6 cards (POS, inventory, HR/payroll, attendance, calendar, billing) |
| 7 | Pricing transparency | `#pricing` | Free-tier card, bait CTA → `/sign_up` |
| 8 | Enterprise scaling | — | 6 cards (platform, schemas, sprawl, RBAC, API, SLA) |
| 9 | Stats + testimonials | — | 4 counters, 4 quotes |
| 10 | Final CTA | — | GET form → `/sign_up?email=` |
| 11 | Footer | — | 5 columns + bottom bar, `© 2025 Skycom Technologies Inc.` |

Header nav links: Solutions → `#solutions`, Pricing → `#pricing`,
Docs → `#platform`. Sections carrying anchors use `scroll-mt-*` for the
fixed header offset.

---

## 4. Live Demo Console

The console is a **mockup with live-feeling numbers** — explicitly demo data,
not account data. Same ApexCharts pattern as
`companies/dashboards/index_controller.js` (`import ApexCharts from
"apexcharts"`, `new ApexCharts(container, options)`, `chart.render()`).

| Piece | Behavior |
|-------|----------|
| Tenant tabs | `switchTenant` flips `aria-pressed` styling, retitles the panel (`#tenant-title`), reseeds sales/txns/credits from per-tab `data-*-param` bases (pool stays global — it is master-level) |
| Ticker (2s) | `tick()` in `home/index_controller.js`: +1–3 txns, +$45–165 sales, +0.1 credit burn, −0.1 pool (floored at 0), latency jitter 100–124ms; skips when tab hidden |
| Y-axis integers | Chart series stores **whole dollars** (`Math.round`), ticks format via `Math.round(val).toLocaleString("en-US")`, tooltip rounds too — float dust (`400.0000000000`) is impossible by construction |
| Reduced motion | `prefers-reduced-motion: reduce` renders the chart but never starts the ticker |
| Cleanup | `disconnect()` clears the interval and destroys the chart (no leaks across Turbo navigations) |

Server-rendered initial values (`$18,450.00`, `248 transactions`, …) double as
the no-JS fallback and the spec anchors (`[data-live="sales"]`, …).

---

## 5. Auth Pages (`/sign_in`, `/sign_up`)

JS-rendered Shell-First pages — the modal markup, minus modal chrome:

| Item | Detail |
|------|--------|
| Routes | `get "sign_in" → sessions#new`, `get "sign_up" → registrations#new` (same helpers as the POSTs) |
| Actions | Shell-First (`format.html { render html: "", layout: true }`); `redirect_if_signed_in → root_path` on both `new` actions |
| Controllers | `sessions/new_controller.js` (`Sessions_NewController`), `registrations/new_controller.js` (`Registrations_NewController`) — Google OAuth form, divider, email form (`form[role="sign-in-form"]` / `form[role="sign-up-form"]`, `data-turbo="false"` full POST), cross-links, logo-home link |
| Failure redirects | Back to their own page (`sign_in_path` / `sign_up_path` with alert) — keeps auth flashes off the homepage cache entry |
| Success | Unchanged: redirect `/` with notice (flash forces `expires_now` there, §7) |
| Prefill | Signup reads `?email=` (final-CTA handoff) |
| Gotcha | `SessionsController::OmniauthConcern` runs an auth filter on every action — `new` **must** stay in its skip list or guests 302 (this bit once) |
| Caching | None (per-session CSRF meta in the layout — same rule as §7) |

---

## 6. Company Page (`/companies/new`)

The New Company modal had exactly one caller (the homepage), so it moved
whole: `companies/new_modal_controller.js` **deleted**,
`companies/new_controller.js` (`Companies_NewController`) renders the same
form as a centered page card (same fields, same `translate()` keys, same
`POST /companies` endpoint and redirects; Cancel is a back-to-`/` link).
Homepage "New Company" is a plain `<a href="/companies/new">`, shipped
`hidden` and revealed client-side only for accounts allowed to create
companies (`User#can_create_company?` — §9); `CompaniesController#new` /
`#create` enforce the same rule server-side (members of existing companies
are redirected back with an alert).

> After deleting any Stimulus controller file, run `bin/rails assets:clobber`
> **then** `bin/rails tailwindcss:build` — clobber wipes the Tailwind build
> and feature specs render unstyled (invisible `hidden` blocks) until it is
> rebuilt.

---

## 7. Caching Contract (read before touching)

`HomeController#index`:

```ruby
if flash.any?
  expires_now
else
  expires_in 1.hour, public: false
  response.headers["Vary"] = "Cookie"
end
```

| Rule | Why |
|------|-----|
| `private, max-age=3600` — browser cache only | Repeat visits are instant per browser |
| **Never `public`** | The layout embeds a per-session CSRF token that modal/page forms submit. A shared copy serves one user's token to everyone → mass 422s; tokens also go stale across sign-out. Verified the hard way. |
| `Vary: Cookie` | Cookie change (sign-in/out) = cache miss = fresh fetch; same-session revisits hit |
| `expires_now` on flash | Post-auth landings carry one-time notices — never cache a response carrying one |

---

## 8. SEO Rules

- Static crawlable HTML — all content (including demo initial values) is in
  the server response; no JS required to read the page.
- Exactly one H1; page `<title>`, meta description, OG tags, and canonical
  via the layout's `content_for(:title)` / `content_for(:head)` slots.
- CTAs are anchors (`/sign_up`, `/sign_in`, `#interactive-preview`), never
  JS-only buttons — except in-page actions (tenant tabs, chart), which carry
  no SEO weight.

---

## 9. Header Swap Mechanics

Static ERB ships `#header-guest` (visible) + `#header-signedin` (`hidden`,
containing Go to Dashboard (`#header-dashboard-link`), New Company
(`#header-new-company-link`), Admin Dashboard (`#header-admin-link`,
`hidden`), and the `home--header--authentication` avatar mount). On connect,
`home/index_controller.js#renderSignedInHeader` checks the synchronous
`Helpers.isSignedIn()` cookie — if set, it hides guest and shows signed-in.
No waiting on the client cache (an earlier version gated on `currentUser()`
arrival and flaked on sync timing); the avatar helper renders a placeholder
until the cache arrives, matching every other page. `syncRoleLinks()`
polls `currentUser()` once the cache arrives: `admin` / `super_admin`
reveals the admin link and hides dashboard + new-company; `company_owner` —
or any account that belongs to no company yet (`currentCompanies()` empty,
e.g. fresh signups) — reveals New Company (shipped `hidden` in the ERB, like
the admin link); members of existing companies (`company_employee` /
`company_customer`) keep only Go to Dashboard. The endpoint enforces the
same rule via `User#can_create_company?` (§6).

The layout's shared flash bar (`#notice` / `#alert`) is a fixed top overlay
(`top-0`, `z-[60]` — above every page header, which tops out at `z-50`), so
a flash is always pinned to the very top of the viewport — including over
the homepage's fixed header, which would otherwise paint straight over an
in-flow bar.

---

## 10. Testing

| Spec | Coverage |
|------|----------|
| `spec/features/homepage_spec.rb` | Static header links + `href`s, swap to signed-in header, avatar, sign-out, dashboard nav, company page flows (owner reveal + manager-employee gating; flash pinned to the viewport top), live-tick (Capybara-waited, never `sleep`), tenant switch |
| `spec/features/authentication_spec.rb` | Signup/signin submit via pages, email prefill, signed-in redirects away |
| `spec/features/sign_in_flash_spec.rb` / `sign_up_flash_spec.rb` | Success flashes, failure stays on auth page with alert, session persists across reload |
| `spec/features/global_session_cache_spec.rb` / `omniauth_spec.rb` | Session lifecycle + Google OAuth, starting at `/sign_in` |
| `spec/requests/home_spec.rb` | `private` + `max-age=3600` + `Vary: Cookie` on clean GET, static-markup anchors, non-cacheable flash response (POSTs use the forgery-disable wrapper — CSRF is on in test env) |
| `spec/requests/companies_controller_spec.rb` | `GET /companies/new` shell for owners/new accounts, redirect + JSON 403 for company members, redirect for guests; `POST /companies` guard blocks members (no self-promotion) |

House patterns this page depends on: `bundle exec parallel_rspec -n 14`
(never bare `rspec` for verification), navigation-before-content assertions
(`FLAKY_TESTS.md` §8), `assets:clobber` → `tailwindcss:build` after
controller deletion (§6).

---

## 11. File Reference

| File | Purpose |
|------|---------|
| `app/controllers/home_controller.rb` | `index` — static render + cache headers + flash guard |
| `app/views/home/index.html.erb` | Entire page: head tags, dual header, all 11 sections, footer |
| `app/javascript/controllers/home/index_controller.js` | Header swap, role-gated header links, ApexCharts chart, 2s ticker, tenant switch |
| `app/javascript/controllers/home/header/authentication_controller.js` | Avatar-only slot inside `#header-signedin` |
| `app/javascript/controllers/sessions/new_controller.js` | Sign-in page form |
| `app/javascript/controllers/registrations/new_controller.js` | Sign-up page form (+ `?email=` prefill) |
| `app/javascript/controllers/companies/new_controller.js` | Company creation page form |
| `app/controllers/sessions_controller.rb` | `new` shell + `create` (failures → `sign_in_path`) |
| `app/controllers/registrations_controller.rb` | `new` shell + `create` (failures → `sign_up_path`) |
| `app/controllers/companies_controller.rb` | `new` shell + `create` (owner/master-account guarded via `User#can_create_company?`) |
| `app/controllers/concerns/sessions_controller/omniauth_concern.rb` | Auth filter — `new` must stay skipped |
| `config/routes.rb` | `GET /sign_in`, `GET /sign_up` (helpers shared with POSTs) |
| `config/importmap.rb` | `apexcharts` pin (@5.3.6); controllers auto-registered via `pin_all_from` |

---

*See also: `docs/CACHE.md` (client cache + `Vary` semantics), `docs/AUTHENTICATION.md`
(session lifecycle), `docs/DASHBOARD_PATTERN.md` (Shell-First + controller
registration), `docs/MODAL_PATTERN.md` (the pattern auth/company UI left),
`docs/STYLING_GUIDELINES.md` (dark mode, `cursor-pointer`, single-line
classes), `docs/LANGUAGE.md` (page is English-only by decision),
`docs/FLAKY_TESTS.md` (no-`sleep`, navigation-first assertions),
`docs/PARALLEL_TESTS.md` (how to run the suite).*
