# Skycom Mobile (Hotwire Native)

Shell-First mobile pages inside the Android Hotwire Native shell. Every page
response is only a mount `<div>`; a mobile Stimulus controller hydrates it from
the same URL as `.json`. Tenant pages are scoped to the company in the URL
(`/mobile/companies/:company_id/*`); the native app owns the five-tab bottom
navigation and shows it only after authentication.

> Feature parity, pending work, and the Android shell audit live in
> [`docs/MOBILE_FEATURE_MATRIX.md`](MOBILE_FEATURE_MATRIX.md).

---

## 1. Routes and pages

| Route | Controller#action | Hydrated by |
|---|---|---|
| `GET/POST /mobile/sign_in` | `Mobile::SessionsController#new/create` | `Mobile_Sessions_NewController` |
| `DELETE /mobile/sign_out` | `Mobile::SessionsController#destroy` | redirect |
| `GET /mobile/companies/:company_id/home` | `Mobile::Companies::HomeController#index` | `Mobile_Companies_Home_IndexController` |
| `GET /mobile/companies/:company_id/notifications` | `Mobile::Companies::NotificationsController#index` | `Mobile_Companies_Notifications_IndexController` |
| `GET /mobile/companies/:company_id/employee` | `Mobile::Companies::EmployeesController#show` | `Mobile_Companies_Employees_ShowController` |
| `GET /mobile/companies/:company_id/attendance_month` | `Mobile::Companies::AttendanceMonthsController#show` | `Mobile_Companies_AttendanceMonths_ShowController` |
| `GET /mobile/companies/:company_id/operations` | `Mobile::Companies::OperationsController#index` | `Mobile_Companies_Operations_IndexController` |
| `GET /mobile/companies/:company_id/operations/pos/:operation_id` | `Mobile::Companies::Operations::PosController#show` | shared `Companies_Operations_Pos_ShowController` |
| `GET /mobile/companies/:company_id/operations/booking/:operation_id` | `Mobile::Companies::Operations::BookingController#show` | shared `Companies_Operations_Booking_ShowController` |
| `GET /mobile/companies/:company_id/operations/reception/:operation_id` | `Mobile::Companies::Operations::ReceptionController#show` | shared `Companies_Operations_Reception_ShowController` |
| `GET /mobile/companies/:company_id/operations/store_manager/:operation_id` | `Mobile::Companies::Operations::StoreManagerController#show` | shared `Companies_Operations_StoreManager_ShowController` |
| `GET /mobile/companies/:company_id/operations/inventory/:operation_id` | `Mobile::Companies::Operations::InventoryController#show` | shared `Companies_Operations_Inventory_ShowController` |
| `GET /mobile/companies/:company_id/payroll/unlock` | `Mobile::Companies::PayrollUnlocksController#new` | `Mobile_Companies_PayrollUnlocks_NewController` |
| `POST /mobile/companies/:company_id/payroll/unlock` | `Mobile::Companies::PayrollUnlocksController#create` | native POST → redirect / 422 shell |
| `GET /mobile/companies/:company_id/payroll` | `Mobile::Companies::PayrollsController#show` | `Mobile_Companies_Payrolls_ShowController` |
| `GET /mobile/companies/:company_id/attendance_requests/new` | `Mobile::Companies::AttendanceRequestsController#new` | `Mobile_Companies_AttendanceRequests_NewController` |
| `POST /mobile/companies/:company_id/attendance_requests` | `Mobile::Companies::AttendanceRequestsController#create` | native POST → redirect / 422 shell |
| `POST /mobile/companies/:company_id/attendances` | `Mobile::Companies::AttendancesController#create` | native POST → redirect |

Every GET route above also accepts `.json`, which returns the page payload. The
HTML response contains no screen content.

> **Adding a new operation console?** Follow `docs/OPERATION_PAGES.md` §8. The
> mobile route, policy, `shell_html`, Operations-list link, and orientation tests
> are part of the same deliverable as the web page. The mobile console shell must
> mount the shared web Stimulus controller; do not create a mobile-only operation
> controller.

`Mobile::Companies::BaseController` resolves the employee through
`current_user.employees.find_by!(company_id: params[:company_id])`. A company
the user does not belong to returns `404`; the stored company id on the device
is never treated as authorization. The `.json` payload uses the same resolution,
so a multi-company user always hydrates the employee for the company in the URL.

### Authorization

Company-level screens use ABAC: Operations, the mobile POS page and the mobile
reception/store manager/inventory consoles require `Operation` read, Notifications require
`Notification` read, and attendance requests require `AttendanceRequest` create.
POS, Booking, Reception and Store Manager additionally resolve an active branch
appointment; Inventory resolves an active warehouse appointment. Every console
checks `Operation#accessible_by?` before rendering the shell. Self-service screens (Home, Profile, Attendance month, Payroll/unlock,
check-in) are membership-scoped instead: the controller always resolves
`@employee` from `current_user` + `company_id`, so they can only reach the
signed-in employee's own records. Payroll still requires the password unlock
before its data is rendered.

Existing companies seeded before the `Operation` grant was added need a re-seed (or
a policy-appointment backfill) before staff roles can open the Operations tab;
new companies receive it from their init service.

### Suspended company block

`Mobile::Companies::SuspendedCompanyConcern` runs after mobile authorization on
every `/mobile/companies/:company_id/*` page. A company with
`workflow_status: suspend` gets a `403` mobile-layout notice (“top up on the
web”); mobile has no top-up flow. Mobile sign-in is not company-scoped and
stays reachable. See
`docs/CREDIT_DEDUCTION.md` §5.2.

### Native auth gate

`android/.../SignInActivity` is the launcher and has no bottom navigation. It
loads `/mobile/sign_in`. After a successful sign-in, Rails redirects to
`/mobile/companies/:company_id/home`; the activity extracts that id, stores it
in `SharedPreferences` (`CompanyStore`), and starts `MainActivity`.

`MainActivity` builds the five tab roots from the stored id:

```
/mobile/companies/<company_id>/home
/mobile/companies/<company_id>/notifications
/mobile/companies/<company_id>/employee        (Profile)
/mobile/companies/<company_id>/attendance_month
/mobile/companies/<company_id>/operations
```

Payroll is no longer a tab. It is opened from Profile through the
password gate and is protected server-side by a five-minute unlock.

Leaving the Profile tab, or putting the app in the background, clears the
Profile back stack so payroll cannot reappear without a fresh password
confirmation.

On `/mobile/sign_in` or a `404`, `MainActivity` clears the stored id and
returns to `SignInActivity` with a cleared task. Company ids are UUIDs
(PostgreSQL `uuidv7`), not numeric ids.

---

## 2. Shell

Native activities:

| Activity | Purpose |
|---|---|
| `SignInActivity` | Launcher; loads `/mobile/sign_in`; no bottom navigation; stores the company id from the post-login redirect. |
| `MainActivity` | Authenticated shell; builds the five company-scoped tab roots (Home, Notifications, Profile, Attendance, Operations) from the stored id; clears the Profile stack on tab exit/background; returns to sign-in on auth loss. |

`app/views/layouts/mobile.html.erb`:

- `viewport-fit=cover` + `pt-[env(safe-area-inset-top)]` on the sticky header.
- Dark-mode pre-paint from `localStorage["darkmode"]` (same key as desktop).
- Inter (body) / Plus Jakarta Sans (headings) and Material Symbols Outlined, loaded from Google Fonts.
- Global flash rendering (`mobile/shared/_flash`) before `yield`.

**Shell-First contract.** Every mobile page action responds to two formats:

- `html` renders `render_mobile_shell(json_url: …)`: a single
  `<div class="min-h-dvh bg-background" data-controller="mobile--…" data-json-url="…">`.
  `Mobile::BaseController#render_mobile_shell` derives the Stimulus identifier
  from `controller_path` + `action_name` (the same derivation as the desktop
  `stimulus_controller` helper), so the shell can never drift from the JS file
  path.
- `json` renders the page payload from a private `*_payload` method. No screen
  content is rendered server-side.

The page controller fetches `data-json-url` in `connect()`, renders the screen
with the shared helpers, and shows a retry state when the fetch fails. A page
that mounts a shared web console (the five operation consoles) keeps its existing
`shell_html` div with the ids that controller needs; every other page uses
`render_mobile_shell`.

Failed native form POSTs (sign-in, payroll unlock, new request) re-render the
same shell with HTTP 422 plus `data-errors` and `data-values`. The page controller
renders the errors inline and restores what the user typed (passwords are never
restored).

The only server-rendered screens left are the layout-level `_flash` partial and
`mobile/shared/suspended.html.erb` (the 403 boundary, which has no data and no
page controller).

Page chrome and formatting live in
`app/javascript/controllers/helpers/mobile_helpers.js`: header, avatar, stat
tile, empty state, month nav, fetch-error state, greeting, initials, duration,
12-hour times, dates/months, money, attendance/payroll badges, and
employee/business-type labels. Reused as-is: `Helpers.form`, `Helpers.fetchJson`,
`Helpers.timeFormat`, `Helpers.formatMoney`, `translate`, `toast`.

Small Stimulus controllers live in `app/javascript/controllers/mobile/`:
`theme`, `flash`, `password_visibility`, `clock`, `copy`,
`character_counter`, `select_nav`. They are local UI only — no JSON calls.

Page controllers live under
`app/javascript/controllers/mobile/companies/<resource>/<action>_controller.js`
and `app/javascript/controllers/mobile/sessions/new_controller.js`. Their
identifiers come from the file path (`mobile--companies--home--index`),
matching `render_mobile_shell`.

---

## 3. Data contract

Every value is read from persisted data. If the schema has no value yet, the
screen shows an empty/dash state instead of fabricated content.

The `.json` sibling of each GET page is the data contract. It carries raw values
only — ids, enum keys, ISO timestamps, cents, minutes and seconds. JS owns the
formatting and copy, so the server never ships a second representation of the
same screen. Errors use `{ errors: [...] }` (plural array) per
`docs/API_ERROR_FORMAT.md`.

| Screen | Payload |
|---|---|
| Sign-in | `email` (kept after a failed attempt), errors |
| Home | employee/company/branch/code, company UTC offset, company switcher, check-in state and every check-in time, today's shift/logs, monthly attendance totals, overtime, pending requests, paid-leave balance and pending days, latest published company announcement |
| Notifications | every subscribed notification (name, description, severity, created_at) |
| Profile | name/code/type/roles/category, email, phone, company, branch, departments, next shift, monthly attendance, group managers, contract renewal (`expiration_date`), Payroll entry point |
| Attendance | month summary (worked/present/absent/overtime), daily in/out/duration/status/recorded method, prev/next month and whether next is disabled |
| Operations | every accessible operation appointment for the company: Operation name/code/type, branch or warehouse location, operation workflow status, appointment workflow status; POS operations expose an **Open POS** action, Booking operations expose **Open Booking**, Reception operations expose **Open Reception**, Store Manager operations expose **Open Store Manager**, and warehouse Inventory operations expose **Open Inventory** |
| POS | Shell-First page mounted by `Companies_Operations_Pos_ShowController`; the controller hydrates products, services, categories, payment methods, cart, receipt and customer lookup from the existing web JSON endpoint |
| Booking | Shell-First page mounted by `Companies_Operations_Booking_ShowController`; the controller hydrates the facility timeline, booking blocks, KPIs, inspector and reservation form from the existing web JSON endpoint, and posts instant reservations |
| Reception | Shell-First page mounted by `Companies_Operations_Reception_ShowController`; the controller hydrates today's visit Events, customers, hosts, facility rooms, parcels and next appointments from the existing web JSON endpoint, and posts walk-in/check-out/parcel actions |
| Inventory | Shell-First page mounted by `Companies_Operations_Inventory_ShowController`; the controller hydrates vital stock metrics, the granular stock ledger, inbound/outbound freight docks, zone capacity and audit state from the existing web JSON endpoint |
| Payroll unlock | signed-in user's password; success sets a five-minute server-side unlock for the current company |
| Payroll | month, status/step, period start/end/days, disbursement date, month options, worked hours, present days, overtime minutes, salary/allowance/overtime/deductions/net amounts, currency, tax percent; only after password confirmation |
| New request | employee/branch, defaults, business types, group managers listed from `EmployeeGroup#manager` (owner fallback), errors and submitted values after a failed POST |

Rules:

- There are no hardcoded mobile sample values. Every value in the payload comes
  from the database, the session, or a Ruby constant.
- Payroll money is computed by `Payrolls::GenerateService` from the employee's
  monthly salary/allowance and the attendance month, then persisted on
  `payrolls`.
- Paid leave is read from `AttendanceBalance` + approved/pending `AttendanceLeave`
  rows. The mobile app only displays it today; there is no leave form.
- Company notices are published `Document` records (`business_type:
  announcement`) linked to the employee through
  `DocumentEmployeeAppointment`.
- Do not invent geofence validation, SSO/biometrics, QR scanning, payslip
  downloads, a mobile profile editor, or attachment uploads. Disable or omit
  them instead of shipping dead controls.
- Activity feeds show real `AttendanceLog` rows only; use the empty state
  instead of fabricated leave/payslip events.

---

## 4. Flows

**Page load** — the HTML request returns the shell; the page controller fetches
`data-json-url` and renders. A failed fetch replaces the shell content with a
retry state (never a blank screen). Turbo restores may reuse an empty shell, but
`connect()` always hydrates it again.

**Forms** — sign-in, payroll unlock and the new-request form submit natively
(`data-turbo="false"`). Success keeps the existing redirect + flash. A validation
failure returns HTTP 422 with the same shell plus `data-errors` and `data-values`;
the page controller renders the errors inline and restores the submitted values.
Check-in and sign-out are also native form posts, so their redirects and flashes
are unchanged.

**Check-in** — `POST /mobile/companies/:company_id/attendances` writes one
`AttendanceLog` (`log_type: check_in`) for the employee resolved from the URL
company. Every tap creates another check-in; the home punch card lists every
check-in time for the company-local day, using the company's timezone offset.
There is no checkout, break, or geofence check in this namespace yet.

**Attendance request** — the form posts `attendance_date`, `business_type`,
`check_in_time`, `check_out_time`, and `reason` to
`/mobile/companies/:company_id/attendance_requests`. The controller combines the
date + times into `check_in`/`check_out`, forces the employee/company/branch
from the URL employee, sets `pending`, and:

- success → redirect back to `new` with a flash toast (stays on the
  new-request screen);
- validation failure → `422` shell with `data-errors`/`data-values`; the page
  controller renders the inline errors and keeps the typed values.

Attachments and approver assignment are not modelled.

**Payroll access** — the only normal entry point is the Payroll button on
Profile. Every tap opens `/payroll/unlock`, even while an unlock is still
active. `POST /payroll/unlock` verifies the current user's password, stores
`mobile_payroll_unlock_company_id` and `mobile_payroll_unlock_expires_at` in the
session, then redirects to Payroll. Direct Payroll URLs without a valid unlock
redirect back to the gate. The unlock is scoped to one company, expires after
`MOBILE_PAYROLL_UNLOCK_WINDOW` (5 minutes), and is cleared on sign-out.

**Month browsing** — attendance uses `?month=YYYY-MM` with prev/next links that
preserve the company id. Payroll uses a `<select>` whose option values are full
company-scoped URLs (`mobile--select-nav` navigates on change). If the unlock
has expired, the next payroll request returns to the password gate with the
selected month preserved.

**POS** — `GET /mobile/companies/:company_id/operations/pos/:operation_id`
is Shell-First: the response contains only a mount `<div>` with
`data-controller="companies--operations--pos--show darkmode"` plus the company
and operation ids. The shared POS Stimulus controller fetches the web JSON
endpoint (`/companies/:company_id/operations/pos/:operation_id.json`) and renders
the catalog, cart, payment and receipt. The Operations card links with the
chosen appointment's `branch_id`; without it the resolver falls back to the
employee's branch. Tablet layout is width-driven: below `lg` the order panel
stacks under the catalog, at `lg` and above they sit side by side.

**Booking** — `GET /mobile/companies/:company_id/operations/booking/:operation_id`
uses the same Shell-First contract:
`data-controller="companies--operations--booking--show darkmode"` plus the
company, operation and employee identifiers. The shared booking controller
hydrates from `/companies/:company_id/operations/booking/:operation_id.json`
and posts instant reservations to the web endpoint. The layout is width-driven
for both orientations: phone and tablet portrait stack the timeline above the
inspector/reservation panels; landscape tablet at `lg` places the timeline
beside the inspector column. The current-time needle remains visible in the
timeline in both orientations.

**Reception** — `GET /mobile/companies/:company_id/operations/reception/:operation_id`
uses the same Shell-First contract:
`data-controller="companies--operations--reception--show darkmode"` plus the
company, operation and employee identifiers. The shared reception controller
hydrates from `/companies/:company_id/operations/reception/:operation_id.json`
and posts walk-in, check-in/check-out, parcel and host-notification actions. The
layout is width-driven for both orientations: phone portrait stacks the queue and
coordination panels; tablet portrait keeps a single column; landscape tablet at
`xl` puts the queue beside the rooms/deliveries/speed-dial panels.

**Store Manager** — `GET /mobile/companies/:company_id/operations/store_manager/:operation_id`
uses the same Shell-First contract:
`data-controller="companies--operations--store-manager--show darkmode"` plus the
company, operation and employee identifiers. The shared store manager controller
hydrates from `/companies/:company_id/operations/store_manager/:operation_id.json`
and renders today's sales KPIs, fulfillment queue, shelf alerts, registers,
hourly order volume and the on-duty roster. The layout is width-driven for both
orientations: phone and tablet portrait stack the fulfillment/replenishment
column above the register/footfall/roster column; landscape tablet at `lg`
places the two columns side by side. Tables scroll horizontally inside their
cards instead of widening the page.

**Inventory** — `GET /mobile/companies/:company_id/operations/inventory/:operation_id`
uses the same Shell-First contract:
`data-controller="companies--operations--inventory--show darkmode"` plus the
company, operation and employee identifiers. Inventory is warehouse-scoped, so
the Operations list links with the appointment's `warehouse_id`; without it the
resolver falls back to a warehouse under the employee's branch. The shared
inventory controller hydrates from
`/companies/:company_id/operations/inventory/:operation_id.json` and renders
stock metrics, the granular stock ledger, inbound/outbound freight docks, zone
capacity and audit state. The layout is width-driven for both orientations:
phone and tablet portrait stack the ledger/BOM column above the docks/zone/audit
column; landscape tablet at `lg` places the two columns side by side. Tables
scroll horizontally inside their cards instead of widening the page.

---

## 5. Styling

- Default Tailwind classes only, Tailwind v4, no config file.
- Responsive: phone-first; use `md:` (tablet) and `lg:` (desktop) to widen
  containers (`max-w-lg md:max-w-2xl lg:max-w-4xl xl:max-w-5xl`) and to
  upgrade grids (`md:grid-cols-3`, `md:gap-4`). Never ship a phone-only
  fixed width on tablet breakpoints.
- Semantic tokens only: `bg-card`, `text-foreground`, `text-muted-foreground`,
  `border-line`, `bg-primary`, `text-danger`, `bg-success/10`, … Never raw
  palette classes (`bg-white`, `text-slate-500`) and never `dark:` on a themed
  color — the CSS variable switches itself. `bin/check_colors --strict` scans
  both `app/javascript` and `app/views`.
- Every card/tile has a border or distinct background in light **and** dark.
- Every clickable has `cursor-pointer`.
- No HTML bottom tab bar; the native shell provides it.
- Safe-area is the only arbitrary-value exception:
  `pt-[env(safe-area-inset-top)]` and the flash offset.

---

## 6. Tests

```bash
bundle exec parallel_rspec -n 14 \
  spec/features/mobile \
  spec/requests/mobile
```

Coverage:

| File | Covers |
|---|---|
| `spec/features/mobile/sign_in_spec.rb` | form, password toggle, invalid/valid auth, company-scoped redirect, sign-out |
| `spec/features/mobile/home_spec.rb` | dashboard data, paid leave, company notice, check-in, company switcher, dark toggle, auth redirect |
| `spec/features/mobile/check_in_spec.rb` | log creation, employee/company stamping, multiple check-ins, company-local day/timezone |
| `spec/features/mobile/employee_info_spec.rb` | Profile title, sections, Payroll gate entry, group managers/contract, disabled editor, back/sign-out |
| `spec/features/mobile/attendance_month_spec.rb` | summary, daily rows, prev/next, empty state |
| `spec/features/mobile/operations_spec.rb` | current-company operation list, another company's records hidden, empty state, auth |
| `spec/features/mobile/pos_spec.rb` | Shell-First hydration, catalog, add-to-cart, ORDER/payment/receipt, Operations link, non-POS operations, missing appointment |
| `spec/features/mobile/booking_spec.rb` | Shell-First hydration, Operations link, tablet portrait/landscape layouts, real facility/booking data |
| `spec/features/mobile/reception_spec.rb` | Shell-First hydration, Operations link, phone portrait, tablet portrait/landscape layouts, walk-in check-in, non-reception operations |
| `spec/features/mobile/store_manager_spec.rb` | Shell-First hydration, Operations link, phone portrait/landscape, tablet portrait/landscape layouts, real sales/stock/roster data |
| `spec/features/mobile/inventory_spec.rb` | Shell-First hydration, Operations link, phone portrait/landscape, tablet portrait/landscape layouts, real stock ledger data |
| `spec/features/mobile/payroll_spec.rb` | password gate, every-entry prompt, wrong password, status, real money amounts, timesheet link, disabled payslip, month switch |
| `spec/features/mobile/attendance_request_spec.rb` | valid submit, group managers, validation errors, future date, auth |
| `spec/requests/mobile/attendances_controller_spec.rb` | check-in, multiple check-ins, cross-tenant 404 |
| `spec/requests/mobile/home_controller_spec.rb` | shell-only response, company-local check-in state and UTC offset |
| `spec/requests/mobile/payrolls_controller_spec.rb` | gate redirect, correct/incorrect password, five-minute expiry, no data leak |
| `spec/requests/mobile/attendance_requests_controller_spec.rb` | pending create, permission failure, cross-tenant 404 |
| `spec/requests/mobile/pos_controller_spec.rb` | Shell-First response, missing/inactive appointment redirect, non-POS 404, cross-tenant 404 |
| `spec/requests/mobile/reception_controller_spec.rb` | Shell-First response, missing/inactive appointment redirect, non-reception 404, cross-tenant 404 |
| `spec/requests/mobile/store_manager_controller_spec.rb` | Shell-First response, missing/inactive appointment redirect, non-store-manager 404, cross-tenant 404 |
| `spec/requests/mobile/inventory_controller_spec.rb` | Shell-First response, missing/inactive appointment redirect, non-inventory 404, cross-tenant 404 |
| `spec/requests/mobile/company_scoping_spec.rb` | member access (shell + JSON), cross-tenant 404, malformed company id |
| `spec/requests/mobile/shell_first_spec.rb` | shell-only HTML plus JSON payload for notifications, operations, attendance month and profile |
| `spec/requests/mobile/sessions_controller_spec.rb` | sign-in shell, empty JSON payload, invalid credentials (errors + email), valid redirect |

Native date/time inputs are unreliable through Selenium `send_keys`; the
request feature spec sets them through the DOM with `set_native_field`.

---

## 7. Known limitations / next

- Multi-employee/company switching is still first/last used; the tenant picker
  is not wired. The URL structure already supports a picker.
- No checkout, break, geofence validation, request attachments, leave-request
  form/history, announcement management UI, or payslip/PDF download. Payroll
  money and seeded leave/notice data are real; the remaining items are not
  modelled yet.
- Operations is a read-only operation-appointment list with built actions for
  POS, Booking, Reception and Store Manager branch appointments and Inventory
  warehouse appointments. Other operation types, filtering, and other actions
  are not built yet.
- Mobile POS reuses the web POS page: it has no mobile-specific order list,
  receipt printing, or offline mode. The POS page's Orders link still points at
  the web Orders page.
- Mobile/tablet Reception reuses the web reception console; there is no native
  visitor/parcel workflow, offline queue, or badge-printer integration.
- Mobile/tablet Store Manager reuses the web store manager console; there is no
  native register/cash-drawer or footfall sensor integration, and the footfall
  panel reports that the sensor is not connected.
- Mobile copy lives in `dictionary.js` and renders through `translate()`.
  Missing entries fall back to the English key, so add the entry whenever a
  string moves or changes.
- `/mobile/home` is not a server route. The Android `CompanyUrl.isMobileHome`
  check is therefore dormant; sign-in either redirects to the member's company
  home or back to `/mobile/sign_in`.
- A suspended company sees a 403 page on mobile; there is no mobile top-up flow
  yet, so recovery happens on the web.
- No HTML tab bar; browser-only users navigate through Home quick actions.
- Payroll is deliberately absent from Home and the bottom tabs. The only entry
  point is Profile, followed by the password gate.
- The Android shell stores the last company id in `SharedPreferences`. It is a
  routing hint only; the server checks membership on every request.

---

## 8. File map

```
app/views/layouts/mobile.html.erb
app/views/mobile/shared/_flash.html.erb
app/views/mobile/shared/suspended.html.erb
app/controllers/mobile/{base,sessions}_controller.rb
app/controllers/mobile/companies/
app/controllers/mobile/companies/operations/{pos,booking,reception,store_manager,inventory}_controller.rb
app/javascript/controllers/helpers/mobile_helpers.js
app/javascript/controllers/mobile/companies/{home,notifications,employees,attendance_months,operations,payrolls,payroll_unlocks,attendance_requests}/
app/javascript/controllers/mobile/sessions/new_controller.js
app/javascript/controllers/mobile/{theme,flash,password_visibility,clock,copy,character_counter,select_nav}_controller.js
android/.../SignInActivity.kt
android/.../MainActivity.kt
android/.../SkycomWebFragment.kt
android/.../CompanyStore.kt
android/.../CompanyUrl.kt
spec/features/mobile/
spec/requests/mobile/
```
