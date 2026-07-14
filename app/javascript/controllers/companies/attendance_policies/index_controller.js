import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendancePolicies_IndexController extends Companies_LayoutController {
  static targets = ["policiesList"]

  /** @type {Array} */
  attendancePolicies = []

  async connect() {
    super.connect()
    try {
      const response = await fetchJson()
      this.attendancePolicies = response.attendance_policies || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load attendance policies") }${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <div class="flex justify-between items-center mb-6">
            <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Attendance Policies")}</h2>
            <a href="${Helpers.new_company_attendance_policy_path(currentCompany().id)}"
              class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("Add")}
            </a>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium">${translate("Branch")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Latitude")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Longitude")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Radius")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Strategy")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="policiesList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.attendancePolicies.map(ap => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="py-4 px-6 text-sm font-medium">
                      <a href="${Helpers.company_attendance_policy_path(currentCompany().id, ap.id)}"
                        class="text-slate-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 cursor-pointer">
                        ${ap.branch?.name || '—'}
                      </a>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600">${ap.latitude || '—'}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${ap.longitude || '—'}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${ap.allowed_radius_meters || '—'}m</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${Helpers.capitalize((ap.resolution_strategy || '').replace('_', ' '))}</td>
                    <td class="py-4 px-6 text-sm text-right">
                      <a href="${Helpers.edit_company_attendance_policy_path(currentCompany().id, ap.id)}"
                        class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </a>
                    </td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}
