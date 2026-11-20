# Booking Console — Shippable Implementation Plan

> Executed inline on branch `dev-4` per `AGENTS.md`. No worktree, no subagents.

**Goal:** Turn the Booking console into a real front-desk surface: real chrome,
real counts, a clickable inspector, conflict-safe locking, real host/customer,
working extend/end/cancel, a printable run sheet, and labelled caps.

**Architecture:** Keep the existing single Stimulus controller and full-screen
layout. Move truth to `Booking::ConsoleService` and small `Booking::*` services;
the browser renders the payload and refreshes timeline/inspector regions instead
of re-rendering over a typed form. Overlap safety uses a Postgres row lock on the
facility plus an overlap query inside the transaction.

**Tech stack:** Rails 8, PostgreSQL, Stimulus, Tailwind, Meilisearch, RSpec.

**Spec:** `docs/business_analysis/03-booking.md` + the BA review (2026-11-20).

## Global Constraints

- Work inline on the current branch. No worktree, no subagents.
- Feature specs are the primary proof; service specs second; request specs third.
- All JSON failures use `{ errors: [...] }` and `:unprocessable_content`.
- Times on the wire are UTC ISO 8601; display uses `Helpers.locationTime` /
  `Helpers.dateOnly`.
- Semantic Tailwind tokens only. No raw palette classes.
- Every new user-facing string has a `dictionary.js` entry with Vietnamese.
- No new JS dependencies. Use `Helpers.form()`, `fetchJson()`, `tooltip()`.
- No model callbacks or migrations.
- Conflict blocking is console-only; Events CRUD remains warn-but-allow.

## Tasks

### Task 1: Backend payload and status
- [x] Add `Booking::Status` (`cancelled` / `done` / `in_progress` / `upcoming`).
- [x] Rewrite `Booking::ConsoleService`: touching-day query, real categories,
  busy facilities, full counts, next-five upcoming, caps, server `now`.
- [x] Add `BOOKING_DAY_BOOKING_LIMIT`, `BOOKING_FACILITY_LIMIT`,
  `BOOKING_HOST_LIMIT`.
- [x] Controller payload: real company, reference caps.

### Task 2: Conflict-safe reservation with real host/customer
- [x] Add `Booking::ConflictChecker` (non-cancelled, non-completed, strict overlap).
- [x] Lock facility row inside create transaction; re-check overlap.
- [x] Accept `host_id` / `customer_id`; remove free-text host matching.
- [x] Named conflict error: `Facility … is already booked …`.

### Task 3: Extend / end / cancel
- [x] Add `Booking::ExtendService` (+30m, next-booking conflict message).
- [x] Add `Booking::FinishService` (done; end=now in progress; stock release).
- [x] Add `Booking::CancelService` (cancelled; frees the time; stock release).
- [x] Add routes/actions/policy gates.

### Task 4: Customer search
- [x] Add `Booking::CustomerSearchService` (Meilisearch, company filter, limit 10).
- [x] Add `GET …/booking/:operation_id/customers`.

### Task 5: Frontend shell and real data
- [x] Remove dead chrome/pills/footer/floor/no-show/Room List/Desk Zones.
- [x] Real KPIs, category cards, Spaces by type, cap notices.
- [x] Add dictionary entries and URL helpers.

### Task 6: Timeline, inspector, outside tags, needle
- [x] Clipped blocks, outside-window tags, conditional now needle.
- [x] Click-to-select, selected outline, selection survives background clicks.
- [x] Empty inspector and real booking inspector fields.

### Task 7: Reservation form
- [x] `Helpers.form()` with `novalidate` + client validation.
- [x] Space/host selects; customer typeahead + clear.
- [x] Inline conflict/time error; preserve typed values; clear on facility/time.
- [x] Create success selects the new booking and resets the form.

### Task 8: Quick Room
- [x] Next quarter-hour +15; focus name; clears space/host/customer.
- [x] 08:00 fallback + note outside the window; never creates by itself.

### Task 9: Extend / end / cancel / upcoming
- [x] Inspector actions act on the selected booking.
- [x] Inline cancel confirmation (Keep / Cancel booking).
- [x] Upcoming list next five with Cancel only.
- [x] Guest check-in line; removed check-in/ring controls.

### Task 10: Run sheet and caps
- [x] Hidden print root, day-only table, empty "No bookings", print invocation.
- [x] Cap lines under timeline/space/host; full-data counts.

### Task 11: Docs and full verification
- [x] Update `docs/OPERATIONS.md`, `docs/EVENTS.md`, `docs/MOBILE*.md`,
  `docs/business_analysis/*`, BE/FE headers.
- [x] Feature → service → request specs; rubocop, colors, time, env, brakeman.

## Definition of Done
- [x] Every visible control works with real data; no dead links or fabricated panels.
- [x] Overlap refused, back-to-back allowed, cancelled/completed free the slot.
- [x] Host/customer are real records; inspector shows them and attendee count.
- [x] Extend/end/cancel/quick-room/run-sheet/caps work.
- [x] Feature specs green, then service specs, then request specs.
- [x] Lint/colors/time/env/security clean.
- [x] Docs updated.
