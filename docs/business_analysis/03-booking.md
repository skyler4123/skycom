# Booking

> **Last audited:** 2026-11-19 · **Audit scope:** frontend controller, console
> service, reservation service, backend controller, feature and service specs.
> No live browser run.
> **Ship readiness:** 🔴 not shippable — four dead header links, three dead view
> tabs, a floor map with invented zones, and a reservation flow that does not
> check whether the space is already booked.
> **Who this is for:** the front-desk host or bookings coordinator.
> **Mobile:** same console, mounted through the Hotwire shell.
> **Read first:** [README](README.md) · **Related:** [00-app-overview](00-app-overview.md),
> [04-reception](04-reception.md)

---

## 1. What this page is for

The Booking console is the reservations desk for a branch's bookable spaces:
meeting rooms, studios, event halls, hot desks, and equipment. It shows one day
as a timeline of resources, lets the host see what is in use right now, and
takes a new reservation in seconds.

"Done" means a reservation is created for the right space at the right time, and
the host can see the day at a glance.

The console is designed around a simple domain decision: a booking **is** an
Event, and the reserved space is a Facility linked to it. There is no separate
reservation table. That choice is sound and worth keeping.

---

## 2. Who uses it

**The person:** a front-desk host, bookings coordinator, or office manager.

**Their goal:** answer "is this room free?" and lock it down before the customer
changes their mind.

**What they can do here today:**

- See a day timeline of resources and their bookings.
- Move to the previous or next day, or jump back to today.
- Filter resources by group.
- Read the selected/first booking's details.
- Create a reservation (title, space, host, start, end).
- See the next five check-ins.

**What they must do elsewhere:**

- Check a guest in — Reception console.
- Extend or release a booking — the Events module.
- Cancel or edit a reservation — the Events module.
- Take a deposit or payment — POS.
- Add attendees or a customer to the booking — Events module.
- Print a run sheet — nothing exists.

**Access:** the Booking operation must be active at the branch and the role must
be allowed by the operation.

---

## 3. The screen, in words

**Header:** Skycom mark, branch name, the date, a four-item nav (Bookings &
Calendar, Resource Directory, Room Management, Analytics & Usage), a "Live
Scheduling Engine" pill, and the user.

**Headline:** the same live pill, branch and date, the title "Booking Operations
Console", and a summary chip "N bookings · N spaces in use".

**KPI strip:** Total Bookings Today, Room Utilization, Equipment Deployed, Hot
Desk Occupancy.

**Action bar:** 15-Min Quick Room, Release Unused, Daily Run Sheet, New
Reservation.

**Main column:**

- View switcher (Day Timeline Grid, Room List, Desk Zones), date navigation
  (previous / date / next / Today), and resource filter chips.
- The day timeline: one row per resource, hour markers, booking blocks, an "now"
  needle, and an "Unassigned bookings" row.
- A floor map card titled "Floor 4 Agile Zoning & Hot Desking" with Zone A, Zone
  B, and a micro-pods grid.

**Side column:**

- Selected Room Inspector: booking details and six action buttons.
- Instant Reservation form.
- Upcoming Check-Ins with two buttons per row.

**Footer:** "Skycom ERP Booking & Reservations • Reception Console v4.8", tenant,
and a copyright line.

**States**

- *No facilities:* "No facilities are configured for this branch yet…"
- *Resource free all day:* a dashed "Available all day" band.
- *No bookings:* the inspector shows "Idle" and asks the user to select a
  booking.
- *No upcoming check-ins:* "No pending check-ins for this day."
- *Load failure:* a full-screen red "Failed to load the booking console."
- *Responsive:* timeline scrolls horizontally; side column stacks under the main
  column.

---

## 4. Control inventory

30 interactive controls.

| ID | Area | Control | What it does today | Status | If shipped as-is |
|---|---|---|---|---|---|
| BKG-01 | Header | Bookings & Calendar | `href="#"` — jumps to the top of the page | ⛔ | Appears to be navigation; is a no-op |
| BKG-02 | Header | Resource Directory | `href="#"` | ⛔ | Same |
| BKG-03 | Header | Room Management | `href="#"` | ⛔ | Same |
| BKG-04 | Header | Analytics & Usage | `href="#"` | ⛔ | Same |
| BKG-05 | Action bar | 15-Min Quick Room | Scrolls to the form; does not set 15 minutes | 🟡 | Label promises a one-tap booking; it is a scroll |
| BKG-06 | Action bar | Release Unused | Scrolls to the form | 🟡 | Implies releasing rooms; releases nothing |
| BKG-07 | Action bar | Daily Run Sheet | Scrolls to the form | 🟡 | Implies a document; there is none |
| BKG-08 | Action bar | New Reservation | Scrolls to and focuses the form | ✅ | — |
| BKG-09 | View switcher | Day Timeline Grid | Already active; does nothing | ✅ | — |
| BKG-10 | View switcher | Room List | Nothing at all | ⛔ | Second view does not exist |
| BKG-11 | View switcher | Desk Zones | Nothing at all | ⛔ | Third view does not exist |
| BKG-12 | Date nav | Previous day | Reloads the previous day | ✅ | — |
| BKG-13 | Date nav | Next day | Reloads the next day | ✅ | — |
| BKG-14 | Date nav | Today | Returns to today | ✅ | — |
| BKG-15 | Filters | Resource group chips | Filters the timeline rows | ✅ | — |
| BKG-16 | Timeline | Booking block | Looks clickable; no handler | 🟡 | The inspector cannot be driven by clicking a booking |
| BKG-17 | Floor map | Claim Seat | Scrolls to the form | 🟡 | Does not preselect the zone or seat |
| BKG-18 | Inspector | Extend +30m | Toast: "Extend the booking from the Events module." | 🗑️ | Core desk action is not here |
| BKG-19 | Inspector | End & Release | Toast: "Release the booking from the Events module." | 🗑️ | Same |
| BKG-20 | Inspector | Check-In Room | Toast: "Check-in is managed from the Reception console." | 🗑️ | Sends the host to another console |
| BKG-21 | Inspector | Ring Organizer | Toast: "Call the organiser from the employee directory." | 🗑️ | No call, no link |
| BKG-22 | Reservation | Meeting / Event Name | Required text | ✅ | — |
| BKG-23 | Reservation | Select Space | Facility dropdown | ✅ | — |
| BKG-24 | Reservation | Host / Dept | Free text; matched to an employee by exact name | 🟡 | A typo silently creates a booking with no host |
| BKG-25 | Reservation | Start time | Time input, default 10:30 | ✅ | — |
| BKG-26 | Reservation | End time | Time input, default 11:30 | ✅ | — |
| BKG-27 | Reservation | 10-Min No-Show Release | Checkbox, not submitted with the form | ⛔ | Promises automatic release; nothing happens |
| BKG-28 | Reservation | Confirm & Lock Booking | Creates the Event + facility link | ✅ | No conflict check (see §6) |
| BKG-29 | Upcoming | Check In Now | Toast: "Check-in is managed from the Reception console." | 🗑️ | — |
| BKG-30 | Upcoming | Release Room | Toast: "Release the booking from the Events module." | 🗑️ | — |

**Count by status:** ✅ 11 · 🟡 6 · 🗑️ 6 · ⛔ 7.

---

## 5. Numbers on screen

| Claim on screen | What it appears to mean | Where it actually comes from | Verdict |
|---|---|---|---|
| Total Bookings Today | Bookings for the day | Events linked to the branch for the selected day, excluding cancelled | ✅ capped at 200 |
| Unit label "Confirmed" | All bookings are confirmed | Includes upcoming, active, and completed | 🟡 label is narrower than the count |
| N pending check-in | Guests waiting to arrive | Bookings whose status is "upcoming" | ✅ counts bookings, not people |
| Room Utilization % | Share of spaces in use | Busy resources ÷ all resources, where busy is time-derived | ✅ |
| Equipment Deployed / Total | Devices in use vs owned | Facilities whose name or category matches a device keyword pattern | 🟡 heuristic classification, not a real type |
| Hot Desk Occupancy | Desks in use | Facilities whose name matches desk/pod/booth/focus | 🟡 same heuristic |
| "Floor 4 Agile Zoning & Hot Desking" | This branch's floor | Hardcoded title | 🔢 the branch may have no floor 4 |
| "Zone A (East Wing)" / "Zone B (Quiet Hub)" | Real zones | Zone A shows the occupied count, Zone B shows the free count; descriptions are hardcoded | 🔢 invented zones |
| Micro-Pods grid | Pod occupancy | The first eight resources of **any** type, labelled pod codes | 🔢 mislabelled; includes rooms and equipment |
| "N% Full" per zone | Zone occupancy | Derived from the invented split | 🔢 |
| Booking status (Active / Confirmed / Done) | Lifecycle state | Event workflow status, else derived from start/end vs now | ✅ |
| Attendees | People in the booking | Customer links + employee links on the Event | ✅ console-created bookings always show 0 |
| Organiser | Who booked it | First employee link, else first customer, else "—" | ✅ |
| "Live Scheduling Engine" (×2) | A live engine is running | Static pill | 🔢 |
| "Synced with live Event reservations" | Fresh sync | Static text | 🔢 |
| Footer "Reception Console v4.8" | This is the booking console | Copy-paste from the reception design | 🔢 says the wrong console name |
| Tenant fallback "Skycom Enterprise Corp" | The company | Fallback when the operation payload has no company | 🔢 invents a tenant |
| Timeline 08:00–18:00 | The branch's opening hours | Fixed constants | 🟡 branch hours are not modelled |

---

## 6. Gaps by user job

### G1 — "Is this room actually free?"
**The most serious gap.** Creating a reservation does not check for an existing
booking of the same facility at an overlapping time. Two hosts can book the same
room for the same hour, and the timeline will show both blocks on top of each
other.

- Smallest real version: reject an overlapping event for the same facility (M).
- Full version: suggest the nearest free slot (M).

### G2 — "Let me look at that booking."
Booking blocks have no event handler. The inspector always shows the
currently-active booking, or the first of the day — never the one the host
clicked. The instruction "Select a booking block to inspect" is false.

- Smallest real version: wire the click to the inspector (S).

### G3 — "Check this guest in."
Check-in, end, release, extend, and call are all toasts that point at other
modules — and the Reception console's check-in flow is for visitor Events, not
necessarily this booking.

- Smallest real version: mark the booking active/completed from the inspector (M).
- Full version: arrival state, no-show, and release automation (M).

### G4 — "Release the room after ten minutes."
The no-show checkbox is decorative: it has no name, is not read on submit, and no
job or service acts on it.

- Smallest real version: remove the checkbox (S).
- Full version: a scheduled no-show release (M).

### G5 — "Put the client and their guests on the booking."
The form creates an Event with a space and an optional host. There is no
customer, no attendee count, and no contact — so the inspector's Attendees shows
0 for every console-created booking.

- Smallest real version: add a customer picker (M).
- Full version: attendees and invitations (L).

### G6 — "The host field didn't stick."
The host is free text matched to an employee by exact name. Any typo, nickname,
or department string creates the booking with no host.

- Smallest real version: replace the text input with the existing host list (S).

### G7 — "Cancel or move this booking."
There is no cancel or edit path from the console; both send the host to Events.

- Smallest real version: cancel from the inspector (M).
- Full version: drag/reschedule on the timeline (L).

### G8 — "What does this floor map show?"
The floor map is invented: a hardcoded floor number, two fabricated zones, and a
grid that shows the first eight resources of any kind as "pods". Only the
occupied/free totals are real.

- Smallest real version: remove the zone cards and keep the real totals (S).
- Better: group resources by their actual category and show per-group occupancy (M).

### G9 — "Which of these are equipment?"
Equipment and hot desks are inferred from words in the facility name or
category. A room called "Boardroom with screen" counts as equipment.

- Smallest real version: require a facility type/category and read it (M).
- Alternative: drop the two KPIs (S).

### G10 — "We open at 7, not 8."
The timeline is fixed to 08:00–18:00 and does not read branch hours, which are
not modelled yet.

- Smallest real version: accept the fixed window and label it (S).
- Full version: branch opening hours (M).

### G11 — "Print the day's run sheet."
There is no printable sheet for the front desk.

- Smallest real version: browser print of the timeline (S).
- Better: a formatted run sheet (M).

### G12 — "Take a deposit."
No payment or deposit is attached to a reservation.

- Full version: deposit at booking through the payment domain (L).

### G13 — "Book every Tuesday for three months."
Only single reservations are supported; there is no recurrence.

- Full version: recurring bookings (L).

### G14 — "I have more than 100 facilities."
Facilities and reference lists are capped at 100, events at 200, with no notice.

- Smallest real version: show the cap (S).

---

## 7. Decisions for the BA

**BKG-D1 — Conflict detection before release?**
- A. Ship without it and rely on staff discipline. Risk: double bookings, angry
  customers, and a timeline that lies.
- B. Block overlapping bookings per facility. Effort M.
- *Recommendation:* B. This is the one gap that makes the console unsafe to run a
  real front desk on.

**BKG-D2 — Does the inspector become clickable?**
- A. Wire block clicks to the inspector. Effort S.
- B. Remove the inspector and show booking details in a modal. Effort M.
- *Recommendation:* A.

**BKG-D3 — Where do check-in and release live?**
- A. Keep them in Reception, remove the toasts from Booking. Effort S.
- B. Implement active/completed transitions here. Effort M.
- *Recommendation:* B for release, A for guest check-in — a host closing a room
  should not leave the console, but a visitor check-in belongs to Reception.

**BKG-D4 — What happens to the four header links?**
- A. Remove them. Effort S.
- B. Point them at real pages (resources, facilities, calendar, analytics).
  Effort S–M.
- *Recommendation:* B is cheap because those pages exist; A is acceptable if the
  links are not part of the story.

**BKG-D5 — The floor map: keep, fix, or remove?**
- A. Remove the zone cards, keep real totals. Effort S.
- B. Build zones from facility categories. Effort M.
- *Recommendation:* B if the product is sold to coworking/office customers; A
  otherwise. Never keep the invented version.

**BKG-D6 — What replaces the equipment and hot-desk heuristics?**
- A. Drop both KPIs. Effort S.
- B. Add a facility type and compute from it. Effort M.
- *Recommendation:* B. "How many desks are free?" is a real front-desk question.

**BKG-D7 — Does the reservation form take a customer?**
- A. No; add attendees later in Events. Effort S.
- B. Customer picker at creation. Effort M.
- *Recommendation:* B — otherwise the booking has no one attached to it.

**BKG-D8 — Host: free text or list?**
- A. Host picker from the reference list already in the payload. Effort S.
- B. Keep free text and match loosely. Effort S, unreliable.
- *Recommendation:* A.

**BKG-D9 — No-show handling?**
- A. Remove the checkbox. Effort S.
- B. Implement automatic release after a configurable grace period. Effort M.
- *Recommendation:* B if rooms are scarce; A until then.

**BKG-D10 — Is recurrence in scope?**
- A. No. Effort S.
- B. Weekly recurrence with an end date. Effort L.
- *Recommendation:* A for v1. It is the largest item on this page and the least
  demanded by a single-site customer.

---

## 8. Safe demo path

1. Open **Operations** → **Booking** for a branch with facilities and at least
   one seeded booking today.
2. Show the timeline: resource rows, hour markers, the now needle.
3. Move to the next day and back to **Today**.
4. Filter by a resource group.
5. Create a reservation: name, space, host, times, Confirm & Lock.
6. Show the new block on the timeline and the Upcoming Check-Ins list.

**Do not demo:**

- Any header nav link or the Room List / Desk Zones switcher.
- The floor map, the zone cards, or the micro-pods grid.
- Extend, End & Release, Check-In Room, Ring Organizer, Check In Now, or Release
  Room — all are toasts.
- The no-show checkbox.
- The equipment or hot-desk KPIs as if they were typed data.
- Double-booking: pick a space that is definitely free, or the demo will show two
  overlapping blocks.
- The footer ("Reception Console v4.8" is the wrong product name).

---

## 9. Engineering appendix

**Routes**

- `GET /companies/:company_id/operations/booking/:operation_id` (HTML + `.json`)
- `POST …/booking/:operation_id/reservations`

**Backend:** `Companies::Operations::BookingController#show` and
`#create_reservation`; `Booking::ConsoleService`; `Booking::ReservationService`.

**Frontend:** `app/javascript/controllers/companies/operations/booking/show_controller.js`
(`Companies_Operations_Booking_ShowController`).

**Payload:** `booking` = `{ date, timeline, resources, bookings, upcoming,
counts }`; `reference` = `{ facilities, hosts }`.

**Reservation behaviour:** creates an `Event` (`business_type: reservation`,
`workflow_status: confirmed`), one `EventFacilityAppointment`, and — only when
the host string equals an employee name exactly — one
`EmployeeEventAppointment`.

**Known code-level issues behind §5 and §6:**

- No overlap query exists in `ReservationService`; nothing rejects a conflicting
  facility/time.
- `renderBookingBlock` emits `data-booking-block` and `cursor-pointer` but the
  element carries no `data-action`.
- `booking_status` is derived from workflow status and the clock; the timeline's
  "busy" state follows the same derivation.
- `EQUIPMENT_PATTERN` and `HOT_DESK_PATTERN` classify facilities by regex over the
  name and category.
- `renderFloorMap` hardcodes "Floor 4", "Zone A (East Wing)", "Zone B (Quiet
  Hub)", and slices the first eight resources for the pod grid.
- The no-show checkbox has no `name` and is not read in `handleReservationSubmit`.
- Facility and host lists are capped at 100; the event query at 200.
- `TIMELINE_START_HOUR = 8`, `TIMELINE_END_HOUR = 18`.

**Source tables:** `facilities`, `events`, `event_facility_appointments`,
`employee_event_appointments`, `customer_event_appointments`, `categories`,
`employees`.

**Proof:** `spec/features/companies/operations/booking_spec.rb`,
`spec/requests/companies/operations/booking_spec.rb`,
`spec/services/booking/*.rb`.

**Not covered by tests:** conflicts, the clickable inspector, the no-show
checkbox, the floor map, and the heuristics.
