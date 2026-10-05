import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_TableConfigLogs_ShowController extends Companies_LayoutController {
  // Single audit row — full raw snapshot + actor + columns preview.
  // Depends on BE: Companies::TableConfigLogsController#show
  // Endpoints: GET /companies/:company_id/table_config_logs/:id.json
  // Docs: docs/DYNAMIC_TABLE.md
  /** @type {Object|null} */
  log = null

  async connect() {
    super.connect()
    const id = window.location.pathname.split("/").pop()
    try {
      const response = await fetchJson(`${Helpers.company_table_config_log_path(currentCompany().id, id)}.json`)
      this.log = response.table_config_log
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load table config log")}${__errDetail ? ": " + __errDetail : ""}` })
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

  field(label, value) {
    return `
      <div>
        <p class="text-xs font-medium text-slate-500">${translate(label)}</p>
        <p class="text-sm font-semibold text-slate-900 dark:text-white">${value ?? '—'}</p>
      </div>`
  }

  contentHTML() {
    const l = this.log
    if (!l) return '<div class="p-8 text-center">Not found.</div>'
    const columns = l.metadata?.columns || []

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_table_config_logs_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back")}
          </a>
          <h2 class="text-2xl font-black text-slate-900 dark:text-white mb-6">${translate("Table Config Log")}</h2>
          <div class="grid grid-cols-2 gap-6 mb-8">
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Action")}</p>
              <p class="text-sm font-semibold">${this.actionBadge(l.action)}</p>
            </div>
            ${this.field("Changed By", l.employee?.name)}
            ${this.field("Changed At", l.created_at ? new Date(l.created_at).toLocaleString() : null)}
            ${this.field("Name", l.name)}
            ${this.field("Category", l.category?.name || l.category_name)}
            ${this.field("Property Mapping", l.property_mapping_name)}
            ${this.field("Resource", l.resource_name)}
            ${this.field("Description", l.description)}
          </div>
          <h3 class="text-lg font-bold text-slate-900 dark:text-white mb-4">${translate("Columns Snapshot")}</h3>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-3 px-4 font-medium">${translate("Key")}</th>
                  <th class="py-3 px-4 font-medium">${translate("Name")}</th>
                  <th class="py-3 px-4 font-medium">${translate("Visible")}</th>
                  <th class="py-3 px-4 font-medium">${translate("Align")}</th>
                  <th class="py-3 px-4 font-medium">${translate("Width")}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-200 dark:divide-slate-800">
                ${columns.map(c => `
                  <tr>
                    <td class="py-3 px-4 text-sm font-mono">${c.key || '—'}</td>
                    <td class="py-3 px-4 text-sm">${c.name || '—'}</td>
                    <td class="py-3 px-4 text-sm">${c.visible ? translate("True") : translate("False")}</td>
                    <td class="py-3 px-4 text-sm">${c.align || '—'}</td>
                    <td class="py-3 px-4 text-sm">${c.width ?? '—'}</td>
                  </tr>`).join('') || `<tr><td colspan="5" class="py-3 px-4 text-sm text-slate-500">—</td></tr>`}
              </tbody>
            </table>
          </div>
        </div>
      </div>`
  }
}
