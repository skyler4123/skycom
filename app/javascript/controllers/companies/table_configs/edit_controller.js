import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_TableConfigs_EditController extends Companies_LayoutController {
  /** @type {any | null} */
  config = null

  /** @type {Array} */
  columnsMetadata = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const configId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_table_config_path(companyId, configId)}.json`)
      this.config = response.table_config
      this.columnsMetadata = this.config?.columns_metadata || []

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
    const c = this.config
    if (!c) return `<div class="p-8 text-center">${translate("Table config not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]

    const rowsHTML = this.columnsMetadata.map((col, index) => `
      <tr class="border-b border-slate-100 dark:border-gray-800 last:border-0">
        <td class="py-2 px-3">
          <input type="text" name="table_config[columns_metadata][${index}][key]" value="${col.key || ''}"
            class="w-full px-2 py-1 text-xs font-mono border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
        </td>
        <td class="py-2 px-3">
          <input type="text" name="table_config[columns_metadata][${index}][label]" value="${col.label || ''}"
            class="w-full px-2 py-1 text-xs border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
        </td>
        <td class="py-2 px-3 text-center">
          <input type="hidden" name="table_config[columns_metadata][${index}][visible]" value="false">
          <input type="checkbox" name="table_config[columns_metadata][${index}][visible]" value="true" ${col.visible !== false ? 'checked' : ''}
            class="rounded border-slate-300 text-blue-600 cursor-pointer">
        </td>
        <td class="py-2 px-3 text-center">
          <input type="hidden" name="table_config[columns_metadata][${index}][sortable]" value="false">
          <input type="checkbox" name="table_config[columns_metadata][${index}][sortable]" value="true" ${col.sortable ? 'checked' : ''}
            class="rounded border-slate-300 text-blue-600 cursor-pointer">
        </td>
        <td class="py-2 px-3">
          <select name="table_config[columns_metadata][${index}][align]"
            class="w-full px-1 py-1 text-xs border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
            <option value="left" ${col.align === 'left' ? 'selected' : ''}>left</option>
            <option value="center" ${col.align === 'center' ? 'selected' : ''}>center</option>
            <option value="right" ${col.align === 'right' ? 'selected' : ''}>right</option>
          </select>
        </td>
        <td class="py-2 px-3">
          <select name="table_config[columns_metadata][${index}][pinned]"
            class="w-full px-1 py-1 text-xs border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
            <option value="" ${!col.pinned ? 'selected' : ''}>none</option>
            <option value="left" ${col.pinned === 'left' ? 'selected' : ''}>left</option>
            <option value="right" ${col.pinned === 'right' ? 'selected' : ''}>right</option>
          </select>
        </td>
        <td class="py-2 px-3">
          <input type="number" name="table_config[columns_metadata][${index}][width]" value="${col.width ?? ''}" placeholder="auto"
            class="w-16 px-1 py-1 text-xs border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
        </td>
        <td class="py-2 px-3">
          <input type="text" name="table_config[columns_metadata][${index}][roles]" value="${(col.roles || []).join(', ')}" placeholder="admin, mgr"
            class="w-full px-1 py-1 text-xs border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
        </td>
        <td class="py-2 px-3 text-center">
          <input type="hidden" name="table_config[columns_metadata][${index}][is_virtual]" value="false">
          <input type="checkbox" name="table_config[columns_metadata][${index}][is_virtual]" value="true" ${col.is_virtual ? 'checked' : ''}
            class="rounded border-slate-300 text-blue-600 cursor-pointer">
        </td>
        <td class="py-2 px-3 text-right">
          <button type="button" data-action="click->${this.identifier}#removeColumn" data-index="${index}"
            class="inline-flex items-center justify-center p-1 text-red-500 hover:text-red-700 hover:bg-red-50 rounded-lg cursor-pointer">
            <span class="material-symbols-outlined text-[16px]">delete</span>
          </button>
        </td>
      </tr>
    `).join('')

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Table Config")}</h2>
        <p class="text-sm text-slate-500">${translate("Controls how data is displayed in this table. To show/hide columns, add constraints or validation rules, click the Property Mapping link below.")}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Name")}</label>
            <input type="text" name="table_config[name]" value="${c.name || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="table_config[description]" rows="2"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">${c.description || ''}</textarea>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Category")}</label>
            <input type="text" value="${currentCategories().find(cat => cat.id === c.category_id)?.name || ''}" disabled
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-slate-700 text-sm text-slate-400">
            <input type="hidden" name="table_config[category_id]" value="${c.category_id}">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Property Mapping")}</label>
            <div class="flex items-center gap-2">
              <input type="text" value="${c.property_mapping?.name || ''}" disabled
                class="flex-1 px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-slate-700 text-sm text-slate-400">
              <input type="hidden" name="table_config[property_mapping_id]" value="${c.property_mapping_id}">
              ${c.property_mapping_id ? `
                <a href="${Helpers.edit_company_property_mapping_path(companyId, c.property_mapping_id)}"
                  class="inline-flex items-center gap-1 px-3 py-2 text-sm font-medium text-blue-600 hover:text-blue-700 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors cursor-pointer whitespace-nowrap"
                  ${tooltip(translate("Manage property fields: show/hide columns, add constraints or validation rules"))}
                >
                  <span class="material-symbols-outlined text-[18px]">open_in_new</span>
                  ${translate("Edit")}
                </a>
              ` : ''}
            </div>
          </div>
        </div>

        <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Column Config")}</h3>

          <div class="overflow-x-auto rounded-lg border border-slate-200 dark:border-gray-800">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-xs text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-gray-800">
                  <th class="py-2 px-3 font-medium">${translate("Key")}</th>
                  <th class="py-2 px-3 font-medium">${translate("Label")}</th>
                  <th class="py-2 px-3 font-medium text-center">${translate("Vis")}</th>
                  <th class="py-2 px-3 font-medium text-center">${translate("Sort")}</th>
                  <th class="py-2 px-3 font-medium">${translate("Align")}</th>
                  <th class="py-2 px-3 font-medium">${translate("Pin")}</th>
                  <th class="py-2 px-3 font-medium">${translate("W")}</th>
                  <th class="py-2 px-3 font-medium">${translate("Roles")}</th>
                  <th class="py-2 px-3 font-medium text-center">${translate("Virt")}</th>
                  <th class="py-2 px-3 font-medium text-right"></th>
                </tr>
              </thead>
              <tbody id="columns-body">
                ${rowsHTML}
              </tbody>
            </table>
          </div>

          <button type="button" data-action="click->${this.identifier}#addColumn"
            class="mt-3 px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-medium transition-colors cursor-pointer">
            ${translate("Add Column")}
          </button>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_table_config_path(companyId, c.id)}"
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
          action: Helpers.company_table_config_path(companyId, c.id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }

  addColumn() {
    this.columnsMetadata.push({
      key: 'name',
      label: '',
      visible: true,
      sortable: true,
      align: 'left',
      pinned: null,
      width: null,
      roles: [],
      is_virtual: false,
      render_config: {}
    })
    this.rerenderEditor()
  }

  removeColumn(event) {
    const index = parseInt(event.currentTarget.getAttribute('data-index'))
    if (isNaN(index)) return

    this.columnsMetadata.splice(index, 1)
    this.rerenderEditor()
  }

  rerenderEditor() {
    const tbody = document.getElementById('columns-body')
    if (!tbody) return

    tbody.innerHTML = this.columnsMetadata.map((col, index) => `
      <tr class="border-b border-slate-100 dark:border-gray-800 last:border-0">
        <td class="py-2 px-3">
          <input type="text" name="table_config[columns_metadata][${index}][key]" value="${col.key || ''}"
            class="w-full px-2 py-1 text-xs font-mono border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
        </td>
        <td class="py-2 px-3">
          <input type="text" name="table_config[columns_metadata][${index}][label]" value="${col.label || ''}"
            class="w-full px-2 py-1 text-xs border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
        </td>
        <td class="py-2 px-3 text-center">
          <input type="hidden" name="table_config[columns_metadata][${index}][visible]" value="false">
          <input type="checkbox" name="table_config[columns_metadata][${index}][visible]" value="true" ${col.visible !== false ? 'checked' : ''}
            class="rounded border-slate-300 text-blue-600 cursor-pointer">
        </td>
        <td class="py-2 px-3 text-center">
          <input type="hidden" name="table_config[columns_metadata][${index}][sortable]" value="false">
          <input type="checkbox" name="table_config[columns_metadata][${index}][sortable]" value="true" ${col.sortable ? 'checked' : ''}
            class="rounded border-slate-300 text-blue-600 cursor-pointer">
        </td>
        <td class="py-2 px-3">
          <select name="table_config[columns_metadata][${index}][align]"
            class="w-full px-1 py-1 text-xs border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
            <option value="left" ${col.align === 'left' ? 'selected' : ''}>left</option>
            <option value="center" ${col.align === 'center' ? 'selected' : ''}>center</option>
            <option value="right" ${col.align === 'right' ? 'selected' : ''}>right</option>
          </select>
        </td>
        <td class="py-2 px-3">
          <select name="table_config[columns_metadata][${index}][pinned]"
            class="w-full px-1 py-1 text-xs border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
            <option value="" ${!col.pinned ? 'selected' : ''}>none</option>
            <option value="left" ${col.pinned === 'left' ? 'selected' : ''}>left</option>
            <option value="right" ${col.pinned === 'right' ? 'selected' : ''}>right</option>
          </select>
        </td>
        <td class="py-2 px-3">
          <input type="number" name="table_config[columns_metadata][${index}][width]" value="${col.width ?? ''}" placeholder="auto"
            class="w-16 px-1 py-1 text-xs border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
        </td>
        <td class="py-2 px-3">
          <input type="text" name="table_config[columns_metadata][${index}][roles]" value="${(col.roles || []).join(', ')}" placeholder="admin, mgr"
            class="w-full px-1 py-1 text-xs border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
        </td>
        <td class="py-2 px-3 text-center">
          <input type="hidden" name="table_config[columns_metadata][${index}][is_virtual]" value="false">
          <input type="checkbox" name="table_config[columns_metadata][${index}][is_virtual]" value="true" ${col.is_virtual ? 'checked' : ''}
            class="rounded border-slate-300 text-blue-600 cursor-pointer">
        </td>
        <td class="py-2 px-3 text-right">
          <button type="button" data-action="click->${this.identifier}#removeColumn" data-index="${index}"
            class="inline-flex items-center justify-center p-1 text-red-500 hover:text-red-700 hover:bg-red-50 rounded-lg cursor-pointer">
            <span class="material-symbols-outlined text-[16px]">delete</span>
          </button>
        </td>
      </tr>
    `).join('')
  }
}
