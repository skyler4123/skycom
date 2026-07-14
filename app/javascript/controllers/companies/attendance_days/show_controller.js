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
      present: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300',
      half_day: 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-300',
      late: 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300',
      absent: 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-300',
      missing_checkout: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300'
    }
    const color = colors[status] || 'bg-gray-100 text-gray-800'
    return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${color}">${Helpers.capitalize(status?.replace('_', ' ') || '')}</span>`
  }

  contentHTML() {
    const d = this.attendanceDay
    if (!d) return '<div class="p-8 text-center">Not found.</div>'

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_attendance_days_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]">arrow_back</span>
            ${translate("Back")}
          </a>
          <h2 class="text-2xl font-black text-slate-900 dark:text-white mb-6">${translate("Attendance Day")}</h2>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Employee")}</p>
              <p class="text-sm font-semibold text-slate-900">${d.employee?.name || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Date")}</p>
              <p class="text-sm font-semibold text-slate-900">${this.formatDate(d.attendance_date)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Check In")}</p>
              <p class="text-sm font-semibold text-slate-900">${this.formatTime(d.check_in)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Check Out")}</p>
              <p class="text-sm font-semibold text-slate-900">${this.formatTime(d.check_out)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Worked")}</p>
              <p class="text-sm font-semibold text-slate-900">${Math.round((d.total_seconds_worked || 0) / 60)}min</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Status")}</p>
              <p class="text-sm font-semibold">${this.statusBadge(d.attendance_status)}</p>
            </div>
          </div>
        </div>
      </div>
    `
  }
}
