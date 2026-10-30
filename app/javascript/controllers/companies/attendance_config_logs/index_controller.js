import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceConfigLogs_IndexController extends Companies_LayoutController {
  // Attendance Config audit trail (read-only).
  // Depends on BE: Companies::AttendanceConfigLogsController#index
  // Endpoints: GET <pathname>.json?attendance_config_id&branch_id&employee_id&action&from&to — traditional GET form, full-page submit
  static targets = ["logsList"]

  /** @type {Array} */
  logs = []
  /** @type {Object} */
  filterOptions = { attendance_configs: [], branches: [], actions: [] }

  async connect() {
    super.connect()
    try {
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson(`${pathname()}.json?${urlParams.toString()}`)
      this.logs = response.attendance_config_logs || []
      this.pagination = response.pagination || {}
      this.filterOptions = response.filters || this.filterOptions
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load attendance config logs")}${__errDetail ? ": " + __errDetail : ""}` })
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

  formatDateTime(dt) {
    if (!dt) return '—'
    return new Date(dt).toLocaleString()
  }

  contentHTML() {
    const urlParams = new URLSearchParams(window.location.search)
    const configValue = urlParams.get('attendance_config_id') || ''
    const branchValue = urlParams.get('branch_id') || ''
    const actionValue = urlParams.get('log_action') || ''
    const fromValue = urlParams.get('from') || ''
    const toValue = urlParams.get('to') || ''

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col">
          <h2 class="text-xl font-bold text-foreground mb-6">${translate("Attendance Config Logs")}</h2>
          <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end gap-4 mb-6 w-full">
            <div class="flex flex-wrap items-end gap-3 w-full lg:w-auto">
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Config")}</label>
                <select name="attendance_config_id"
                  class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground">
                  ${selectOptionsHTML(cloneNewKey(this.filterOptions.attendance_configs || [], "id", "value"), configValue, translate("All Configs"))}
                </select>
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Branch")}</label>
                <select name="branch_id"
                  class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground">
                  ${selectOptionsHTML(cloneNewKey(this.filterOptions.branches || [], "id", "value"), branchValue, translate("All Branches"))}
                </select>
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Action")}</label>
                <select name="log_action"
                  class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground">
                  ${selectOptionsHTML((this.filterOptions.actions || []).map(a => ({ value: a, name: Helpers.capitalize(a) })), actionValue, translate("All Actions"))}
                </select>
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("From")}</label>
                <input type="date" name="from" value="${fromValue}"
                  class="px-3 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground" />
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("To")}</label>
                <input type="date" name="to" value="${toValue}"
                  class="px-3 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground" />
              </div>
              <div class="flex gap-2 mt-auto">
                <button type="submit" class="h-[38px] px-6 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg transition-colors font-medium text-sm flex items-center gap-2">
                  <span class="material-symbols-outlined text-[18px]!">search</span>
                  ${translate("Search")}
                </button>
              </div>
            </div>
          </form>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-muted-foreground border-b border-line">
                  <th class="py-4 px-6 font-medium">${translate("When")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Branch")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Action")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Changed By")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Radius")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Strategy")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="logsList" class="divide-y divide-line">
                ${this.logs.map(l => `
                  <tr class="hover:bg-muted/50">
                    <td class="py-4 px-6 text-sm text-muted-foreground">${this.formatDateTime(l.created_at)}</td>
                    <td class="py-4 px-6 text-sm font-medium text-foreground">${l.branch?.name || '—'}</td>
                    <td class="py-4 px-6 text-sm">${this.actionBadge(l.action)}</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${l.employee?.name || '—'}</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${l.allowed_radius_meters ?? '—'}</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${l.resolution_strategy ?? '—'}</td>
                    <td class="py-4 px-6 text-sm text-right">
                      <a href="${Helpers.company_attendance_config_log_path(currentCompany().id, l.id)}"
                        class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                      </a>
                    </td>
                  </tr>`).join('')}
              </tbody>
            </table>
          </div>
          <div class="flex justify-center pt-6">${pagination(this.pagination)}</div>
        </div>
      </div>`
  }
}
