# Reception

> **Last audited:** 2026-11-19 · **Audit scope:** frontend controller, console
> service, check-in/advance/parcel services, backend controller, feature and
> service specs. No live browser run.
> **Ship readiness:** 🔴 not shippable — four dead nav tabs, five dead speed-dial
> buttons, badge printing that only toasts, and five status claims that are
> static text.
> **Who this is for:** the front-desk receptionist or lobby host.
> **Mobile:** same console, mounted through the Hotwire shell.
> **Read first:** [README](README.md) · **Related:** [00-app-overview](00-app-overview.md),
> [03-booking](03-booking.md)

---

## 1. What this page is for

The Reception console is the building's front door. It answers one question at
a glance — *who is in the building, who is waiting, and who is expected* — and
lets the receptionist check a walk-in guest in, hand out a badge, log a parcel,
and move a visit through check-in and check-out.

"Done" means a guest is inside with a host, a parcel is with its recipient, or a
visitor has left and the lobby count is correct.

The console reuses the Event domain: each visit is an Event, the visitor is a
linked Customer, the host is a linked Employee, and the room is a linked
Facility. Parcels are Events carrying a parcel marker in their metadata.

---

## 2. Who uses it

**The person:** a receptionist, lobby host, or security desk officer.

**Their goal:** keep the lobby moving and know exactly who is inside.

**What they can do here today:**

- Search visitors, hosts, companies, badges, and zones.
- Switch between lobby, inside, next hour, and departed.
- Check in a walk-in guest (name, company, host, room/zone).
- Move a visit forward: check in, check out, re-open.
- Log a host notification.
- Log a parcel, notify the recipient, mark it picked up.
- See room availability and the next five appointments.
- Open the walk-in and parcel forms.

**What they must do elsewhere:**

- Pre-register a visitor — create an Event in the Events module.
- Print a badge — no printer integration exists.
- Issue or deactivate an access card — no access-control model.
- Call security or first aid — the speed dial is decorative.
- Broadcast an emergency message — the button is decorative.

**Access:** the Reception operation must be active at the branch and the role
must be allowed by the operation.

---

## 3. The screen, in words

**Header:** Skycom FrontDesk mark, branch, a global quick-search, the shift pill,
a notification bell with the lobby count, the user, and a dark-mode toggle.
Below it, five tabs: Reception Console, Visitor Log, Appointments & Rooms,
Deliveries & Packages, Security & Badges.

**Headline:** a "Terminal Active" pill, the branch and "Desk Station A1 (Central
Turnstile)", the title, and four actions: Quick Walk-In Check-In, Log Delivery,
Issue Temp Badge, and an emergency broadcast icon.

**KPI ribbon (five cards):** Inside Building, Lobby Waiting, Expected Today,
Parcel Intake, Facility Rooms.

**Main column:** the queue toolbar (filter, four tabs, VIP count, density and
auto-sync labels), the visitor cards, and the walk-in station (hidden until
opened).

**Side column:** Upcoming & Rooms (room grid plus next appointments), Couriers &
Deliveries (list plus the parcel form), and Speed Dial & Emergency Desk.

**Footer:** copyright, "Terminal Operational", emergency extension, support link.

**States**

- *No activity:* a notice explaining that walk-ins and today's events will
  appear here.
- *No visitors in a tab:* "No visitors match this view."
- *No parcels:* "No parcels waiting at the desk."
- *Load failure:* a full-screen red "Failed to load the reception console."
- *Responsive:* the side column stacks under the queue; forms collapse to one
  column.

---

## 4. Control inventory

45 interactive controls.

| ID | Area | Control | What it does today | Status | If shipped as-is |
|---|---|---|---|---|---|
| RCP-01 | Header | Global quick search | Filters visitor cards; `/` focuses it | ✅ | Filters only the active tab |
| RCP-02 | Header | Notification bell | Switches to the lobby tab and scrolls to it | ✅ | Badge count is the lobby count |
| RCP-03 | Header | Dark-mode toggle | Switches theme | ✅ | — |
| RCP-04 | Tabs | Reception Console | Active tab; does nothing | ✅ | — |
| RCP-05 | Tabs | Visitor Log | Toast: "Visitor Log is coming soon." | 🗑️ | Four of five tabs are promises |
| RCP-06 | Tabs | Appointments & Rooms | Toast: "… is coming soon." | 🗑️ | Same |
| RCP-07 | Tabs | Deliveries & Packages | Toast: "… is coming soon." | 🗑️ | Same |
| RCP-08 | Tabs | Security & Badges | Toast: "… is coming soon." | 🗑️ | Same |
| RCP-09 | Headline | Quick Walk-In Check-In | Opens and focuses the walk-in form | ✅ | — |
| RCP-10 | Headline | Log Delivery | Opens and focuses the parcel form | ✅ | — |
| RCP-11 | Headline | Issue Temp Badge | Toast: "Temporary badge issuing is not connected yet." | 🗑️ | Core front-desk action missing |
| RCP-12 | Headline | Emergency broadcast | Toast: "Emergency broadcast is not connected yet." | 🗑️ | A safety control that does nothing |
| RCP-13 | Queue | Filter input | Filters cards in the active tab | ✅ | — |
| RCP-14 | Queue | In Lobby tab | Shows waiting visitors | ✅ | — |
| RCP-15 | Queue | Active in Bldg tab | Shows checked-in visitors | ✅ | — |
| RCP-16 | Queue | Next Hour tab | Shows expected visitors | ✅ | — |
| RCP-17 | Queue | Departed tab | Shows completed visits | ✅ | — |
| RCP-18 | Visitor card | Re-Notify Host | Records the host-notified time | ✅ | No message is actually sent |
| RCP-19 | Visitor card | Print visitor badge | Toast: "Badge … sent to the printer" | 🗑️ | Claims printing that never happens |
| RCP-20 | Visitor card | Check in visitor | Moves the visit to in progress | ✅ | — |
| RCP-21 | Visitor card | Complete Check-Out | Completes the visit | ✅ | — |
| RCP-22 | Visitor card | Manage key | Toast: "Key station unlocked…" | 🗑️ | No key or access model |
| RCP-23 | Visitor card | Badge details | Toast: badge sent to printer | 🗑️ | Duplicate of printing |
| RCP-24 | Visitor card | Notify Host (expected) | Records the host-notified time | ✅ | Same as RCP-18 |
| RCP-25 | Visitor card | Pre-print badge | Toast: badge sent to printer | 🗑️ | — |
| RCP-26 | Visitor card | Re-open visit | Returns a departed visit to in progress | ✅ | — |
| RCP-27 | Walk-in form | Full guest name | Required text | ✅ | — |
| RCP-28 | Walk-in form | Company / organisation | Required text | ✅ | — |
| RCP-29 | Walk-in form | Internal host | Employee dropdown | ✅ | Empty means "General Front Desk Escort" |
| RCP-30 | Walk-in form | Access level & zone | Facility dropdown | 🟡 | It picks a room; it does not grant access |
| RCP-31 | Walk-in form | Send arrival SMS to host | Stored as a metadata flag | 🟡 | Nothing sends an SMS |
| RCP-32 | Walk-in form | Auto-print adhesive badge | Stored as a metadata flag | 🟡 | Nothing prints |
| RCP-33 | Walk-in form | Check-In & Print Badge | Creates the visit and closes the form | ✅ | Prints nothing |
| RCP-34 | Walk-in form | Close (X) | Hides the form | ✅ | — |
| RCP-35 | Rooms | View all appointments | Toast: "Appointments & Rooms is coming soon." | 🟡 | Count is real; the view is not |
| RCP-36 | Parcels | Log delivery / scan waybill | Opens the parcel form; no scanner | 🟡 | Label promises scanning |
| RCP-37 | Parcels | Notify (recipient) | Stamps the parcel's notified time | ✅ | No message is sent |
| RCP-38 | Parcels | Mark picked up | Completes the parcel Event | ✅ | — |
| RCP-39 | Parcels | Cancel | Closes the parcel form | ✅ | — |
| RCP-40 | Parcels | Log package | Creates the parcel Event | ✅ | — |
| RCP-41 | Speed dial | Security Command | Toast: "Calling Security Command · Ext. #101" | 🗑️ | No call is placed |
| RCP-42 | Speed dial | Facilities Urgent | Same toast | 🗑️ | Same |
| RCP-43 | Speed dial | Valet / Parking | Same toast | 🗑️ | Same |
| RCP-44 | Speed dial | First Aid Post | Same toast | 🗑️ | Same |
| RCP-45 | Speed dial | Test Chime | Toast: "Chime broadcast over the lobby PA." | 🗑️ | No PA exists |

**Count by status:** ✅ 26 · 🟡 4 · 🗑️ 15 · ⛔ 0. Fabricated status claims are
counted in §5.

---

## 5. Numbers on screen

| Claim on screen | What it appears to mean | Where it actually comes from | Verdict |
|---|---|---|---|
| Inside Building | People currently inside | Visits in progress | ✅ |
| N checked out | Departures today | Completed visits | ✅ |
| Lobby Waiting | People waiting | Confirmed visits not yet checked in | ✅ |
| "Avg wait: N mins" | Average lobby wait | Mean of positive waits among lobby visitors | ✅ |
| Expected Today | Expected visitors | The main number is **remaining**, not expected; "N Sched" is the total | 🟡 label and number disagree |
| "Progress: N%" | Share of the day's visits handled | (expected − remaining) ÷ expected | ✅ derived |
| Parcel Intake | Parcels held | Parcels awaiting pickup | ✅ capped at 50 |
| "N lockers available" | Free lockers | `8 − parcels` | 🔢 there is no locker model; 8 is invented |
| "Locker capacity: N%" | Locker occupancy | parcels ÷ 8 | 🔢 same invented capacity |
| Facility Rooms N / M Ready | Free rooms / all rooms | Rooms are the first 8 facilities whose category looks room-like | 🟡 the 8 is a hard cap; the room list may include non-rooms |
| "N in active sessions" | Rooms in use | Rooms whose current Event is in progress | ✅ |
| VIP flagged | VIP guests present | A metadata flag on the visit Event | ✅ no UI sets it; seed only |
| "Shift: Morning (08:00 - 17:00)" | The working shift | Branch-local hour bucketed at 12:00 and 17:00 | 🔢 invented; labels contradict the cut-offs |
| "Desk Station A1 (Central Turnstile)" | This terminal's identity | Hardcoded text | 🔢 |
| "Terminal Active" / "Terminal Operational" | Terminal health | Static text | 🔢 |
| "Auto-sync: 15s" | The page refreshes itself | Static text; there is no timer | 🔢 |
| "Density: Standard" | A layout setting | Static text; nothing changes it | 🔢 |
| "VOIP UP" | Phone system connected | Static text | 🔢 |
| "PA System: Channel 1 connected" | PA connected | Static text | 🔢 |
| "Emergency Ext: 9110" / speed-dial numbers | Real extensions | Hardcoded | 🔢 |
| "Sent to the printer" toasts | A badge was printed | No printer integration | 🔢 |
| "Emergency broadcast" | A lobby display was addressed | No integration | 🔢 |

---

## 6. Gaps by user job

### G1 — "Print the visitor a badge."
Badge printing is the receptionist's most repeated task. Three print buttons and
one checkbox all promise it; none of them reaches a printer.

- Smallest real version: generate a printable badge PDF or browser print layout (M).
- Full version: label-printer integration (L).

### G2 — "Tell the host their guest has arrived."
Notify Host writes a timestamp into the visit's metadata. No in-app notification,
SMS, email, or chat message is sent, and the host has no screen that shows it.

- Smallest real version: create a Notification for the host (M).
- Full version: SMS/email with delivery status (L).

### G3 — "Scan the waybill."
The button says scan; it opens a form and requires typing the carrier, recipient,
and item.

- Smallest real version: rename to "Log delivery" (S).
- Better: barcode/QR scan into the carrier and tracking fields (M).

### G4 — "Which lockers are free?"
The console invents a capacity of eight lockers and derives availability from
the parcel count. There is no locker record, no assignment, and no size.

- Smallest real version: remove both locker claims (S).
- Full version: locker model with assignment and release (M).

### G5 — "Call security."
Four speed-dial buttons and a PA chime are decorative. In an emergency the
receptionist gets a toast.

- Smallest real version: remove the panel (S).
- Better: show real extension numbers as text and make them dialable on mobile (S).

### G6 — "Pre-register tomorrow's guest."
There is no pre-registration form. Expected visitors only appear if someone
creates an Event in the Events module, so the front desk cannot do its most
common planning task.

- Smallest real version: a pre-registration form that creates the same visit Event (M).
- Full version: invitation email with a QR pass (L).

### G7 — "Give this contractor a temporary badge with zone access."
The "Access Level & Zone" dropdown picks a Facility; it does not grant access,
set an expiry, or record a badge number.

- Smallest real version: rename to "Room / zone" (S).
- Full version: access levels and badge lifecycle (L).

### G8 — "Is this visitor still inside after hours?"
There is no overstay alert, no expected-departure time, and no evacuation list.

- Smallest real version: show time inside on the card (S).
- Better: overstay highlight and an "everyone inside" export (M).

### G9 — "The lobby queue shows a meeting room booking."
Visits are today's Events for the branch, so internal bookings and appointments
appear as visitors, with the Event title as the name when no customer is linked.

- Smallest real version: filter to customer-linked visits (S).
- Better: explicitly separate "appointments" from "visitors" (M).

### G10 — "Only fetch the first 50 parcels / 200 visits."
Both lists are capped with no pagination or warning.

- Smallest real version: show the cap (S).

### G11 — "Refresh the page for me."
"Auto-sync: 15s" is a lie; the page never refreshes on its own.

- Smallest real version: remove the label (S).
- Better: poll or subscribe to the company channel (M).

### G12 — "Reception is for hotels too."
The page is branded "Enterprise Hospitality ERP" with "FrontDesk", "Valet /
Parking", and "Concierge". A clinic or office using the same operation sees
hospitality language.

- Smallest real version: neutral copy (S).

---

## 7. Decisions for the BA

**RCP-D1 — Is badge printing in the first release?**
- A. Remove the three print buttons and the checkbox. Effort S.
- B. Printable badge page. Effort M.
- C. Label printer. Effort L.
- *Recommendation:* B. It is the most-used front-desk artifact and a browser
  print layout is enough for most customers.

**RCP-D2 — How is the host notified?**
- A. In-app notification only. Effort M.
- B. In-app plus SMS. Effort L.
- *Recommendation:* A now; B when messaging infrastructure is shared with
  notifications.

**RCP-D3 — Pre-registration: build or defer?**
- A. Defer; Events module creates expected visitors. Effort S.
- B. Add a pre-registration form. Effort M.
- *Recommendation:* B. Without it, the "Next Hour" tab depends on another module's
  UI that most receptionists do not use.

**RCP-D4 — Lockers: remove or model?**
- A. Remove the locker claims. Effort S.
- B. Add locker records and assignment. Effort M.
- *Recommendation:* A unless the building actually has lockers and a customer
  asks for them.

**RCP-D5 — Speed dial and PA: remove or wire?**
- A. Remove the panel and the static "VOIP UP" / "PA connected" claims. Effort S.
- B. Show real extensions as click-to-call on mobile. Effort S.
- *Recommendation:* B. It costs little and keeps the emergency information that is
  actually useful.

**RCP-D6 — Should the queue include internal bookings?**
- A. Keep everything (current). Effort S. Risk: the lobby count is wrong.
- B. Show only customer-linked visits, and give appointments their own tab. Effort M.
- *Recommendation:* B — "how many people are inside" must not include meeting
  rooms.

**RCP-D7 — Access levels: rename or build?**
- A. Rename the field. Effort S.
- B. Build access levels, expiries, and badge numbers. Effort L.
- *Recommendation:* A until a customer with controlled zones asks.

**RCP-D8 — Auto-refresh?**
- A. Remove the false "15s" label. Effort S.
- B. Poll every 15–30 seconds. Effort S–M.
- *Recommendation:* B on a wall-mounted lobby screen; A elsewhere.

**RCP-D9 — Hospitality branding?**
- A. Keep it. Effort S. Risk: alienates office, clinic, and school customers.
- B. Use neutral front-desk copy. Effort S.
- *Recommendation:* B.

**RCP-D10 — Terminal identity and health claims?**
- A. Remove "Desk Station A1 (Central Turnstile)", "Terminal Active", and
  "Terminal Operational". Effort S.
- B. Let each reception desk be named and report real health. Effort M.
- *Recommendation:* A. A desk identity is only useful once there is more than one
  desk, and there is no health signal to report.

**RCP-D11 — The "Current Shift" label?**
- A. Remove it; the header already shows the branch. Effort S.
- B. Derive it from today's scheduled shifts, as recommended for Store Manager
  (SM-D11). Effort M.
- *Recommendation:* B, shared with SM-D11 so both consoles use one source.

---

## 8. Safe demo path

1. Open **Operations** → **Reception** for a branch with facilities.
2. Show the KPI ribbon and explain each number.
3. Open **Quick Walk-In Check-In**, register a guest with a host and room.
4. Show the guest in the **In Lobby** tab, then **Check in visitor**.
5. Switch to **Active in Bldg** and complete the check-out.
6. Open **Log Delivery**, log a parcel, notify the recipient, mark it picked up.
7. Show the room grid and the next appointments.

**Do not demo:**

- The Visitor Log, Appointments & Rooms, Deliveries & Packages, or Security &
  Badges tabs.
- Issue Temp Badge, emergency broadcast, any print/badge button, Manage Key, or
  the speed dial.
- The locker capacity, "Auto-sync: 15s", "VOIP UP", "PA System", "Terminal
  Active", or "Desk Station A1".
- The SMS and auto-print checkboxes as if a message or badge would be produced.
- "View all appointments".
- A branch whose Events include internal meetings — they will appear as visitors.

---

## 9. Engineering appendix

**Routes**

- `GET /companies/:company_id/operations/reception/:operation_id` (HTML + `.json`)
- `POST …/reception/:operation_id/check_in`
- `POST …/reception/:operation_id/advance`
- `POST …/reception/:operation_id/parcels`
- `POST …/reception/:operation_id/parcels/:parcel_id/notify`
- `POST …/reception/:operation_id/parcels/:parcel_id/pick_up`
- `POST …/reception/:operation_id/notify_host`

**Backend:** `Companies::Operations::ReceptionController`;
`Reception::ConsoleService`, `Reception::CheckInService`,
`Reception::AdvanceService`, `Reception::ParcelService`.

**Frontend:** `app/javascript/controllers/companies/operations/reception/show_controller.js`
(`Companies_Operations_Reception_ShowController`).

**Payload:** `reception` = `{ visits, parcels, rooms, appointments, counts }`;
`reference` = `{ hosts, facilities }`.

**Visit state machine:** `pending/draft → upcoming`, `confirmed → lobby`,
`in_progress → active`, `completed → departed`. Transitions go through
`advance` with `check_in`, `check_out`, or `reopen`.

**Parcels:** Events with `metadata["reception_kind"] = "parcel"`, created by
`ParcelService`, notified by stamping `notified_at`, completed by pick-up.

**Known code-level issues behind §5 and §6:**

- `lockerFreeCount` is `8 − deliveries.length`; the footer computes
  `deliveries ÷ 8`. No locker model exists.
- `renderSpeedDialPanel` uses a hardcoded `lines` array (101, 104, 109, 911) and
  `dialLine` only toasts.
- `issueBadge`, `broadcast`, and `chime` only toast.
- `printBadge` only toasts "sent to the printer".
- The `visitor[notify]` and `visitor[print]` flags are stored in Event metadata
  (`notify_host`, `auto_print`) by `CheckInService`; nothing consumes them.
- `rooms` selects facilities whose category matches `ROOM_CATEGORY_PATTERN`,
  falling back to all facilities, then takes the first 8.
- `currentShift` is duplicated from Store Manager with the same invented
  thresholds.
- The file header comment still says the page ships demo data — it has been
  wired to the backend since; the comment is stale.

**Source tables:** `events`, `customers`, `customer_event_appointments`,
`employees`, `employee_event_appointments`, `facilities`,
`event_facility_appointments`, `categories`.

**Proof:** `spec/features/companies/operations/reception_spec.rb`,
`spec/requests/companies/operations/reception_spec.rb`,
`spec/services/reception/*.rb`.

**Not covered by tests:** badge printing, host notification delivery, locker
capacity, speed dial, auto-sync, and the room cap.
