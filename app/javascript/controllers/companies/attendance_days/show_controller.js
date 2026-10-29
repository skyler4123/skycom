import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceDays_ShowController extends Companies_LayoutController {
  /** @type {Object|null} */
  attendanceDay = null

  async connect() {
    super.connect()
    const id = window.location.pathname.split("/").pop()
    try {
      const response = await fetchJson(`${Helpers.company_attendance_day_path(currentCompany().id, id)}.json`)
      this.attendanceDay = response.attendance_day
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load attendance record") }${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  formatDate(dateStr) {
    if (!dateStr) return '—'
    return new Date(dateStr + 'T00:00:00').toLocaleDateString()
  }

  formatTime(dt) {
    if (!dt) return '—'
    return new Date(dt).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', hour12: false })
  }

  statusBadge(status) {
    const colors = {
      present: 'bg-success/10 text-success ',
      half_day: 'bg-warning/10 text-warning ',
      late: 'bg-danger/10 text-danger ',
      absent: 'bg-muted text-foreground ',
      missing_checkout: 'bg-warning/10 text-warning '
    }
    const color = colors[status] || 'bg-muted text-foreground'
    return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${color}">${Helpers.capitalize(status?.replace('_', ' ') || '')}</span>`
  }

  contentHTML() {
    const d = this.attendanceDay
    if (!d) return '<div class="p-8 text-center">Not found.</div>'

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_attendance_days_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back")}
          </a>
          <h2 class="text-2xl font-black text-foreground mb-6">${translate("Attendance Day")}</h2>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Employee")}</p>
              <p class="text-sm font-semibold text-foreground">${d.employee?.name || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Date")}</p>
              <p class="text-sm font-semibold text-foreground">${this.formatDate(d.attendance_date)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Check In")}</p>
              <p class="text-sm font-semibold text-foreground">${this.formatTime(d.check_in)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Check Out")}</p>
              <p class="text-sm font-semibold text-foreground">${this.formatTime(d.check_out)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Worked")}</p>
              <p class="text-sm font-semibold text-foreground">${Math.round((d.total_seconds_worked || 0) / 60)}min</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Status")}</p>
              <p class="text-sm font-semibold">${this.statusBadge(d.attendance_status)}</p>
            </div>
          </div>
        </div>
      </div>
    `
  }
}
