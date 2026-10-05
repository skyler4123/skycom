import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_EventConfigLogs_IndexController extends Companies_LayoutController {
  // Event Config audit trail (read-only).
  // Depends on BE: Companies::EventConfigLogsController#index
  // Endpoints: GET <pathname>.json?event_config_id&category_id&employee_id&action&from&to — traditional GET form, full-page submit
  static targets = ["logsList"]

  /** @type {Array} */
  logs = []
  /** @type {Object} */
  filterOptions = { event_configs: [], categories: [], actions: [] }

  async connect() {
    super.connect()
    try {
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson(`${pathname()}.json?${urlParams.toString()}`)
      this.logs = response.event_config_logs || []
      this.pagination = response.pagination || {}
      this.filterOptions = response.filters || this.filterOptions
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load event config logs")}${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  actionBadge(action) {
    const colors = {
      created: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300',
      updated: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300'
    }
    const color = colors[action] || 'bg-gray-100 text-gray-800'
    return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${color}">${Helpers.capitalize(action || '')}</span>`
  }

  flagBadge(value) {
    return value
      ? `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400">${translate("True")}</span>`
      : `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md bg-slate-50 text-slate-700 dark:bg-slate-800 dark:text-slate-400">${translate("False")}</span>`
  }

  formatDateTime(dt) {
    if (!dt) return '—'
    return new Date(dt).toLocaleString()
  }

  contentHTML() {
    const urlParams = new URLSearchParams(window.location.search)
    const configValue = urlParams.get('event_config_id') || ''
    const categoryValue = urlParams.get('category_id') || ''
    const actionValue = urlParams.get('log_action') || ''
    const fromValue = urlParams.get('from') || ''
    const toValue = urlParams.get('to') || ''

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <h2 class="text-xl font-bold text-slate-900 dark:text-white mb-6">${translate("Event Config Logs")}</h2>
          <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end gap-4 mb-6 w-full">
            <div class="flex flex-wrap items-end gap-3 w-full lg:w-auto">
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("Config")}</label>
                <select name="event_config_id"
                  class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                  ${selectOptionsHTML(cloneNewKey(this.filterOptions.event_configs || [], "id", "value"), configValue, translate("All Configs"))}
                </select>
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("Category")}</label>
                <select name="category_id"
                  class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                  ${selectOptionsHTML(cloneNewKey(this.filterOptions.categories || [], "id", "value"), categoryValue, translate("All Categories"))}
                </select>
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("Action")}</label>
                <select name="log_action"
                  class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                  ${selectOptionsHTML((this.filterOptions.actions || []).map(a => ({ value: a, name: Helpers.capitalize(a) })), actionValue, translate("All Actions"))}
                </select>
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("From")}</label>
                <input type="date" name="from" value="${fromValue}"
                  class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300" />
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("To")}</label>
                <input type="date" name="to" value="${toValue}"
                  class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300" />
              </div>
              <div class="flex gap-2 mt-auto">
                <button type="submit" class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm flex items-center gap-2">
                  <span class="material-symbols-outlined text-[18px]!">search</span>
                  ${translate("Search")}
                </button>
              </div>
            </div>
          </form>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium">${translate("When")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Category")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Action")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Changed By")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Hold Stock")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Strict Hold")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="logsList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.logs.map(l => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="py-4 px-6 text-sm text-slate-600">${this.formatDateTime(l.created_at)}</td>
                    <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">${l.category?.name || l.category_name || '—'}</td>
                    <td class="py-4 px-6 text-sm">${this.actionBadge(l.action)}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${l.employee?.name || '—'}</td>
                    <td class="py-4 px-6 text-sm">${this.flagBadge(l.create_stock_pending)}</td>
                    <td class="py-4 px-6 text-sm">${this.flagBadge(l.strict_stock_hold)}</td>
                    <td class="py-4 px-6 text-sm text-right">
                      <a href="${Helpers.company_event_config_log_path(currentCompany().id, l.id)}"
                        class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer">
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
