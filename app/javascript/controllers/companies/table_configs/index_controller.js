import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_TableConfigs_IndexController extends Companies_LayoutController {
  static targets = ["configsList"]

  /** @type {any[]} */
  tableConfigs = []

  async connect() {
    super.connect()

    try {
      const response = await fetchJson()
      this.tableConfigs = response.table_configs || []
      this.pagination = response.pagination || {}

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      toast({ type: "error", message: translate("Failed to load table configs") })
    }
  }

  contentHTML() {
    const categoryFilter = currentCategories() || []
    const urlParams = new URLSearchParams(window.location.search)

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end justify-between gap-4 mb-6 w-full">
              <div class="flex flex-wrap items-center gap-3 w-full lg:w-auto">
                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("Category")}</label>
                  <select name="category_id" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                    ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), urlParams.get('category_id'), translate("All Categories"))}
                  </select>
                </div>
                <div class="flex gap-2 mt-auto">
                  <button type="submit" class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm flex items-center gap-2">
                    <span class="material-symbols-outlined text-[18px]">search</span>
                    ${translate("Search")}
                  </button>
                </div>
              </div>

              <a href="${Helpers.new_company_table_config_path(currentCompany().id)}"
                class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap cursor-pointer">
                <span class="material-symbols-outlined text-[20px]">add</span>
                ${translate("Add")}
              </a>
            </form>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Name")}</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Category")}</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Property Mapping")}</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Description")}</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="configsList">
                ${this.tableConfigs.map(c => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td class="py-4 px-6 text-sm">
                      <div class="flex items-center gap-4">
                        <div class="w-10 h-10 rounded-lg bg-cyan-100 dark:bg-cyan-900/30 flex items-center justify-center">
                          <span class="material-symbols-outlined text-cyan-600 dark:text-cyan-400">table</span>
                        </div>
                        <div>
                          <a href="${Helpers.company_table_config_path(currentCompany().id, c.id)}"
                            class="font-medium text-slate-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 transition-colors cursor-pointer">
                            ${c.name || translate('N/A')}
                          </a>
                        </div>
                      </div>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                      ${c.category?.name || '-'}
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                      ${c.property_mapping?.name || '-'}
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 max-w-xs truncate">
                      ${c.description || '-'}
                    </td>
                    <td class="py-4 px-6 text-sm text-right">
                      <a href="${Helpers.edit_company_table_config_path(currentCompany().id, c.id)}"
                        class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </a>
                    </td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>

          ${this.tableConfigs.length === 0 ? `
            <div class="flex flex-col items-center justify-center py-12 text-slate-500 dark:text-slate-400">
              <span class="material-symbols-outlined text-4xl mb-2">table</span>
              <p>${translate("No table configs found")}</p>
            </div>
          ` : ''}

          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}
