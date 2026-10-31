# Skycom Mobile (Hotwire Native)

Server-rendered mobile pages inside the Android Hotwire Native shell. Tenant
pages are scoped to the company in the URL (`/mobile/companies/:company_id/*`);
the native app owns the five-tab bottom navigation and shows it only after
authentication.

> Feature parity, pending work, and the Android shell audit live in
> [`docs/MOBILE_FEATURE_MATRIX.md`](MOBILE_FEATURE_MATRIX.md).

---

## 1. Routes and pages

| Route | Controller#action | View |
|---|---|---|
| `GET/POST /mobile/sign_in` | `Mobile::SessionsController#new/create` | `mobile/sessions/new` |
| `DELETE /mobile/sign_out` | `Mobile::SessionsController#destroy` | redirect |
| `GET /mobile/home` | `Mobile::HomeController#index` | `mobile/companies/home/index` (no-employee fallback) |
| `GET /mobile/companies/:company_id/home` | `Mobile::Companies::HomeController#index` | `mobile/companies/home/index` |
| `GET /mobile/companies/:company_id/notifications` | `Mobile::Companies::NotificationsController#index` | `mobile/companies/notifications/index` |
| `GET /mobile/companies/:company_id/employee` | `Mobile::Companies::EmployeesController#show` | `mobile/companies/employees/show` (Profile) |
| `GET /mobile/companies/:company_id/attendance_month` | `Mobile::Companies::AttendanceMonthsController#show` | `mobile/companies/attendance_months/show` |
| `GET /mobile/companies/:company_id/operations` | `Mobile::Companies::OperationsController#index` | `mobile/companies/operations/index` |
| `GET /mobile/companies/:company_id/payroll/unlock` | `Mobile::Companies::PayrollUnlocksController#new` | `mobile/companies/payroll_unlocks/new` |
| `POST /mobile/companies/:company_id/payroll/unlock` | `Mobile::Companies::PayrollUnlocksController#create` | redirect / 422 re-render |
| `GET /mobile/companies/:company_id/payroll` | `Mobile::Companies::PayrollsController#show` | `mobile/companies/payrolls/show` |
| `GET /mobile/companies/:company_id/attendance_requests/new` | `Mobile::Companies::AttendanceRequestsController#new` | `mobile/companies/attendance_requests/new` |
| `POST /mobile/companies/:company_id/attendance_requests` | `Mobile::Companies::AttendanceRequestsController#create` | redirect / 422 re-render |
| `POST /mobile/companies/:company_id/attendances` | `Mobile::Companies::AttendancesController#create` | redirect |

`Mobile::Companies::BaseController` resolves the employee through
`current_user.employees.find_by!(company_id: params[:company_id])`. A company
the user does not belong to returns `404`; the stored company id on the device
is never treated as authorization.

### Suspended company block

`Mobile::Companies::SuspendedCompanyConcern` runs after mobile authorization on
every `/mobile/companies/:company_id/*` page. A company with
`workflow_status: suspend` gets a `403` mobile-layout notice (“top up on the
web”); mobile has no top-up flow. Mobile sign-in, `/mobile/home`, and the
company picker are not company-scoped and stay reachable. See
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

On `/mobile/sign_in`, `/mobile/home`, or a `404`, `MainActivity` clears the
stored id and returns to `SignInActivity` with a cleared task. Company ids are
UUIDs (PostgreSQL `uuidv7`), not numeric ids.

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

Shared partials in `app/views/mobile/shared/`:

| Partial | Purpose |
|---|---|
| `_header` | Brand/back header, theme toggle, initials avatar |
| `_flash` | Notice/alert toast, dismiss + auto-hide |
| `_avatar` | Initials circle (no placeholder image dependency) |
| `_stat_tile` | Label/value/hint/icon card |
| `_empty_state` | Dashed empty state |
| `_month_nav` | Previous/next month links with disabled next |

Helpers live in `app/helpers/mobile_helper.rb`: greeting, initials, duration
formatting, 12-hour times, dates/months, attendance rate, status badges,
employee/business-type labels, and preview values.

Small Stimulus controllers live in `app/javascript/controllers/mobile/`:
`theme`, `flash`, `password_visibility`, `clock`, `copy`,
`character_counter`, `select_nav`. They are local UI only — no JSON calls.

---

## 3. Data contract

Every value is read from persisted data. If the schema has no value yet, the
screen shows an empty/dash state instead of fabricated content.

| Page | Real data |
|---|---|
| Sign-in | email/password auth, errors |
| Home | greeting, company/branch/code, live clock, multi check-in state/times, today's shift/logs, monthly attendance %, worked time, overtime, pending requests, paid-leave balance and pending days, latest published company announcement |
| Profile | name/code/type/roles/category, email, phone, company, branch, departments, next shift, monthly attendance, group managers, contract renewal (`expiration_date`), Payroll entry point |
| Attendance | month summary (worked/present/absent/overtime), daily in/out/duration/status |
| Operations | every `Page` for the company: name/code, branch, business type, target role, target resolution, lifecycle/workflow status |
| Payroll unlock | signed-in user's password; success sets a five-minute server-side unlock for the current company |
| Payroll | month, status/step, period days, worked hours, present days, overtime minutes, salary/allowance/overtime/tax/social/net amounts; only after password confirmation |
| New request | employee/branch, date, type, times, reason, validation, group managers listed from `EmployeeGroup#manager` (owner fallback) |

Rules:

- There are no hardcoded mobile sample values. `MobileHelper::PREVIEW` and
  `mobile_sample_badge` were removed.
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
- validation failure → `422` re-render with inline errors.

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

---

## 5. Styling

- Default Tailwind classes only, Tailwind v4, no config file.
- Responsive: phone-first; use `md:` (tablet) and `lg:` (desktop) to widen
  containers (`max-w-lg md:max-w-2xl lg:max-w-4xl xl:max-w-5xl`) and to
  upgrade grids (`md:grid-cols-3`, `md:gap-4`). Never ship a phone-only
  fixed width on tablet breakpoints.
- Skycom palette: `blue-600/700` primary, `slate` surfaces/text, `green`
  success, `amber` pending, `red` error.
- Every card/tile has a border or distinct background in light **and** dark.
- Every text has a `dark:` variant; every clickable has `cursor-pointer`.
- No HTML bottom tab bar; the native shell provides it.
- Safe-area is the only arbitrary-value exception:
  `pt-[env(safe-area-inset-top)]` and the flash offset.

---

## 6. Tests

```bash
bundle exec parallel_rspec -n 14 \
  spec/features/mobile \
  spec/requests/mobile \
  spec/helpers/mobile_helper_spec.rb
```

Coverage:

| File | Covers |
|---|---|
| `spec/features/mobile/sign_in_spec.rb` | form, password toggle, invalid/valid auth, company-scoped redirect, sign-out |
| `spec/features/mobile/home_spec.rb` | dashboard data, paid leave, company notice, check-in, dark toggle, no-employee fallback, company redirect, auth redirect |
| `spec/features/mobile/check_in_spec.rb` | log creation, employee/company stamping, multiple check-ins, company-local day/timezone |
| `spec/features/mobile/employee_info_spec.rb` | Profile title, sections, Payroll gate entry, group managers/contract, disabled editor, back/sign-out |
| `spec/features/mobile/attendance_month_spec.rb` | summary, daily rows, prev/next, empty state |
| `spec/features/mobile/operations_spec.rb` | current-company page list, another company's records hidden, empty state, auth |
| `spec/features/mobile/payroll_spec.rb` | password gate, every-entry prompt, wrong password, status, real money amounts, timesheet link, disabled payslip, month switch |
| `spec/features/mobile/attendance_request_spec.rb` | valid submit, group managers, validation errors, future date, auth |
| `spec/requests/mobile/attendances_controller_spec.rb` | check-in, multiple check-ins, cross-tenant 404 |
| `spec/requests/mobile/home_controller_spec.rb` | company-local day/timezone for check-ins |
| `spec/requests/mobile/payrolls_controller_spec.rb` | gate redirect, correct/incorrect password, five-minute expiry, no data leak |
| `spec/requests/mobile/attendance_requests_controller_spec.rb` | pending create, permission failure, cross-tenant 404 |
| `spec/requests/mobile/company_scoping_spec.rb` | member access, cross-tenant 404, malformed company id |
| `spec/helpers/mobile_helper_spec.rb` | formatting/labels/preview helpers |

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
- Operations is a read-only Page list. Opening a page, filtering, and page
  actions are not built yet.
- Mobile ERB remains English-only; `dictionary.js` covers the new JS toasts
  (`Copied to clipboard`, copy failure).
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
app/views/mobile/sessions/
app/views/mobile/companies/{home,employees,attendance_months,operations,payrolls,payroll_unlocks,attendance_requests}/
app/views/mobile/shared/
app/helpers/mobile_helper.rb
app/controllers/mobile/{base,sessions,home}_controller.rb
app/controllers/mobile/companies/
app/javascript/controllers/mobile/
android/.../SignInActivity.kt
android/.../MainActivity.kt
android/.../SkycomWebFragment.kt
android/.../CompanyStore.kt
android/.../CompanyUrl.kt
spec/features/mobile/
spec/requests/mobile/
spec/helpers/mobile_helper_spec.rb
```
