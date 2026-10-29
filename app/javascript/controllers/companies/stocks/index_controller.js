import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Stocks_IndexController extends Companies_LayoutController {
  // Stocks dashboard — table hydrates from the index JSON of the current URL.
  // Search/filter controls render from the active TableConfig via the shared helpers
  // (dynamicSearchHTML / dynamicFiltersHTML).
  // Depends on BE: Companies::StocksController#index (list + Meilisearch q / filters[key])
  // Endpoints: GET <pathname>.json?category_id&branch_id&q&filters[key] — traditional GET form, full-page submit
  // Docs: docs/DYNAMIC_TABLE.md §2.5
  static targets = ["stocksList"]

  /** @type {Stock[]} */
  stocks = []

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
      this.stocks = response.stocks || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load stocks") }${__errDetail ? ": " + __errDetail : ""}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  stocksCategories() {
    return currentCategories().filter(c => c.resource_name === "stocks")
  }

  defaultFilterCategory() {
    return this.stocksCategories()[0]
  }

  contentHTML() {
    const categoryFilter = this.stocksCategories()
    const categoryValue = this.categoryIdValue || this.defaultFilterCategory()?.id
    const branchValue = new URLSearchParams(window.location.search).get('branch_id') || ''

    const tableConfig = this.currentTableConfig()
    const propertyMapping = this.currentPropertyMapping()

    const fallbackColumns = [
      { key: "name", name: translate("Stock Name") },
      { key: "product_name", name: translate("Product") },
      { key: "category_name", name: translate("Category") },
      { key: "warehouse_name", name: translate("Warehouse") },
      { key: "quantity", name: translate("Quantity") },
      { key: "pending", name: translate("Pending") },
      { key: "business_type", name: translate("Type") },
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
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col">

          ${this.renderTableTitle()}

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end justify-between gap-4 w-full">
              <div class="flex flex-wrap items-center gap-3 w-full lg:w-auto">
                ${searchHTML}
                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Category")}</label>
                  <select
                    name="category_id"
                    class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground"
                  >
                    ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), categoryValue)}
                  </select>
                </div>
                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Branch")}</label>
                  <select
                    name="branch_id"
                    class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground"
                  >
                    ${selectOptionsHTML(cloneNewKey(currentBranches(), "id", "value"), branchValue, translate("All Branches"))}
                  </select>
                </div>
                ${filtersHTML}
                <div class="flex gap-2 mt-auto">
                  <button type="submit" class="h-[38px] px-6 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg transition-colors font-medium text-sm flex items-center gap-2">
                    <span class="material-symbols-outlined text-[18px]!">search</span>
                    ${translate("Search")}
                  </button>
                </div>
              </div>
            </form>
          </div>

          <div class="overflow-x-auto">
            ${table({
              rows: this.stocks,
              columns: visibleColumns,
              identifier: this.identifier,
              target: "stocksList",
              mappingLookup,
              renderers: {
                name: (value) => `<p class="font-medium text-foreground">${value || translate("Unnamed Stock")}</p>`,
                code: (value) => `<span class="font-mono text-xs bg-muted/60 px-2 py-0.5 rounded text-muted-foreground font-medium">${value || '—'}</span>`,
                quantity: (value) => `<span class="font-medium text-foreground">${value ?? 0}</span>`,
                pending: (value) => `<span class="text-muted-foreground">${value ?? 0}</span>`,
                business_type: (value) => `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary/10 text-primary /50 ">${Helpers.capitalize((value || 'inventory').replace(/_/g, ' '))}</span>`,
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
