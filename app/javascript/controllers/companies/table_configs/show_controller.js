import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_TableConfigs_ShowController extends Companies_LayoutController {
  /** @type {any | null} */
  config = null

  async connect() {
    super.connect()

    const configId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_table_config_path(companyId, configId)}.json`)
      this.config = response.table_config

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      poll(() => {
        if (this.hasContentTarget) {
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load table config.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    return this.showHTML()
  }

  showHTML() {
    const c = this.config
    if (!c) return `<div class="p-8 text-center">${translate("Table config not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const category = currentCategories().find(cat => cat.id === c.category_id)
    const columns = c.columns_metadata || []

    const columnsTable = columns.length > 0 ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Column Config")}</h3>
        <div class="overflow-x-auto rounded-lg border border-slate-200 dark:border-gray-800">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-gray-800">
                <th class="py-3 px-4 font-medium whitespace-nowrap">${translate("Key")}</th>
                <th class="py-3 px-4 font-medium whitespace-nowrap">${translate("Label")}</th>
                <th class="py-3 px-4 font-medium whitespace-nowrap">${translate("Visible")}</th>
                <th class="py-3 px-4 font-medium whitespace-nowrap">${translate("Sortable")}</th>
                <th class="py-3 px-4 font-medium whitespace-nowrap">${translate("Align")}</th>
                <th class="py-3 px-4 font-medium whitespace-nowrap">${translate("Pinned")}</th>
                <th class="py-3 px-4 font-medium whitespace-nowrap">${translate("Width")}</th>
                <th class="py-3 px-4 font-medium whitespace-nowrap">${translate("Virtual")}</th>
              </tr>
            </thead>
            <tbody>
              ${columns.map(col => `
                <tr class="border-b border-slate-100 dark:border-gray-800 last:border-0 hover:bg-slate-50 dark:hover:bg-slate-800/50">
                  <td class="py-3 px-4 text-sm font-mono text-slate-700 dark:text-slate-300">${col.key}</td>
                  <td class="py-3 px-4 text-sm font-medium text-slate-900 dark:text-white">${col.label}</td>
                  <td class="py-3 px-4">${col.visible !== false ? `<span class="text-emerald-600 text-sm">${translate("Yes")}</span>` : `<span class="text-slate-400 text-sm">${translate("No")}</span>`}</td>
                  <td class="py-3 px-4">${col.sortable ? `<span class="text-emerald-600 text-sm">${translate("Yes")}</span>` : `<span class="text-slate-400 text-sm">${translate("No")}</span>`}</td>
                  <td class="py-3 px-4 text-sm text-slate-600 dark:text-slate-300">${col.align || 'left'}</td>
                  <td class="py-3 px-4 text-sm text-slate-600 dark:text-slate-300">${col.pinned || '-'}</td>
                  <td class="py-3 px-4 text-sm text-slate-600 dark:text-slate-300">${col.width || '-'}</td>
                  <td class="py-3 px-4">${col.is_virtual ? `<span class="text-blue-600 text-sm">${translate("Yes")}</span>` : `<span class="text-slate-400 text-sm">${translate("No")}</span>`}</td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>
      </div>
    ` : ''

    const colCount = columns.length

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_table_configs_path(companyId)}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 mb-6">
            <span class="material-symbols-outlined text-[18px]">arrow_back</span>
            ${translate("Back to Dynamic Tables")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-cyan-100 dark:border-cyan-900/30 bg-cyan-100 dark:bg-gray-800 shadow-lg flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-cyan-600 dark:text-cyan-400">table</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-slate-900 dark:text-white">${c.name}</h2>
              <p class="font-semibold text-cyan-600 dark:text-cyan-400">${c.description || ''}</p>
              <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-cyan-100 dark:bg-cyan-900/40 px-3 py-1 text-xs font-bold text-cyan-700 dark:text-cyan-300">${colCount} ${translate("columns")}</span>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-6 sm:grid-cols-2">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-cyan-600 dark:text-cyan-400">
                <span class="material-symbols-outlined">category</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Category")}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${category?.name || c.category?.name || 'N/A'}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-cyan-600 dark:text-cyan-400">
                <span class="material-symbols-outlined">settings_applications</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Property Mapping")}</p>
                ${c.property_mapping_id
                  ? `<a href="${Helpers.company_property_mapping_path(companyId, c.property_mapping_id)}"
                       class="inline-flex items-center gap-1 text-sm font-semibold text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 transition-colors cursor-pointer">
                       <span class="material-symbols-outlined text-[16px]">open_in_new</span>
                       ${c.property_mapping?.name || 'N/A'}
                     </a>`
                  : `<p class="text-sm font-semibold text-slate-900 dark:text-white">N/A</p>`}
              </div>
            </div>
          </div>

          ${columnsTable}

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-slate-200 dark:border-gray-800">
            <a href="${Helpers.edit_company_table_config_path(companyId, c.id)}"
              class="inline-flex items-center px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm transition-colors cursor-pointer"
              ${tooltip(translate("Edit or add columns to this table configuration"))}
            >
              ${translate("Edit Table Config")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}
