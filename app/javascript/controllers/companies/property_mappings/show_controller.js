import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_PropertyMappings_ShowController extends Companies_LayoutController {
  /** @type {any | null} */
  mapping = null

  async connect() {
    super.connect()

    const mappingId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_property_mapping_path(companyId, mappingId)}.json`)
      this.mapping = response.property_mapping

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load property mapping.")}</div>`
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
    const m = this.mapping
    if (!m) return `<div class="p-8 text-center">${translate("Property mapping not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const category = currentCategories().find(c => c.id === m.category_id)
    const metadata = m.property_metadata || []

    const fieldsTable = metadata.length > 0 ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Property Fields")}</h3>
        <div class="overflow-x-auto rounded-lg border border-slate-200 dark:border-gray-800">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-gray-800">
                <th class="py-3 px-4 font-medium whitespace-nowrap">${translate("Key")}</th>
                <th class="py-3 px-4 font-medium whitespace-nowrap">${translate("Name")}</th>
                <th class="py-3 px-4 font-medium whitespace-nowrap">${translate("Type")}</th>
                <th class="py-3 px-4 font-medium whitespace-nowrap">${translate("Name")}</th>
                <th class="py-3 px-4 font-medium whitespace-nowrap">${translate("Validates")}</th>
              </tr>
            </thead>
            <tbody>
              ${metadata.map(field => `
                <tr class="border-b border-slate-100 dark:border-gray-800 last:border-0 hover:bg-slate-50 dark:hover:bg-slate-800/50">
                  <td class="py-3 px-4 text-sm font-mono text-slate-700 dark:text-slate-300">${field.key}</td>
                  <td class="py-3 px-4 text-sm text-slate-600 dark:text-slate-400">${field.name || '-'}</td>
                  <td class="py-3 px-4">
                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400">
                      ${field.type || field.key?.replace(/_\d+$/, '').replace('property_', '') || '-'}
                    </span>
                  </td>
                  <td class="py-3 px-4 text-sm font-medium text-slate-900 dark:text-white">${field.name || '-'}</td>
                  <td class="py-3 px-4 text-sm">
                    ${this.renderValidates(field.validates)}
                  </td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>
      </div>
    ` : ''

    const propsCount = metadata.length

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_property_mappings_path(companyId)}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 mb-6">
            <span class="material-symbols-outlined text-[18px]">arrow_back</span>
            ${translate("Back to Dynamic Properties")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-purple-100 dark:border-purple-900/30 bg-purple-100 dark:bg-gray-800 shadow-lg flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-purple-600 dark:text-purple-400">settings_applications</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-slate-900 dark:text-white">${m.name}</h2>
              <p class="font-semibold text-purple-600 dark:text-purple-400">${m.description || ''}</p>
              <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-purple-100 dark:bg-purple-900/40 px-3 py-1 text-xs font-bold text-purple-700 dark:text-purple-300 uppercase">${m.resource_name || 'N/A'}</span>
                <span class="inline-flex items-center rounded-lg bg-slate-100 dark:bg-slate-800 px-3 py-1 text-xs font-bold text-slate-600 dark:text-slate-400">${propsCount} ${translate("fields")}</span>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-6 sm:grid-cols-2">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-purple-600 dark:text-purple-400">
                <span class="material-symbols-outlined">category</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Category")}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${category?.name || 'N/A'}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-purple-600 dark:text-purple-400">
                <span class="material-symbols-outlined">description</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Description")}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${m.description || '-'}</p>
              </div>
            </div>
          </div>

          ${fieldsTable}

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-slate-200 dark:border-gray-800">
            <a href="${Helpers.edit_company_property_mapping_path(companyId, m.id)}"
              class="inline-flex items-center px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm transition-colors cursor-pointer"
            >
              ${translate("Edit Property Mapping")}
            </a>
          </div>
        </div>
      </div>
    `
  }

  renderValidates(validates) {
    if (!validates || (typeof validates === 'object' && Object.keys(validates).length === 0)) {
      return '<span class="text-slate-300 dark:text-slate-700">—</span>'
    }
    const json = JSON.stringify(validates, null, 2)
    return `<pre class="text-xs font-mono text-slate-600 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/60 p-2 rounded max-w-[300px] overflow-x-auto whitespace-pre-wrap break-all leading-relaxed">${json}</pre>`
  }
}
