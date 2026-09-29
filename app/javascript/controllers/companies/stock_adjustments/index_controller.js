import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_StockAdjustments_IndexController extends Companies_LayoutController {
  // StockAdjustments dashboard — table hydrates from the index JSON of the current URL.
  // Plain DB path (no Meilisearch service on this controller); category filter only.
  // Depends on BE: Companies::StockAdjustmentsController#index,
  //                #show (lines + ledger), #new (warehouses + stocks), #create
  // Endpoints: GET <pathname>.json?category_id — traditional GET form, full-page submit
  static targets = ["adjustmentsList"]

  /** @type {any[]} */
  adjustments = []

  async connect() {
    super.connect()

    this.categoryIdValue = new URLSearchParams(window.location.search).get('category_id') || this.defaultFilterCategory()?.id

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryIdValue)
    if (propertyMapping) this.propertyMappingIdValue = propertyMapping.id

    const tableConfig = currentTableConfigs().find(c => c.property_mapping_id === this.propertyMappingIdValue)
    if (tableConfig) this.tableConfigIdValue = tableConfig.id

    try {
      const urlParams = new URLSearchParams(window.location.search)
      if (!urlParams.get('category_id') && this.categoryIdValue) urlParams.set('category_id', this.categoryIdValue)
      const response = await fetchJson(`${pathname()}.json?${urlParams.toString()}`)
      this.adjustments = response.stock_adjustments || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load stock adjustments") }${__errDetail ? ": " + __errDetail : ""}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  stockAdjustmentsCategories() {
    return currentCategories().filter(c => c.resource_name === "stock_adjustments")
  }

  defaultFilterCategory() {
    return this.stockAdjustmentsCategories()[0]
  }

  contentHTML() {
    const categoryFilter = this.stockAdjustmentsCategories()
    const categoryValue = this.categoryIdValue || this.defaultFilterCategory()?.id

    const tableConfig = this.currentTableConfig()
    const propertyMapping = this.currentPropertyMapping()

    const fallbackColumns = [
      { key: "code", name: translate("Code") },
      { key: "name", name: translate("Stock Adjustment") },
      { key: "direction", name: translate("Direction") },
      { key: "category_name", name: translate("Category") },
      { key: "quantity", name: translate("Quantity") },
      { key: "workflow_status", name: translate("Status") }
    ]

    const rawColumns = tableConfig?.metadata?.columns || fallbackColumns
    const visibleColumns = rawColumns.filter(col => col.visible !== false)

    const mappingLookup = (propertyMapping?.metadata?.properties || []).reduce((acc, field) => {
      acc[field.key] = field
      return acc
    }, {})

    const urlParams = new URLSearchParams(window.location.search)
    const searchHTML = dynamicSearchHTML({ searchCols: rawColumns.filter(c => c.search === true), urlParams })
    const filtersHTML = dynamicFiltersHTML({
      filterCols: rawColumns.filter(c => c.filter && typeof c.filter === "object" && c.filter.type && c.filter.active !== false),
      urlParams,
      mappingLookup
    })

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          ${this.renderTableTitle()}

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end justify-between gap-4 w-full">
              <div class="flex flex-wrap items-center gap-3 w-full lg:w-auto">
                ${searchHTML}
                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("Category")}</label>
                  <select
                    name="category_id"
                    class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300"
                  >
                    ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), categoryValue)}
                  </select>
                </div>
                ${filtersHTML}
                <div class="flex gap-2 mt-auto">
                  <button type="submit" class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm flex items-center gap-2">
                    <span class="material-symbols-outlined text-[18px]!">search</span>
                    ${translate("Search")}
                  </button>
                </div>
              </div>

              <a href="${Helpers.new_company_stock_adjustment_path(currentCompany().id)}"
                class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap cursor-pointer">
                <span class="material-symbols-outlined text-[20px]">add</span>
                ${translate("Add")}
              </a>
            </form>
          </div>

          <div class="overflow-x-auto">
            ${table({
              rows: this.adjustments,
              columns: visibleColumns,
              identifier: this.identifier,
              target: "adjustmentsList",
              mappingLookup,
              renderers: {
                name: (value, record) => `
                  <a href="${Helpers.company_stock_adjustment_path(currentCompany().id, record.id)}"
                    class="font-medium text-slate-900 dark:text-white overflow-visible whitespace-normal hover:text-blue-600 dark:hover:text-blue-400 transition-colors cursor-pointer">
                    ${value || translate("Unnamed Stock Adjustment")}
                  </a>`,
                code: (value) => `<span class="font-mono text-xs bg-slate-100 dark:bg-slate-800/60 px-2 py-0.5 rounded text-slate-600 dark:text-slate-300 font-medium">${value || '—'}</span>`,
                quantity: (value) => `<span class="font-medium text-slate-900 dark:text-white">${value ?? 0}</span>`,
                direction: (value) => `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium capitalize ${value === 'decrease' ? 'bg-amber-100 text-amber-800 dark:bg-amber-900/50 dark:text-amber-300' : 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/50 dark:text-emerald-300'}">${value || '—'}</span>`,
                business_type: (value) => `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-300">${Helpers.capitalize((value || 'purchase').replace(/_/g, ' '))}</span>`,
                workflow_status: (value) => `${Helpers.statusBadge(value)}`,
              }
            })}
          </div>

          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}
