# Skycom Calendar System (Cal.com Engine)

> **Status**: Live (2026-09-24). Company-scoped `calendar_*` tables front an
> isolated Cal.com Docker service via the Adapter pattern. The legacy
> `reservations` / `reservation_appointments` tables are **not used** by this
> module and are left untouched (owner removes them separately).

---

## 1. Overview

| Piece | What it is |
|-------|------------|
| **Engine** | Cal.com (`calcom/cal.com:latest`, Docker service `calcom`, host port `3001`) — booking UI, availability, video links |
| **Source of truth** | `calendar_events` (Skycom DB) — every booking exists here first or is imported here |
| **Dedup key** | `calendar_sync_mappings` (`external_event_id` unique per integration) — bidirectional sync never double-creates |
| **Auth** | `calendar_integrations` (one row per company + accountable + provider; tokens via `encrypts`) |
| **Isolation** | `CalendarAdapters::BaseAdapter` contract — Cal.com details never leak into controllers/jobs |

Tables are company-scoped (`company_id NOT NULL` everywhere) and carry the
standard System Fields block. Dynamic `property_*` slots are intentionally
absent — calendar data is fixed-shape; extensibility lives in the single
`metadata` jsonb per table via `store_accessor` (`docs/STORE_ACCESSOR.md`).

## 2. Networking (Rails on host, Cal.com in Docker)

Rails web (`bin/dev`, port 3000) and jobs (`bin/jobs`) run on the **host
machine**, not inside Docker. Cal.com runs in Docker with host port `3001`.

```
Host machine                              Docker network
─────────────────                         ──────────────
Rails web :3000  ◄── webhook ──────────── calcom container
bin/dev (-b 0.0.0.0)  http://192.168.0.100:3000
                      /webhooks/calendar/cal_com
        │
        └── API calls ──► http://localhost:3001/api/v2
            (host port mapping 3001:3000)
bin/jobs (host) ──► same localhost:3001
```

| Direction | URL | Constant |
|-----------|-----|----------|
| Rails → Cal.com | `http://localhost:3001/api/v2` | `CALCOM_API_URL` |
| Cal.com → Rails | `http://192.168.0.100:3000/webhooks/calendar/cal_com` | `RAILS_PUBLIC_URL` + route |
| Webhook secret | HMAC-SHA256 (`X-Cal-Signature-256`) | `CALCOM_WEBHOOK_SECRET` |

All three live in `config/initializers/constants.rb` as `ENV.fetch` with the
values above as defaults (hardcoded ENV per request — overridable without code
change). `docker-compose.yml` `WEBHOOK_URL` mirrors the Cal.com → Rails URL.

> `http://web:80/...` only resolves **inside** the Docker network. It never
> worked for host-run Rails and must not be reintroduced.

## 3. Schema

### calendar_integrations

One connected account per company + accountable (User) + provider.

| Column | Purpose |
|--------|---------|
| `company_id` / `accountable_type`+`id` / `provider` (unique together) | Tenant + owner + engine |
| `external_user_id` | Cal.com user id |
| `access_token` / `refresh_token` | `encrypts` — never logged |
| `status` | `inactive` / `active` / `errored` |
| `metadata` → `calcom_event_type_id`, `webhook_secret` | `store_accessor` (no extra jsonb columns) |

### calendar_events

Internal source of truth. `schedulable` (polymorphic, optional) links to a
future internal Booking/Consultation — unused today, reserved.

| Column | Purpose |
|--------|---------|
| `company_id`, `calendar_integration_id` (optional), `schedulable` (optional) | Scope + links |
| `title`, `description`, `starts_at`, `ends_at`, `time_zone` | The booking |
| `status` | `pending` / `confirmed` / `cancelled` / `rescheduled` |
| `metadata` → `attendees`, `meeting_url`, `location_type`, `external_uid` | `store_accessor` |

### calendar_sync_mappings

Dedup rows: one per (`calendar_event`, `calendar_integration`) pair.

| Column | Purpose |
|--------|---------|
| `company_id` (derived from event/integration) | Tenant scope |
| `external_event_id` (unique per integration) | Cal.com booking id |
| `external_booking_uid` | Cal.com uid |
| `last_synced_at` | Freshness |

## 4. Adapter Pattern

```
Controllers / Jobs
      │  CalendarAdapters::BaseAdapter contract
      │  (create_event / update_event / cancel_event / process_webhook)
      ▼
CalendarAdapters::CalComAdapter   (Faraday, CALCOM_API_URL, Bearer token)
      │
      ▼
Cal.com API v2
```

- `BaseAdapter` (`app/services/calendar_adapters/base_adapter.rb`) — raises
  `NotImplementedError` per method. New providers (Google, Outlook) subclass it.
- `CalComAdapter` — `create_event` POSTs `bookings` (`start`, `eventTypeId`
  from `metadata["calcom_event_type_id"]`, `attendees`, `metadata.skycom_event_id`)
  and writes the mapping row; returns `false` on rejection (no mapping).
  `process_webhook` handles `BOOKING_CREATED` (import + dedupe),
  `BOOKING_CANCELLED` (`cancelled!`), `BOOKING_RESCHEDULED` (new times +
  `rescheduled` + `touch(:last_synced_at)`).

## 5. Webhook Flow

```
Cal.com event ──POST (X-Cal-Signature-256)──►
  Webhooks::Calendar::CalComController#create
    │  verify HMAC (dev fallback: plain secret compare for curl)
    │  401 { errors: [...] } on bad signature
    ▼
  CalendarSyncJob.perform_later(company_id:, payload:)
    │  queue_as :calendar_sync, resolves active cal_com integration
    ▼
  CalComAdapter#process_webhook
```

- Route: `POST /webhooks/calendar/cal_com` (`config/routes.rb`).
- Controller never touches calendar rows directly — job + adapter own the write
  path (mirrors `Webhooks::Payments::MockQrGatewayController`).
- Error format is `errors` (plural array) per `docs/API_ERROR_FORMAT.md`.
- Multi-tenant note: the job resolves `company_id` when the webhook URL carries
  `?company_id=` (per-integration Cal.com webhook config), else the first
  active `cal_com` integration. Per-integration fan-out is future work.

## 6. Usage

```ruby
integration = CalendarIntegration.create!(
  company: company, accountable: user, provider: "cal_com",
  status: :active, access_token: "cal_live_...",
  calcom_event_type_id: "123"
)

event = CalendarEvent.create!(
  company: company, calendar_integration: integration,
  title: "ERP Setup Consultation",
  starts_at: 2.days.from_now, ends_at: 2.days.from_now + 45.minutes,
  attendees: [ { "name" => "Client", "email" => "client@example.com" } ]
)

CalendarAdapters::CalComAdapter.new(integration).create_event(event)
```

## 7. What This Module Does NOT Use

- `reservations` / `reservation_appointments` / `ReservationConcern` — legacy
  booking tables. Untouched by migrations, models, and specs in this module;
  removal is a separate task owned outside this doc.

## 8. File Reference

| File | Purpose |
|------|---------|
| `db/migrate/20260924000001_create_calendar_tables.rb` | 3 tables (company-scoped, UUIDv7, System Fields) |
| `app/models/calendar_integration.rb` | Account + `encrypts` tokens + metadata accessors |
| `app/models/calendar_event.rb` | Source of truth + `upcoming` scope + time validation |
| `app/models/calendar_sync_mapping.rb` | Dedup + company derivation |
| `app/models/company.rb` | `has_many :calendar_*` + `DEFAULT_RESOURCE_NAMES` entries |
| `app/services/calendar_adapters/base_adapter.rb` | Provider contract |
| `app/services/calendar_adapters/cal_com_adapter.rb` | Cal.com implementation (Faraday) |
| `app/jobs/calendar_sync_job.rb` | Async webhook processing (`queue_as :calendar_sync`) |
| `app/controllers/webhooks/calendar/cal_com_controller.rb` | Signature check + enqueue |
| `config/routes.rb` | `POST /webhooks/calendar/cal_com` |
| `config/initializers/constants.rb` | `CALCOM_API_URL`, `CALCOM_WEBHOOK_SECRET`, `RAILS_PUBLIC_URL` |
| `docker-compose.yml` | `WEBHOOK_URL` → host LAN URL |
| `spec/models/calendar_*_spec.rb` | Model coverage (11 examples) |
| `spec/services/calendar_adapters/cal_com_adapter_spec.rb` | Adapter contract + webhook import/dedupe (7 examples) |
| `spec/requests/webhooks/calendar/cal_com_controller_spec.rb` | Webhook auth + job dispatch (3 examples) |

---

*See also: `docs/MONEY_FLOW.md` §13 (gateway pattern precedent),
`docs/WEBSOCKET.md` (event publishing), `docs/API_ERROR_FORMAT.md` (`errors`
plural), `docs/CONSTANTS.md` (ENV-backed constants).*
