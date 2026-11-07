import Companies_LayoutController from "controllers/companies/layout_controller"
import {
  columnName,
  columnType,
  columnTypeIcon,
  columnTypeLabel,
  columnTypeTooltip,
  filterSummary
} from "controllers/helpers/table_config_helpers"

// Read-only Table Config detail page — friendly labels/types/filter summaries,
// never raw keys.
// Depends on BE: Companies::TableConfigsController#show (JSON hydration),
//               Companies::PropertyMappingsController#show (labels/types)
// Docs: docs/DYNAMIC_TABLE.md
export default class Companies_TableConfigs_ShowController extends Companies_LayoutController {
  /** @type {any | null} */
  config = null

  /** @type {any | null} */
  propertyMapping = null

  /** @type {Array} */
  propertyEntries = []

  /** @type {Array} */
  extraColumns = []

  async connect() {
    super.connect()

    const configId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_table_config_path(companyId, configId)}.json`)
      this.config = response.table_config

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
    return this.showHTML()
  }

  showHTML() {
    const c = this.config
    if (!c) return `<div class="p-8 text-center">${translate("Table config not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const category = currentCategories().find(cat => cat.id === c.category_id)
    const columns = c.metadata?.columns || []

    const columnsTable = columns.length > 0 ? `
      <div class="border-t border-line pt-6 mt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Column Config")}</h3>
        <div class="overflow-x-auto rounded-lg border border-line">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="text-sm text-muted-foreground bg-muted border-b border-line">
                <th class="py-3 px-4 font-medium whitespace-nowrap"
                  ${tooltip(translate("Column labels come from Property Mapping."))}
                >${translate("Display Name")}</th>
                <th class="py-3 px-4 font-medium whitespace-nowrap"
                  ${tooltip(translate("The column data type controls which search and filter options are available."))}
                >${translate("Type")}</th>
                <th class="py-3 px-4 font-medium whitespace-nowrap"
                  ${tooltip(translate("Whether this column appears in the live table."))}
                >${translate("Visible")}</th>
                <th class="py-3 px-4 font-medium whitespace-nowrap"
                  ${tooltip(translate("Whether this column participates in keyword search."))}
                >${translate("Search")}</th>
                <th class="py-3 px-4 font-medium whitespace-nowrap"
                  ${tooltip(translate("The index-page filter configured for this column."))}
                >${translate("Filter")}</th>
              </tr>
            </thead>
            <tbody>
              ${columns.map(col => this.columnRowHTML(col)).join("")}
            </tbody>
          </table>
        </div>
      </div>
    ` : ""

    const colCount = columns.length

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_table_configs_path(companyId)}"
            class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Dynamic Tables")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-info/30 bg-info/10 shadow-lg flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-info">table</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-foreground">${escapeHtml(c.name)}</h2>
              <p class="font-semibold text-info">${escapeHtml(c.description || "")}</p>
              <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-info/10 px-3 py-1 text-xs font-bold text-info">${colCount} ${translate("columns")}</span>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-line pt-6 sm:grid-cols-2">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-info">
                <span class="material-symbols-outlined">category</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Category")}</p>
                <p class="text-sm font-semibold text-foreground">${escapeHtml(category?.name || c.category?.name || "N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-info">
                <span class="material-symbols-outlined">settings_applications</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Property Mapping")}</p>
                ${c.property_mapping_id
                  ? `<a href="${Helpers.company_property_mapping_path(companyId, c.property_mapping_id)}"
                       class="inline-flex items-center gap-1 text-sm font-semibold text-primary hover:text-primary transition-colors cursor-pointer">
                       <span class="material-symbols-outlined text-[16px]">open_in_new</span>
                       ${escapeHtml(c.property_mapping?.name || this.propertyMapping?.name || "N/A")}
                     </a>`
                  : `<p class="text-sm font-semibold text-foreground">N/A</p>`}
              </div>
            </div>
          </div>

          ${columnsTable}

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-line">
            <a href="${Helpers.edit_company_table_config_path(companyId, c.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer"
              ${tooltip(translate("Edit or add columns to this table configuration"))}
            >
              ${translate("Edit Table Config")}
            </a>
          </div>
        </div>
      </div>
    `
  }

  columnRowHTML(col) {
    const key = String(col.key || "")
    const displayName = columnName(key, this.propertyEntries, this.extraColumns, col.name || "")
    const type = columnType(key, this.propertyEntries, this.extraColumns)
    const searchable = col.search === true

    return `
      <tr class="border-b border-line last:border-0 hover:bg-muted/50">
        <td class="py-3 px-4 text-sm font-medium text-foreground">${escapeHtml(displayName)}</td>
        <td class="py-3 px-4">
          ${type ? `
            <span class="inline-flex w-fit items-center gap-1 rounded-md border border-line bg-card px-2 py-1 text-xs font-medium text-foreground"
              ${tooltip(columnTypeTooltip(type))}>
              <span class="material-symbols-outlined text-[14px]">${columnTypeIcon(type)}</span>
              ${escapeHtml(columnTypeLabel(type))}
            </span>
          ` : `<span class="text-muted-foreground">—</span>`}
        </td>
        <td class="py-3 px-4">
          ${col.visible !== false
            ? `<span class="text-success text-sm font-medium">${translate("Yes")}</span>`
            : `<span class="text-muted-foreground text-sm">${translate("No")}</span>`}
        </td>
        <td class="py-3 px-4">
          ${searchable
            ? `<span class="text-success text-sm font-medium">${translate("Yes")}</span>`
            : `<span class="text-muted-foreground text-sm">—</span>`}
        </td>
        <td class="py-3 px-4 text-sm text-muted-foreground">${escapeHtml(filterSummary(col))}</td>
      </tr>
    `
  }
}
