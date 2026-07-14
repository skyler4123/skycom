import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceLogs_ShowController extends Companies_LayoutController {
  /** @type {Object|null} */
  attendanceLog = null

  async connect() {
    super.connect()
    const id = window.location.pathname.split("/").pop()
    try {
      const response = await fetchJson(`${Helpers.company_attendance_log_path(currentCompany().id, id)}.json`)
      this.attendanceLog = response.attendance_log
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load attendance log") }${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  formatDate(dt) {
    if (!dt) return '—'
    return new Date(dt).toLocaleDateString()
  }

  formatTime(dt) {
    if (!dt) return '—'
    return new Date(dt).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', hour12: false })
  }

  logTypeBadge(type) {
    const colors = {
      check_in: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300',
      check_out: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300'
    }
    const color = colors[type] || 'bg-gray-100 text-gray-800'
    return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${color}">${Helpers.capitalize(type || '')}</span>`
  }

  contentHTML() {
    const l = this.attendanceLog
    if (!l) return '<div class="p-8 text-center">Not found.</div>'

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_attendance_logs_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]">arrow_back</span>
            ${translate("Back")}
          </a>
          <h2 class="text-2xl font-black text-slate-900 dark:text-white mb-6">${translate("Attendance Log")}</h2>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Employee")}</p>
              <p class="text-sm font-semibold text-slate-900">${l.employee?.name || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Type")}</p>
              <p class="text-sm font-semibold">${this.logTypeBadge(l.log_type)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Logged At")}</p>
              <p class="text-sm font-semibold text-slate-900">${this.formatDate(l.logged_at)} ${this.formatTime(l.logged_at)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Location")}</p>
              <p class="text-sm font-semibold text-slate-900">${l.latitude ? `${l.latitude}, ${l.longitude}` : '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("WiFi SSID")}</p>
              <p class="text-sm font-semibold text-slate-900">${l.wifi_ssid || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Device")}</p>
              <p class="text-sm font-semibold text-slate-900">${l.device_fingerprint || '—'}</p>
            </div>
          </div>
        </div>
      </div>
    `
  }
}
