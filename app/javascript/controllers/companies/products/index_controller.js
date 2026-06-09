import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_Products_NewModalController from "controllers/companies/products/new_modal_controller";
import Companies_Products_ShowModalController from "controllers/companies/products/show_modal_controller";

export default class Companies_Products_IndexController extends Companies_LayoutController {
  static targets = ["categorySelect", "productsList"]

  /** @type {(Product & { name: string })[]} */
  products = []

  async connect() {
    console.log(this)
    super.connect()
    try {
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson({
        params: { category_id: urlParams.get('category_id') || this.defaultFilterCategory()?.id }
      })

      this.products = response.products || []
      this.pagination = response.pagination || {}

      poll(() => {
        if (this.hasContentTarget) {
          this.categoryIdValue = getQueryParam("category_id")
          
          const propertyMapping = currentPropertyMappings().find(mapping => mapping.category_id === this.categoryIdValue)
          if (propertyMapping) this.propertyMappingIdValue = propertyMapping.id
          
          const tableConfig = currentTableConfigs().find(config => config.property_mapping_id === this.propertyMappingIdValue)
          if (tableConfig) this.tableConfigIdValue = tableConfig.id
          
          this.renderContent()

          return true
        }
        return false
      })

    } catch (error) {
      toast({ type: "error", message: "Failed to load products" })
    }
  }

  productsCategories() {
    return currentCategories().filter(c => c.resource_name === "products")
  }

  defaultFilterCategory() {
    return this.productsCategories()[0]
  }

  openNewModal() {
    openModal({ html: `<div data-controller="${identifier(Companies_Products_NewModalController)}"></div>` })
  }

  openShowModal(event) {
    event.preventDefault()
    const { productId } = event.params
    window.currentProduct = findById(this.products, productId)
    openModal({ html: `<div data-controller="${identifier(Companies_Products_ShowModalController)}"></div>` })
  }

  /**
   * Generates the dynamic headers and rows by combining TableConfig order 
   * with PropertyMapping data labels.
   */
  contentHTML() {
    const categoryFilter = this.productsCategories()
    const urlParams = new URLSearchParams(window.location.search)
    const categoryValue = urlParams.get('category_id') || this.defaultFilterCategory()?.id

    // 1. Grab both configuration structures safely
    const tableConfig = this.currentTableConfig()
    const propertyMapping = this.currentPropertyMapping()

    // Fallback blueprint if configs haven't fully initialized on page load
    const fallbackColumns = [
      { key: "name", label: "Product Name" },
      { key: "code", label: "Product Code" },
      { key: "workflow_status", label: "Status" }
    ]

    const rawColumns = tableConfig?.columns_metadata || fallbackColumns
    const visibleColumns = rawColumns.filter(col => col.visible !== false)

    // Build an in-memory dictionary lookup from PropertyMapping for O(1) attribute matching
    const mappingLookup = (propertyMapping?.property_metadata || []).reduce((acc, field) => {
      acc[field.key] = field
      return acc
    }, {})

    return `
      <div class="p-4 overflow-y-auto" data-action="filter:changed@window->${this.identifier}#handleFilter">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end justify-between gap-4 mb-6 w-full">
              <div class="flex flex-wrap items-center gap-3 w-full lg:w-auto">
                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Category</label>
                  <select
                    name="category_id"
                    class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300"
                    data-${this.identifier}-target="categorySelect"
                  >
                    ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), categoryValue)}
                  </select>
                </div>
                <div class="flex gap-2 mt-auto">
                  <button type="submit" class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm flex items-center gap-2">
                    <span class="material-symbols-outlined text-[18px]">search</span>
                    Search
                  </button>
                </div>
              </div>

              <button
                type="button"
                data-action="click->${this.identifier}#openNewModal"
                class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap cursor-pointer">
                <span class="material-symbols-outlined text-[20px]">add</span>
                Add
              </button>
            </form>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse table-fixed">
              <thead>
                <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  ${visibleColumns.map(col => {
                    // Resolve human label: Prefer PropertyMapping.label over raw TableConfig fallback
                    const mappedField = mappingLookup[col.key]
                    const resolvedLabel = mappedField?.label || col.label || col.key

                    const widthStyle = col.width ? `style="width: ${col.width}px;"` : ''
                    const alignmentClass = col.align === 'right' ? 'text-right' : col.align === 'center' ? 'text-center' : 'text-left'
                    
                    return `<th ${widthStyle} class="py-4 px-6 font-medium whitespace-nowrap ${alignmentClass}">${resolvedLabel}</th>`
                  }).join('')}
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap w-[100px]">Actions</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="productsList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.products.map(product => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    ${visibleColumns.map(col => {
                      const alignmentClass = col.align === 'right' ? 'text-right' : col.align === 'center' ? 'text-center' : 'text-left'
                      const mappedField = mappingLookup[col.key]
                      
                      return `
                        <td class="py-4 px-6 text-sm ${alignmentClass}">
                          ${this.renderCellContent(product, col, mappedField)}
                        </td>
                      `
                    }).join('')}
                    
                    <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer"
                        data-action="click->${this.identifier}#openShowModal"
                        data-${this.identifier}-product-id-param="${product.id}"
                      >
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                    </td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>

          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }

  /**
   * Evaluates formatting styles based on types (string, integer, boolean, decimal)
   */
  renderCellContent(product, col, mappedField) {
    const value = product[col.key]

    // Core layout field mappings
    if (col.key === "name") {
      return `
        <div class="flex items-center gap-4">
          <div class="w-8 h-8 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center shrink-0">
            <span class="material-symbols-outlined text-emerald-600 dark:text-emerald-400 text-[18px]">inventory_2</span>
          </div>
          <p class="font-medium text-slate-900 dark:text-white cursor-pointer hover:underline truncate">
            ${value || 'Unnamed Product'}
          </p>
        </div>
      `
    }

    if (col.key === "code") {
      return `<span class="font-mono text-xs bg-slate-100 dark:bg-slate-800/60 px-2 py-0.5 rounded text-slate-600 dark:text-slate-300 font-medium">${value || '—'}</span>`
    }

    if (col.key === "workflow_status") {
      return Helpers.statusBadge(value)
    }

    // Dynamic Matrix Fallback Check
    if (value === null || value === undefined) {
      return `<span class="text-slate-300 dark:text-slate-700">—</span>`
    }

    // Custom formatting strategies inferred from PropertyMapping types
    const fieldType = mappedField?.type

    if (fieldType === "boolean") {
      const isTrue = value === true || value === "true"
      const badgeColor = isTrue ? "emerald" : "slate"
      return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md bg-${badgeColor}-50 text-${badgeColor}-700 dark:bg-${badgeColor}-900/30 dark:text-${badgeColor}-400">${isTrue ? 'Yes' : 'No'}</span>`
    }

    if (fieldType === "integer") {
      return `<span class="font-mono text-slate-900 dark:text-slate-100">${Number(value).toLocaleString()}</span>`
    }

    if (fieldType === "decimal") {
      // Formats decimals like Certification Scores or specific pricing dimensions cleanly
      return `<span class="font-mono font-medium text-blue-600 dark:text-blue-400">${Number(value).toFixed(2)}</span>`
    }

    return value
  }
}
