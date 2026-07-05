import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendancePolicies_ShowController extends Companies_LayoutController {
  /** @type {Object|null} */
  attendancePolicy = null

  async connect() {
    super.connect()
    const id = window.location.pathname.split("/").pop()
    try {
      const response = await fetchJson(`${Helpers.company_attendance_policy_path(currentCompany().id, id)}.json`)
      this.attendancePolicy = response.attendance_policy
    } catch (error) {
      toast({ type: "error", message: translate("Failed to load attendance policy") })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  contentHTML() {
    const ap = this.attendancePolicy
    if (!ap) return '<div class="p-8 text-center">Not found.</div>'

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_attendance_policies_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]">arrow_back</span>
            ${translate("Back")}
          </a>
          <h2 class="text-2xl font-black text-slate-900 dark:text-white mb-6">${translate("Attendance Policy")}</h2>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Branch")}</p>
              <p class="text-sm font-semibold text-slate-900">${ap.branch?.name || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Latitude / Longitude")}</p>
              <p class="text-sm font-semibold text-slate-900">${ap.latitude || '—'}, ${ap.longitude || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Allowed Radius")}</p>
              <p class="text-sm font-semibold text-slate-900">${ap.allowed_radius_meters || '—'}m</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("WiFi SSID")}</p>
              <p class="text-sm font-semibold text-slate-900">${ap.allowed_wifi_ssid || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Strategy")}</p>
              <p class="text-sm font-semibold text-slate-900">${Helpers.capitalize((ap.resolution_strategy || '').replace('_', ' '))}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Require Photo")}</p>
              <p class="text-sm font-semibold text-slate-900">${ap.require_photo ? 'Yes' : 'No'}</p>
            </div>
          </div>
          <div class="mt-8 flex justify-end">
            <a href="${Helpers.edit_company_attendance_policy_path(currentCompany().id, ap.id)}"
              class="inline-flex items-center px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer">
              ${translate("Edit")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}
