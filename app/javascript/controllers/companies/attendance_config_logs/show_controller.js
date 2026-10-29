import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceConfigLogs_ShowController extends Companies_LayoutController {
  // Single audit row — full raw snapshot + actor.
  // Depends on BE: Companies::AttendanceConfigLogsController#show
  // Endpoints: GET /companies/:company_id/attendance_config_logs/:id.json
  /** @type {Object|null} */
  log = null

  async connect() {
    super.connect()
    const id = window.location.pathname.split("/").pop()
    try {
      const response = await fetchJson(`${Helpers.company_attendance_config_log_path(currentCompany().id, id)}.json`)
      this.log = response.attendance_config_log
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load attendance config log")}${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  actionBadge(action) {
    const colors = {
      created: 'bg-success/10 text-success ',
      updated: 'bg-primary/10 text-primary '
    }
    const color = colors[action] || 'bg-muted text-foreground'
    return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${color}">${Helpers.capitalize(action || '')}</span>`
  }

  field(label, value) {
    return `
      <div>
        <p class="text-xs font-medium text-muted-foreground">${translate(label)}</p>
        <p class="text-sm font-semibold text-foreground">${value ?? '—'}</p>
      </div>`
  }

  contentHTML() {
    const l = this.log
    if (!l) return '<div class="p-8 text-center">Not found.</div>'

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_attendance_config_logs_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back")}
          </a>
          <h2 class="text-2xl font-black text-foreground mb-6">${translate("Attendance Config Log")}</h2>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Action")}</p>
              <p class="text-sm font-semibold">${this.actionBadge(l.action)}</p>
            </div>
            ${this.field("Changed By", l.employee?.name)}
            ${this.field("Changed At", l.created_at ? new Date(l.created_at).toLocaleString() : null)}
            ${this.field("Branch", l.branch?.name)}
            ${this.field("Latitude", l.latitude)}
            ${this.field("Longitude", l.longitude)}
            ${this.field("Radius (m)", l.allowed_radius_meters)}
            ${this.field("WiFi SSID", l.allowed_wifi_ssid)}
            ${this.field("Require Photo", l.require_photo ? translate("True") : translate("False"))}
            ${this.field("Resolution Strategy", l.resolution_strategy)}
            ${this.field("Discarded At", l.discarded_at ? new Date(l.discarded_at).toLocaleString() : null)}
          </div>
        </div>
      </div>`
  }
}
