import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_TableConfigs_EditController extends Companies_LayoutController {
  // TableConfig editor — rows carry key/name/visible/search/filter/align/width.
  // `search` checkbox: string-capable columns only; `filter` textarea: raw JSON
  // ({type: range|enum|boolean|date, buckets}) — parsed + validated server-side.
  // Depends on BE: Companies::TableConfigsController#show (JSON hydration),
  //               Companies::TableConfigsController#update (form PATCH + normalize_column_types)
  // Docs: docs/DYNAMIC_TABLE.md, docs/superpowers/specs/2026-09-06-dynamic-search-filter-design.md
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
      this.columnsMetadata = this.config?.metadata?.columns || []

      const pm = currentPropertyMappings().find(m => m.id === this.config?.property_mapping_id)
      /** @type {Array} */
      this.propertyEntries = pm?.metadata?.properties || []

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

    const rowsHTML = this.columnsMetadata.map((col, index) => this.columnRowHTML(col, index)).join('')

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
                  <th class="py-2 px-3 font-medium"
                    ${tooltip(translate("Field key stored in the database (e.g. name, property_string_1)"))}
                  >${translate("Key")}</th>
                  <th class="py-2 px-3 font-medium"
                    ${tooltip(translate("Display name shown as the column header"))}
                  >${translate("Name")}</th>
                  <th class="py-2 px-3 font-medium text-center"
                    ${tooltip(translate("Show or hide this column in the table"))}
                  >${translate("Visible")}</th>
                  <th class="py-2 px-3 font-medium text-center"
                    ${tooltip(translate("Include this column in the keyword search box (string columns only)"))}
                  >${translate("Search")}</th>
                  <th class="py-2 px-3 font-medium"
                    ${tooltip(translate("Filter config JSON — how this column filters (range / enum / boolean / date). The Active checkbox enables it; leave the JSON empty for no filter."))}
                  >${translate("Filter")}</th>
                  <th class="py-2 px-3 font-medium"
                    ${tooltip(translate("Text alignment inside the column: left, center, or right"))}
                  >${translate("Align")}</th>
                  <th class="py-2 px-3 font-medium"
                    ${tooltip(translate("Fixed column width in pixels (leave empty for auto)"))}
                  >${translate("Width")}</th>
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
      name: '',
      visible: true,
      search: false,
      align: 'left',
      width: null
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

    tbody.innerHTML = this.columnsMetadata.map((col, index) => this.columnRowHTML(col, index)).join('')
  }

  propertyEntryFor(key) {
    return this.propertyEntries.find(p => p.key === key) || null
  }

  columnType(key) {
    const entry = this.propertyEntryFor(key)
    if (entry?.type) return entry.type
    const match = /^property_(string|integer|decimal|boolean|datetime)_\d+$/.exec(key)
    return match ? match[1] : null
  }

  isSearchableColumn(key) {
    return key === "name" || key === "description" || key === "code" || key.startsWith("property_string_")
  }

  canFilter(col) {
    const type = this.columnType(col.key)
    return type === "integer" || type === "decimal" || type === "boolean" || type === "datetime"
  }

  filterSkeleton(col) {
    const type = this.columnType(col.key)
    const isEnum = type === "integer" && this.propertyEntryFor(col.key)?.input_type === "select"
    switch (type) {
      case 'integer':
        return isEnum ? '{"type":"enum"}' : '{"type":"range","buckets":[[null,10],[10,null]]}'
      case 'decimal':
        return '{"type":"range","buckets":[[null,10.5],[10.5,null]]}'
      case 'boolean':
        return '{"type":"boolean","true_false":true,"yes_no":false}'
      case 'datetime':
        return '{"type":"date","buckets":[[null,2025],[2025,2026],[2026,null]]}'
      default:
        return ''
    }
  }

  escapeHTML(str) {
    return String(str).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }

  columnRowHTML(col, index) {
    const filterValue = col.filter && typeof col.filter === "object" ? JSON.stringify(col.filter) : ""
    const key = col.key || ''

    return `
      <tr class="border-b border-slate-100 dark:border-gray-800 last:border-0">
        <td class="py-2 px-3">
          <input type="text" name="table_config[metadata][columns][${index}][key]" value="${key}"
            class="w-full px-2 py-1 text-xs font-mono border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
        </td>
        <td class="py-2 px-3">
          ${key.startsWith('property_') ? `
            <input type="text" name="table_config[metadata][columns][${index}][name]" value="${col.name || ''}"
              class="w-full px-2 py-1 text-xs border border-slate-200 dark:border-slate-600 rounded bg-slate-50 dark:bg-slate-700 text-slate-400 cursor-not-allowed"
              readonly
              ${tooltip(translate("This field is synced from PropertyMapping. Please access the Property Mapping edit page to update this name."))}
            >
          ` : `
            <input type="text" name="table_config[metadata][columns][${index}][name]" value="${col.name || ''}"
              class="w-full px-2 py-1 text-xs border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
          `}
        </td>
        <td class="py-2 px-3 text-center">
          <input type="hidden" name="table_config[metadata][columns][${index}][visible]" value="false">
          <input type="checkbox" name="table_config[metadata][columns][${index}][visible]" value="true" ${col.visible !== false ? 'checked' : ''}
            class="rounded border-slate-300 text-blue-600 cursor-pointer">
        </td>
        <td class="py-2 px-3 text-center">
          ${this.isSearchableColumn(key) ? `
            <input type="hidden" name="table_config[metadata][columns][${index}][search]" value="false">
            <input type="checkbox" id="col-search-${index}" name="table_config[metadata][columns][${index}][search]" value="true" ${col.search === true ? 'checked' : ''}
              class="rounded border-slate-300 text-blue-600 cursor-pointer"
              ${tooltip(translate("Allow keyword search on this column"))}>
          ` : `<span class="text-slate-300 dark:text-slate-700">—</span>`}
        </td>
        <td class="py-2 px-3">
          ${this.canFilter(col) ? `
            <div class="flex items-center gap-2 mb-1">
              <input type="hidden" name="table_config[metadata][columns][${index}][filter_active]" value="false">
              <input type="checkbox" id="col-filter-active-${index}" name="table_config[metadata][columns][${index}][filter_active]" value="true" ${col.filter?.active !== false ? 'checked' : ''}
                class="rounded border-slate-300 text-blue-600 cursor-pointer"
                ${tooltip(translate("Enable this filter on the index page"))}>
              <span class="text-[10px] font-bold text-slate-400 uppercase">${translate("Active")}</span>
            </div>
            <textarea id="col-filter-${index}" name="table_config[metadata][columns][${index}][filter]" rows="2" placeholder='${this.filterSkeleton(col)}'
              class="w-44 px-2 py-1 text-xs font-mono border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">${this.escapeHTML(filterValue)}</textarea>
          ` : `<span class="text-slate-300 dark:text-slate-700">—</span>`}
        </td>
        <td class="py-2 px-3">
          <select name="table_config[metadata][columns][${index}][align]"
            class="w-full px-1 py-1 text-xs border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
            <option value="left" ${col.align === 'left' ? 'selected' : ''}>left</option>
            <option value="center" ${col.align === 'center' ? 'selected' : ''}>center</option>
            <option value="right" ${col.align === 'right' ? 'selected' : ''}>right</option>
          </select>
        </td>
        <td class="py-2 px-3">
          <input type="number" name="table_config[metadata][columns][${index}][width]" value="${col.width ?? ''}" placeholder="auto"
            class="w-16 px-1 py-1 text-xs border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
        </td>
        <td class="py-2 px-3 text-right">
          <button type="button" data-action="click->${this.identifier}#removeColumn" data-index="${index}"
            class="inline-flex items-center justify-center p-1 text-red-500 hover:text-red-700 hover:bg-red-50 rounded-lg cursor-pointer">
            <span class="material-symbols-outlined text-[16px]">delete</span>
          </button>
        </td>
      </tr>
    `
  }
}
