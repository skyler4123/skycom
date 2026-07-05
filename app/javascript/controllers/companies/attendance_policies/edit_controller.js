import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendancePolicies_EditController extends Companies_LayoutController {
  /** @type {Object|null} */
  attendancePolicy = null

  /** @type {string} */
  policyId = ""

  async connect() {
    super.connect()
    const pathParts = window.location.pathname.split("/")
    this.policyId = pathParts[pathParts.length - 2]
    try {
      const response = await fetchJson(`${Helpers.company_attendance_policy_path(currentCompany().id, this.policyId)}.json`)
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

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Attendance Policy")}</h2>
        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Branch ID")}</label>
            <input type="text" name="attendance_policy[branch_id]" value="${ap.branch_id || ''}" required class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Latitude")}</label>
            <input type="number" step="0.000001" name="attendance_policy[latitude]" value="${ap.latitude || ''}" required class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Longitude")}</label>
            <input type="number" step="0.000001" name="attendance_policy[longitude]" value="${ap.longitude || ''}" required class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Allowed Radius (m)")}</label>
            <input type="number" name="attendance_policy[allowed_radius_meters]" value="${ap.allowed_radius_meters || 100}" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("WiFi SSID")}</label>
            <input type="text" name="attendance_policy[allowed_wifi_ssid]" value="${ap.allowed_wifi_ssid || ''}" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Resolution Strategy")}</label>
            <select name="attendance_policy[resolution_strategy]" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="paired" ${ap.resolution_strategy === 'paired' ? 'selected' : ''}>Paired (check in/out)</option>
              <option value="check_in_only" ${ap.resolution_strategy === 'check_in_only' ? 'selected' : ''}>Check In Only</option>
            </select>
          </div>
          <div class="flex items-center gap-3 py-2">
            <input type="hidden" name="attendance_policy[require_photo]" value="false">
            <input type="checkbox" name="attendance_policy[require_photo]" value="true" ${ap.require_photo ? 'checked' : ''}
              class="h-5 w-5 rounded border-slate-300 text-blue-600 cursor-pointer">
            <span class="text-sm text-slate-900 dark:text-white">${translate("Require Photo")}</span>
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_attendance_policy_path(currentCompany().id, this.policyId)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Changes")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_attendance_policy_path(currentCompany().id, this.policyId),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
