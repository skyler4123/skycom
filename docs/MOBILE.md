# Skycom Mobile (Hotwire Native)

Server-rendered `/mobile/*` pages inside the Android Hotwire Native shell.
No desktop sidebar/workspace, no JSON page endpoints, no HTML tab bar — the
native app owns the five-tab bottom navigation.

> Feature parity, pending work, and the Android shell audit live in
> [`docs/MOBILE_FEATURE_MATRIX.md`](MOBILE_FEATURE_MATRIX.md).

---

## 1. Routes and pages

| Route | Controller#action | View |
|---|---|---|
| `GET/POST /mobile/sign_in` | `Mobile::SessionsController#new/create` | `mobile/sessions/new` |
| `DELETE /mobile/sign_out` | `Mobile::SessionsController#destroy` | redirect |
| `GET /mobile/home` | `Mobile::HomeController#index` | `mobile/home/index` |
| `GET /mobile/employee` | `Mobile::EmployeesController#show` | `mobile/employees/show` |
| `GET /mobile/attendance_month` | `Mobile::AttendanceMonthsController#show` | `mobile/attendance_months/show` |
| `GET /mobile/payroll` | `Mobile::PayrollsController#show` | `mobile/payrolls/show` |
| `GET /mobile/attendance_requests/new` | `Mobile::AttendanceRequestsController#new` | `mobile/attendance_requests/new` |
| `POST /mobile/attendance_requests` | `Mobile::AttendanceRequestsController#create` | redirect / 422 re-render |
| `POST /mobile/attendances` | `Mobile::AttendancesController#create` | redirect |

The Android tab roots (`android/.../MainActivity.kt`) point at `home`,
`employee`, `attendance_month`, `payroll`, and `attendance_requests/new`.
Keep those paths stable unless the native shell is updated in the same change.

---

## 2. Shell

`app/views/layouts/mobile.html.erb`:

- `viewport-fit=cover` + `pt-[env(safe-area-inset-top)]` on the sticky header.
- Dark-mode pre-paint from `localStorage["darkmode"]` (same key as desktop).
- Material Symbols Outlined font.
- Global flash rendering (`mobile/shared/_flash`) before `yield`.

Shared partials in `app/views/mobile/shared/`:

| Partial | Purpose |
|---|---|
| `_header` | Brand/back header, theme toggle, initials avatar |
| `_flash` | Notice/alert toast, dismiss + auto-hide |
| `_avatar` | Initials circle (no placeholder image dependency) |
| `_stat_tile` | Label/value/hint/icon card, optional `Sample` badge |
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

Real data first. A sample is only rendered when the schema genuinely has no
value, and it is always marked.

| Page | Real | Marked sample |
|---|---|---|
| Sign-in | email/password auth, errors | — |
| Home | greeting, company/branch/code, live clock, check-in state, today's shift/logs, monthly attendance %, worked time, overtime, pending requests, payroll status | paid-leave balance, company notice |
| Employee | name/code/type/roles/category, email, phone, company, branch, departments, next shift, monthly attendance | reports-to, contract renewal |
| Attendance | month summary (worked/present/absent/overtime), daily in/out/duration/status | — |
| Payroll | month, status/step, period days, worked hours, present days, overtime minutes | all money figures |
| New request | employee/branch, date, type, times, reason, validation | assigned approver |

Rules:

- `MobileHelper::PREVIEW` is the only hardcoded sample source.
- Every sample renders `mobile_sample_badge`; payroll also renders a
  page-level preview banner.
- Do not invent geofence validation, SSO/biometrics, QR scanning, payslip
  downloads, a mobile profile editor, or attachment uploads. Disable or omit
  them instead of shipping dead controls.
- Activity feeds show real `AttendanceLog` rows only; use the empty state
  instead of fabricated leave/payslip events.

---

## 4. Flows

**Check-in** — `POST /mobile/attendances` writes one `AttendanceLog`
(`log_type: check_in`) for `current_user.employees.first`. A second check-in
on the same local day is rejected. There is no checkout, break, or geofence
check in this namespace yet.

**Attendance request** — the form posts `attendance_date`, `business_type`,
`check_in_time`, `check_out_time`, and `reason`. The controller combines the
date + times into `check_in`/`check_out`, forces the employee/company/branch
from the session, sets `pending`, and:

- success → redirect back to `new` with a flash toast (stays in the native
  Requests tab);
- validation failure → `422` re-render with inline errors.

Attachments and approver assignment are not modelled.

**Month browsing** — attendance uses `?month=YYYY-MM` with prev/next links.
Payroll uses a `<select>` whose option values are full URLs
(`mobile--select-nav` navigates on change).

---

## 5. Styling

- Default Tailwind classes only, Tailwind v4, no config file.
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
| `spec/features/mobile/sign_in_spec.rb` | form, password toggle, invalid/valid auth, redirect, sign-out |
| `spec/features/mobile/home_spec.rb` | dashboard data, check-in, dark toggle, no-employee fallback, auth redirect |
| `spec/features/mobile/check_in_spec.rb` | log creation, employee/company stamping, checked-in state |
| `spec/features/mobile/employee_info_spec.rb` | profile sections, disabled editor, back/sign-out |
| `spec/features/mobile/attendance_month_spec.rb` | summary, daily rows, prev/next, empty state |
| `spec/features/mobile/payroll_spec.rb` | status, sample banner, timesheet link, disabled payslip, month switch |
| `spec/features/mobile/attendance_request_spec.rb` | valid submit, validation errors, future date, auth |
| `spec/requests/mobile/attendances_controller_spec.rb` | check-in, duplicate guard, no employee |
| `spec/requests/mobile/attendance_requests_controller_spec.rb` | pending create, permission/no-employee redirects |
| `spec/helpers/mobile_helper_spec.rb` | formatting/labels/preview helpers |

Native date/time inputs are unreliable through Selenium `send_keys`; the
request feature spec sets them through the DOM with `set_native_field`.

---

## 7. Known limitations / next

- Multi-employee/company switching is still `current_user.employees.first`.
  The mockup's tenant selector is not wired.
- No checkout, break, geofence validation, attachments, approver assignment,
  leave balances, announcements, or payroll money engine.
- Mobile ERB remains English-only; `dictionary.js` covers the new JS toasts
  (`Copied to clipboard`, copy failure).
- No HTML tab bar; browser-only users navigate through Home quick actions.

---

## 8. File map

```
app/views/layouts/mobile.html.erb
app/views/mobile/{sessions,home,employees,attendance_months,payrolls,attendance_requests}/
app/views/mobile/shared/
app/helpers/mobile_helper.rb
app/controllers/mobile/
app/javascript/controllers/mobile/
spec/features/mobile/
spec/requests/mobile/
spec/helpers/mobile_helper_spec.rb
```
