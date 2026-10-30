# Skycom Mobile Feature Matrix

> **Last verified:** 2026-10-27
> **Scope:** Android Hotwire Native app + the server-rendered
> `/mobile/companies/:company_id/*` pages.
> **Purpose:** the single place to compare mobile with web, track what works,
> and decide what to build next.

## 0. How to read this

Mobile is an **employee self-service companion**, not a full ERP client. It
currently mirrors the web **My Profile** group (Employee, Attendance, Payroll)
and adds a Home dashboard and an attendance-request form. Everything else in
the web sidebar is classified as web-only unless it is explicitly listed as a
mobile backlog item.

| Badge | Meaning |
|---|---|
| ✅ | Available on mobile and usable end to end |
| 🟡 | Partial: limited or read-only mobile version |
| 🚧 | Planned mobile work, not built |
| ⛔ | Web-only by design for mobile v1 |
| 💤 | The web feature itself is coming soon |
| ❓ | Broken or stale route/model/controller |

Source files for the inventory:

- Web surface: `app/javascript/controllers/companies/sidebar_items.js`
- Web routes: `config/routes.rb`
- Mobile routes/controllers: `config/routes.rb` (`namespace :mobile`) + `app/controllers/mobile/`
- Mobile views: `app/views/mobile/`
- Android shell: `android/app/src/main/java/com/example/skycomandroid/{SignInActivity,MainActivity}.kt`
- Mobile implementation contract: `docs/MOBILE.md`

---

## 1. Executive scorecard

| Domain | Mobile today | What works | Main gap |
|---|---|---|---|
| Auth | 🟡 | Email/password sign-in, sign-out, session cookie | Forgot password, biometrics, SSO |
| Home | 🟡 | Greeting, live clock, multi check-in state/times, today shift, monthly stats, quick actions, activity, paid-leave balance, latest company notice | No checkout/break |
| Profile | 🟡 | Own name, code, type, roles, category, email, phone, company, branch, departments, next shift, monthly totals, reports-to, contract renewal | No edit, no dynamic profiles |
| Attendance | 🟡 | Own month summary, daily rows, month navigation, check-in | No check-out, geofence, QR, request history, or PDF |
| Requests | 🟡 | Create attendance request with validation, assigned approver from manager chain | No inbox, status, or attachments |
| Payroll | 🟡 | Own status/step, period, worked hours, present days, overtime, salary/allowance/tax/net money | No payslip/PDF |
| Notifications | ⛔ | — | No inbox, unread badge, mark-read, push, or preferences |
| Leave | 🟡 | Paid-leave balance and pending days on Home, seeded leave requests | No leave request form or history |
| Schedule | 🟡 | Today/next shift read | No roster, shift list, or swap |
| Documents and help desk | ⛔ | — | Web-only; future candidates |
| Native shell | 🟡 | Five tabs, pull-to-refresh, edge-to-edge safe area, dark mode | No GPS, camera, biometrics, push, offline, or deep links |

**Headline:** 6 mobile screens, 5 native tabs, 3 write endpoints
(check-in, request create, sign-out), 3 read surfaces (profile, attendance
month, payroll). The web has **69 sidebar items** across 16 active groups plus
3 coming-soon groups.

**Biggest blockers**

1. Attendance months are not refreshed by a scheduled job in production.
2. Mobile can only check in; the HR check-out service is unused.
3. The Requests tab opens a form, not a request inbox.
4. Notifications exist on web but have no mobile surface.
5. `current_user.employees.first` is used everywhere; multi-employee users
   can see the wrong record.
6. Payroll money, paid-leave balances, and company notices are now real
   persisted data, but they are seed-only: there is no payroll-money editor,
   leave request flow, or announcement management UI yet.

---

## 2. Mobile surface inventory

| # | Screen | Route | Controller | Reads | Writes | Limits |
|---|---|---|---|---|---|---|
| 1 | Sign in | `GET/POST /mobile/sign_in` | `Mobile::SessionsController#new/create` | `User`, session | Sign in | No forgot password or biometrics; sign-in activity has no tabs |
| 2 | Home | `GET /mobile/companies/:company_id/home` | `Mobile::Companies::HomeController#index` | `Employee`, `AttendanceMonth`, `ScheduledShift`, `AttendanceLog`, `AttendanceRequest`, `Payroll`, `LeaveBalance`, `Document` | Check-in via `POST /mobile/companies/:company_id/attendances` | No checkout or break |
| 3 | Employee | `GET /mobile/companies/:company_id/employee` | `Mobile::Companies::EmployeesController#show` | `Employee` (manager), roles, departments, category, next shift, month totals | — | Read-only; no edit or dynamic profiles |
| 4 | Attendance month | `GET /mobile/companies/:company_id/attendance_month` | `Mobile::Companies::AttendanceMonthsController#show` | `AttendanceMonth`, `AttendanceDay` | — | Read-only; no PDF, collect, or request list |
| 5 | Payroll | `GET /mobile/companies/:company_id/payroll` | `Mobile::Companies::PayrollsController#show` | `Payroll` (money), `AttendanceMonth` | — | No payslip download |
| 6 | New request | `GET/POST /mobile/companies/:company_id/attendance_requests` | `Mobile::Companies::AttendanceRequestsController#new/create` | `Employee` (manager), `AttendanceRequest` | Create request | No attachments |

`GET /mobile/home` remains the signed-in no-employee fallback and renders
without a company id. Every tenant page asserts membership through
`current_user.employees`; cross-tenant requests return `404`.

Cross-cutting mobile behavior:

| Capability | Status | Notes |
|---|---|---|
| Native bottom tabs | ✅ | Owned by the Android shell; hidden on sign-in; roots use the stored company id |
| Theme toggle + persistence | ✅ | `localStorage["darkmode"]`, same key as desktop |
| Pull-to-refresh | ✅ | Enabled by the Android path configuration, except sign-in/new |
| Safe area | ✅ | HTML emits `env(safe-area-inset-top)` |
| Flash/notice toasts | ✅ | Server flash rendered as dismissible banners |
| Copy email | ✅ | Clipboard controller with toast fallback |
| English strings | 🟡 | English-only; web supports EN/VI |
| Offline | ⛔ | No service worker or native cache |
| Push | ⛔ | No FCM or notification permission |

---

## 3. Employee self-service parity

| Capability | Web | Mobile | Notes / next |
|---|---|---|---|
| Sign in | ✅ | ✅ | Email/password only |
| Sign out | ✅ | ✅ | `DELETE /mobile/sign_out` |
| Forgot password | ✅ passwordless flow | ⛔ | Not linked from mobile |
| Biometric sign-in | — | ⛔ | No native biometric permission or library |
| Home dashboard | — (web Dashboard is manager analytics) | ✅ | Mobile-only employee dashboard |
| Live clock | — | ✅ | Client-side clock |
| Check-in | ✅ manager view | ✅ | Writes one `AttendanceLog` per tap; Home lists all company-local check-ins; no geofence |
| Check-out | ✅ manager view | ⛔ | `Attendance::CheckOutService` exists |
| Break tracking | — | ⛔ | No mobile break action |
| Geofence validation | ✅ config + service | ⛔ | Mobile bypasses `Attendance::CheckInService` |
| QR check-in | — | ⛔ | No scanner; HR roadmap item |
| Today/next shift | ✅ shifts list | 🟡 | Read-only, one day at a time |
| Month summary | ✅ admin | 🟡 | Own month only |
| Daily rows | ✅ admin | ✅ | Own month |
| Month navigation | ✅ admin | ✅ | Prev/next query param |
| Attendance request create | ✅ | ✅ | Date, type, times, reason |
| Request list/status | ✅ admin | ⛔ | Requests tab is the form |
| Request approvals | ✅ manager | ⛔ | Web-only manager workflow |
| Request approver | ✅ after decision | ✅ | Derived from the employee's manager (owner/manager fallback) |
| Request attachments | — | ⛔ | No attachment association |
| Attendance PDF/audit | — | ⛔ | No endpoint; HR roadmap item |
| Payroll status/step | ✅ admin | ✅ | Draft/approved/paid |
| Payroll hours/day totals | ✅ admin | ✅ | From `AttendanceMonth` |
| Payroll money | ✅ admin | ✅ | `payrolls` money columns + `Payrolls::GenerateService` |
| Payslip/PDF | ❓ route only | ⛔ | `payslips` route has no controller/model |
| Leave balance | — | ✅ | `LeaveBalance` + approved/pending `LeaveRequest` rows on Home |
| Leave request/history | — | ⛔ | No mobile leave form or history yet |
| Notifications inbox | ✅ | ⛔ | Web controller exists |
| Unread badge | ✅ | ⛔ | Header has no bell |
| Mark read/all read | ✅ | ⛔ | Web endpoints exist |
| Push notifications | — | ⛔ | No FCM |
| Notification preferences | ✅ | ⛔ | Web config only |
| Profile edit | ✅ admin | ⛔ | Mobile edit button is disabled |
| Dynamic profiles/subprofiles | ✅ admin | ⛔ | Mobile shows basic profile only |
| Reports-to / contract | — | ✅ | `manager_id` and `expiration_date` |
| Multi-employee/company switch | ✅ employee list | ⛔ | `employees.first` everywhere |
| Dark mode | ✅ | ✅ | Shared storage key |
| Language switch | ✅ JS dictionary | ⛔ | Mobile ERB is English-only |
| Offline mode | — | ⛔ | No cache |
| Accessibility | — | ❓ | Not audited |

---

## 4. Full web inventory (69 sidebar items)

All items below are shipped on web unless marked 💤. Status is the **mobile**
status.

### My Profile

| Web item | Mobile | Reason / next |
|---|---|---|
| Employee | 🟡 | Own profile view only; web has list/create/edit |
| Attendance | 🟡 | Own month view only; web has admin list/collect |
| Payroll | 🟡 | Own status, hours, and money; no payslip |

### General

| Web item | Mobile | Reason / next |
|---|---|---|
| Dashboard | ⛔ | Manager analytics; mobile Home is a different employee dashboard |
| Analytics | ⛔ | Manager reporting |

### Notification

| Web item | Mobile | Reason / next |
|---|---|---|
| Notifications | 🚧 | P0 mobile inbox, unread badge, mark-read |
| Notification Tags | ⛔ | Admin configuration |

### Catalog

| Web item | Mobile | Reason / next |
|---|---|---|
| Products | ⛔ | ERP catalog |
| Brands | ⛔ | ERP catalog |
| Services | ⛔ | ERP catalog |

### Sales

| Web item | Mobile | Reason / next |
|---|---|---|
| Orders | ⛔ | POS/ERP |
| Customers | ⛔ | CRM |
| Customer Profiles | ⛔ | CRM |
| Customer Subprofiles | ⛔ | CRM |
| Invoices | ⛔ | Finance |
| Purchases | ⛔ | Procurement |
| Tickets | ⛔ | Generic ticketing; future candidate |
| Discounts | ⛔ | Pricing |

### Organization

| Web item | Mobile | Reason / next |
|---|---|---|
| Branches | ⛔ | Admin |
| Departments | ⛔ | Admin |
| Employees | 🟡 | Own profile only; web has list/CRUD |
| Employee Profiles | ⛔ | Dynamic profiles, admin |
| Employee Subprofiles | ⛔ | Dynamic profiles, admin |
| Facilities | ⛔ | Admin |

### Platform

| Web item | Mobile | Reason / next |
|---|---|---|
| Categories | ⛔ | Admin |
| Dynamic Properties | ⛔ | Admin |
| Dynamic Tables | ⛔ | Admin |
| Table Config Logs | ⛔ | Admin audit |
| Workflows | ⛔ | Admin |
| Pages | ⛔ | Content admin |
| Documents | ⛔ | Future candidate (employee documents) |
| Data Import | ⛔ | Admin |
| Payment Methods | ⛔ | Admin |

### Storage

| Web item | Mobile | Reason / next |
|---|---|---|
| Folders | ⛔ | Admin |
| Storage Statistics | ⛔ | Admin |

### Schedule

| Web item | Mobile | Reason / next |
|---|---|---|
| Calendar | ⛔ | Future candidate |
| Events | ⛔ | Future candidate |
| Event Configs | ⛔ | Admin |
| Event Config Logs | ⛔ | Admin audit |

### Attendance

| Web item | Mobile | Reason / next |
|---|---|---|
| Shift Templates | ⛔ | Admin |
| Shifts | 🟡 | Today/next shift read only |
| Attendance Days | ⛔ | Admin list |
| Attendance Requests | 🟡 | Create only; web has index/show/approve/reject |
| Attendance Configs | ⛔ | Admin geofence config; mobile check-in ignores it |
| Attendance Config Logs | ⛔ | Admin audit |
| Attendance Logs | ⛔ | Admin audit; mobile writes but cannot list |
| Attendance Months | 🟡 | Own read-only month |

### Inventory

| Web item | Mobile | Reason / next |
|---|---|---|
| Warehouses | ⛔ | ERP |
| Stocks | ⛔ | ERP |
| Stock Transfers | ⛔ | ERP |
| Stock Imports | ⛔ | ERP |
| Stock Exports | ⛔ | ERP |
| Stock Adjustments | ⛔ | ERP |
| Stock Pendings | ⛔ | ERP |
| Suppliers | ⛔ | ERP |

### Tax

| Web item | Mobile | Reason / next |
|---|---|---|
| Tax Data | ⛔ | Finance admin |
| Tax Config | ⛔ | Finance admin |

### Payroll

| Web item | Mobile | Reason / next |
|---|---|---|
| Payroll Data | 🟡 | Own read-only status/hours/money; no payslip |
| Payroll Config | ⛔ | Admin |

### Authorization

| Web item | Mobile | Reason / next |
|---|---|---|
| Roles | ⛔ | Admin |
| Policies | ⛔ | Admin |
| Permissions | ⛔ | Admin |
| Permission Logs | ⛔ | Admin audit |

### Coming-soon groups

| Web group | Mobile | Reason / next |
|---|---|---|
| Chat & Help Desk | 💤 | No web feature yet |
| Email Marketing | 💤 | No web feature yet |
| AI Assistant | 💤 | No web feature yet |

### Settings

| Web item | Mobile | Reason / next |
|---|---|---|
| Company | ⛔ | Admin |
| Quick Links | ⛔ | Admin |

### System (locked)

| Web item | Mobile | Reason / next |
|---|---|---|
| Usage | ⛔ | Billing/admin |
| Top Up | ⛔ | Billing/admin |
| Billing | ⛔ | Billing/admin |
| Help Center | ⛔ | Future candidate (employee support tickets) |

### Web surfaces outside the sidebar

| Surface | Web | Mobile | Notes |
|---|---|---|---|
| Passwordless sign-in, password reset, email verification | ✅ | ⛔ | Mobile has email/password sign-in only |
| Invitation | ❓ | ⛔ | Route only; no controller |
| Marketing homepage | ✅ | ⛔ | Public web |
| Admin namespace: companies, payment methods, company credits, promo campaigns, company tickets | ✅ | ⛔ | Platform admin |
| Notification config | ✅ | ⛔ | Web settings; mobile has no preferences |
| Subscription plan appointments | ❓ | ⛔ | Route only; no controller |
| Policy appointments | ❓ | ⛔ | Route only; no controller |
| Transactions | ❓ | ⛔ | Route only; no controller and no sidebar item |
| Order processing | ✅ | ⛔ | Part of Orders/ERP |
| Demo, client cache, redirect | ✅ | ⛔ | Internal/dev tooling |
| `payslips`, `announcements`, `reports` routes | ❓ | ⛔ | Routes without controller/model |
| `tasks` | ❓ | ⛔ | Model/route without a controller |

---

## 5. Pending mobile backlog

### P0 — correctness and core usability

| ID | Feature | Why | Depends on | Acceptance | Effort |
|---|---|---|---|---|---|
| M-01 | Schedule attendance resolution | Mobile attendance months read `attendance_months`, but `Attendance::DailyResolutionJob` is not in `config/recurring.yml` | Ops/queue configuration | Nightly job (or post-check-in trigger) refreshes monthly totals | S |
| M-02 | Check-out | Mobile can only check in; `Attendance::CheckOutService` exists | Mobile controller + Home UI | Clock Out writes `check_out`, guards duplicates, Home shows completed state; break tracking remains separate | S |
| M-03 | Request inbox and status | The Requests tab opens a form; employees cannot see history or decisions | `AttendanceRequestsController#index` or a mobile-only query | Own requests list with date, type, status, detail link; New Request button | M |
| M-04 | Notifications inbox and unread badge | Web notifications exist; mobile has no surface | `Companies::NotificationsController` | List, mark read/all read, unread count in the header | M |
| M-05 | Multi-employee/company selector | Every mobile controller uses `employees.first`; multi-account users can see the wrong record | Session/current-employee selection | Selector at sign-in or profile; all mobile pages scoped to the selection | M |
### P1 — self-service parity

| ID | Feature | Why | Depends on | Acceptance | Effort |
|---|---|---|---|---|---|
| M-07 | Leave request form and history | Balance/pending days are real and seeded, but employees cannot file leave on mobile | Mobile leave form + endpoints | Request, cancel, history, status | M |
| M-08 | Payslip/PDF | Payroll money is real; the `payslips` route is stale | Document generation | Downloadable payslip from persisted payroll money | M |
| M-09 | Announcement list and read tracking | Home shows the latest published `Document` notice; no list/read state | Announcement list + read tracking | List and read/unread state | M |
| M-10 | Request attachments | Approver is derived from the manager chain; no attachments | ActiveStorage + mobile upload | Optional photo/PDF proof | M |
| M-11 | Profile edit | Mobile profile is read-only | Mobile form + permitted fields | Employee can edit allowed fields (for example phone, email) | M |
| M-12 | GPS/geofence check-in | Mobile check-in bypasses `AttendanceConfig` and `CheckInService` | Android location permission + native/WebView geolocation | Check-in validates branch geofence or WiFi, with a clear failure state | L |
| M-13 | Push notifications | No FCM or `POST_NOTIFICATIONS` | Firebase + native permission + backend | Push received and opens the relevant mobile page | L |

### P2 — polish and native

| ID | Feature | Why | Depends on | Acceptance | Effort |
|---|---|---|---|---|---|
| M-14 | QR check-in | Mockup has a QR action; no scanner | QR payload design + camera permission | Scan branch QR to check in | M |
| M-15 | Biometric sign-in | Mockup has biometrics; no native library | Android BiometricPrompt + token storage | Biometric unlock after first sign-in | M |
| M-16 | Offline/cache | No service worker or native cache | Hotwire Native cache or PWA strategy | Read-only cached Home/Attendance/Payroll | L |
| M-17 | Vietnamese mobile UI | Mobile ERB is English-only | ERB translation pass or `data-i18n` runtime | All mobile strings switch with the language setting | M |
| M-18 | Native share/camera/file picker | No native wiring; no attachment model | Android intents + attachment model | Share payslip; attach photo/PDF to a request | M |
| M-19 | Accessibility audit | No mobile accessibility tests | Audit + fixes | Touch targets, labels, contrast, screen-reader pass | S |
| M-20 | Deep links and remote path config | Remote `configurations/android_v1.json` has no server route | Server endpoint + path rules | Deep links open the right tab/page; remote config loads | S |
| M-21 | Release readiness | `minifyEnabled false`, no signing config, version 1.0, default `BASE_URL` | Release signing + versioning | Signed release build, production base URL, versioning policy | S |
| M-22 | Attendance PDF/audit export | No PDF endpoint | PDF service | Download own attendance audit PDF | M |
| M-23 | Documents, calendar, help desk | Web-only today | Separate product decisions | Employee document list, event calendar, own tickets | L |

### Future candidates

These are deliberately outside mobile v1 but plausible later: Documents,
Calendar/Events, Help Center/company tickets, generic Tickets, notification
preferences, and dynamic employee profiles.

---

## 6. Android shell audit

| Area | Current | Gap / next |
|---|---|---|
| Navigation | 5 tabs: Home, Employee, Attendance, Payroll, Requests | Requests opens the form; make it an inbox with a New Request action |
| Hotwire Native | 1.3.2, fragments, lazy tabs | Keep version current |
| Path configuration | Asset `json/path-configuration.json`; pull-to-refresh on; off for sign-in/new | Remote `configurations/android_v1.json` URL has no server route; add it or drop it |
| Tabs/back | Native bottom nav; HTML sticky header | No native toolbar; HTML back link on stack pages |
| Edge-to-edge | `enableEdgeToEdge`, IME insets; HTML safe-area | Keep `env(safe-area-inset-*)` in the HTML |
| Permissions | `INTERNET` only | Missing location, camera, biometrics, notifications |
| Push | None | Firebase + `POST_NOTIFICATIONS` |
| GPS/location | None | `ACCESS_FINE_LOCATION` + runtime permission + native/WebView bridge |
| Camera/file upload | None | `CAMERA` as needed + file chooser + attachment model |
| Biometrics | None | Android BiometricPrompt |
| Offline | None | Cache strategy |
| Deep links | Launcher only | Intent filters + path configuration |
| Branding | Native theme primary `#16A34A` green; HTML primary blue-600 | Align native tab/theme accent with the web blue palette |
| Release build | `minifyEnabled false`, no signing, `versionCode 1`, default `BASE_URL` | Signing config, minify/proguard, production URL, versioning |
| Tests | Placeholder unit/instrumented tests only | Add smoke UI test for the five tabs and sign-in |
| Auth | WebView cookie session | Refresh/expiry handling and sign-out cleanup |
| Dark mode | HTML controlled | Native status/navigation bars follow the app theme, not the HTML dark class |

---

## 7. Broken or stale surfaces

| Surface | Issue | Impact | Fix |
|---|---|---|---|
| `payslips` route | No controller and no model | Visiting the route raises an error | Remove the route or build the payslip feature |
| `announcements` route | No controller and no model | Visiting the route raises an error | Remove the route or build announcements |
| `reports` route | No controller and no model | Visiting the route raises an error | Remove the route or build reports |
| `tasks` route/model | Model exists; no controller and no sidebar item | Orphan model/resource | Remove or build the UI |
| `transactions` route | No controller and no sidebar item | Visiting the route raises an error | Remove the route or build transactions |
| `policy_appointments` route | No controller | Visiting the route raises an error | Remove the route or build the UI |
| `subscription_plan_appointments` route | No controller | Visiting the route raises an error | Remove the route or build the UI |
| `invitation` route | No controller | Invitation links raise an error | Build the controller or remove the route |
| `Attendance::DailyResolutionJob` | Exists but not scheduled in `config/recurring.yml` | Attendance months can stay stale in production | Add a production schedule or trigger after check-in |
| `configurations/android_v1.json` | Remote path-config URL has no server route | Android logs a failed fetch and falls back to the asset | Add the endpoint or remove the remote URL |
| `docs/HR.md` §9 | Lists several already-built items as future | Misleading planning | Refresh the doc or link to this matrix |
| Native theme | Green native accent vs blue HTML primary | Visual mismatch in the tab bar/status bar | Align the palette |
| Android package/version | `com.example.skycomandroid`, version 1.0 | Not a production identity | Rename before release |
| Android tests | Placeholder `2 + 2` and package-name tests | No mobile regression coverage | Add tab/sign-in smoke tests |

---

## 8. Keeping this matrix current

- Add or update a row when a web sidebar item changes, or when a mobile route,
  view, controller, or Android tab changes.
- Update **Last verified** in the same pull request.
- Use the status legend exactly; do not add a new status without updating §0.
- A mobile feature is only ✅ when it has a real data source, a working write
  path where applicable, and a feature or request spec.
- A mockup value with no backend is not ✅. The mobile namespace no longer
  ships hardcoded sample values; add the model/seed data instead of a new
  `Sample` badge.
- Web-only ERP/admin features stay ⛔ unless a product decision explicitly
  moves them into the mobile backlog.

## 9. Source map

| Area | File |
|---|---|
| Web sidebar registry | `app/javascript/controllers/companies/sidebar_items.js` |
| Web routes | `config/routes.rb` |
| Mobile routes | `config/routes.rb` (`namespace :mobile`) |
| Mobile controllers | `app/controllers/mobile/` |
| Mobile views/partials | `app/views/mobile/` |
| Mobile formatting helpers | `app/helpers/mobile_helper.rb` |
| Mobile implementation contract | `docs/MOBILE.md` |
| Android shell | `android/app/src/main/java/com/example/skycomandroid/MainActivity.kt` |
| Android path config | `android/app/src/main/assets/json/path-configuration.json` |
| Android manifest | `android/app/src/main/AndroidManifest.xml` |
| Android theme | `android/app/src/main/res/values/themes.xml` |
| Attendance jobs | `app/jobs/attendance/`, `config/recurring.yml` |
| Payroll generation | `app/services/payrolls/generate_service.rb` |
| Notifications | `app/controllers/companies/notifications_controller.rb` |
