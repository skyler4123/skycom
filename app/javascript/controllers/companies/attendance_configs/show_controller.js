import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceConfigs_ShowController extends Companies_LayoutController {
  // Attendance Config detail — read-only geofence + strategy view.
  // Depends on BE: Companies::AttendanceConfigsController#show
  // Endpoints: GET /companies/:company_id/attendance_configs/:id.json
  // Docs: docs/HR.md
  /** @type {Object|null} */
  attendanceConfig = null

  async connect() {
    super.connect()
    const id = window.location.pathname.split("/").pop()
    try {
      const response = await fetchJson(`${Helpers.company_attendance_config_path(currentCompany().id, id)}.json`)
      this.attendanceConfig = response.attendance_config
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load attendance config") }${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  contentHTML() {
    const ac = this.attendanceConfig
    if (!ac) return '<div class="p-8 text-center">Not found.</div>'

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_attendance_configs_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back")}
          </a>
          <h2 class="text-2xl font-black text-foreground mb-6">${translate("Attendance Config")}</h2>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Branch")}</p>
              <p class="text-sm font-semibold text-foreground">${ac.branch?.name || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Latitude / Longitude")}</p>
              <p class="text-sm font-semibold text-foreground">${ac.latitude || '—'}, ${ac.longitude || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Allowed Radius")}</p>
              <p class="text-sm font-semibold text-foreground">${ac.allowed_radius_meters || '—'}m</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("WiFi SSID")}</p>
              <p class="text-sm font-semibold text-foreground">${ac.allowed_wifi_ssid || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Strategy")}</p>
              <p class="text-sm font-semibold text-foreground">${Helpers.capitalize((ac.resolution_strategy || '').replace('_', ' '))}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Require Photo")}</p>
              <p class="text-sm font-semibold text-foreground">${ac.require_photo ? translate("True") : translate("False")}</p>
            </div>
          </div>
          <div class="mt-8 flex justify-end">
            <a href="${Helpers.edit_company_attendance_config_path(currentCompany().id, ac.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm cursor-pointer">
              ${translate("Edit")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}
