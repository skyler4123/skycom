# Time Display UTC / Location Timezone — Implementation Plan

> Self-contained plan. A fresh session can execute it without chat history.
> The rule lives in `docs/TIME_DISPLAY.md`.

## Status (2026-11-17)

- [x] Rule, helpers, AGENTS/README wiring
- [x] Operations backend + frontend + feature/service/request specs
- [x] Company and mobile display sweep; admin routed through `utcTime`
- [x] `bin/check_time` guard
- [ ] `datetime-local` native form seeds and params (Step 5)
- [ ] Company-facing `Date.current` / `beginning_of_day` outside operations
      (dashboards, KPI, payroll defaults) — audit and convert to `LocalTime`

---

## 1. Goal

All time data is stored and transported in UTC. The operations consoles show the
Branch/Warehouse clock, company pages show the Company clock, and admin shows
UTC. No screen prints a raw ISO value, and no frontend page leaves the timezone
to the browser.

The reported bug: a UTC+7 reception desk saw `02:00` for a `09:00` local
appointment because the backend formatted UTC strings and the frontend printed
them.

---

## 2. Locked decisions

| Decision | Choice |
|---|---|
| Wire format | ISO 8601 UTC (`2026-11-17T02:00:00Z`) |
| Operation page timezone | Appointment Branch or Warehouse |
| Company page timezone | Company |
| Mobile timezone | Company (`company.utc_offset`) |
| Admin timezone | UTC |
| Frontend formatter | `Helpers.utcTime` / `companyTime` / `locationTime` / `dateOnly` |
| Date-only values | Rendered as calendar dates, never timezone-converted |
| Backend display strings | Removed from console payloads |
| Guard | `bin/check_time` + `docs/TIME_DISPLAY.md` + AGENTS doc map |

---

## 3. Current state

### 3.1 Files

| File | Current role |
|---|---|
| `app/javascript/controllers/helpers/ui_helpers.js` | `timeFormat` defaults to `"UTC"` and ISO output |
| `app/javascript/controllers/helpers/mobile_helpers.js` | Mobile date/time defaults to UTC |
| `app/services/operation_serializer.rb` | Location payload has no timezone |
| `app/services/reception/console_service.rb` | `format_time` -> `"9:15 AM"` UTC strings |
| `app/services/store_manager/console_service.rb` | `placed_at` -> UTC string |
| `app/services/booking/console_service.rb` | `start_label` / `end_label` UTC strings; UTC day window |
| `app/services/booking/reservation_service.rb` | Parses local input as UTC |
| `app/javascript/controllers/companies/operations/*` | Print server strings / browser-local time |
| Company Stimulus controllers | Mix `timeFormat` (UTC), `toLocale*` (browser), raw ISO |
| `app/javascript/controllers/admin/*` | `timeFormat` default UTC (correct) |

### 3.2 Pain points

- Operations show UTC clocks.
- Operations "today" is the UTC day.
- Booking input is stored as if the entered wall clock were UTC.
- Date-only values shift a day when formatted through a timezone.
- No shared helper, no guard, no documented rule.

---

## 4. Target behavior

### 4.1 Operations

- Reception: arrival, checked-in/out, parcel received, room busy-until, next
  appointment time all use the branch timezone.
- Store Manager: order `placed_at`, audit `generated_at`, current shift hour all
  use the branch timezone; today/yesterday windows are branch days.
- Booking: block labels, needle, selected-day default, and reservation parsing
  use the branch timezone.
- POS: receipt `issued_at` uses the branch timezone.

### 4.2 Company pages

- Every `Helpers.timeFormat(...)` call becomes `Helpers.companyTime(...)`.
- Every `new Date(value).toLocale*String()` becomes `Helpers.companyTime(...)`
  or `Helpers.dateOnly(...)`.
- Calendar/"today"/month defaults use `Helpers.localToday` / `localMonth`.
- Date-only columns use `Helpers.dateOnly`.

### 4.3 Admin

- Time values use `Helpers.utcTime(...)`.
- Screens that could be mistaken for local show a `UTC` label.
- Company timezone renders `UTC+7`, never `plus_7`.

---

## 5. Data and backend contract

```json
{
  "location": { "id": "...", "name": "Downtown", "timezone": "plus_7", "utc_offset": 25200 },
  "placed_at": "2026-11-17T02:15:00Z"
}
```

- `utc_offset` is seconds (same unit as mobile `company.utc_offset`).
- No display strings in any `.json` payload.
- `LocalTime` is the single Ruby conversion point:
  - `LocalTime.offset_seconds(record_or_timezone)`
  - `LocalTime.now(record_or_timezone, at: Time.current)`
  - `LocalTime.today(record_or_timezone, at: Time.current)`
  - `LocalTime.day_range(date, record_or_timezone)`
  - `LocalTime.parse(date, time, record_or_timezone)`

---

## 6. Shared helpers

| Helper | Responsibility |
|---|---|
| `Helpers.utcTime(value, format?)` | Admin display |
| `Helpers.companyTime(value, format?)` | Company/mobile display |
| `Helpers.locationTime(value, format?, location)` | Operation display |
| `Helpers.dateOnly(value, format?)` | Calendar dates |
| `Helpers.datetimeLocalValue(value, location)` | Seed `datetime-local` |
| `Helpers.fromDatetimeLocal(value, location)` | Convert input back to UTC |
| `Helpers.locationNow(location)` | Location-local now |
| `Helpers.localToday(location)` | Location-local `YYYY-MM-DD` |
| `Helpers.localMonth(location)` | Location-local `YYYY-MM` |
| `Helpers.timezoneOffsetHours(value)` | `plus_7` -> 7 |
| `Helpers.timezoneLabel(value)` | `plus_7` -> `UTC+7` |

---

## 7. Implementation steps

### Step 1 — Rule + helpers

1. Add `docs/TIME_DISPLAY.md`.
2. Add the doc-map row and pre-commit bullet in `AGENTS.md`.
3. Update the time paragraph in `README.md`.
4. Add `app/javascript/controllers/helpers/time_helpers.js`.
5. Export it from `controllers/helpers.js`.
6. Update `mobile_helpers.js` defaults.

### Step 2 — Operations backend

1. Add `app/services/local_time.rb`.
2. Add `timezone` / `utc_offset` to `OperationSerializer.location`.
3. Reception: ISO fields, location day, delete `format_time`.
4. Store Manager: ISO `placed_at`, location day.
5. Booking: remove labels, location day default.
6. Reservation: parse in branch timezone.
7. Replace the mobile base controller offset math with `LocalTime`.

### Step 3 — Operations frontend

1. Reception controller formats `arrival_at`, `note_at`, `received_at`,
   `busy_until`, `time_at`.
2. Store Manager formats `placed_at`, `generated_at`, current hour.
3. Booking formats `start_at`/`end_at`, positions blocks and needle in location
   time, defaults the selected day to the location day.
4. POS formats `issued_at`.

### Step 4 — Company + mobile sweep

1. Replace UTC `timeFormat` calls with `companyTime`.
2. Replace `toLocale*` date/time calls with the helper.
3. Replace raw ISO prints.
4. Date-only fields use `dateOnly`.
5. Today/month defaults use `localToday` / `localMonth`.
6. Admin uses `utcTime`; fix the timezone label.

### Step 5 — Inputs and business days

1. `datetime-local` seeds/submits use the helpers.
2. Native form input is parsed by `LocalTime` in the BE.
3. Company-facing day windows use `LocalTime`.

### Step 6 — Guard

1. Add `bin/check_time`.
2. Add it to the AGENTS pre-commit checklist.
3. Re-scan and prove zero banned patterns.

---

## 8. Tests

### Feature specs (primary proof)

- Reception: branch `plus_7`, event `02:00Z` -> shows `09:00`; a UTC-day event at
  `00:30` local is included.
- Store Manager: order created at `02:15Z` -> shows `09:15`; generated-at label
  is branch time.
- Booking: block label and needle are branch time; `14:00` reservation stores
  `07:00Z`.
- Admin: same event shows `02:15` + `UTC`.

### Service specs

- Console payloads expose ISO timestamps, not display strings.
- Day range includes local-day boundary events.
- `LocalTime.parse` returns the correct UTC instant.
- `OperationSerializer.location` includes `utc_offset`.

### Request specs

- Operation JSON includes `location.timezone` and `location.utc_offset`.

---

## 9. Documentation

- `docs/TIME_DISPLAY.md` — the rule.
- `docs/OPERATIONS.md` — location timezone note.
- `docs/MOBILE.md` — company offset contract.
- `AGENTS.md` — doc map + pre-commit.
- `README.md` — helper API.

---

## 10. Verification

```bash
bundle exec parallel_rspec -n 14 spec/features/companies/operations
bundle exec parallel_rspec -n 14 spec/services spec/requests/companies/operations
bin/rubocop
bin/check_colors --strict
bin/check_time
bin/brakeman --no-pager
```

---

## 11. Risks

- Console payload field renames must update every consumer in the same change.
- Fixed-offset timezones ignore DST; that is the current model. An IANA upgrade
  is out of scope.
- Company pages that keep a custom format are still compliant as long as they
  use the helper with the company timezone.

---

## 12. Definition of done

- [ ] Operations show the branch/warehouse clock.
- [ ] Company pages never default to UTC.
- [ ] Admin shows UTC with a label.
- [ ] No raw ISO or `toLocale*` date/time in page controllers.
- [ ] Date-only values do not shift.
- [ ] Feature, service, and request specs are green.
- [ ] `bin/rubocop`, `bin/check_colors --strict`, `bin/check_time`, `bin/brakeman`
      are clean.
- [ ] `docs/TIME_DISPLAY.md` is linked from `AGENTS.md`.
