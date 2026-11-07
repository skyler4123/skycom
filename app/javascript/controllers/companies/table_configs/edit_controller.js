import Companies_LayoutController from "controllers/companies/layout_controller"
import {
  STANDARD_COLUMN_NAMES,
  canFilter,
  columnName,
  columnSource,
  columnType,
  columnTypeIcon,
  columnTypeLabel,
  columnTypeTooltip,
  enumChoicesFor,
  filterSummary,
  filterTypeLabel,
  filterTypeOptions,
  isSearchableColumn
} from "controllers/helpers/table_config_helpers"

export default class Companies_TableConfigs_EditController extends Companies_LayoutController {
  // TableConfig editor — displays friendly column labels and controls order,
  // visibility, keyword search, and index filters. Raw keys stay in hidden
  // inputs and are never shown to the manager.
  // Depends on BE: Companies::TableConfigsController#show (JSON hydration),
  //               Companies::PropertyMappingsController#show (labels/types/options),
  //               Companies::TableConfigsController#update (form PATCH + normalize_column_types)
  // Docs: docs/DYNAMIC_TABLE.md
  /** @type {any | null} */
  config = null

  /** @type {Array} */
  columnsMetadata = []

  /** @type {any | null} */
  propertyMapping = null

  /** @type {Array} */
  propertyEntries = []

  /** @type {Array} */
  extraColumns = []

  /** @type {string | null} */
  expandedFilterKey = null

  /** @type {string | null} */
  selectedAddKey = null

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const configId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_table_config_path(companyId, configId)}.json`)
      this.config = response.table_config
      this.columnsMetadata = JSON.parse(JSON.stringify(this.config?.metadata?.columns || []))

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

    const fields = `
      <div class="space-y-6">
        <div>
          <h2 class="text-xl font-bold text-foreground">${translate("Edit Table Config")}</h2>
          <p class="mt-1 text-sm text-muted-foreground">${translate("Choose which columns appear in this table, in what order, and how people can search or filter them.")}</p>
        </div>

        ${this.helpCardHTML()}
        ${this.mappingDetailsHTML(c, companyId)}
        ${this.columnTableHTML()}

        <input type="hidden" name="table_config[metadata][columns_submitted]" value="1">

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
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false" novalidate data-action="submit->${this.identifier}#handleSubmit"`,
          html: fields
        })}
      </div>
    `
  }

  helpCardHTML() {
    return `
      <div class="rounded-lg border border-line bg-muted/40 p-4">
        <p class="text-sm font-medium text-foreground">${translate("Column labels come from Property Mapping. This page controls order, visibility, search, and filters.")}</p>
        <ol class="mt-2 list-inside list-decimal space-y-1 text-sm text-muted-foreground">
          <li>${translate("Add columns — pick from standard columns and category properties.")}</li>
          <li>${translate("Arrange order — use the up/down buttons.")}</li>
          <li>${translate("Configure — choose visibility, keyword search, and index filters.")}</li>
        </ol>
        <div class="mt-3 space-y-1 border-t border-line pt-3 text-xs text-muted-foreground">
          <p>${translate("Range filter: 10 – 20 means 10 ≤ value < 20.")}</p>
          <p>${translate("Date filter: 2024 – 2025 means the year 2024.")}</p>
          <p>${translate("Choice list filter: uses the options defined in Property Mapping.")}</p>
        </div>
      </div>
    `
  }

  mappingDetailsHTML(c, companyId) {
    const categoryName = currentCategories().find(cat => cat.id === c.category_id)?.name || ""
    const mappingName = c.property_mapping?.name || this.propertyMapping?.name || ""

    return `
      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div class="space-y-1 sm:col-span-2">
          <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider"
            ${tooltip(translate("This name identifies the table configuration. It is not a column label."))}
          >${translate("Table Config Name")}</label>
          <input type="text" name="table_config[name]" value="${escapeHtml(c.name || "")}" required
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
        </div>

        <div class="space-y-1 sm:col-span-2">
          <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider"
            ${tooltip(translate("A short description of when this table configuration should be used."))}
          >${translate("Description")}</label>
          <textarea name="table_config[description]" rows="2"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">${escapeHtml(c.description || "")}</textarea>
        </div>

        <div class="space-y-1">
          <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider"
            ${tooltip(translate("The category this table configuration belongs to. It cannot be changed here."))}
          >${translate("Category")}</label>
          <input type="text" value="${escapeHtml(categoryName)}" disabled
            class="w-full px-3 py-2 border border-line rounded-lg bg-background text-sm text-muted-foreground">
          <input type="hidden" name="table_config[category_id]" value="${escapeHtml(c.category_id)}">
        </div>

        <div class="space-y-1">
          <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider"
            ${tooltip(translate("Property labels, types, and choices are managed in the Property Mapping."))}
          >${translate("Property Mapping")}</label>
          <div class="flex items-center gap-2">
            <input type="text" value="${escapeHtml(mappingName)}" disabled
              class="flex-1 px-3 py-2 border border-line rounded-lg bg-background text-sm text-muted-foreground">
            <input type="hidden" name="table_config[property_mapping_id]" value="${escapeHtml(c.property_mapping_id)}">
            ${c.property_mapping_id ? `
              <a href="${Helpers.edit_company_property_mapping_path(companyId, c.property_mapping_id)}"
                class="inline-flex items-center gap-1 px-3 py-2 text-sm font-medium text-primary hover:text-primary hover:bg-primary/10 rounded-lg transition-colors cursor-pointer whitespace-nowrap"
                ${tooltip(translate("Manage property fields, labels, types, and choices."))}
              >
                <span class="material-symbols-outlined text-[18px]!">open_in_new</span>
                ${translate("Edit Property Mapping")}
              </a>
            ` : ""}
          </div>
        </div>
      </div>
    `
  }

  columnTableHTML() {
    return `
      <div class="border-t border-line pt-6 mt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Column Config")}</h3>

        <div class="overflow-x-auto rounded-lg border border-line">
          <table class="w-full min-w-[900px] text-left border-collapse">
            <thead>
              <tr class="text-xs text-muted-foreground bg-muted border-b border-line">
                <th class="py-2 px-3 font-medium"
                  ${tooltip(translate("Column labels are managed in Property Mapping. This page controls display behavior."))}
                >${translate("Display Name")}</th>
                <th class="py-2 px-3 font-medium"
                  ${tooltip(translate("The column data type controls which search and filter options are available."))}
                >${translate("Type")}</th>
                <th class="py-2 px-3 font-medium text-center"
                  ${tooltip(translate("Show this column in the live table. Hidden columns keep their settings and data."))}
                >${translate("Visible")}</th>
                <th class="py-2 px-3 font-medium text-center"
                  ${tooltip(translate("Include this column in the keyword search box on the index page."))}
                >${translate("Search")}</th>
                <th class="py-2 px-3 font-medium"
                  ${tooltip(translate("Configure the index-page filter for this column."))}
                >${translate("Filter")}</th>
                <th class="py-2 px-3 font-medium text-right"
                  ${tooltip(translate("Reorder or remove this column."))}
                >${translate("Actions")}</th>
              </tr>
            </thead>
            <tbody id="columns-body">
              ${this.rowsHTML()}
            </tbody>
          </table>
        </div>

        <div id="add-column-area">
          ${this.addColumnAreaHTML()}
        </div>
      </div>
    `
  }

  rowsHTML() {
    if (this.columnsMetadata.length === 0) {
      return `
        <tr>
          <td colspan="6" class="py-8 px-3 text-center text-sm text-muted-foreground">
            ${translate("No columns yet. Add your first column below.")}
          </td>
        </tr>
      `
    }

    return this.columnsMetadata
      .map((col, index) => `${this.columnRowHTML(col, index)}${this.filterPanelRowHTML(col, index)}`)
      .join("")
  }

  columnRowHTML(col, index) {
    const key = String(col.key || "")
    const displayName = columnName(key, this.propertyEntries, this.extraColumns, col.name || "")
    const source = columnSource(key)
    const type = columnType(key, this.propertyEntries, this.extraColumns)

    return `
      <tr class="border-b border-line last:border-0" data-column-row="${escapeHtml(key)}">
        <td class="py-3 px-3 align-top">
          <input type="hidden" name="table_config[metadata][columns][${index}][key]" value="${escapeHtml(key)}">
          <input type="hidden" name="table_config[metadata][columns][${index}][name]" value="${escapeHtml(displayName)}">
          <div class="flex flex-col gap-1">
            <span class="text-sm font-medium text-foreground" ${tooltip(translate("Column labels are managed in Property Mapping. This page controls display behavior."))}>${escapeHtml(displayName)}</span>
            ${this.sourceBadgeHTML(source)}
          </div>
        </td>
        <td class="py-3 px-3 align-top">
          ${this.typeCellHTML(type)}
        </td>
        <td class="py-3 px-3 align-top text-center">
          <input type="hidden" name="table_config[metadata][columns][${index}][visible]" value="false">
          <input type="checkbox" id="col-visible-${escapeHtml(key)}" name="table_config[metadata][columns][${index}][visible]"
            value="true" ${col.visible !== false ? "checked" : ""} data-column-field="visible"
            class="rounded border-line text-primary cursor-pointer"
            ${tooltip(translate("Show this column in the live table. Hidden columns keep their settings and data."))}>
        </td>
        <td class="py-3 px-3 align-top text-center">
          ${this.searchCellHTML(col, index, key)}
        </td>
        <td class="py-3 px-3 align-top">
          ${this.filterCellHTML(col, key)}
        </td>
        <td class="py-3 px-3 align-top text-right">
          ${this.actionsCellHTML(col, index, key)}
        </td>
      </tr>
    `
  }

  sourceBadgeHTML(source) {
    if (source === "standard") {
      return `<span class="inline-flex w-fit items-center rounded-md border border-line bg-muted px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-wide text-muted-foreground">${translate("Standard")}</span>`
    }

    if (source === "property" || source === "extra") {
      return `<span class="inline-flex w-fit items-center gap-1 rounded-md border border-info/30 bg-info/10 px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-wide text-info">
        <span class="material-symbols-outlined text-[12px]">lock</span>
        ${translate("Property Mapping")}
      </span>`
    }

    return ""
  }

  typeCellHTML(type) {
    if (!type) {
      return `<span class="text-muted-foreground" ${tooltip(translate("No type information is available for this column."))}>—</span>`
    }

    return `<span class="inline-flex w-fit items-center gap-1 rounded-md border border-line bg-card px-2 py-1 text-xs font-medium text-foreground"
      ${tooltip(columnTypeTooltip(type))}>
      <span class="material-symbols-outlined text-[14px]">${columnTypeIcon(type)}</span>
      ${escapeHtml(columnTypeLabel(type))}
    </span>`
  }

  searchCellHTML(col, index, key) {
    if (!isSearchableColumn(key)) {
      return `<span class="text-muted-foreground" ${tooltip(translate("Only text columns can be included in keyword search."))}>
        <span class="material-symbols-outlined text-[16px]">lock</span>
      </span>`
    }

    return `
      <input type="hidden" name="table_config[metadata][columns][${index}][search]" value="false">
      <input type="checkbox" id="col-search-${escapeHtml(key)}" name="table_config[metadata][columns][${index}][search]"
        value="true" ${col.search === true ? "checked" : ""} data-column-field="search"
        class="rounded border-line text-primary cursor-pointer"
        ${tooltip(translate("Include this column in the keyword search box on the index page."))}>
    `
  }

  filterCellHTML(col, key) {
    const options = filterTypeOptions(key, this.propertyEntries, this.extraColumns)
    if (options.length === 0) {
      return `<span class="text-muted-foreground" ${tooltip(translate("This column cannot be used as an index filter."))}>—</span>`
    }

    return `
      <div class="flex items-center gap-2">
        <span id="col-filter-summary-${escapeHtml(key)}" class="text-sm text-muted-foreground">${escapeHtml(filterSummary(col))}</span>
        <button type="button" data-action="click->${this.identifier}#toggleFilterPanel" data-key="${escapeHtml(key)}"
          class="inline-flex items-center gap-1 rounded-lg px-2 py-1 text-xs font-medium text-primary hover:bg-primary/10 cursor-pointer"
          ${tooltip(translate("Open the filter settings for this column."))}>
          ${translate("Configure")}
        </button>
      </div>
    `
  }

  actionsCellHTML(col, index, key) {
    const isFirst = index === 0
    const isLast = index === this.columnsMetadata.length - 1
    const isProtected = key === "name"

    return `
      <div class="inline-flex items-center gap-1">
        <button type="button" data-action="click->${this.identifier}#moveColumn" data-key="${escapeHtml(key)}" data-direction="up"
          ${isFirst ? "disabled" : ""}
          class="inline-flex items-center justify-center rounded-lg p-1 text-muted-foreground hover:bg-muted disabled:opacity-30 disabled:cursor-not-allowed cursor-pointer"
          ${tooltip(translate("Move this column up."))}>
          <span class="material-symbols-outlined text-[16px]">arrow_upward</span>
        </button>
        <button type="button" data-action="click->${this.identifier}#moveColumn" data-key="${escapeHtml(key)}" data-direction="down"
          ${isLast ? "disabled" : ""}
          class="inline-flex items-center justify-center rounded-lg p-1 text-muted-foreground hover:bg-muted disabled:opacity-30 disabled:cursor-not-allowed cursor-pointer"
          ${tooltip(translate("Move this column down."))}>
          <span class="material-symbols-outlined text-[16px]">arrow_downward</span>
        </button>
        <button type="button" data-action="click->${this.identifier}#removeColumn" data-key="${escapeHtml(key)}"
          ${isProtected ? "disabled" : ""}
          class="inline-flex items-center justify-center rounded-lg p-1 text-danger hover:bg-danger/10 disabled:opacity-30 disabled:cursor-not-allowed cursor-pointer"
          ${tooltip(isProtected
            ? translate("The name column is required and cannot be removed.")
            : translate("Removes this column from this table only. The property and its data are not deleted."))}>
          <span class="material-symbols-outlined text-[16px]">delete</span>
        </button>
      </div>
    `
  }

  filterPanelRowHTML(col, index) {
    const key = String(col.key || "")
    if (!canFilter(key, this.propertyEntries, this.extraColumns)) return ""

    const expanded = this.expandedFilterKey === key

    return `
      <tr data-filter-panel="${escapeHtml(key)}" class="${expanded ? "" : "hidden"}">
        <td colspan="6" class="border-b border-line bg-muted/30 px-4 py-4">
          ${this.filterPanelHTML(col, index, key)}
        </td>
      </tr>
    `
  }

  filterPanelHTML(col, index, key) {
    const filter = col.filter && typeof col.filter === "object" ? col.filter : {}
    const options = filterTypeOptions(key, this.propertyEntries, this.extraColumns)
    const selectedType = options.some(option => option.value === filter.type) ? filter.type : ""
    const active = filter.active !== false
    const displayName = columnName(key, this.propertyEntries, this.extraColumns, col.name || "")

    return `
      <div class="space-y-3">
        <div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <div class="flex flex-wrap items-center gap-2">
            <h4 class="text-sm font-bold text-foreground">${translate("Filter for")} ${escapeHtml(displayName)}</h4>
            ${selectedType ? `<span class="inline-flex items-center rounded-md border border-line bg-card px-2 py-1 text-xs font-medium text-foreground">${escapeHtml(filterTypeLabel(selectedType))}</span>` : ""}
          </div>
          <button type="button" data-action="click->${this.identifier}#closeFilterPanel"
            class="inline-flex w-fit items-center rounded-lg px-3 py-1.5 text-sm font-medium text-primary hover:bg-primary/10 cursor-pointer">
            ${translate("Done")}
          </button>
        </div>

        <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider"
              ${tooltip(translate("Choose how this column filters the index page."))}
            >${translate("Filter type")}</label>
            <select id="col-filter-type-${escapeHtml(key)}" data-filter-field="type" data-key="${escapeHtml(key)}"
              name="table_config[metadata][columns][${index}][filter][type]"
              data-action="change->${this.identifier}#onFilterTypeChange"
              class="w-full px-3 py-2 text-sm border border-line rounded-lg bg-card text-foreground">
              <option value="">${translate("None")}</option>
              ${options.map(option => `<option value="${option.value}" ${selectedType === option.value ? "selected" : ""}>${translate(option.label)}</option>`).join("")}
            </select>
          </div>

          ${selectedType ? `
            <div class="flex items-end">
              <div class="flex items-center gap-2 pb-2">
                <input type="hidden" name="table_config[metadata][columns][${index}][filter][active]" value="false">
                <input type="checkbox" id="col-filter-active-${escapeHtml(key)}" data-filter-field="active" data-key="${escapeHtml(key)}"
                  name="table_config[metadata][columns][${index}][filter][active]" value="true" ${active ? "checked" : ""}
                  class="rounded border-line text-primary cursor-pointer"
                  ${tooltip(translate("Only active filters appear on the index page."))}>
                <span class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Active")}</span>
              </div>
            </div>
          ` : ""}
        </div>

        ${this.filterPanelBodyHTML(col, index, key, selectedType, filter)}
      </div>
    `
  }

  filterPanelBodyHTML(col, index, key, selectedType, filter) {
    if (!selectedType) {
      return `<p class="text-sm text-muted-foreground">${translate("Choose a filter type to configure how this column filters the index page.")}</p>`
    }

    if (selectedType === "range" || selectedType === "date") {
      return this.filterBucketsHTML(col, index, key, selectedType, filter.buckets)
    }

    if (selectedType === "enum") {
      return this.enumChoicesHTML(key)
    }

    if (selectedType === "boolean") {
      return `
        <div class="space-y-2">
          <div class="flex items-center gap-2">
            <span class="inline-flex items-center rounded-md border border-success/30 bg-success/10 px-2 py-1 text-xs font-medium text-success">${translate("True")}</span>
            <span class="inline-flex items-center rounded-md border border-line bg-card px-2 py-1 text-xs font-medium text-muted-foreground">${translate("False")}</span>
          </div>
          <p class="text-xs text-muted-foreground">${translate("The index filter shows True and False options.")}</p>
        </div>
      `
    }

    return ""
  }

  filterBucketsHTML(col, index, key, type, buckets) {
    const isDate = type === "date"
    const step = isDate ? "1" : (columnType(key, this.propertyEntries, this.extraColumns) === "decimal" ? "any" : "1")
    const rows = Array.isArray(buckets) ? buckets : []

    const bucketRows = rows.map((bucket, bucketIndex) => {
      const from = Array.isArray(bucket) ? bucket[0] : null
      const to = Array.isArray(bucket) ? bucket[1] : null
      const fromLabel = isDate ? translate("From year") : translate("From")
      const toLabel = isDate ? translate("To year") : translate("To")

      return `
        <div class="flex items-center gap-2" data-filter-bucket="${bucketIndex}">
          <input type="number" step="${step}" id="col-filter-bucket-${escapeHtml(key)}-${bucketIndex}-from"
            name="table_config[metadata][columns][${index}][filter][buckets][${bucketIndex}][from]"
            value="${escapeHtml(from ?? "")}" placeholder="${escapeHtml(fromLabel)}" data-bucket-side="from"
            class="w-24 px-2 py-1.5 text-sm border border-line rounded-lg bg-card text-foreground">
          <span class="text-muted-foreground">–</span>
          <input type="number" step="${step}" id="col-filter-bucket-${escapeHtml(key)}-${bucketIndex}-to"
            name="table_config[metadata][columns][${index}][filter][buckets][${bucketIndex}][to]"
            value="${escapeHtml(to ?? "")}" placeholder="${escapeHtml(toLabel)}" data-bucket-side="to"
            class="w-24 px-2 py-1.5 text-sm border border-line rounded-lg bg-card text-foreground">
          <button type="button" data-action="click->${this.identifier}#removeFilterBucket"
            data-key="${escapeHtml(key)}" data-bucket-index="${bucketIndex}"
            class="inline-flex items-center justify-center rounded-lg p-1 text-danger hover:bg-danger/10 cursor-pointer"
            ${tooltip(translate("Remove this bucket."))}>
            <span class="material-symbols-outlined text-[16px]">remove</span>
          </button>
        </div>
      `
    }).join("")

    return `
      <div class="space-y-2">
        <div class="space-y-2">${bucketRows}</div>
        <button type="button" data-action="click->${this.identifier}#addFilterBucket" data-key="${escapeHtml(key)}"
          class="inline-flex items-center gap-1 rounded-lg px-2 py-1 text-xs font-medium text-primary hover:bg-primary/10 cursor-pointer"
          ${tooltip(translate("Add another bucket to this filter."))}>
          <span class="material-symbols-outlined text-[14px]">add</span>
          ${translate("Add Bucket")}
        </button>
        <p class="text-xs text-muted-foreground">
          ${isDate
            ? translate("Half-open year buckets. 2024 – 2025 means the year 2024.")
            : translate("From is inclusive, To is exclusive. Leave one side blank for an open-ended bucket.")}
        </p>
      </div>
    `
  }

  enumChoicesHTML(key) {
    const choices = enumChoicesFor(key, this.propertyEntries)
    const companyId = window.location.pathname.split("/")[2]
    const mappingId = this.config?.property_mapping_id

    const choicesHTML = choices.length > 0
      ? `<div class="flex flex-wrap gap-2">
          ${choices.map(choice => `
            <span class="inline-flex items-center rounded-md border border-line bg-card px-2 py-1 text-xs font-medium text-foreground">
              ${escapeHtml(choice.value)} = ${escapeHtml(choice.label)}
            </span>
          `).join("")}
        </div>`
      : `<p class="rounded-lg border border-warning/30 bg-warning/10 px-3 py-2 text-xs text-warning">
          ${translate("No choices defined. Add choices in Property Mapping first.")}
        </p>`

    return `
      <div class="space-y-2">
        ${choicesHTML}
        ${mappingId ? `
          <a href="${Helpers.edit_company_property_mapping_path(companyId, mappingId)}"
            class="inline-flex items-center gap-1 text-xs font-medium text-primary hover:bg-primary/10 rounded px-1 py-0.5 cursor-pointer">
            <span class="material-symbols-outlined text-[14px]">open_in_new</span>
            ${translate("Edit choices in Property Mapping")}
          </a>
        ` : ""}
      </div>
    `
  }

  addColumnAreaHTML() {
    const available = this.availableColumns()
    const all = [ ...available.standard, ...available.property, ...available.extra ]

    if (this.selectedAddKey && !all.some(item => item.key === this.selectedAddKey)) {
      this.selectedAddKey = null
    }

    if (all.length === 0) {
      return `<p class="mt-4 rounded-lg border border-dashed border-line bg-muted/30 px-4 py-3 text-sm text-muted-foreground">${translate("All available columns are already in this table.")}</p>`
    }

    const optionHTML = (item) => {
      const typeText = item.type ? ` — ${columnTypeLabel(item.type)}` : ""
      return `<option value="${escapeHtml(item.key)}" ${this.selectedAddKey === item.key ? "selected" : ""}>${escapeHtml(item.name)}${escapeHtml(typeText)}</option>`
    }

    const groupHTML = (label, items) => items.length === 0 ? "" : `
      <optgroup label="${translate(label)}">
        ${items.map(optionHTML).join("")}
      </optgroup>
    `

    return `
      <div class="mt-4 rounded-lg border border-dashed border-line bg-muted/30 p-4">
        <label for="new-column-slot" class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider"
          ${tooltip(translate("Pick a column to add. Nothing is added until you click Add Column."))}
        >${translate("Add a column")}</label>
        <div class="mt-2 flex flex-col gap-2 sm:flex-row sm:items-center">
          <select id="new-column-slot"
            class="min-w-0 flex-1 px-3 py-2 text-sm border border-line rounded-lg bg-card text-foreground"
            data-action="change->${this.identifier}#onAddColumnSelectionChange">
            <option value="">${translate("Choose a column")}</option>
            ${groupHTML("Standard columns", available.standard)}
            ${groupHTML("Property columns", available.property)}
            ${groupHTML("Extra columns", available.extra)}
          </select>
          <button type="button" id="add-column-button" data-action="click->${this.identifier}#addColumn"
            ${this.selectedAddKey ? "" : "disabled"}
            class="inline-flex items-center justify-center gap-1 rounded-lg bg-primary px-3 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer">
            <span class="material-symbols-outlined text-[16px]">add</span>
            ${translate("Add Column")}
          </button>
        </div>
        <p id="add-column-hint" class="mt-2 text-xs text-muted-foreground">${escapeHtml(this.addColumnHintText(all))}</p>
      </div>
    `
  }

  availableColumns() {
    const usedKeys = new Set((this.columnsMetadata || []).map(column => column.key))

    const standard = Object.keys(STANDARD_COLUMN_NAMES)
      .filter(key => !usedKeys.has(key))
      .map(key => ({
        key,
        source: "standard",
        name: columnName(key, this.propertyEntries, this.extraColumns),
        type: columnType(key, this.propertyEntries, this.extraColumns)
      }))

    const property = (this.propertyEntries || [])
      .filter(entry => entry?.key && !usedKeys.has(entry.key))
      .map(entry => ({
        key: entry.key,
        source: "property",
        name: entry.name || entry.key,
        type: columnType(entry.key, this.propertyEntries, this.extraColumns)
      }))

    const extra = (this.extraColumns || [])
      .filter(entry => entry?.key && !usedKeys.has(entry.key))
      .map(entry => ({
        key: entry.key,
        source: "extra",
        name: entry.name || entry.key,
        type: columnType(entry.key, this.propertyEntries, this.extraColumns)
      }))

    return { standard, property, extra }
  }

  addColumnHintText(all = null) {
    const items = all || [ ...this.availableColumns().standard, ...this.availableColumns().property, ...this.availableColumns().extra ]
    const selected = items.find(item => item.key === this.selectedAddKey)

    if (!selected) return translate("Choose a column to add.")

    const typeText = selected.type ? columnTypeLabel(selected.type) : translate("Unknown type")
    const sourceText = selected.source === "standard" ? translate("Standard column") : translate("From Property Mapping")
    return `${typeText} · ${sourceText}`
  }

  updateAddColumnUI() {
    const button = document.getElementById("add-column-button")
    if (button) button.disabled = !this.selectedAddKey

    const hint = document.getElementById("add-column-hint")
    if (hint) hint.textContent = this.addColumnHintText()
  }

  onAddColumnSelectionChange(event) {
    this.selectedAddKey = event.currentTarget.value || null
    this.updateAddColumnUI()
  }

  addColumn() {
    const key = this.selectedAddKey
    if (!key) return
    if (this.columnsMetadata.some(column => column.key === key)) return

    this.captureColumnsFromDOM()
    this.columnsMetadata.push({
      key,
      name: columnName(key, this.propertyEntries, this.extraColumns),
      visible: true,
      search: false
    })

    this.selectedAddKey = null
    this.renderTable()

    const row = document.querySelector(`[data-column-row="${key}"]`)
    row?.scrollIntoView({ block: "nearest", behavior: "smooth" })
    this.updateAddColumnUI()
  }

  removeColumn(event) {
    const key = event.currentTarget.getAttribute("data-key")
    if (!key || key === "name") return

    this.captureColumnsFromDOM()
    this.columnsMetadata = this.columnsMetadata.filter(column => column.key !== key)
    if (this.expandedFilterKey === key) this.expandedFilterKey = null
    this.renderTable()
  }

  moveColumn(event) {
    const key = event.currentTarget.getAttribute("data-key")
    const direction = event.currentTarget.getAttribute("data-direction")
    this.captureColumnsFromDOM()

    const index = this.columnsMetadata.findIndex(column => column.key === key)
    if (index < 0) return

    const target = direction === "up" ? index - 1 : index + 1
    if (target < 0 || target >= this.columnsMetadata.length) return

    const [ column ] = this.columnsMetadata.splice(index, 1)
    this.columnsMetadata.splice(target, 0, column)
    this.renderTable()
  }

  toggleFilterPanel(event) {
    const key = event.currentTarget.getAttribute("data-key")
    this.captureColumnsFromDOM()
    this.expandedFilterKey = this.expandedFilterKey === key ? null : key
    this.renderTable()
  }

  closeFilterPanel() {
    this.captureColumnsFromDOM()
    this.expandedFilterKey = null
    this.renderTable()
  }

  onFilterTypeChange(event) {
    const key = event.currentTarget.getAttribute("data-key")
    const type = event.currentTarget.value
    const column = this.columnsMetadata.find(item => item.key === key)
    if (!column) return

    this.captureColumnsFromDOM()
    const active = column.filter?.active !== false

    if (!type) {
      delete column.filter
    } else {
      column.filter = { type, active }
      if (type === "range" || type === "date") {
        column.filter.buckets = this.defaultBucketsFor(column)
      }
    }

    this.expandedFilterKey = key
    this.renderTable()
  }

  addFilterBucket(event) {
    const key = event.currentTarget.getAttribute("data-key")
    this.captureColumnsFromDOM()

    const column = this.columnsMetadata.find(item => item.key === key)
    if (!column?.filter) return

    column.filter.buckets = Array.isArray(column.filter.buckets) ? column.filter.buckets : []
    column.filter.buckets.push([ null, null ])
    this.expandedFilterKey = key
    this.renderTable()
  }

  removeFilterBucket(event) {
    const key = event.currentTarget.getAttribute("data-key")
    const bucketIndex = parseInt(event.currentTarget.getAttribute("data-bucket-index"), 10)
    if (!key || isNaN(bucketIndex)) return

    this.captureColumnsFromDOM()
    const buckets = this.columnsMetadata.find(item => item.key === key)?.filter?.buckets
    if (!Array.isArray(buckets)) return

    buckets.splice(bucketIndex, 1)
    this.expandedFilterKey = key
    this.renderTable()
  }

  defaultBucketsFor(column) {
    const type = columnType(column.key, this.propertyEntries, this.extraColumns)
    if (type === "datetime") {
      const year = new Date().getFullYear()
      return [ [ null, year - 1 ], [ year - 1, year ], [ year, null ] ]
    }
    if (type === "decimal") return [ [ null, 10 ], [ 10, null ] ]
    return [ [ null, 100 ], [ 100, null ] ]
  }

  captureColumnsFromDOM() {
    this.columnsMetadata.forEach((column) => {
      const key = column.key
      const row = document.querySelector(`[data-column-row="${key}"]`)
      if (!row) return

      const visible = row.querySelector('[data-column-field="visible"]')
      if (visible) column.visible = visible.checked

      const search = row.querySelector('[data-column-field="search"]')
      if (search) {
        column.search = search.checked
      } else {
        delete column.search
      }

      const panel = document.querySelector(`[data-filter-panel="${key}"]`)
      if (!panel) {
        delete column.filter
        return
      }

      const type = panel.querySelector('[data-filter-field="type"]')?.value || ""
      if (!type) {
        delete column.filter
        return
      }

      const activeField = panel.querySelector('[data-filter-field="active"]')
      const filter = { type, active: activeField ? activeField.checked : true }

      if (type === "range" || type === "date") {
        const buckets = []
        panel.querySelectorAll("[data-filter-bucket]").forEach((bucketElement) => {
          const from = bucketElement.querySelector('[data-bucket-side="from"]')?.value
          const to = bucketElement.querySelector('[data-bucket-side="to"]')?.value
          buckets.push([
            this.normalizeBucketValue(from),
            this.normalizeBucketValue(to)
          ])
        })
        filter.buckets = buckets
      }

      column.filter = filter
    })
  }

  normalizeBucketValue(value) {
    if (value === "" || value === null || value === undefined) return null

    const number = Number(value)
    return Number.isFinite(number) ? number : value
  }

  validate() {
    const errors = []
    const nameInput = document.querySelector('input[name="table_config[name]"]')

    if (!nameInput || !nameInput.value.trim()) {
      errors.push({
        message: translate("Table config name is required."),
        element: nameInput
      })
    }

    if (this.columnsMetadata.length === 0) {
      errors.push({ message: translate("Add at least one column.") })
    }

    this.columnsMetadata.forEach((column) => {
      const key = column.key
      const filter = column.filter
      if (!filter) return

      const validTypes = filterTypeOptions(key, this.propertyEntries, this.extraColumns).map(option => option.value)
      if (!validTypes.includes(filter.type)) {
        errors.push({
          message: translate("Choose a valid filter type for this column."),
          key,
          element: this.filterTypeElement(key)
        })
        return
      }

      if (filter.type !== "range" && filter.type !== "date") return

      const buckets = Array.isArray(filter.buckets) ? filter.buckets : []
      if (buckets.length === 0) {
        errors.push({
          message: translate("Add at least one filter bucket."),
          key,
          element: this.filterTypeElement(key)
        })
        return
      }

      buckets.forEach((bucket, bucketIndex) => {
        const from = Array.isArray(bucket) ? bucket[0] : null
        const to = Array.isArray(bucket) ? bucket[1] : null
        const fromElement = this.bucketElement(key, bucketIndex, "from")

        if (from === null && to === null) {
          errors.push({
            message: translate("Each filter bucket needs at least one value."),
            key,
            bucketIndex,
            side: "from",
            element: fromElement
          })
          return
        }

        if (filter.type === "date") {
          if (from !== null && !Number.isInteger(Number(from))) {
            errors.push({
              message: translate("Date buckets must use whole years."),
              key,
              bucketIndex,
              side: "from",
              element: fromElement
            })
          }
          if (to !== null && !Number.isInteger(Number(to))) {
            errors.push({
              message: translate("Date buckets must use whole years."),
              key,
              bucketIndex,
              side: "to",
              element: this.bucketElement(key, bucketIndex, "to")
            })
          }
        } else {
          if (from !== null && !Number.isFinite(Number(from))) {
            errors.push({
              message: translate("Numeric buckets must use numbers."),
              key,
              bucketIndex,
              side: "from",
              element: fromElement
            })
          }
          if (to !== null && !Number.isFinite(Number(to))) {
            errors.push({
              message: translate("Numeric buckets must use numbers."),
              key,
              bucketIndex,
              side: "to",
              element: this.bucketElement(key, bucketIndex, "to")
            })
          }
        }

        if (from !== null && to !== null && Number(from) >= Number(to)) {
          errors.push({
            message: translate("From must be less than To."),
            key,
            bucketIndex,
            side: "from",
            element: fromElement
          })
        }
      })
    })

    return errors
  }

  filterTypeElement(key) {
    return document.querySelector(`[data-filter-panel="${key}"] [data-filter-field="type"]`)
  }

  bucketElement(key, bucketIndex, side) {
    return document.querySelector(`[data-filter-panel="${key}"] [data-filter-bucket="${bucketIndex}"] [data-bucket-side="${side}"]`)
  }

  focusFirstInvalid(errors) {
    const first = errors.find(error => error.key || error.element)
    if (!first) return

    if (first.key && this.expandedFilterKey !== first.key) {
      this.expandedFilterKey = first.key
      this.renderTable()
    }

    const element = first.key && first.bucketIndex !== undefined
      ? this.bucketElement(first.key, first.bucketIndex, first.side || "from")
      : (first.key ? this.filterTypeElement(first.key) : first.element)

    if (!element) return

    element.focus()
    element.scrollIntoView({ block: "center", behavior: "smooth" })
  }

  handleSubmit(event) {
    event.preventDefault()
    this.captureColumnsFromDOM()

    const errors = this.validate()
    if (errors.length > 0) {
      toast({ type: "error", message: errors.map(error => error.message).join(". ") })
      this.focusFirstInvalid(errors)
      return
    }

    event.target.submit()
  }

  renderTable() {
    const tbody = document.getElementById("columns-body")
    if (tbody) tbody.innerHTML = this.rowsHTML()

    const addArea = document.getElementById("add-column-area")
    if (addArea) addArea.innerHTML = this.addColumnAreaHTML()

    this.updateAddColumnUI()
  }
}
