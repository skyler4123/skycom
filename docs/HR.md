# Skycom HR Module

## 1. Overview

The HR module handles shift scheduling and attendance check-in/out tracking. This feature was built with a **3-tier aggregation** approach:

```
AttendanceLogs (raw check-in/out events)
  → AttendanceRecords (per-session computed metrics)
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
| 3 | `attendance_records` | Per check-in/check-out session with metrics | employee_id, check_in_at, check_out_at, total_work_minutes, late_minutes, overtime_minutes, computed_status |
| 4 | `attendance_logs` | Immutable raw audit trail | employee_id, log_type, logged_at, latitude, longitude, wifi_ssid, device_fingerprint |
| 5 | `attendance_days` | Employee-facing daily view | employee_id, attendance_date, check_in, check_out, total_seconds_* |
| 6 | `attendance_months` | Payroll-ready monthly rollup | employee_id, month, total_work_minutes, total_late_minutes, total_overtime_minutes, total_present_days, total_absent_days |
| 7 | `attendance_policies` | Per-branch geofence configuration | branch_id, latitude, longitude, allowed_radius_meters, allowed_wifi_ssid |

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
    → AttendanceRecord created (check_in_at set, late_minutes computed)
      → ScheduledShift updated (status: active)
      
Employee checks out
  → AttendanceLog created (log_type: check_out)
    → AttendanceRecord updated (check_out_at, total_work_minutes, overtime, computed_status)
      → ScheduledShift updated (status: completed)

Nightly aggregation job
  → AttendanceRecords grouped by employee + date → AttendanceDays
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

Returns `Result.success(attendance_record)` or `Result.failure("error message")`.

Steps:
1. Load branch's `AttendancePolicy` → validate GPS distance or WiFi SSID
2. Find today's `ScheduledShift` for the employee
3. Create `AttendanceLog` (immutable audit)
4. Compute late minutes: `max(actual check-in - expected_start - grace_period, 0)`
5. Create `AttendanceRecord` with computed metrics
6. Update `ScheduledShift.status` → `:active`

### Attendance::CheckOutService

```ruby
Attendance::CheckOutService.new(
  employee: employee,
  latitude: 10.773,
  longitude: 106.694
).call
```

Steps:
1. Find open `AttendanceRecord` (check_out_at IS NULL) for the employee
2. Create `AttendanceLog`
3. Compute: total_work_minutes, early_leave_minutes, overtime_minutes
4. Update `AttendanceRecord` with computed metrics
5. Update `ScheduledShift.status` → `:completed`

---

## 5. Dashboards

Three dashboards following the Shell-First pattern, all with pagination:

| Dashboard | Route | Controller | Stimulus |
|-----------|-------|------------|----------|
| Shift Templates | `/companies/:id/shift_templates` | `Companies::ShiftTemplatesController` | `companies/shift_templates/*` |
| Shifts | `/companies/:id/schedules` | `Companies::SchedulesController` | `companies/schedules/*` |
| Attendance | `/companies/:id/attendances` | `Companies::AttendancesController` | `companies/attendances/*` |

Shift Templates has full CRUD (index, new, create, show, edit, update). Shifts shows employee rosters with date/status filters and pagination. Attendance has index (with date/employee filters, pagination) and show.

---

## 6. Permission Matrix

| Role | ShiftTemplate | ScheduledShift | AttendanceRecord |
|------|--------------|---------------|-----------------|
| Owner (bypass) | Full CRUD | Full CRUD | Full CRUD |
| Admin | Full CRUD | Full CRUD | Full CRUD |
| Manager | Full CRUD | Full CRUD | Full CRUD |
| Other roles | No access | No access | No access |

Only Owner (via `owner_role?` bypass) and Admin/Manager roles have access. Other roles (Receptionist, Dentist, etc.) cannot access HR dashboards unless explicitly granted by Owner via the Permissions UI.

---

## 7. Seeding

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

## 8. What's Built vs What's Next

### ✅ Built

| Component | Status |
|-----------|--------|
| Database tables (7) | Done |
| Models with validations | Done |
| Model specs (35 examples) | Done |
| CheckInService | Done |
| CheckOutService | Done |
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
| **Midnight crossover** | Handle shifts crossing midnight (e.g., 23:00-07:00) in attendance_records association |
| **Payroll integration** | Link attendance_months to payroll/commission engine |
| **Employee self-service** | Employee-facing dashboard to view their own attendance_days and flag issues |
| **Attendance policies UI** | CRUD dashboard for per-branch geofence configuration |

---

## 9. File Reference

| File | Purpose |
|------|---------|
| `db/migrate/*create_shift_templates.rb` | Migration |
| `db/migrate/*create_scheduled_shifts.rb` | Migration |
| `db/migrate/*create_attendance_records.rb` | Migration |
| `db/migrate/*create_attendance_logs.rb` | Migration (redesigned) |
| `db/migrate/*create_attendance_days.rb` | Migration (redesigned) |
| `db/migrate/*create_attendance_months.rb` | Migration (redesigned) |
| `db/migrate/*create_attendance_policies.rb` | Migration |
| `app/models/shift_template.rb` | Model |
| `app/models/scheduled_shift.rb` | Model |
| `app/models/attendance_record.rb` | Model |
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
