import { Controller } from "@hotwired/stimulus"
import { escapeHtml, translate } from "controllers/helpers/ui_helpers"
import {
  mobileHeader,
  mobileMain,
  mobileAvatar,
  mobileStatTile,
  mobileEmptyState,
  mobileMonthNav,
  mobileDate,
  mobileWeekday,
  mobileTime,
  mobileDuration,
  mobileDurationFromSeconds,
  mobileMonthLabel,
  mobileAttendanceBadge,
  renderMobileError
} from "controllers/helpers/mobile_helpers"

// Mobile attendance month — summary tiles plus every daily record, with
// previous/next month navigation.
// Depends on BE: Mobile::Companies::AttendanceMonthsController#show
// Endpoints: GET /mobile/companies/:company_id/attendance_month.json?month=YYYY-MM
// Docs: docs/MOBILE.md §2-§3
export default class Mobile_Companies_AttendanceMonths_ShowController extends Controller {
  async connect() {
    document.title = "Attendance"

    try {
      const data = await fetchJson(this.element.dataset.jsonUrl)
      this.element.innerHTML = this.contentHTML(data)
    } catch (error) {
      renderMobileError(this.element, error, () => this.connect())
    }
  }

  contentHTML(data) {
    const { company, employee, month, current_month: currentMonth } = data

    return `
      ${mobileHeader({
        title: "Attendance",
        avatarName: employee.name,
        avatarPath: Helpers.mobile_company_employee_path(company.id)
      })}
      ${mobileMain(`
        <div class="flex flex-col gap-4">
          <section class="flex items-center justify-between gap-3 rounded-xl border border-line bg-card p-4 shadow-sm">
            <div class="flex min-w-0 items-center gap-3">
              ${mobileAvatar({ name: employee.name, size: "h-10 w-10 text-xs" })}
              <div class="min-w-0">
                <p class="truncate text-base font-semibold text-foreground">${escapeHtml(employee.name)}</p>
                <p class="truncate text-xs text-muted-foreground">${escapeHtml([ employee.branch_name, company.name ].filter(Boolean).join(" • "))}</p>
              </div>
            </div>
            <span class="shrink-0 rounded-full bg-primary/10 px-2 py-0.5 text-xs font-semibold text-primary">
              ${translate(currentMonth ? "Current month" : "Past month")}
            </span>
          </section>

          ${mobileMonthNav({
            label: mobileMonthLabel(month),
            prevPath: Helpers.mobile_company_attendance_month_path(company.id, { month: data.prev_month }),
            nextPath: Helpers.mobile_company_attendance_month_path(company.id, { month: data.next_month }),
            nextDisabled: data.next_disabled
          })}

          ${this.summaryHTML(data)}

          <div class="flex items-center justify-between gap-2 pt-1">
            <div class="flex items-center gap-2">
              <h2 class="text-base font-bold text-foreground">${translate("Daily Breakdown")}</h2>
              <span class="flex h-5 min-w-5 items-center justify-center rounded-full bg-muted px-1.5 text-xs font-bold text-muted-foreground">${data.attendance_days.length}</span>
            </div>
            <a href="${Helpers.new_mobile_company_attendance_request_path(company.id)}"
              class="flex cursor-pointer items-center gap-1.5 rounded-lg bg-primary px-3 py-1.5 text-xs font-semibold text-primary-foreground shadow-sm transition-colors hover:bg-primary/90">
              ${translate("New Request")}
            </a>
          </div>

          <section class="flex flex-col gap-2">
            ${this.daysHTML(data.attendance_days)}
          </section>
        </div>
      `)}
    `
  }

  summaryHTML({ attendance_month: attendanceMonth }) {
    if (!attendanceMonth) {
      return mobileEmptyState({
        title: "No summary for this month",
        hint: "Attendance totals appear once this month has been aggregated.",
        icon: "summarize"
      })
    }

    return `
      <section class="grid grid-cols-2 gap-2 md:grid-cols-3 md:gap-4">
        ${mobileStatTile({
          label: "Total Worked",
          value: mobileDuration(attendanceMonth.total_work_minutes),
          hint: `${attendanceMonth.total_work_minutes} ${translate("minutes total")}`,
          icon: "schedule"
        })}
        ${mobileStatTile({
          label: "Present Days",
          value: `${attendanceMonth.total_present_days} ${translate("Days")}`,
          hint: `${translate("of")} ${attendanceMonth.total_records} ${translate("recorded")}`,
          icon: "task_alt",
          hintClass: "text-success"
        })}
        ${mobileStatTile({
          label: "Absent",
          value: `${attendanceMonth.total_absent_days} ${translate("Days")}`,
          hint: translate("This month"),
          icon: "event_busy"
        })}
        ${mobileStatTile({
          label: "Overtime",
          value: mobileDuration(attendanceMonth.total_overtime_minutes),
          hint: translate("This month"),
          icon: "more_time"
        })}
      </section>
    `
  }

  daysHTML(days) {
    if (!days.length) {
      return mobileEmptyState({
        title: "No daily records for this month yet",
        hint: "Check in from Home or file an attendance request.",
        icon: "event_note"
      })
    }

    return days.map((day) => `
      <article class="rounded-xl border border-line bg-card p-4 shadow-sm">
        <div class="flex items-center justify-between gap-2">
          <div class="flex min-w-0 items-center gap-3">
            <div class="flex h-11 w-11 shrink-0 flex-col items-center justify-center rounded-lg border border-line bg-background">
              <span class="text-xs font-bold uppercase text-muted-foreground">${escapeHtml(mobileWeekday(day.attendance_date))}</span>
              <span class="text-base font-bold leading-none text-primary">${escapeHtml(String(day.attendance_date || "").slice(8, 10))}</span>
            </div>
            <div class="min-w-0">
              <p class="truncate text-sm font-semibold text-foreground">${escapeHtml(mobileDate(day.attendance_date))}</p>
              <p class="truncate text-xs text-muted-foreground">${escapeHtml(this.recordedLabel(day.recorded_method))}</p>
            </div>
          </div>
          ${mobileAttendanceBadge(day.attendance_status)}
        </div>

        <div class="mt-3 flex items-center justify-between gap-2 rounded-lg border border-line bg-background p-2.5">
          <div class="flex flex-wrap items-center gap-3">
            <span class="flex items-center gap-1">
              <span class="material-symbols-outlined text-base text-success">login</span>
              <span class="text-xs font-medium text-foreground">${escapeHtml(mobileTime(day.check_in))}</span>
            </span>
            <span class="text-xs text-muted-foreground">•</span>
            <span class="flex items-center gap-1">
              <span class="material-symbols-outlined text-base text-muted-foreground">logout</span>
              <span class="text-xs font-medium text-foreground">${escapeHtml(mobileTime(day.check_out))}</span>
            </span>
          </div>
          <span class="shrink-0 text-sm font-bold text-primary">${mobileDurationFromSeconds(day.total_seconds_worked)}</span>
        </div>
      </article>
    `).join("")
  }

  recordedLabel(method) {
    if (method === "request") return translate("Recorded via request")
    if (method === "check_in") return translate("Recorded via check-in")
    return translate("Attendance record")
  }
}
