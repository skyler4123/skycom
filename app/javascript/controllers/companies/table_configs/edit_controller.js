import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_TableConfigs_EditController extends Companies_LayoutController {
  // TableConfig editor — rows carry key/name/visible/search/filter.
  // The filter is edited with a type select and typed bucket inputs (no JSON).
  // Depends on BE: Companies::TableConfigsController#show (JSON hydration),
  //               Companies::TableConfigsController#update (form PATCH + normalize_column_types)
  // Docs: docs/DYNAMIC_TABLE.md
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
        <p class="text-sm text-muted-foreground">${translate("Controls how data is displayed in this table. Dynamic property names are managed in the Property Mapping.")}</p>

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
                  ${tooltip(translate("Manage property fields: show/hide columns and rename them"))}
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
                    ${tooltip(translate("Choose how this column filters. The Active checkbox enables it on the index page."))}
                  >${translate("Filter")}</th>
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
      search: false
    })

    const select = document.getElementById('new-column-slot')
    if (select) select.value = ''
    this.rerenderEditor()
  }

  availableColumns() {
    const usedKeys = new Set((this.columnsMetadata || []).map(c => c.key))
    const candidateKeys = [
      'name', 'description', 'code', 'title', 'quantity', 'pending',
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
    if (key === 'quantity') return 'Quantity'
    if (key === 'pending') return 'Pending'
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
    if (["name", "description", "code", "title"].includes(key)) return "string"
    if (["quantity", "pending"].includes(key)) return "integer"
    const match = /^property_(string|integer|decimal|boolean|datetime)_\d+$/.exec(key)
    return match ? match[1] : null
  }

  isSearchableColumn(key) {
    if (!key || key.startsWith("extra_")) return false
    return ["name", "description", "code", "title"].includes(key) || key.startsWith("property_string_")
  }

  filterTypeOptions(key) {
    const type = this.columnType(key)
    const options = []

    if (type === "integer") {
      options.push({ value: "range", label: "Range" })
      if (this.propertyEntryFor(key)?.input_type === "select") {
        options.push({ value: "enum", label: "Enum" })
      }
    } else if (type === "decimal") {
      options.push({ value: "range", label: "Range" })
    } else if (type === "boolean") {
      options.push({ value: "boolean", label: "Boolean" })
    } else if (type === "datetime") {
      options.push({ value: "date", label: "Date" })
    }

    return options
  }

  canFilter(col) {
    if (col.key?.startsWith("extra_")) return false
    return this.filterTypeOptions(col.key).length > 0
  }

  defaultBucketsFor(col) {
    const type = this.columnType(col.key)
    if (type === "datetime") {
      const year = new Date().getFullYear()
      return [ [ null, year - 1 ], [ year - 1, year ], [ year, null ] ]
    }
    if (type === "decimal") return [ [ null, 10 ], [ 10, null ] ]
    return [ [ null, 100 ], [ 100, null ] ]
  }

  filterCellHTML(col, index) {
    if (!this.canFilter(col)) return `<span class="text-muted-foreground/60">—</span>`

    const filter = col.filter && typeof col.filter === "object" ? col.filter : {}
    const options = this.filterTypeOptions(col.key)
    const selectedType = options.some(o => o.value === filter.type) ? filter.type : ""
    const active = filter.active !== false
    const buckets = Array.isArray(filter.buckets) ? filter.buckets : []

    return `
      <div class="space-y-2 min-w-[220px]">
        <select id="col-filter-type-${index}" name="table_config[metadata][columns][${index}][filter][type]"
          data-action="change->${this.identifier}#onFilterTypeChange" data-index="${index}"
          class="w-full px-2 py-1 text-xs border border-line rounded bg-card text-foreground">
          <option value="">${translate("None")}</option>
          ${options.map(o => `<option value="${o.value}" ${selectedType === o.value ? 'selected' : ''}>${translate(o.label)}</option>`).join('')}
        </select>

        ${selectedType ? `
          <div class="flex items-center gap-2">
            <input type="hidden" name="table_config[metadata][columns][${index}][filter][active]" value="false">
            <input type="checkbox" id="col-filter-active-${index}" name="table_config[metadata][columns][${index}][filter][active]" value="true" ${active ? 'checked' : ''}
              class="rounded border-line text-primary cursor-pointer"
              ${tooltip(translate("Enable this filter on the index page"))}>
            <span class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Active")}</span>
          </div>
          ${this.filterBucketsHTML(col, index, selectedType, buckets)}
        ` : ''}
      </div>
    `
  }

  filterBucketsHTML(col, index, type, buckets) {
    if (type !== "range" && type !== "date") return ""

    const step = type === "date" ? "1" : (this.columnType(col.key) === "decimal" ? "any" : "1")

    const rows = buckets.map((bucket, bucketIndex) => {
      const from = Array.isArray(bucket) ? bucket[0] : null
      const to = Array.isArray(bucket) ? bucket[1] : null

      return `
        <div class="flex items-center gap-1">
          <input type="number" step="${step}" id="col-filter-bucket-${index}-${bucketIndex}-from"
            name="table_config[metadata][columns][${index}][filter][buckets][${bucketIndex}][from]"
            value="${from ?? ''}" placeholder="${translate("From")}"
            class="w-20 px-1 py-1 text-xs border border-line rounded bg-card text-foreground">
          <span class="text-muted-foreground">–</span>
          <input type="number" step="${step}" id="col-filter-bucket-${index}-${bucketIndex}-to"
            name="table_config[metadata][columns][${index}][filter][buckets][${bucketIndex}][to]"
            value="${to ?? ''}" placeholder="${translate("To")}"
            class="w-20 px-1 py-1 text-xs border border-line rounded bg-card text-foreground">
          <button type="button" data-action="click->${this.identifier}#removeFilterBucket"
            data-index="${index}" data-bucket-index="${bucketIndex}"
            class="inline-flex items-center justify-center p-1 text-danger hover:text-danger hover:bg-danger/10 rounded cursor-pointer"
            ${tooltip(translate("Remove Bucket"))}>
            <span class="material-symbols-outlined text-[14px]">remove</span>
          </button>
        </div>
      `
    }).join('')

    return `
      <div class="space-y-1">
        ${rows}
        <button type="button" data-action="click->${this.identifier}#addFilterBucket" data-index="${index}"
          class="inline-flex items-center gap-1 text-xs font-medium text-primary hover:text-primary hover:bg-primary/10 rounded px-1 py-0.5 cursor-pointer">
          <span class="material-symbols-outlined text-[14px]">add</span>
          ${translate("Add Bucket")}
        </button>
      </div>
    `
  }

  onFilterTypeChange(event) {
    const index = parseInt(event.currentTarget.getAttribute("data-index"))
    const col = this.columnsMetadata[index]
    if (!col) return

    const type = event.currentTarget.value
    if (!type) {
      delete col.filter
    } else {
      col.filter = { type, active: col.filter?.active !== false }
      if (type === "range" || type === "date") {
        col.filter.buckets = this.defaultBucketsFor(col)
      }
    }

    this.rerenderFilterCell(index)
  }

  addFilterBucket(event) {
    const index = parseInt(event.currentTarget.getAttribute("data-index"))
    this.syncFilterCellFromDOM(index)

    const filter = this.columnsMetadata[index]?.filter
    if (!filter) return

    filter.buckets = Array.isArray(filter.buckets) ? filter.buckets : []
    filter.buckets.push([ null, null ])
    this.rerenderFilterCell(index)
  }

  removeFilterBucket(event) {
    const index = parseInt(event.currentTarget.getAttribute("data-index"))
    const bucketIndex = parseInt(event.currentTarget.getAttribute("data-bucket-index"))
    if (isNaN(index) || isNaN(bucketIndex)) return

    this.syncFilterCellFromDOM(index)
    this.columnsMetadata[index]?.filter?.buckets?.splice(bucketIndex, 1)
    this.rerenderFilterCell(index)
  }

  syncFilterCellFromDOM(index) {
    const col = this.columnsMetadata[index]
    if (!col) return

    const type = document.getElementById(`col-filter-type-${index}`)?.value || ""
    if (!type) {
      delete col.filter
      return
    }

    const activeCheckbox = document.getElementById(`col-filter-active-${index}`)
    const filter = { type, active: activeCheckbox ? activeCheckbox.checked : true }

    if (type === "range" || type === "date") {
      const buckets = []
      const current = Array.isArray(col.filter?.buckets) ? col.filter.buckets : []

      current.forEach((_, bucketIndex) => {
        const from = document.getElementById(`col-filter-bucket-${index}-${bucketIndex}-from`)?.value
        const to = document.getElementById(`col-filter-bucket-${index}-${bucketIndex}-to`)?.value
        buckets.push([ from === "" ? null : from, to === "" ? null : to ])
      })

      filter.buckets = buckets
    }

    col.filter = filter
  }

  rerenderFilterCell(index) {
    const cell = document.getElementById(`col-filter-cell-${index}`)
    if (!cell) return
    cell.innerHTML = this.filterCellHTML(this.columnsMetadata[index], index)
  }

  escapeHTML(str) {
    return String(str).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }

  columnRowHTML(col, index) {
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
        <td class="py-2 px-3" id="col-filter-cell-${index}">
          ${this.filterCellHTML(col, index)}
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
