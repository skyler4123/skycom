# Booking

> **Last audited:** 2026-11-20 · **Audit scope:** browser console, console
> service, reservation/lifecycle services, controller/policies/routes, feature,
> service and request specs.
> **Ship readiness:** 🟢 shippable — the console shows only real data and every
> visible control changes the same booking the inspector shows.
> **Who this is for:** the front-desk host or bookings coordinator.
> **Mobile:** same console, mounted through the Shell-First mobile route.
> **Read first:** [README](README.md) · **Related:** [00-app-overview](00-app-overview.md),
> [04-reception](04-reception.md)

---

## 1. What this page is for

The Booking console is the reservations desk for a branch's bookable spaces. It
shows one day as a timeline of real Facilities, shows where the day is already
busy, and locks a new reservation without allowing a double booking.

"Done" means a host can see the day, open any booking from the timeline, lock a
free room, extend/end/cancel it, and print the day — without leaving the page
and without reading invented numbers.

The domain decision is unchanged: a booking **is** an Event, and the reserved
space is a Facility linked to it. There is no separate reservation table.

---

## 2. Who uses it

**The person:** a front-desk host, bookings coordinator, or office manager.

**Their goal:** answer "is this room free?" and lock it before the customer
changes their mind.

**What they can do here today:**

- See a day timeline of real facilities and their bookings, including bookings
  outside the 08:00–18:00 grid.
- Click a block or an outside-window tag to inspect that booking.
- Move to the previous/next day, jump to today, and filter by the branch's real
  facility categories.
- Lock a reservation with a name, space, optional host, optional customer,
  start and end; an overlap is refused and the conflicting time is named.
- Extend an active booking by 30 minutes, end and release it, or cancel it with
  a confirmation.
- Print the day's run sheet.
- See the next five not-yet-started bookings and cancel one.

**What they must do elsewhere:**

- Check a guest in — Reception console (the page says so; it does not pretend).
- Take a deposit or payment — POS.
- Create a recurring series — not built.
- Change real branch opening hours — not modelled.

**Access:** the Booking operation must be active at the branch and the role must
be allowed by the operation. Customer search is operation-gated (no Customers
dashboard permission needed).

---

## 3. The screen, in words

**Header:** Skycom mark, real branch name, real date, one **Bookings** link, and
the signed-in user. No dead Resource Directory/Room Management/Analytics links,
no "live engine" pill.

**Headline:** "Booking Operations Console", branch + date, and
`N bookings · N spaces in use now`.

**KPI strip:** Bookings today (with `N upcoming · N in progress · N done`),
Spaces in use (`busy / all` + percent), then one card per real facility category
(`in use / total`). A category with no facilities never appears.

**Action bar:** 15-Min Quick Room, Daily run sheet, New Reservation.

**Main column:**

- `Day` view, `Day window 08:00–18:00`, prev/next/Today, and category chips.
- One row per real facility, hour markers, clipped booking blocks, clickable
  outside-window time tags, and a now needle only when "now" is inside the
  window.
- **Spaces by type**: one row per real category with `N in use · N free` and a
  bar. No floor number, zones, pods, or Claim Seat.

**Side column:**

- **Selected booking** inspector: facility/category/capacity, booking name,
  Upcoming / In progress / Done, time range, Host or No host, Customer or No
  customer, attendee count, reference code. Extend/End/Cancel act on this
  booking; guest check-in is explicitly Reception's job.
- **Instant reservation** form: name, space, host, searchable customer,
  start/end, Confirm & Lock Booking.
- **Upcoming check-ins**: next five not-started bookings, each with Cancel.

**Footer:** `Skycom ERP · Booking` and the real company name. No version, no
fallback tenant.

**States**

- No facilities: timeline and form both say the branch has no spaces.
- No bookings: empty timeline rows show "Available all day"; inspector says
  "Select a booking" / "or lock a room with the form"; run sheet says "No
  bookings".
- Outside-window booking: a tag such as `1 booking outside this window · 11:50 PM`.
- Capped list: "Showing the first 200 bookings for this day." and "Showing the
  first 100." under the space/host pickers.
- Load failure: full-screen red "Failed to load the booking console."

---

## 4. Control inventory

26 interactive controls remain. Old IDs are kept; removed controls stay in the
table struck through so earlier decisions remain readable.

| ID | Area | Control | What it does now | Status |
|---|---|---|---|---|
| BKG-01 | Header | Bookings | One real link to the current console; no dead nav items | ✅ |
| BKG-02 | Header | ~~Resource Directory~~ | Removed; no real page | ~~⛔~~ |
| BKG-03 | Header | ~~Room Management~~ | Removed; no real page | ~~⛔~~ |
| BKG-04 | Header | ~~Analytics & Usage~~ | Removed; no real page | ~~⛔~~ |
| BKG-05 | Action bar | 15-Min Quick Room | Fills a 15-minute range, focuses the name, does not create | ✅ |
| BKG-06 | Action bar | ~~Release Unused~~ | Removed; released nothing | ~~🗑️~~ |
| BKG-07 | Action bar | Daily run sheet | Opens browser print of the day only | ✅ |
| BKG-08 | Action bar | New Reservation | Scrolls to the form and focuses the name | ✅ |
| BKG-09 | View | Day | Static indicator; no dead Room List/Desk Zones tabs | ✅ |
| BKG-10 | View | ~~Room List~~ | Removed; view does not exist | ~~⛔~~ |
| BKG-11 | View | ~~Desk Zones~~ | Removed; view does not exist | ~~⛔~~ |
| BKG-12 | Date nav | Previous day | Loads the previous day | ✅ |
| BKG-13 | Date nav | Next day | Loads the next day | ✅ |
| BKG-14 | Date nav | Today | Returns to the branch's today | ✅ |
| BKG-15 | Filters | Category chips | Filters timeline rows by real facility category | ✅ |
| BKG-16 | Timeline | Booking block | Selects that booking in the inspector | ✅ |
| BKG-17 | Floor map | ~~Claim Seat~~ | Floor map replaced by **Spaces by type** | ~~🗑️~~ |
| BKG-18 | Inspector | Extend +30m | Moves the selected booking's end by 30 minutes, or names the next booking | ✅ |
| BKG-19 | Inspector | End & release | Marks the selected booking done, ends it at now when in progress, frees the space | ✅ |
| BKG-20 | Inspector | ~~Check-In Room~~ | Removed; check-in is Reception's job | ~~🗑️~~ |
| BKG-21 | Inspector | ~~Ring Organizer~~ | Removed; calling is not this page | ~~🗑️~~ |
| BKG-22 | Reservation | Meeting / event name | Required text | ✅ |
| BKG-23 | Reservation | Space | Required select of real branch facilities, name + category | ✅ |
| BKG-24 | Reservation | Host | Optional dropdown of real branch employees; placeholder No host | ✅ |
| BKG-25 | Reservation | Start time | Required wall-clock time | ✅ |
| BKG-26 | Reservation | End time | Required; must be after start | ✅ |
| BKG-27 | Reservation | ~~10-Min No-Show Release~~ | Removed; nothing released the room | ~~⛔~~ |
| BKG-28 | Reservation | Confirm & Lock Booking | Creates a conflict-checked Event + facility/host/customer links | ✅ |
| BKG-29 | Upcoming | ~~Check In Now~~ | Removed; no fake check-in | ~~🗑️~~ |
| BKG-30 | Upcoming | Cancel | Opens the same Cancel this booking? confirmation | ✅ |
| BKG-31 | Inspector | Cancel booking | Opens Cancel this booking? | ✅ |
| BKG-32 | Inspector | Keep | Closes the cancel confirmation without changing anything | ✅ |
| BKG-33 | Inspector | Cancel booking (confirm) | Cancels the booking and frees the time | ✅ |
| BKG-34 | Reservation | Customer search | Typeahead over company customers; optional | ✅ |
| BKG-35 | Reservation | Clear customer | Removes the selected customer | ✅ |
| BKG-36 | Timeline | Outside-window tag | Selects a booking that falls entirely outside 08:00–18:00 | ✅ |
| BKG-37 | Upcoming | Keep / Cancel booking (confirm) | Same confirmation as the inspector | ✅ |

**Status count:** ✅ 26 · 🟡 0 · 🗑️ 0 · ⛔ 0 · 🔢 0.

---

## 5. Numbers on screen

| Claim on screen | Where it comes from | Verdict |
|---|---|---|
| Bookings today | Non-cancelled Events whose time touches the selected day (`start_at < day_end AND end_at > day_start`) | ✅ |
| `N upcoming · N in progress · N done` | `Booking::Status` over all day bookings, using the server `now` | ✅ |
| Spaces in use `busy / all` | Facilities linked to a non-completed booking in progress at `now` ÷ all branch facilities | ✅ |
| Category cards | Real `facilities.category` totals and the same busy facilities | ✅ |
| Spaces by type rows | Same category totals; `in use` + `free` = total | ✅ |
| Summary chip | Same booking and space counts | ✅ |
| Outside-window tags | Real booking start times outside the 08:00–18:00 window | ✅ |
| Host / Customer / Attendees | Real `EmployeeEventAppointment` / `CustomerEventAppointment` links | ✅ |
| Reference | Event `code`; `—` when absent, never a raw UUID | ✅ |
| 08:00–18:00 | Fixed stand-in window, labelled; branch hours are not modelled | 🟡 |
| Cap notices | `{ capped, limit }` from the server; counts remain full-data counts | ✅ |

No equipment/hot-desk classification, no floor/zone map, no invented tenant or
version.

---

## 6. Gaps by user job

### Resolved in this pass

- **G1 "Is this room actually free?"** — overlapping bookings are refused with
  the facility and conflicting time; the facility row is locked during the check.
- **G2 "Let me look at that booking."** — clicking a block/tag selects that
  booking; selection survives background clicks.
- **G3 "Release/move this booking."** — Extend +30m, End & release, and Cancel
  work from the inspector. Guest check-in remains Reception's job.
- **G4 "No-show release."** — decorative checkbox removed; automatic release is
  not claimed.
- **G5 "Put the client on the booking."** — customer typeahead at creation.
- **G6 "The host field didn't stick."** — host is a real employee dropdown.
- **G7 "Cancel or move."** — cancel/end/extend work; drag reschedule is not built.
- **G8 "What does the floor map show?"** — replaced with real category occupancy.
- **G9 "Which are equipment?"** — no name-based classification.
- **G10 "We open at 7."** — fixed window is labelled; real hours remain a gap.
- **G11 "Print the run sheet."** — browser print of the day.
- **G14 "More than 100 facilities."** — caps are labelled.

### Still future

- **G12 "Take a deposit."** — deposit/payment at booking is not built.
- **G13 "Book every Tuesday."** — recurrence is not built.
- Automatic no-show release.
- Drag-to-reschedule.
- Room List / Desk Zones as separate screens.

---

## 7. Decisions (resolved)

| Decision | Resolution |
|---|---|
| BKG-D1 Conflict detection | **Block** overlapping console reservations; back-to-back allowed. |
| BKG-D2 Inspector | **Click-to-select** block/tag; no modal. |
| BKG-D3 Check-in vs release | Release/end lives here; guest check-in stays in Reception. |
| BKG-D4 Header links | **Remove** the dead links; one real Bookings item. |
| BKG-D5 Floor map | **Remove** invented zones; show **Spaces by type** from real categories. |
| BKG-D6 Equipment/hot-desk KPIs | **Drop** both; use real category cards. |
| BKG-D7 Customer on reservation | **Add** a searchable customer picker. |
| BKG-D8 Host field | **Dropdown** of real branch employees. |
| BKG-D9 No-show | **Remove** the checkbox; automatic release is future work. |
| BKG-D10 Recurrence | **Out of scope** for this pass. |
| BKG-D11 Pills/footer | **Remove** live pills; footer names Booking and the real company. |

---

## 8. Safe demo path

1. Open **Operations → Booking** for a branch with three facilities and one
   booking tonight.
2. Show the header, KPI strip, category cards, and **Spaces by type** — no dead
   links, no Floor 4.
3. Point at the evening booking: it is an outside-window tag, not "Available all
   day". Click it; the inspector shows that booking.
4. Try a second booking over the same time; it is refused with the conflicting
   facility and time.
5. Use **15-Min Quick Room**, pick a host and customer, submit; the new booking
   appears and the inspector shows both names.
6. **Extend +30m**, **End & release**, and **Cancel booking** on another
   reservation; the freed time can be booked again.
7. **Daily run sheet** prints only the day.
8. Show the KPI cards using booking/facility/category counts only.

**Do not demo:** recurrence, deposits, real opening hours, automatic no-show
release, drag rescheduling, or Room List/Desk Zones — they are explicitly out of
this pass.

---

## 9. Engineering appendix

**Routes**

- `GET /companies/:company_id/operations/booking/:operation_id`
- `GET …/booking/:operation_id/customers`
- `POST …/booking/:operation_id/reservations`
- `POST …/booking/:operation_id/reservations/:reservation_id/extend`
- `POST …/booking/:operation_id/reservations/:reservation_id/end`
- `POST …/booking/:operation_id/reservations/:reservation_id/cancel`

**Backend:** `Companies::Operations::BookingController`; `Booking::ConsoleService`,
`Booking::Status`, `Booking::ConflictChecker`, `Booking::ReservationService`,
`Booking::ExtendService`, `Booking::FinishService`, `Booking::CancelService`,
`Booking::CustomerSearchService`.

**Frontend:** `app/javascript/controllers/companies/operations/booking/show_controller.js`
(`Companies_Operations_Booking_ShowController`).

**Payload:** `booking` = `{ date, now, timeline, resources, bookings, upcoming,
counts, caps }`; `reference` = `{ hosts, facilities, caps }`; top-level
`company` = `{ id, name }`. Errors are `{ errors: [...] }` with
`:unprocessable_content`.

**Conflict rule:** same company + same facility + non-cancelled + non-completed;
`existing.start_at < new_end AND existing.end_at > new_start`; excludes the
event being extended; facility row locked inside the transaction.

**Proof:** `spec/features/companies/operations/booking_spec.rb` (23 feature
examples), `spec/features/mobile/booking_spec.rb` (4),
`spec/services/booking/*_spec.rb` (24 service examples),
`spec/requests/companies/operations/booking_spec.rb` (5 request examples).
Lint/colors/time/env/security guards run with the suite.
