# Time Display & Timezone Rule

> One clock on the wire, one clock on screen.

All time data is stored, transported, and compared in **UTC**. The browser never
decides the timezone. Every displayed time is converted by the shared time
helper using the timezone that owns the record.

---

## 1. The contract

| Layer | Clock | Format |
|---|---|---|
| Database | UTC | `datetime` columns |
| API / JSON / jobs / services | UTC | ISO 8601 with `Z` or `+00:00` |
| Operation pages | Branch / Warehouse local | time helper |
| Company pages | Company local | time helper |
| Mobile pages | Company local | time helper |
| Admin pages | UTC | time helper (`utcTime`) |

- "UTC" governs storage, transport, and comparison. It does **not** govern
  calendars: a business day is the local day of the owning location.
- "Local" always means the tenant or location timezone. Never the browser.
- One screen, one clock. Never mix local and UTC values on the same page.
- If a page could be read as local while showing UTC (admin), label it `UTC`.

---

## 2. Ownership: which timezone applies

| Surface | Timezone |
|---|---|
| Reception, POS, Booking, Store Manager, Inventory | The operation appointment's Branch or Warehouse |
| Attendance, payroll, orders, invoices, imports, events, exams, dashboards, tickets, discounts, stocks | Company |
| Mobile screens | Company (`company.utc_offset`) |
| Admin | UTC |

- `Branch` inherits the `Company` timezone on create; `Warehouse` has its own
  `timezone`.
- Fallback when a timezone is missing: UTC. Never fall back to the browser.
- Never render a raw enum key (`plus_7`); render `UTC+7` through
  `Helpers.timezoneLabel(...)`.

### Operation pages specifically

An operation console belongs to one physical location. The timezone comes from
that location, not from the company and not from the viewer:

- Branch operation → `appointment.branch.timezone`
- Warehouse operation → `appointment.warehouse.timezone`
- `OperationSerializer.location` ships `{ id, name, timezone, utc_offset }` so
  the frontend never guesses.

The reception desk, the POS receipt, the booking timeline, the store manager
"today", and the inventory console all use that location clock.

---

## 3. Backend rules (UTC only)

1. **Store UTC.** Never write a local wall-clock value into a datetime column.
2. **Return UTC ISO, never display strings.**
   - Good: `{ "placed_at": "2026-11-17T02:15:00Z" }`
   - Bad: `{ "placed_at": "9:15 AM" }`
   - Do not use `strftime("%-I:%M %p")`, `to_fs`, or `l(...)` in API payloads.
   - Do not add `*_label`, `*_time`, or `*_at_formatted` fields.
3. **Parse wall-clock input in the owning timezone, then store UTC.**
   - `datetime-local`, `date`, and `time` values arrive without a zone.
   - `Time.zone.parse("#{date} #{time}")` assumes UTC — do not use it for tenant
     input. Use `LocalTime.parse(date, time, location)`.
4. **Compute day and period windows in the owning timezone, query UTC.**
   - `LocalTime.now(location)` returns "now" at that location's offset.
   - `LocalTime.day_range(date, location)` returns the UTC range for that local
     calendar day.
   - "Today", "yesterday", "this month", payroll periods, attendance days, and
     KPI ranges all follow this rule.
5. **Expose the timezone with the data.**
   - Operation payloads: `location.timezone` (enum key) and
     `location.utc_offset` (seconds).
   - Mobile payloads: `company.utc_offset` (seconds).
   - Client cache: company and branch `timezone`.
6. **Admin endpoints stay UTC end-to-end.**

---

## 4. Frontend rules

1. **Every displayed time goes through the time helper.** No exceptions.
   Banned:
   - `new Date(value).toLocaleString()`
   - `toLocaleDateString()` / `toLocaleTimeString()`
   - raw ISO strings in template literals
   - `toISOString().slice(0, 10 | 7 | 16)` for display or "today"
2. **Use the scoped helper:**
   - `Helpers.utcTime(value, format?)` — admin.
   - `Helpers.companyTime(value, format?)` — company and mobile pages.
   - `Helpers.locationTime(value, format?, location)` — operation pages; pass
     the appointment location.
   - `Helpers.dateOnly(value, format?)` — calendar dates.
   - `Helpers.timeOnly(value, format?)` — `time` columns (wall clock, no zone).
   - `Helpers.timezoneLabel(value)` — `plus_7` → `UTC+7`.
3. **Pass the timezone explicitly.** A page must never rely on
   `dayjs.tz.guess()` or `Intl` defaults.
4. **Date-only values are calendar dates, not instants.** `work_date`,
   `attendance_date`, `due_date`, `expiration_date`, `period_start`,
   `period_end`, `disbursement_date` must render with `dateOnly` and must never
   be timezone-converted. Converting them shifts the day.
5. **"Now" and "today" on a location page are location-local.**
   Use `Helpers.locationNow(location)` / `Helpers.localToday(location)`, not
   `new Date()` or `new Date().toISOString()`.
6. **`datetime-local` / `time` inputs show the owning location's wall clock.**
   Seed with `Helpers.datetimeLocalValue(value, location)`; convert back to UTC
   on submit with `Helpers.fromDatetimeLocal(value, location)`. Native form
   posts that send date/time parts are converted by the BE.
7. **Empty, null, or invalid values render `—`.** The helper owns that.
8. **Format strings belong to the helper.** New screens use the defaults:
   - timestamp `DD MMM YYYY, HH:mm`
   - date `DD MMM YYYY`
   - time `HH:mm`
   - month `MMMM YYYY`

   A screen may keep an established format until it is touched, but the
   timezone argument is mandatory. Mobile keeps `hh:mm A` through
   `mobile_helpers.js`.

---

## 5. Operation pages — exact contract

- `OperationSerializer.location` returns
  `{ id, name, timezone, utc_offset }`.
- Console services return ISO timestamps only: `arrival_at`, `start_at`,
  `end_at`, `placed_at`, `received_at`, `generated_at`, `busy_until`,
  `note_at`, `issued_at`, …
- Console services do **not** format times. `format_time`,
  `strftime("%-I:%M %p")`, `start_label`, `end_label`, and `placed_at: "9:15 AM"`
  are removed.
- The Stimulus console formats with
  `Helpers.locationTime(value, format, appointment.location)`.
- Booking reservation parses `date + start_time` in the branch timezone and
  stores UTC.
- "Today" on every console is the location's calendar day.

---

## 6. Anti-patterns

| Anti-pattern | Why it is wrong |
|---|---|
| `new Date(value).toLocaleString()` | Uses the browser timezone. |
| `Helpers.timeFormat(value)` in a page | Defaults to UTC. |
| `placed_at: order.created_at.strftime("%-I:%M %p")` | Display string, UTC, in the API. |
| `Time.zone.parse("#{date} #{time}")` | Treats local input as UTC. |
| `now.beginning_of_day` on a branch console | UTC day, not location day. |
| `timeFormat("2026-11-17", "MMM D")` | Shifts a date-only value a day. |
| `c.timezone > 0` | The enum key is a string (`plus_7`). |
| Mixing `timeFormat` and `toLocaleString` on one page | Two clocks on one screen. |

---

## 7. Enforcement

- `bin/check_time` fails on banned display patterns in
  `app/javascript/controllers` (outside `helpers/`).
- `bin/check_time` fails on direct `Helpers.timeFormat(` calls in page
  controllers; pages use the scoped helpers.
- `bin/check_time` fails on UTC date slices (`toISOString().slice(0, 7|10|19)`)
  and `getUTC*` date parts.
- `datetime-local` seeding in legacy native forms is still being migrated; it
  must use `Helpers.datetimeLocalValue` and a matching backend conversion. See
  `docs/plans/2026-11-17-time-display-utc.md` Step 5.
- Feature specs for time-sensitive screens must set a non-zero location
  timezone and assert the rendered local clock, for example:
  branch `plus_7`, event `02:00Z`, reception shows `9:00 AM`.
- Admin feature specs assert UTC and the `UTC` label.
- The pre-commit checklist and the doc map both point here.

---

## 8. Why this exists

Before this rule the codebase had three clocks on the same screen: helpers that
defaulted to UTC, `toLocaleString()` that used the browser, and console services
that formatted UTC strings on the server. A receptionist in UTC+7 saw 02:00 for
a 09:00 appointment, and the "today" list was the UTC day.

The rule keeps the wire honest (UTC everywhere) and puts the one conversion
where it belongs: the display layer, using the location that owns the record.
