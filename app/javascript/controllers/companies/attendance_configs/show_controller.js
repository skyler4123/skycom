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
    if (!ap) return '<div class="p-8 text-center">Not found.</div>'

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_attendance_configs_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back")}
          </a>
          <h2 class="text-2xl font-black text-slate-900 dark:text-white mb-6">${translate("Attendance Config")}</h2>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Branch")}</p>
              <p class="text-sm font-semibold text-slate-900">${ac.branch?.name || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Latitude / Longitude")}</p>
              <p class="text-sm font-semibold text-slate-900">${ac.latitude || '—'}, ${ac.longitude || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Allowed Radius")}</p>
              <p class="text-sm font-semibold text-slate-900">${ac.allowed_radius_meters || '—'}m</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("WiFi SSID")}</p>
              <p class="text-sm font-semibold text-slate-900">${ac.allowed_wifi_ssid || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Strategy")}</p>
              <p class="text-sm font-semibold text-slate-900">${Helpers.capitalize((ac.resolution_strategy || '').replace('_', ' '))}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Require Photo")}</p>
              <p class="text-sm font-semibold text-slate-900">${ac.require_photo ? translate("True") : translate("False")}</p>
            </div>
          </div>
          <div class="mt-8 flex justify-end">
            <a href="${Helpers.edit_company_attendance_config_path(currentCompany().id, ac.id)}"
              class="inline-flex items-center px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer">
              ${translate("Edit")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}
