import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceConfigs_IndexController extends Companies_LayoutController {
  // Attendance Configs dashboard — one geofence + resolution row per branch.
  // Depends on BE: Companies::AttendanceConfigsController#index
  // Endpoints: GET <pathname>.json
  // Docs: docs/HR.md
  static targets = ["configsList"]

  /** @type {Array} */
  attendanceConfigs = []

  async connect() {
    super.connect()
    try {
      const response = await fetchJson()
      this.attendanceConfigs = response.attendance_configs || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load attendance configs") }${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col">
          <div class="flex justify-between items-center mb-6">
            <h2 class="text-xl font-bold text-foreground">${translate("Attendance Configs")}</h2>
            <a href="${Helpers.new_company_attendance_config_path(currentCompany().id)}"
              class="flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg text-sm cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("Add")}
            </a>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-muted-foreground border-b border-line">
                  <th class="py-4 px-6 font-medium">${translate("Branch")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Latitude")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Longitude")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Radius")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Strategy")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="configsList" class="divide-y divide-line">
                ${this.attendanceConfigs.map(ac => `
                  <tr class="hover:bg-muted/50">
                    <td class="py-4 px-6 text-sm font-medium">
                      <a href="${Helpers.company_attendance_config_path(currentCompany().id, ac.id)}"
                        class="text-foreground hover:text-primary cursor-pointer">
                        ${ac.branch?.name || '—'}
                      </a>
                    </td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${ac.latitude || '—'}</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${ac.longitude || '—'}</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${ac.allowed_radius_meters || '—'}m</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${Helpers.capitalize((ac.resolution_strategy || '').replace('_', ' '))}</td>
                    <td class="py-4 px-6 text-sm text-right">
                      <a href="${Helpers.edit_company_attendance_config_path(currentCompany().id, ac.id)}"
                        class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer">
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
