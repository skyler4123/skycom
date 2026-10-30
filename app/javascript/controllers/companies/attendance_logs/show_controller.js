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
      check_in: 'bg-success/10 text-success ',
      check_out: 'bg-primary/10 text-primary '
    }
    const color = colors[type] || 'bg-muted text-foreground'
    return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${color}">${Helpers.capitalize(type || '')}</span>`
  }

  contentHTML() {
    const l = this.attendanceLog
    if (!l) return '<div class="p-8 text-center">Not found.</div>'

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_attendance_logs_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back")}
          </a>
          <h2 class="text-2xl font-black text-foreground mb-6">${translate("Attendance Log")}</h2>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Employee")}</p>
              <p class="text-sm font-semibold text-foreground">${l.employee?.name || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Type")}</p>
              <p class="text-sm font-semibold">${this.logTypeBadge(l.log_type)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Logged At")}</p>
              <p class="text-sm font-semibold text-foreground">${this.formatDate(l.logged_at)} ${this.formatTime(l.logged_at)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Location")}</p>
              <p class="text-sm font-semibold text-foreground">${l.latitude ? `${l.latitude}, ${l.longitude}` : '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("WiFi SSID")}</p>
              <p class="text-sm font-semibold text-foreground">${l.wifi_ssid || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Device")}</p>
              <p class="text-sm font-semibold text-foreground">${l.device_fingerprint || '—'}</p>
            </div>
          </div>
        </div>
      </div>
    `
  }
}
