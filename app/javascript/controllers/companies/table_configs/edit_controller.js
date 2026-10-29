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

      /** @type {any | null} */
      this.propertyMapping = null
      if (this.config?.property_mapping_id) {
        try {
          const pmResponse = await fetchJson(`${Helpers.company_property_mapping_path(companyId, this.config.property_mapping_id)}.json`)
          this.propertyMapping = pmResponse.property_mapping || null
        } catch (e) {
          this.propertyMapping = currentPropertyMappings().find(m => m.id === this.config?.property_mapping_id) || null
        }
      }
      /** @type {Array} */
      this.propertyEntries = this.propertyMapping?.metadata?.properties || []
      /** @type {Array} */
      this.extraColumns = this.propertyMapping?.metadata?.extra_columns || []

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load table config.")}</div>`
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
        <h2 class="text-xl font-bold text-foreground">${translate("Edit Table Config")}</h2>
        <p class="text-sm text-muted-foreground">${translate("Controls how data is displayed in this table. To show/hide columns, add constraints or validation rules, click the Property Mapping link below.")}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Name")}</label>
            <input type="text" name="table_config[name]" value="${c.name || ''}" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="table_config[description]" rows="2"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">${c.description || ''}</textarea>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Category")}</label>
            <input type="text" value="${currentCategories().find(cat => cat.id === c.category_id)?.name || ''}" disabled
              class="w-full px-3 py-2 border border-line rounded-lg bg-background text-sm text-muted-foreground">
            <input type="hidden" name="table_config[category_id]" value="${c.category_id}">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Property Mapping")}</label>
            <div class="flex items-center gap-2">
              <input type="text" value="${c.property_mapping?.name || ''}" disabled
                class="flex-1 px-3 py-2 border border-line rounded-lg bg-background text-sm text-muted-foreground">
              <input type="hidden" name="table_config[property_mapping_id]" value="${c.property_mapping_id}">
              ${c.property_mapping_id ? `
                <a href="${Helpers.edit_company_property_mapping_path(companyId, c.property_mapping_id)}"
                  class="inline-flex items-center gap-1 px-3 py-2 text-sm font-medium text-primary hover:text-primary hover:bg-primary/10 rounded-lg transition-colors cursor-pointer whitespace-nowrap"
                  ${tooltip(translate("Manage property fields: show/hide columns, add constraints or validation rules"))}
                >
                  <span class="material-symbols-outlined text-[18px]!">open_in_new</span>
                  ${translate("Edit")}
                </a>
              ` : ''}
            </div>
          </div>
        </div>

        <div class="border-t border-line pt-6 mt-6">
          <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Column Config")}</h3>

          <div class="overflow-x-auto rounded-lg border border-line">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-xs text-muted-foreground bg-muted border-b border-line">
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

          <div id="add-column-area" class="mt-3">
            ${this.addColumnDropdownHTML()}
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_table_config_path(companyId, c.id)}"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer">
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
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }

  addColumn(event) {
    let selectedKey = null
    if (event?.currentTarget?.tagName === 'SELECT') {
      selectedKey = event.currentTarget.value
    } else {
      const select = document.getElementById('new-column-slot')
      selectedKey = select?.value || null
    }
    if (!selectedKey) return

    const usedKeys = new Set((this.columnsMetadata || []).map(c => c.key))
    if (usedKeys.has(selectedKey)) return

    this.columnsMetadata.push({
      key: selectedKey,
      name: this.rawColumnNameFor(selectedKey),
      visible: true,
      search: false,
      align: 'left',
      width: null
    })

    const select = document.getElementById('new-column-slot')
    if (select) select.value = ''
    this.rerenderEditor()
  }

  availableColumns() {
    const usedKeys = new Set((this.columnsMetadata || []).map(c => c.key))
    const candidateKeys = [
      'name', 'description', 'code', 'title',
      ...(this.allPropertySlots ? this.allPropertySlots().map(s => s.key) : [])
    ]
    const seen = new Set()
    const result = []
    for (const key of candidateKeys) {
      if (seen.has(key) || usedKeys.has(key)) continue
      seen.add(key)
      result.push({ key, name: this.rawColumnNameFor(key) })
    }
    return result
  }

  rawColumnNameFor(key) {
    if (key === 'name') return 'Name'
    if (key === 'description') return 'Description'
    if (key === 'code') return 'Code'
    if (key === 'title') return 'Title'
    const entry = this.propertyEntryFor(key)
    if (entry?.name) return entry.name
    const extra = this.extraEntryFor(key)
    if (extra?.name) return extra.name
    return key
  }

  addColumnDropdownHTML() {
    const available = this.availableColumns()
    if (available.length === 0) {
      return `<p class="text-sm text-muted-foreground mt-3">${translate("All columns are in use.")}</p>`
    }
    return `
      <div class="flex items-center gap-2 mt-3">
        <label for="new-column-slot" class="sr-only">${translate("Add Column")}</label>
        <select id="new-column-slot"
          class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground"
          data-action="change->${this.identifier}#addColumn">
          <option value="">${translate("Add Column")}</option>
          ${available.map(c => `<option value="${this.escapeHTML(c.key)}">${this.escapeHTML(c.name)}</option>`).join('')}
        </select>
        <button type="button" data-action="click->${this.identifier}#addColumn"
          class="px-3 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg text-sm font-medium transition-colors cursor-pointer">
          ${translate("Add Column")}
        </button>
      </div>
    `
  }

  allPropertySlots() {
    const slots = []
    // Only columns actually defined in the Property Mapping (no undefined dynamic slots).
    for (const entry of (this.propertyEntries || [])) {
      if (entry?.key) slots.push({ key: entry.key })
    }
    for (const ec of (this.extraColumns || [])) {
      if (ec?.key) slots.push({ key: ec.key })
    }
    // Fall back to client cache if the fresh fetch did not populate anything.
    if (slots.length === 0) {
      const pm = (window.currentPropertyMappings?.() || []).find(m => m.id === this.config?.property_mapping_id)
      for (const entry of (pm?.metadata?.properties || [])) {
        if (entry?.key) slots.push({ key: entry.key })
      }
      for (const ec of (pm?.metadata?.extra_columns || [])) {
        if (ec?.key) slots.push({ key: ec.key })
      }
    }
    return slots
  }

  removeColumn(event) {
    const index = parseInt(event.currentTarget.getAttribute('data-index'))
    if (isNaN(index)) return

    this.columnsMetadata.splice(index, 1)
    this.rerenderEditor()
  }

  rerenderEditor() {
    const tbody = document.getElementById('columns-body')
    if (tbody) tbody.innerHTML = this.columnsMetadata.map((col, index) => this.columnRowHTML(col, index)).join('')
    const addArea = document.getElementById('add-column-area')
    if (addArea) addArea.innerHTML = this.addColumnDropdownHTML()
  }

  propertyEntryFor(key) {
    return this.propertyEntries.find(p => p.key === key) || null
  }

  extraEntryFor(key) {
    const found = (this.extraColumns || []).find(e => e.key === key)
    if (found) return found
    const pm = (window.currentPropertyMappings?.() || []).find(m => m.id === this.config?.property_mapping_id)
    return (pm?.metadata?.extra_columns || []).find(e => e.key === key) || null
  }

  columnType(key) {
    const entry = this.propertyEntryFor(key)
    if (entry?.type) return entry.type
    const pm = (window.currentPropertyMappings?.() || []).find(m => m.id === this.config?.property_mapping_id)
    const extra = (pm?.metadata?.extra_columns || []).find(e => e.key === key)
    if (extra?.type) return extra.type
    const match = /^property_(string|integer|decimal|boolean|datetime)_\d+$/.exec(key)
    return match ? match[1] : null
  }

  isSearchableColumn(key) {
    if (!key || key.startsWith("extra_")) return false
    return key === "name" || key === "description" || key === "code" || key.startsWith("property_string_")
  }

  canFilter(col) {
    if (col.key?.startsWith("extra_")) return false
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
        return '{"type":"boolean"}'
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
      <tr class="border-b border-line last:border-0">
        <td class="py-2 px-3">
          <input type="text" name="table_config[metadata][columns][${index}][key]" value="${key}" readonly
            class="w-full px-2 py-1 text-xs font-mono border border-line rounded bg-background text-muted-foreground cursor-not-allowed">
        </td>
        <td class="py-2 px-3">
          ${key.startsWith('property_') || key.startsWith('extra_') ? `
            <input type="text" name="table_config[metadata][columns][${index}][name]" value="${col.name || ''}"
              class="w-full px-2 py-1 text-xs border border-line rounded bg-background text-muted-foreground cursor-not-allowed"
              readonly
              ${tooltip(translate("This field is synced from PropertyMapping. Please access the Property Mapping edit page to update this name."))}
            >
          ` : `
            <input type="text" name="table_config[metadata][columns][${index}][name]" value="${col.name || ''}"
              class="w-full px-2 py-1 text-xs border border-line rounded bg-card text-foreground">
          `}
        </td>
        <td class="py-2 px-3 text-center">
          <input type="hidden" name="table_config[metadata][columns][${index}][visible]" value="false">
          <input type="checkbox" name="table_config[metadata][columns][${index}][visible]" value="true" ${col.visible !== false ? 'checked' : ''}
            class="rounded border-line text-primary cursor-pointer">
        </td>
        <td class="py-2 px-3 text-center">
          ${this.isSearchableColumn(key) ? `
            <input type="hidden" name="table_config[metadata][columns][${index}][search]" value="false">
            <input type="checkbox" id="col-search-${index}" name="table_config[metadata][columns][${index}][search]" value="true" ${col.search === true ? 'checked' : ''}
              class="rounded border-line text-primary cursor-pointer"
              ${tooltip(translate("Allow keyword search on this column"))}>
          ` : `<span class="text-muted-foreground/60">—</span>`}
        </td>
        <td class="py-2 px-3">
          ${this.canFilter(col) ? `
            <div class="flex items-center gap-2 mb-1">
              <input type="hidden" name="table_config[metadata][columns][${index}][filter_active]" value="false">
              <input type="checkbox" id="col-filter-active-${index}" name="table_config[metadata][columns][${index}][filter_active]" value="true" ${col.filter?.active !== false ? 'checked' : ''}
                class="rounded border-line text-primary cursor-pointer"
                ${tooltip(translate("Enable this filter on the index page"))}>
              <span class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Active")}</span>
            </div>
            <textarea id="col-filter-${index}" name="table_config[metadata][columns][${index}][filter]" rows="2" placeholder='${this.filterSkeleton(col)}'
              class="w-44 px-2 py-1 text-xs font-mono border border-line rounded bg-card text-foreground">${this.escapeHTML(filterValue)}</textarea>
          ` : `<span class="text-muted-foreground/60">—</span>`}
        </td>
        <td class="py-2 px-3">
          <select name="table_config[metadata][columns][${index}][align]"
            class="w-full px-1 py-1 text-xs border border-line rounded bg-card text-foreground">
            <option value="left" ${col.align === 'left' ? 'selected' : ''}>left</option>
            <option value="center" ${col.align === 'center' ? 'selected' : ''}>center</option>
            <option value="right" ${col.align === 'right' ? 'selected' : ''}>right</option>
          </select>
        </td>
        <td class="py-2 px-3">
          <input type="number" name="table_config[metadata][columns][${index}][width]" value="${col.width ?? ''}" placeholder="auto"
            class="w-16 px-1 py-1 text-xs border border-line rounded bg-card text-foreground">
        </td>
        <td class="py-2 px-3 text-right">
          <button type="button" data-action="click->${this.identifier}#removeColumn" data-index="${index}"
            class="inline-flex items-center justify-center p-1 text-danger hover:text-danger hover:bg-danger/10 rounded-lg cursor-pointer">
            <span class="material-symbols-outlined text-[16px]">delete</span>
          </button>
        </td>
      </tr>
    `
  }
}
