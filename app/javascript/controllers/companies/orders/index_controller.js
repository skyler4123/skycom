import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Orders_IndexController extends Companies_LayoutController {
  static targets = ["ordersList"]

  /** @type {(Order & { name: string })[]} */
  orders = []

  /** @type {string | null} */
  categoryIdValue = null

  async connect() {
    super.connect()

    this.categoryIdValue = new URLSearchParams(window.location.search).get('category_id')
      || this.defaultFilterCategory()?.id

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryIdValue)
    if (propertyMapping) this.propertyMappingIdValue = propertyMapping.id

    const tableConfig = currentTableConfigs().find(c => c.property_mapping_id === this.propertyMappingIdValue)
    if (tableConfig) this.tableConfigIdValue = tableConfig.id

    try {
      const response = await fetchJson({ params: { category_id: this.categoryIdValue } })
      this.orders = response.orders || []
      this.pagination = response.pagination || {}
    } catch (error) {
      toast({ type: "error", message: "Failed to load orders" })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  ordersCategories() {
    return currentCategories().filter(c => c.resource_name === "orders")
  }

  defaultFilterCategory() {
    return this.ordersCategories()[0]
  }

  contentHTML() {
    const categoryFilter = this.ordersCategories()
    const categoryValue = this.categoryIdValue || this.defaultFilterCategory()?.id
    const propertyMapping = this.currentPropertyMapping()

    const mappingLookup = (propertyMapping?.property_metadata || []).reduce((acc, field) => {
      acc[field.key] = field
      return acc
    }, {})

    const fallbackColumns = [
      { key: "name", label: "Order Name" },
      { key: "code", label: "Order Code" },
      { key: "workflow_status", label: "Status" }
    ]

    const rawColumns = this.currentTableConfig()?.columns_metadata || fallbackColumns
    const visibleColumns = rawColumns.filter(col => col.visible !== false)

    if (!visibleColumns.some(c => c.key === "category")) {
      const nameIdx = visibleColumns.findIndex(c => c.key === "name")
      if (nameIdx >= 0) visibleColumns.splice(nameIdx + 1, 0, { key: "category", label: "Category" })
    }

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end justify-between gap-4 w-full">
              <div class="flex flex-wrap items-center gap-3 w-full lg:w-auto">
                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Category</label>
                  <select
                    name="category_id"
                    class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300"

                  >
                    ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), categoryValue)}
                  </select>
                </div>
                <div class="flex gap-2 mt-auto">
                  <button type="submit" class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm flex items-center gap-2">
                    <span class="material-symbols-outlined text-[18px]">search</span>
                    Search
                  </button>
                </div>
              </div>

              <a href="${Helpers.new_company_order_path(currentCompany().id)}"
                class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm whitespace-nowrap cursor-pointer">
                <span class="material-symbols-outlined text-[20px]">add</span>
                Add
              </a>
            </form>
          </div>

          <div class="overflow-x-auto">
            ${table({
              rows: this.orders,
              columns: visibleColumns,
              identifier: this.identifier,
              target: "ordersList",
              mappingLookup,
              renderers: {
                name: (value, record) => `
                  <div class="flex items-center gap-4">
                    <div class="w-8 h-8 rounded-lg bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center shrink-0">
                      <span class="material-symbols-outlined text-amber-600 dark:text-amber-400 text-[18px]">receipt_long</span>
                    </div>
                    <a href="${Helpers.company_order_path(currentCompany().id, record.id)}"
                      class="font-medium text-slate-900 dark:text-white overflow-visible whitespace-normal hover:text-blue-600 dark:hover:text-blue-400 transition-colors cursor-pointer">
                      ${value || 'Unnamed Order'}
                    </a>
                  </div>
                `,
                code: (value) => `<span class="font-mono text-xs bg-slate-100 dark:bg-slate-800/60 px-2 py-0.5 rounded text-slate-600 dark:text-slate-300 font-medium">${value || '—'}</span>`,
                category: (value, record) => record.category?.name || '<span class="text-slate-300 dark:text-slate-700">—</span>',
              },
              renderActions: (record) => `
                <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                  <a href="${Helpers.edit_company_order_path(currentCompany().id, record.id)}"
                    class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer">
                    <span class="material-symbols-outlined text-[20px]">edit</span>
                  </a>
                </td>`
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
