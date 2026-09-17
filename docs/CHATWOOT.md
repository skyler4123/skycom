# Skycom Chatwoot Integration

> **Status**: Live (2026-09-17) — DB/service phase. Chatwoot is the embedded
> live-chat platform (Docker, `docker-compose.yml` `chatwoot-*` services) and
> its database is the **second source of truth** in the Skycom ecosystem for
> chat data — Skycom provisions and maintains it. No UI yet: this phase wires
> the data layer (per-company account provisioning + seed cleanup). The UI
> and conversation flows come with the Chat & Help Desk feature
> (`docs/ROADMAP.md`).

---

## 1. Overview

| Concept | Meaning |
|---------|---------|
| **Chatwoot** | Self-hosted open-source chat platform (`chatwoot/chatwoot:v3.12.0`), running isolated in Docker (`chatwoot-web` on `localhost:3001`, its own `chatwoot-postgres` + `chatwoot-redis`) |
| **Second source of truth** | Chat data (accounts, contacts, conversations — later phases) lives in Chatwoot's DB; Skycom owns/maintains that data too — cleared + re-provisioned at seed time |
| **Provisioning** | Every `Company` (normal **and** system companies) automatically gets one Chatwoot account on creation |
| **Service boundary** | All Chatwoot interaction goes through `Chatwoot::BaseService` — no controller/model/job talks to Chatwoot directly |

### The One Account Rule

| Company kind | Gets a Chatwoot account? | Why |
|--------------|--------------------------|-----|
| Normal company | ✅ | Hosts the company's future chat (B2C customer ↔ company, B2B company ↔ Skycom) |
| System company (`system_owned`) | ✅ Same callback, unconditional | The platform side of Chat & Help Desk — see `docs/SYSTEM_COMPANY.md` |

The account is **not** deleted when the company is destroyed or wiped — Chatwoot
data survives company lifecycles by design; only seeding clears it.

## 2. Architecture

```
Company#after_create :setup_chatwoot_account      ← unconditional (outside skip_init/system_owned guard)
      │  rescue + log "[Chatwoot]" — never blocks company creation
      ▼
Chatwoot::BaseService            ← domain surface (class-level API, §4)
      │
      ▼
Chatwoot::Client                 ← transport (Faraday, Platform API, api_access_token header)
      │
      ▼
chatwoot-web  →  POST/GET/DELETE /platform/api/v1/accounts
```

## 3. Platform API Facts (v3.12.0 — verified from source)

| Fact | Consequence |
|------|-------------|
| `POST /platform/api/v1/accounts` — `{ name, locale?, custom_attributes? ... }` → `{ id, name }` | Create path; the created account is auto-permitted to the calling platform app |
| `GET /platform/api/v1/accounts/:id` | Fetch path (debug hook) |
| `DELETE /platform/api/v1/accounts/:id` — **async** (`DeleteObjectJob`, returns 200 immediately) | Clear path is fire-and-forget per id |
| **No list-accounts endpoint** | Clearing enumerates ids (§5) |
| Platform apps only access objects **they created** (or were explicitly permitted via `PlatformAppPermissible`) | GET on foreign accounts errors — treated as a miss |
| Auth header: `api_access_token: <platform token>` | `Chatwoot::Client` sets it on every request |

## 4. Service API

`Chatwoot::BaseService` (class-level methods):

| Method | Behavior |
|--------|----------|
| `create_account!(company:)` | **Idempotent.** Stored id + reachable account → return existing (heal path). Stored id stale (404) → re-provision. Otherwise `POST` `{ name: company.name, custom_attributes: { skycom_company_id: company.id } }` and store the returned id on `companies.chatwoot_account_id`. Raises `Chatwoot::Error` on transport/validation failure (the Company callback rescues) |
| `account_for(company)` | **Debug/verify hook** — returns the Chatwoot account payload for a company: `nil` when no stored id or account gone (404/403), parsed hash on success, raises transport errors so failures stay visible |
| `clear_all!` | Seed-time wipe: enumerate ids `1, 2, 3, …`, DELETE every reachable account, return the deleted count. See §5 |

`Chatwoot::Client` (transport): `get` / `post` / `delete` over `request(method, path, body:)` — 2xx → parsed JSON (`{}` for empty bodies), 404 → `NotFoundError`, 401/403 → `UnauthorizedError`, transport failure → `ConnectionError`, other → `Chatwoot::Error`. Errors live in `app/services/chatwoot.rb` (Zeitwerk namespace root).

## 5. The Clearing Algorithm (no list endpoint)

```
id = 1; consecutive_misses = 0
loop while consecutive_misses < CLEAR_MISS_LIMIT (500)
  GET  /accounts/#{id}   → 200 ⇒ DELETE #{id} (deleted++, misses reset)
                          → non-200 (404/403/…) ⇒ consecutive_misses++
```

- Chatwoot account ids are **Postgres serials — never reused**, so the dead-id prefix grows by 4 with every reseed. The consecutive-miss buffer handles the gaps.
- `CLEAR_MISS_LIMIT = 500` (single-file constant in `base_service.rb`) covers ~125 reseeds; raise it if seeding ever reports stale accounts after a long history.
- Returns the deleted count.

## 6. Configuration

| Setting | Resolution | Value |
|---------|-----------|-------|
| Base URL | `credentials.dig(:chatwoot, :base_url) \|\| ENV.fetch("CHATWOOT_BASE_URL", "http://localhost:3001")` | `localhost:3001` is hardcoded for now — the Rails app runs on the host and Chatwoot exposes `3001:3000` in compose |
| Platform token | `credentials.dig(:chatwoot, :platform_token) \|\| ENV["CHATWOOT_PLATFORM_TOKEN"]` | Required for real HTTP; blank → no-op mode |

**No-op mode** (blank token): `create_account!` / `clear_all!` log a `[Chatwoot]` warning and return (`nil` / `0`) without HTTP; `account_for` raises a configuration error. This keeps any environment without Chatwoot — including the rspec compose — running cleanly, and the dev seed never blocks on a missing token.

## 7. One-Time Bootstrap (ops step)

Platform API access requires a platform app (created once in the Chatwoot container):

```bash
docker compose exec chatwoot-web rails runner "app = PlatformApp.create!(name: 'Skycom'); puts app.access_token.token"
```

Then export the token for the Rails app (host shell or `.env`):

```bash
export CHATWOOT_PLATFORM_TOKEN=<printed token>
```

The Rails app runs on the host (`bin/dev`), so the hardcoded default base URL `http://localhost:3001` already points at the compose-exposed `chatwoot-web`; no docker-compose wiring is needed for the Rails services.

## 8. Failure Policy

| Scenario | Behavior |
|----------|----------|
| Chatwoot down at company creation | One failed HTTP attempt (5s timeout) → rescued + `[Chatwoot]` error log; company is created without an account. Re-run `Chatwoot::BaseService.create_account!(company:)` to heal |
| Chatwoot down at seed time | `clear_chatwoot!` rescues + logs (same philosophy as the Meilisearch wipe); provisioning no-ops warn; seeding completes |
| Token missing | Warn + no-op (see §6) |
| API validation failure (422) | `create_account!` raises → callback logs |

## 9. Linkage & Schema

- `companies.chatwoot_account_id` — nullable `bigint`, unique index (`db/migrate/20260917000001_add_chatwoot_account_id_to_companies.rb`).
- Chatwoot side: account `custom_attributes.skycom_company_id` = company UUID (reverse debugging).
- Seeding wipes companies (`delete_all`) and wipes Chatwoot (`clear_all!`) at seed start — both sides always re-provisioned together.

## 10. Not Built Yet (future phases)

| Layer | Not built yet |
|-------|---------------|
| Users | Platform `User` per company owner + `AccountUser` (administrator) link, employee↔agent mapping |
| Inboxes | Default inbox per account/branch, channel provisioning |
| Conversations | B2C (customer ↔ company) and B2B (company ↔ system company, `docs/SYSTEM_COMPANY.md`) flows |
| Webhooks / WS | Chatwoot → Skycom event bridge |

## 11. File Reference

| File | Purpose |
|------|---------|
| `app/services/chatwoot.rb` | Namespace root — shared error hierarchy |
| `app/services/chatwoot/base_service.rb` | Domain surface: `create_account!` / `account_for` / `clear_all!` |
| `app/services/chatwoot/client.rb` | Faraday transport + config resolution + typed errors |
| `app/models/company.rb` | `after_create :setup_chatwoot_account` (unconditional, rescued) |
| `app/services/seed/application_service.rb` | `clear_external_services!` → `clear_meilisearch!` + `clear_chatwoot!` |
| `db/migrate/20260917000001_add_chatwoot_account_id_to_companies.rb` | Linkage column + unique index |
| `docker-compose.yml` | Chatwoot services (`chatwoot-postgres` / `chatwoot-redis` / `chatwoot-web` / `chatwoot-worker`); Rails env wiring stays on the host (§7) |
| `spec/services/chatwoot/base_service_spec.rb` | Service behaviors (Client-level stubs) |
| `spec/services/chatwoot/client_spec.rb` | Transport status mapping + config precedence |
| `spec/models/company_spec.rb` | Callback provisioning (normal + system) + resilience |
| `spec/services/seed/application_service_spec.rb` | Seed clear wiring |

## 12. See Also

- `docs/CONSTANTS.md` — single-file constants (`API_PREFIX`, `CLEAR_MISS_LIMIT`, `REQUEST_TIMEOUT_SECONDS`)
- `docs/MEILISEARCH.md` §3.1 — the seed-time external-service wipe pattern this extends
- `docs/SYSTEM_COMPANY.md` — why the system company gets an account too
- `docs/ROADMAP.md` — Chat & Help Desk (the feature these accounts will serve)

---

*End of document*
