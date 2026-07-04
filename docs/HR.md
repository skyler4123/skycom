# Skycom HR Module

## 1. Overview

The HR module handles shift scheduling and attendance check-in/out tracking. This feature was built with a **3-tier aggregation** approach:

```
AttendanceLogs (raw check-in/out events)
  → AttendanceDays (daily rollup per employee)
    → AttendanceMonths (monthly payroll rollup)
```

The system supports multiple business types (retail, hospital) through the same shift/attendance tables, with different shift templates per clinic/branch.

---

## 2. Tables

| # | Table | Purpose | Key Columns |
|---|-------|---------|-------------|
| 1 | `shift_templates` | Reusable shift definitions | name, start_time, end_time, grace_period_minutes, unpaid_break_minutes |
| 2 | `scheduled_shifts` | Employee roster (who works when) | employee_id, work_date, expected_start_at, expected_end_at, status |
| 3 | `attendance_logs` | Immutable raw audit trail | employee_id, log_type, logged_at, latitude, longitude, wifi_ssid, device_fingerprint |
| 4 | `attendance_days` | Employee-facing daily view | employee_id, attendance_date, check_in, check_out, total_seconds_* |
| 5 | `attendance_months` | Payroll-ready monthly rollup | employee_id, month, total_work_minutes, total_late_minutes, total_overtime_minutes, total_present_days, total_absent_days |
| 6 | `attendance_policies` | Per-branch geofence + resolution config | branch_id, latitude, longitude, allowed_radius_meters, resolution_strategy |

All tables include the standard System Fields Block (lifecycle_status, workflow_status, business_type, metadata, discarded_at, permission_resource_name).

### Key Design Decisions

- **No `period` association**: Direct time fields (start_time, end_time, check_in_at) instead of linking to shared Period records
- **Employee-linked**: All tables reference `employee_id` (not `user_id`), matching Skycom's HR model
- **Metrics pre-computed**: Attendance records store computed values (late_minutes, overtime_minutes) for fast payroll queries without runtime calculation
- **Statuses accepted for `computed_status`**: `pending`, `present`, `half_day`, `late`, `missing_checkout`

---

## 3. Data Flow

```
Employee checks in via mobile app
  → AttendanceLog created (log_type: check_in, with GPS)
    → ScheduledShift updated (status: active)

Employee checks out
  → AttendanceLog created (log_type: check_out)
    → ScheduledShift updated (status: completed)

Daily resolution engine (nightly or on-demand)
  → AttendanceLogs grouped by employee + date → segments → AttendanceDay
    → AttendanceDays grouped by employee + month → AttendanceMonths
```

---

## 4. Services

### Attendance::CheckInService

```ruby
Attendance::CheckInService.new(
  employee: employee,
  branch: branch,
  latitude: 10.773,
  longitude: 106.694,
  wifi_ssid: "Clinic_WiFi"
).call
```

Returns `Result.success(scheduled_shift)` or `Result.failure("error message")`.

Steps:
1. Load branch's `AttendancePolicy` → validate GPS distance or WiFi SSID
2. Find today's `ScheduledShift` for the employee
3. Create `AttendanceLog` (immutable audit)
4. Update `ScheduledShift.status` → `:active`

### Attendance::CheckOutService

```ruby
Attendance::CheckOutService.new(
  employee: employee,
  latitude: 10.773,
  longitude: 106.694
).call
```

Steps:
1. Create `AttendanceLog` (immutable check-out event)
2. The daily resolution engine (see Section 5) computes metrics from logs

---

## 5. Daily Resolution Engine

Phase 1 (AttendanceLogs) collects raw timestamps. Phase 2 resolves them into daily attendance states using a **strategy pattern** dispatched by `Attendance::DailyResolutionService`:

```
AttendanceLogs (raw sequential timestamps)
  → ResolutionStrategy (configured per branch via AttendancePolicy)
    → Segment Fusion (pair In/Out into work segments)
      → Break Deduction (fixed lunch, multi-punch, or auto-deduct)
        → Policy Match (compare net minutes against shift template)
          → AttendanceDay (daily status: full_day, half_day, underhours)
```

### Strategy Architecture

Each branch's `AttendancePolicy` has a `resolution_strategy` enum that determines how logs are resolved:

| Enum | Strategy Class | Behavior |
|------|---------------|----------|
| `paired` (default) | `Strategies::PairedStrategy` | Standard check_in → check_out paired segments |
| `check_in_only` | `Strategies::CheckInOnlyStrategy` | First-to-last check_in virtual segment for devices that only record arrivals |

`DailyResolutionService` loads the branch's policy and dispatches to the correct strategy class:

```ruby
STRATEGIES = {
  "paired" => Strategies::PairedStrategy,
  "check_in_only" => Strategies::CheckInOnlyStrategy
}.freeze
```

To add a new resolution strategy, create a class under `Strategies::` that implements `call(logs, employee, date, shift_template)` returning `{ status:, net_minutes:, segments:, late_minutes:, early_leave_minutes:, overtime_minutes: }`, register it in `STRATEGIES`, and add the enum value to `AttendancePolicy`.

### Step 1: Segment Fusion

Gather all AttendanceLog entries for one employee on one day, sorted chronologically.

**With check_out events:** Pair them sequentially:

- Punch 1 (In) → Punch 2 (Out) = Work Segment A
- Punch 3 (In) → Punch 4 (Out) = Work Segment B

If an "In" has no matching "Out" before end of day, the segment is invalid — flagged for manager review.

**Check-in only devices (no check_out):** Some companies use devices that only record check-in events. In this case, create a single virtual segment from the **first check_in** to the **last check_in**:

- First check_in = arrival time
- Last check_in = last known presence at work
- Duration = last_check_in - first_check_in

This gives the total time span at work. Break deduction and policy matching proceed normally. If the last check_in is before the expected end time, the employee is flagged with under-hours or early departure.

### Step 2: Calculate Gross Minutes

Sum all segment durations:

```
Gross = Duration(A) + Duration(B) + ...
```

### Step 3: Break Deduction

| Scenario | Behavior |
|----------|----------|
| **Fixed Lunch Window** (e.g. 12:00-13:00 unpaid) | Auto-deduct break time if segments overlap the window |
| **Multi-Punch Breaks** (employee clocks out for lunch) | Break is already absent from segments — no deduction needed |
| **Auto-Deduct** (no lunch punch, but policy requires break) | Subtract mandatory break (e.g. 60min) from gross if gross exceeds threshold (e.g. 5 hours) |

### Step 4: Policy Match

Three policy configurations determine the final attendance state:

| Policy | Rule | Evaluation |
|--------|------|------------|
| **Fixed Shift** | Must work specific clock hours | Net ≥ 480min AND check-in within grace window of expected start |
| **Pure Flexible** | 8 hours anytime (e.g. 06:00-22:00 window) | Net ≥ 480min = full day; 240-479min = half day; < 240 = absent |
| **Core-Hours Flexible** | 8 hours + must cover mandatory core block | Net ≥ 480min AND a single segment covers the core block (e.g. 13:00-16:00) |

### Under-hours Deficit

Minutes below the full-time target (480min/day for 8h shift) are tracked in a monthly deficit account:

```
Daily Deficit = max(0, 480 - Net Worked Minutes)
Monthly Deficit = Σ Daily Deficits
```

This deficit rolls month-to-month. The company can set a maximum deficit threshold before triggering alerts or payroll deductions.

---

## 6. Dashboards

Three dashboards following the Shell-First pattern, all with pagination:

| Dashboard | Route | Controller | Stimulus |
|-----------|-------|------------|----------|
| Shift Templates | `/companies/:id/shift_templates` | `Companies::ShiftTemplatesController` | `companies/shift_templates/*` |
| Shifts | `/companies/:id/schedules` | `Companies::SchedulesController` | `companies/schedules/*` |
| Attendance | `/companies/:id/attendances` | `Companies::AttendancesController` | `companies/attendances/*` |

Shift Templates has full CRUD (index, new, create, show, edit, update). Shifts shows employee rosters with date/status filters and pagination. Attendance has index (with date/employee filters, pagination) and show.

---

## 7. Permission Matrix

| Role | ShiftTemplate | ScheduledShift | AttendanceDay |
|------|--------------|---------------|--------------|
| Owner (bypass) | Full CRUD | Full CRUD | Full CRUD |
| Admin | Full CRUD | Full CRUD | Full CRUD |
| Manager | Full CRUD | Full CRUD | Full CRUD |
| Other roles | No access | No access | No access |

Only Owner (via `owner_role?` bypass) and Admin/Manager roles have access. Other roles (Receptionist, Dentist, etc.) cannot access HR dashboards unless explicitly granted by Owner via the Permissions UI.

---

## 8. Seeding

Hospital enrich service creates:

| Resource | Count | Details |
|----------|-------|---------|
| Shift Templates | 6 | 3 per clinic (Morning 07-15, Afternoon 15-23, Night 23-07) |
| Scheduled Shifts | ~440 | 14 days of past shifts + future shifts per employee |
| Attendance Logs | ~800 | 2 per shift (check_in + check_out) |
| Attendance Records | ~400 | 1 per shift with computed metrics |
| Attendance Days | ~400 | Aggregated per employee per date |
| Attendance Months | ~80 | Monthly payroll rollups |
| Attendance Policies | 2 | 1 per clinic (GPS: 10.773, 106.694 / 100m radius) |

Shift seeds include realistic edge cases:
- Employees checking in 5-15 minutes early
- Some check-outs slightly late (overtime)
- Weekends are skipped (no shifts on Sat/Sun)

---

## 9. What's Built vs What's Next

### ✅ Built

| Component | Status |
|-----------|--------|
| Database tables (6) | Done |
| Models with validations | Done |
| Model specs (35 examples) | Done |
| CheckInService | Done |
| CheckOutService | Done |
| DailyResolutionService + SegmentFuser + PolicyMatcher | Done |
| Check-in only device support (virtual segments) | Done |
| Shift Templates dashboard (CRUD) | Done |
| Shifts dashboard (list) | Done |
| Attendance dashboard (list) | Done |
| Pagination on all HR dashboards | Done |
| Sidebar navigation links | Done |
| Hospital seeding (shift/attendance data) | Done |
| MOCK_OAUTH_EMAIL → hospital Manager | Done |
| Geofence calculation (Haversine) | Done |

### ⬜ Next (Future Development)

| Feature | Description |
|---------|-------------|
| **Check-in/out API endpoints** | REST endpoints under `/companies/:id/attendances/check_in` and `/check_out` for mobile integration |
| **Redis throttle** | Prevent duplicate check-ins within 10 seconds using Kredis flag |
| **QR code check-in** | Generate per-branch QR codes; scanning validates location and creates log |
| **Mobile GPS native** | Native mobile app integration with background location tracking |
| **Nightly SyncAttendanceJob** | Cron job to auto-close stale sessions (>16h open) and aggregate days → months |
| **Daily Resolution Engine** | Background job that fuses AttendanceLogs into segments, deducts breaks, evaluates against policy (Fixed Shift, Pure Flexible, Core-Hours Flexible) |
| **Multi-punch support** | Handle multiple In/Out pairs per day for lunch breaks and flexible schedules |
| **Flexible time policies** | Support Pure Flexible and Core-Hours Flexible in addition to Fixed Shift |
| **Under-hours deficit tracking** | Monthly account tracking minutes below full-time target |
| **Core hours enforcement** | Flag policy violations when core hours are missed even if total hours are met |
| **Midnight crossover** | Handle shifts crossing midnight (e.g., 23:00-07:00) in scheduled_shift association |
| **Payroll integration** | Link attendance_months to payroll/commission engine |
| **Employee self-service** | Employee-facing dashboard to view their own attendance_days and flag issues |
| **Attendance policies UI** | CRUD dashboard for per-branch geofence configuration |

---

## 10. File Reference

| File | Purpose |
|------|---------|
| `db/migrate/*create_shift_templates.rb` | Migration |
| `db/migrate/*create_scheduled_shifts.rb` | Migration |
| `db/migrate/*create_attendance_logs.rb` | Migration (redesigned) |
| `db/migrate/*create_attendance_days.rb` | Migration (redesigned) |
| `db/migrate/*create_attendance_months.rb` | Migration (redesigned) |
| `db/migrate/*create_attendance_policies.rb` | Migration |
| `app/models/shift_template.rb` | Model |
| `app/models/scheduled_shift.rb` | Model |
| `app/models/attendance_log.rb` | Model (redesigned) |
| `app/models/attendance_day.rb` | Model (redesigned) |
| `app/models/attendance_month.rb` | Model (redesigned) |
| `app/models/attendance_policy.rb` | Model |
| `app/services/attendance/check_in_service.rb` | Service |
| `app/services/attendance/check_out_service.rb` | Service |
| `app/services/seed/shift_template_service.rb` | Seed service |
| `app/controllers/companies/shift_templates_controller.rb` | Controller |
| `app/controllers/companies/schedules_controller.rb` | Controller |
| `app/controllers/companies/attendances_controller.rb` | Controller |
| `app/policies/companies/shift_templates_policy.rb` | Pundit policy |
| `app/policies/companies/schedules_policy.rb` | Pundit policy |
| `app/policies/companies/attendances_policy.rb` | Pundit policy |
| `app/javascript/controllers/companies/shift_templates/*` | Stimulus (5 files) |
| `app/javascript/controllers/companies/schedules/*` | Stimulus (1 file) |
| `app/javascript/controllers/companies/attendances/*` | Stimulus (1 file) |
| `spec/models/*_spec.rb` | Model specs (7 files) |
