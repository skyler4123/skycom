# Reception

> **Last audited:** 2026-11-20 · **Audit scope:** frontend controller, console
> service, check-in/pre-register/advance/parcel/notify/shift services, backend
> controller, feature/service/request specs.
> **Ship readiness:** 🟢 shippable — one honest page, guest-linked visits only,
> real pre-registration, browser badge print, direct in-app notifications, real
> shift/timers/search/polling.
> **Who this is for:** the front-desk receptionist or lobby host.
> **Mobile:** same console, mounted through the Hotwire shell.
> **Read first:** [README](README.md) · **Related:** [00-app-overview](00-app-overview.md),
> [03-booking](03-booking.md)

---

## 1. What this page is for

The Reception console is the building's front door. It answers one question at
a glance — *who is inside, who is waiting, and who is still expected* — and lets
the receptionist check a walk-in in, pre-register a future guest, print one
visitor badge, log a parcel, notify a host or recipient, and move a visit
through arrival, entry and departure.

"Done" means a guest is inside with a host, a parcel is with its recipient, or a
visitor has left and the lobby count is correct.

The console reuses the Event domain: each visit is an Event, the visitor is a
linked Customer, the host is a linked Employee, and the room is a linked
Facility. Parcels are Events carrying a parcel marker in their metadata.

**A booking with no guest is not a visitor.** It is a facility appointment and
appears only in the appointments panel.

---

## 2. Who uses it

**The person:** a receptionist, lobby host, or security desk officer.

**Their goal:** keep the lobby moving and know exactly who is inside.

**What they can do here today:**

- Search today's visits and waiting parcels from the header.
- Filter the open queue without changing any KPI.
- Check in a walk-in guest (name + company required; host, room and VIP optional).
- Pre-register a future guest with date, start time and optional end time.
- Move a visit: They've arrived → Mark inside → Check out → Reopen.
- Notify the host of an expected or lobby visit; notify again if needed.
- Print one visitor badge in the browser.
- Log a parcel, notify the recipient, and mark it picked up.
- See real room readiness and today's non-visit appointments.
- See a real scheduled-shift pill when a shift covers now.
- See the page refresh every ~20 seconds without losing a form or filter.

**Access:** the Reception operation must be active at the branch and the role
must be allowed by the operation.

---

## 3. The screen, in words

**Header:** Skycom Reception, company, branch, search, bell with the lobby count,
the signed-in person, and a dark-mode toggle. The shift pill appears only when
this employee has a real scheduled shift covering now.

**Headline:** `{Branch} · Reception` with three actions: **Walk-in check-in**,
**Pre-register**, **Log delivery**.

**KPI ribbon (five cards):** Inside, Lobby, Expected (still to arrive only),
Parcels held, Rooms `ready / all`. Expected carries `N scheduled today` (all
four visit buckets) and hides its progress bar at zero.

**Queue:** In lobby, Inside, Expected, Departed. Those four buckets do not
overlap. The filter only narrows the currently open bucket. A capped list says
`Showing the first 200` (the panel says which list is capped).

**Visitor cards:** name, visitor company, host (or **No host**), room (or **No
room**), VIP marker, code, arrival time, the status-specific timer, and the
actions that belong to that status. Notify shows **Notified {time}** and
**Notify again** after the first click. Print appears only on lobby and inside
cards.

**Side column:** Rooms (first 8, **Show all** / **Show less**), Appointments
today (non-visit facility events, first 5, **Show all N appointments**), and
Parcels held (list + inline Log delivery form). Nothing below that.

**Footer:** `Skycom · Reception · {company}`.

**States**

- *No visits:* "No visitors match this view."
- *No parcels:* "No parcels waiting at the desk."
- *No rooms:* "No rooms configured for this branch."
- *No appointments:* "No appointments today."
- *No host:* notify is inert and says **No host to notify**.
- *Load failure:* full-screen error state.
- *Poll failure:* existing data stays; the update label says `Update failed · retrying`.
- *Responsive:* the side column stacks under the queue; forms collapse to one column.

---

## 4. Control inventory

44 interactive controls.

| ID | Area | Control | What it does | Status |
|---|---|---|---|---|
| RCP-01 | Header | Quick search | Jumps across today's visits and waiting parcels | ✅ |
| RCP-02 | Header | Notification bell | Shows the lobby count and focuses the lobby queue | ✅ |
| RCP-03 | Header | Dark-mode toggle | Switches theme | ✅ |
| RCP-04 | Headline | Walk-in check-in | Opens the walk-in form | ✅ |
| RCP-05 | Headline | Pre-register | Opens the pre-registration form | ✅ |
| RCP-06 | Headline | Log delivery | Opens the parcel form | ✅ |
| RCP-07 | Queue | Filter input | Narrows only the open queue bucket | ✅ |
| RCP-08 | Queue | In lobby | Shows confirmed visits | ✅ |
| RCP-09 | Queue | Inside | Shows in-progress visits | ✅ |
| RCP-10 | Queue | Expected | Shows pending/draft visits for today | ✅ |
| RCP-11 | Queue | Departed | Shows completed visits | ✅ |
| RCP-12 | Card | They've arrived | Expected → lobby | ✅ |
| RCP-13 | Card | Mark inside | Lobby → inside | ✅ |
| RCP-14 | Card | Check out | Inside → departed | ✅ |
| RCP-15 | Card | Reopen | Departed → inside | ✅ |
| RCP-16 | Card | Notify host / Notify again | One direct notification + timestamp per click | ✅ |
| RCP-17 | Card | Print visitor badge | Browser print of that visit only | ✅ |
| RCP-18 | Walk-in | Guest name | Required text | ✅ |
| RCP-19 | Walk-in | Guest company | Required text | ✅ |
| RCP-20 | Walk-in | Host | Optional employee picker; empty means No host | ✅ |
| RCP-21 | Walk-in | Room | Optional facility picker; empty means No room | ✅ |
| RCP-22 | Walk-in | VIP guest | Sets the VIP marker | ✅ |
| RCP-23 | Walk-in | Close | Hides the form | ✅ |
| RCP-24 | Walk-in | Check in to lobby | Creates a confirmed lobby visit | ✅ |
| RCP-25 | Pre-register | Guest name | Required text | ✅ |
| RCP-26 | Pre-register | Guest company | Required text | ✅ |
| RCP-27 | Pre-register | Host | Optional employee picker | ✅ |
| RCP-28 | Pre-register | Room | Optional facility picker; overlap allowed | ✅ |
| RCP-29 | Pre-register | Date | Required branch-local date | ✅ |
| RCP-30 | Pre-register | Start time | Required branch-local time | ✅ |
| RCP-31 | Pre-register | End time | Optional; defaults to +1 hour | ✅ |
| RCP-32 | Pre-register | VIP guest | Sets the VIP marker | ✅ |
| RCP-33 | Pre-register | Close | Hides the form | ✅ |
| RCP-34 | Pre-register | Save pre-registration | Creates a pending visit | ✅ |
| RCP-35 | Rooms | Show all / Show less | Expands the full room list; no toast | ✅ |
| RCP-36 | Appointments | Show all N appointments | Expands the full appointment list; no toast | ✅ |
| RCP-37 | Parcels | Log delivery | Opens the parcel form | ✅ |
| RCP-38 | Parcels | Notify / Notify again | Direct notification to the recipient | ✅ |
| RCP-39 | Parcels | Mark picked up | Completes the parcel Event | ✅ |
| RCP-40 | Parcels | Carrier | Required text | ✅ |
| RCP-41 | Parcels | Recipient | Required employee picker | ✅ |
| RCP-42 | Parcels | Item summary | Required text | ✅ |
| RCP-43 | Parcels | Cancel | Closes the parcel form | ✅ |
| RCP-44 | Parcels | Save delivery | Creates the held parcel | ✅ |

**Count by status:** ✅ 44 · 🟡 0 · 🗑️ 0 · ⛔ 0.

---

## 5. Numbers on screen

| Claim on screen | What it means | Where it comes from | Verdict |
|---|---|---|---|
| Inside | People currently inside | `in_progress` guest-linked visits, including carry-over | ✅ |
| N checked out | Departures today | `completed` visits that started today | ✅ |
| Lobby | People waiting | `confirmed` guest-linked visits | ✅ |
| "Avg wait: N mins" / "Just arrived" | Mean lobby wait | Mean of lobby-entry elapsed minutes; under 1 minute says Just arrived | ✅ |
| Expected | Still to arrive | `pending`/`draft` guest-linked visits starting today | ✅ |
| "N scheduled today" | All visit buckets today | All guest-linked visits starting today, any status | ✅ |
| Progress bar | Share of today's visits handled | `(scheduled − expected) ÷ scheduled`; hidden at zero | ✅ |
| Parcels held | Parcels waiting | Parcel Events not completed/cancelled | ✅ |
| Rooms `ready / all` | Rooms free now / all room-like facilities | Room status from current/next facility Events | ✅ |
| VIP flagged | VIP guests in the open queue | Visit metadata `vip` | ✅ |
| Waiting N mins | Time since entering the lobby | `lobby_entered_at` (fallback `checked_in_at`, then start) | ✅ |
| Inside N mins | Time since Mark inside | `inside_at` (fallback `checked_in_at`) | ✅ |
| Shift pill | This employee's shift | `ScheduledShift` covering now, or hidden | ✅ |
| "Updated {time}" | Last successful poll | Server `generated_at` rendered on the branch clock | ✅ |
| "Showing the first 200" | Display cap | Visits/parcels/appointments first 200; counts stay full | ✅ |

---

## 6. Gaps by user job

All gaps named in the previous audit are closed:

| Job | Previous gap | Now |
|---|---|---|
| Print a visitor badge | Toast only | Browser print of one visit; no printer claim |
| Tell the host their guest arrived | Metadata only | One direct in-app notification per click + timestamp |
| Pre-register tomorrow's guest | Open the Events module | Pre-register on this page |
| Which lockers are free | Invented capacity | Lockers removed |
| Call security | Decorative speed dial | Removed |
| Scan the waybill | Form with a scan label | Renamed Log delivery |
| Access level and zone | Facility pretending to be access | Renamed Room; it is a facility |
| Auto-refresh | Static "15s" label | Real 20-second poll |
| Hospitality branding | FrontDesk/Valet/Concierge | Neutral Skycom Reception copy |
| Terminal identity | Hardcoded station/health | Removed |
| Current shift | Clock-derived label | Real scheduled shift or hidden |
| Internal bookings in the lobby | All Events counted | Only guest-linked visit Events |

**Not built, deliberately:**

- Label-printer integration.
- SMS, email, or push delivery.
- Access cards, keys, or locker assignment.
- Click-to-call or emergency broadcast.
- QR invites.
- A separate Visitor Log module.

---

## 7. Decisions for the BA

All decisions are closed for this finish.

| Decision | Choice |
|---|---|
| Badge | Browser print of one visit. No printer integration, no temp-badge product. |
| Notify | One direct in-app notification per click + timestamp. No SMS checkbox. |
| Pre-register | On this page. Do not send the receptionist to Events. |
| Lockers, speed dial, PA, VOIP, chime | Removed. The numbers were not real. |
| Queue | Reception visits with a guest only. A booking with no guest is an appointment. |
| Room field | A facility. Not an access level, key, or zone. |
| Shift pill | Today's scheduled shift, or hidden. Never invented from the clock. |
| Copy | Skycom Reception + company + branch. No FrontDesk, Hospitality, Valet, Concierge, Turnstile, or PA language. |

---

## 8. Safe demo path

1. Open the desk: no fake chrome, one page, real counts.
2. Pre-register tomorrow's guest: Expected +1 tomorrow, absent today.
3. They've arrived: Expected −1, Lobby +1.
4. Notify host: one inbox row and a time on the card.
5. Print badge: the browser preview contains only that visitor's card.
6. Mark inside, then check out: counts follow.
7. Walk-in with no host: Notify stays off, card says No host.
8. Log a parcel, notify, mark picked up: held goes 0 → 1 → 0; no locker line.
9. Rooms and appointments: counts match rows; Show all does not toast.
10. A booking with no guest does not move the queue.

---

## 9. Engineering appendix

**Routes**

- `GET /companies/:company_id/operations/reception/:operation_id` (HTML + `.json`)
- `POST …/reception/:operation_id/check_in`
- `POST …/reception/:operation_id/pre_register`
- `POST …/reception/:operation_id/advance`
- `POST …/reception/:operation_id/parcels`
- `POST …/reception/:operation_id/parcels/:parcel_id/notify`
- `POST …/reception/:operation_id/parcels/:parcel_id/pick_up`
- `POST …/reception/:operation_id/notify_host`
- `GET /mobile/companies/:company_id/operations/reception/:operation_id` (Shell-First mount)

**Backend:** `Companies::Operations::ReceptionController`;
`Reception::ConsoleService`, `Reception::GuestResolver`,
`Reception::CheckInService`, `Reception::PreRegisterService`,
`Reception::AdvanceService`, `Reception::NotifyHostService`,
`Reception::ParcelService`, `Reception::ShiftService`.

**Frontend:** `app/javascript/controllers/companies/operations/reception/show_controller.js`
(`Companies_Operations_Reception_ShowController`).

**Payload:** `reception` = `{ visits, parcels, rooms, appointments, counts,
shift, generated_at }`; `company` = `{ id, name }`; `reference` = `{ hosts,
facilities }`.

**Visit filter:** `metadata["reception_kind"] = "visit"` **and** a linked
`CustomerEventAppointment`. Statuses: `pending/draft → expected`,
`confirmed → lobby`, `in_progress → inside`, `completed → departed`,
`cancelled → hidden`.

**Transitions:** `arrive`, `mark_inside`, `check_out`, `reopen`. Timestamps:
`lobby_entered_at`, `inside_at`, `checked_out_at`. Legacy `checked_in_at` is a
fallback for old visits.

**Parcels:** Events with `metadata["reception_kind"] = "parcel"`, created by
`ParcelService`, notified through `notified_at`, completed by pick-up. No
locker metadata or capacity is stored or displayed.

**Notifications:** direct recipient rows use
`notifications.recipient_employee_id`; `Notification.subscribed_for`,
`Notifications::UnreadQuery`, and `Notifications::CreateService` include direct
recipients alongside tag broadcasts. Each notify click creates one notification.

**Print:** the screen wrapper is `print:hidden`; `#reception-badge-print` is
`hidden print:block`. It contains only company, Visitor, name, visitor company,
host, room, branch, time and code. No barcode, photo, or printer claim.

**Caps:** visits/parcels/appointments first 200 (`visits_capped`,
`parcels_capped`, `appointments_capped`). Rooms load all room-like facilities;
the panel previews 8.

**Tests:** `spec/features/companies/operations/reception_spec.rb`,
`spec/features/mobile/reception_spec.rb`,
`spec/requests/companies/operations/reception_controller_spec.rb`,
`spec/requests/mobile/reception_controller_spec.rb`,
`spec/services/reception/*`,
`spec/models/notification_spec.rb`,
`spec/services/notifications/notification_services_spec.rb`,
`spec/requests/companies/notifications_controller_spec.rb`.

**Source tables:** `events`, `customers`, `customer_event_appointments`,
`employees`, `employee_event_appointments`, `facilities`,
`event_facility_appointments`, `categories`, `scheduled_shifts`,
`shift_templates`, `notifications`.
