import { Controller } from "@hotwired/stimulus"
import { escapeHtml, translate, form } from "controllers/helpers/ui_helpers"
import {
  mobileHeader,
  mobileMain,
  mobileAvatar,
  mobileStatTile,
  mobileGreeting,
  mobileTime,
  mobileDuration,
  mobileAttendanceRate,
  renderMobileError
} from "controllers/helpers/mobile_helpers"

// Mobile home — the employee dashboard: company switcher, punch card, monthly
// stats, quick actions, company notice and today's activity.
// Depends on BE: Mobile::Companies::HomeController#index
// Endpoints: GET /mobile/companies/:company_id/home.json
// Docs: docs/MOBILE.md §2-§4
export default class Mobile_Companies_Home_IndexController extends Controller {
  async connect() {
    document.title = "Home"

    try {
      const data = await fetchJson(this.element.dataset.jsonUrl)
      this.element.innerHTML = this.contentHTML(data)
    } catch (error) {
      renderMobileError(this.element, error, () => this.connect())
    }
  }

  contentHTML(data) {
    const { company, employee } = data

    return `
      ${mobileHeader({
        title: "Home",
        avatarName: employee.name,
        avatarPath: Helpers.mobile_company_employee_path(company.id)
      })}
      ${mobileMain(`
        <div class="flex flex-col gap-4">
          ${this.switcherHTML(data)}
          ${this.greetingHTML(data)}
          ${this.punchCardHTML(data)}
          ${this.statsHTML(data)}
          ${this.quickActionsHTML(data)}
          ${this.noticeHTML(data)}
          ${this.activityHTML(data)}
        </div>
      `)}
    `
  }

  switcherHTML({ company, companies = [] }) {
    if (companies.length <= 1) return ""

    const options = companies.map((option) => `
      <option value="${Helpers.mobile_company_home_path(option.id)}" ${option.id === company.id ? "selected" : ""}>
        ${escapeHtml(option.name)}
      </option>
    `).join("")

    const chips = companies.map((option) => `
      <a href="${Helpers.mobile_company_home_path(option.id)}"
        class="inline-flex items-center rounded-full border border-line bg-muted px-3 py-1 text-xs font-semibold text-foreground transition-colors hover:bg-primary/10 ${option.id === company.id ? "bg-primary/10 text-primary" : ""}">
        ${escapeHtml(option.name)}
      </a>
    `).join("")

    return `
      <section class="rounded-xl border border-line bg-card p-4 shadow-sm">
        <div class="flex items-center gap-2">
          <span class="material-symbols-outlined text-xl text-primary">business</span>
          <div class="min-w-0 flex-1">
            <label for="mobile-company-switch" class="sr-only">${translate("Company")}</label>
            <label for="mobile-company-switch" class="text-xs font-semibold uppercase tracking-wider text-muted-foreground">${translate("Switch company")}</label>
            <select id="mobile-company-switch" aria-label="${translate("Company")}" data-controller="mobile--select-nav"
              data-action="change->mobile--select-nav#navigate"
              class="mt-1 w-full cursor-pointer appearance-none rounded-lg bg-card text-sm font-semibold text-foreground outline-none">
              ${options}
            </select>
          </div>
          <span class="material-symbols-outlined pointer-events-none text-xl text-muted-foreground">expand_more</span>
        </div>
        <div class="mt-3 flex flex-wrap gap-2">${chips}</div>
      </section>
    `
  }

  greetingHTML({ company, employee }) {
    return `
      <section class="flex items-center gap-3 rounded-xl border border-line bg-card p-4 shadow-sm">
        ${mobileAvatar({ name: employee.name, size: "h-12 w-12 text-sm" })}
        <div class="min-w-0">
          <p class="truncate text-lg font-bold text-foreground">${mobileGreeting(employee.name)}</p>
          <div class="mt-1 flex flex-wrap items-center gap-1.5">
            <span class="inline-flex items-center gap-1 rounded-full bg-primary/10 px-2 py-0.5 text-xs font-semibold text-primary">
              <span class="material-symbols-outlined text-sm">business</span>
              <span class="max-w-44 truncate">${escapeHtml(company.name)}</span>
            </span>
            ${employee.code ? `<span class="text-xs font-medium text-muted-foreground">#${escapeHtml(employee.code)}</span>` : ""}
          </div>
        </div>
      </section>
    `
  }

  punchCardHTML({ company, employee, checked_in: checkedIn, today_shift: todayShift, check_in_logs: checkInLogs = [] }) {
    const offsetHours = Number(company.utc_offset || 0) / 3600
    const shiftText = todayShift
      ? `${translate("Scheduled")}: ${mobileTime(todayShift.expected_start_at, offsetHours)} – ${mobileTime(todayShift.expected_end_at, offsetHours)}`
      : translate("No shift scheduled today")

    return `
      <section class="relative overflow-hidden rounded-xl border border-line bg-card p-4 shadow-sm">
        <div class="pointer-events-none absolute -right-12 -top-12 h-40 w-40 rounded-full bg-primary/10"></div>
        <div class="relative flex items-start justify-between gap-3">
          <div class="min-w-0">
            <div class="flex items-center gap-2">
              <span class="h-2.5 w-2.5 rounded-full ${checkedIn ? "bg-success" : "bg-danger"}"></span>
              <span data-check-in-status="${checkedIn ? "checked_in" : "not_checked_in"}"
                class="text-xs font-semibold uppercase tracking-wider ${checkedIn ? "text-success" : "text-muted-foreground"}">
                ${translate(checkedIn ? "Checked In" : "Not Checked In")}
              </span>
            </div>
            <div class="mt-1 flex items-baseline gap-2" data-controller="mobile--clock">
              <span data-mobile--clock-target="time" class="text-3xl font-bold tracking-tight text-foreground">--:--:--</span>
              <span data-mobile--clock-target="period" class="text-sm font-semibold uppercase text-muted-foreground">--</span>
            </div>
            <p class="mt-1 text-xs text-muted-foreground">${escapeHtml(shiftText)}</p>
          </div>
          <div class="flex max-w-44 flex-col items-end gap-1 text-right">
            <span class="inline-flex items-center gap-1 rounded-full bg-primary/10 px-2.5 py-1 text-xs font-semibold text-primary">
              <span class="material-symbols-outlined text-base">location_on</span>
              <span class="truncate">${escapeHtml(employee.branch?.name || translate("Branch check-in"))}</span>
            </span>
            <span class="truncate text-xs text-muted-foreground">${escapeHtml(company.name)}</span>
          </div>
        </div>

        <div class="relative mt-4">
          ${this.checkInFormHTML(company, checkedIn)}
          ${checkInLogs.length ? `
            <div class="mt-3 rounded-lg border border-line bg-muted/50 p-3">
              <div class="flex items-center justify-between gap-2">
                <p class="text-xs font-semibold uppercase tracking-wider text-muted-foreground">${translate("Today's Check-ins")}</p>
                <span class="rounded-full border border-line bg-card px-2 py-0.5 text-xs font-bold text-foreground">${checkInLogs.length}</span>
              </div>
              <div class="mt-2 flex flex-wrap gap-1.5">
                ${checkInLogs.map((log) => `
                  <span data-check-in-time class="inline-flex items-center gap-1 rounded-full border border-line bg-card px-2.5 py-1 text-xs font-semibold text-foreground">
                    <span class="material-symbols-outlined text-sm text-success">login</span>
                    ${mobileTime(log.logged_at, offsetHours)}
                  </span>
                `).join("")}
              </div>
            </div>
          ` : ""}
        </div>
      </section>
    `
  }

  checkInFormHTML(company, checkedIn) {
    return form({
      action: Helpers.mobile_company_attendances_path(company.id),
      method: "POST",
      attributes: `data-turbo="false"`,
      html: `
        <button type="submit"
          class="flex h-11 w-full cursor-pointer items-center justify-center gap-2 rounded-lg bg-primary text-sm font-semibold text-primary-foreground shadow-sm transition-colors hover:bg-primary/90 active:scale-95">
          <span class="material-symbols-outlined text-xl">login</span>
          ${translate(checkedIn ? "Check In Again" : "Clock In")}
        </button>
      `
    })
  }

  statsHTML({ attendance_month: attendanceMonth, attendance_balance: balance }) {
    return `
      <section class="grid grid-cols-3 gap-2 md:gap-4">
        ${mobileStatTile({
          label: "Attendance",
          value: mobileAttendanceRate(attendanceMonth),
          hint: translate("This month"),
          icon: "task_alt"
        })}
        <div class="flex flex-col justify-between rounded-xl border border-line bg-card p-4 shadow-sm">
          <div class="flex items-center justify-between gap-2">
            <span class="text-xs font-medium text-muted-foreground">${translate("Paid Leave")}</span>
            <span class="material-symbols-outlined text-xl text-primary">beach_access</span>
          </div>
          <div class="mt-2">
            <p class="text-lg font-bold leading-tight text-foreground">${balance.remaining_days} ${translate("Days")}</p>
            <p class="mt-0.5 text-xs text-muted-foreground">${balance.pending_days} ${translate("Pending")}</p>
          </div>
        </div>
        ${mobileStatTile({
          label: "Overtime",
          value: mobileDuration(attendanceMonth?.total_overtime_minutes),
          hint: translate("This month"),
          icon: "schedule"
        })}
      </section>
    `
  }

  quickActionsHTML({ company, attendance_month: attendanceMonth, pending_requests_count: pendingRequests }) {
    const attendanceBadge = attendanceMonth?.total_records
      ? `<span class="rounded-full bg-primary/10 px-2 py-0.5 text-xs font-bold text-primary">${attendanceMonth.total_present_days}/${attendanceMonth.total_records}</span>`
      : `<span class="material-symbols-outlined text-lg text-muted-foreground/60">arrow_forward</span>`
    const requestsBadge = pendingRequests > 0
      ? `<span class="flex h-5 w-5 items-center justify-center rounded-full bg-danger text-xs font-bold text-danger-foreground">${pendingRequests}</span>`
      : `<span class="material-symbols-outlined text-lg text-muted-foreground/60">arrow_forward</span>`

    return `
      <section class="flex flex-col gap-2">
        <div class="flex items-center justify-between px-1">
          <h2 class="text-sm font-bold text-foreground">${translate("Quick Operations")}</h2>
          <span class="text-xs font-semibold text-primary">${translate("Skycom ERP")}</span>
        </div>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-2">
          ${this.actionCardHTML({
            path: Helpers.mobile_company_employee_path(company.id),
            icon: "badge",
            title: "Profile",
            hint: "Profile, branch, roles",
            trailing: `<span class="material-symbols-outlined text-lg text-muted-foreground/60">arrow_forward</span>`
          })}
          ${this.actionCardHTML({
            path: Helpers.mobile_company_attendance_month_path(company.id),
            icon: "calendar_month",
            title: "Attendance",
            hint: "Monthly log & requests",
            trailing: attendanceBadge
          })}
          ${this.actionCardHTML({
            path: Helpers.new_mobile_company_attendance_request_path(company.id),
            icon: "assignment_late",
            title: "Requests",
            hint: "File an attendance request",
            trailing: requestsBadge
          })}
        </div>
      </section>
    `
  }

  actionCardHTML({ path, icon, title, hint, trailing }) {
    return `
      <a href="${path}" class="group flex cursor-pointer flex-col justify-between rounded-xl border border-line bg-card p-4 shadow-sm transition-colors hover:border-primary/30">
        <div class="flex items-center justify-between">
          <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10 text-primary">
            <span class="material-symbols-outlined text-2xl">${icon}</span>
          </div>
          ${trailing}
        </div>
        <div class="mt-3">
          <p class="text-sm font-bold text-foreground">${translate(title)}</p>
          <p class="mt-0.5 text-xs text-muted-foreground">${translate(hint)}</p>
        </div>
      </a>
    `
  }

  noticeHTML({ announcement }) {
    if (!announcement) return ""

    return `
      <section class="flex items-start gap-3 rounded-xl border border-primary/20 bg-primary/10 p-4">
        <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-card text-primary shadow-sm">
          <span class="material-symbols-outlined text-2xl">campaign</span>
        </span>
        <div class="min-w-0">
          <span class="text-xs font-bold uppercase tracking-wider text-primary">${translate("Company Notice")}</span>
          <p class="mt-0.5 text-sm font-semibold text-foreground">${escapeHtml(announcement.name)}</p>
          <p class="text-xs text-muted-foreground">${escapeHtml(announcement.description)}</p>
        </div>
      </section>
    `
  }

  activityHTML({ company, today_logs: logs = [] }) {
    const offsetHours = Number(company.utc_offset || 0) / 3600
    const rows = logs.length
      ? logs.map((log) => {
          const isCheckIn = log.log_type === "check_in"
          return `
            <div class="flex items-start gap-2">
              <span class="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-full ${isCheckIn ? "bg-success/10 text-success" : "bg-muted text-muted-foreground"}">
                <span class="material-symbols-outlined text-lg">${isCheckIn ? "login" : "logout"}</span>
              </span>
              <div class="min-w-0 flex-1">
                <div class="flex items-center justify-between gap-2">
                  <p class="truncate text-sm font-semibold text-foreground">${translate(isCheckIn ? "Clock In Recorded" : "Clock Out Recorded")}</p>
                  <span class="shrink-0 text-xs text-muted-foreground">${mobileTime(log.logged_at, offsetHours)}</span>
                </div>
                <p class="truncate text-xs text-muted-foreground">${escapeHtml(log.branch_name)}</p>
              </div>
            </div>
          `
        }).join("")
      : `<p class="text-sm text-muted-foreground">${translate("No activity yet.")}</p>`

    return `
      <section class="rounded-xl border border-line bg-card p-4 shadow-sm">
        <div class="flex items-center justify-between">
          <h2 class="text-sm font-bold text-foreground">${translate("Today's Activity")}</h2>
          <span class="text-xs font-medium text-muted-foreground">${logs.length} ${translate("events")}</span>
        </div>
        <div class="mt-3 flex flex-col gap-3">${rows}</div>
      </section>
    `
  }
}
