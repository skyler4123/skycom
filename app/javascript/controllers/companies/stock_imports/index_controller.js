import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_StockImports_IndexController extends Companies_LayoutController {
  static targets = ["importsList"]

  /** @type {(StockImport & { product_name: string, branch_name: string, from_name: string, to_name: string })[]} */
  imports = []

  async connect() {
    super.connect()

    try {
      /** @type {{ stock_imports: StockImport[], pagination: any }} */
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson({
        params: { category_id: urlParams.get('category_id') || this.defaultFilterCategory()?.id }
      })

      this.imports = response.stock_imports || []
      this.pagination = response.pagination || {}

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })

    } catch (error) {
      toast({ type: "error", message: "Failed to load stock imports" })
    }
  }

  stockImportsCategories() {
    return currentCategories().filter(c => c.resource_name === "stock_imports")
  }

  defaultFilterCategory() {
    return this.stockImportsCategories()[0]
  }

  contentHTML() {
    const typeFilter = Enums()?.stock_import?.business_types || []
    const workflowStatusFilter = Enums()?.stock_import?.workflow_statuses || []
    const categoryFilter = this.stockImportsCategories()

    const urlParams = new URLSearchParams(window.location.search)
    const categoryValue = urlParams.get('category_id') || this.defaultFilterCategory()?.id

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <form method="get" action="${pathname()}" class="flex flex-wrap items-end gap-3 mb-6 w-full">
            <div class="flex flex-wrap items-center gap-3">
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Category</label>
                <select name="category_id" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                  ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), categoryValue)}
                </select>
              </div>

              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Search</label>
                <input 
                  type="text" 
                  name="search" 
                  value="${urlParams.get('search') || ''}" 
                  placeholder="Import Code"
                  class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 w-40"
                >
              </div>

              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Type</label>
                <select name="business_type" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                  ${selectOptionsHTML(typeFilter, urlParams.get('business_type'), "All Types")}
                </select>
              </div>

              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Status</label>
                <select name="workflow_status" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                  ${selectOptionsHTML(workflowStatusFilter, urlParams.get('workflow_status'), "All Statuses")}
                </select>
              </div>

              <button type="submit" class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm flex items-center gap-2">
                <span class="material-symbols-outlined text-[18px]">search</span>
                Search
              </button>
            </div>
          </form>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Code</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Product</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">From</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">To</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Quantity</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Type</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="importsList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.imports.map(import_data => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td class="py-4 px-6 text-sm">
                      <span class="font-mono font-medium text-slate-900 dark:text-white">${import_data.code || 'N/A'}</span>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${import_data.product_name || 'N/A'}</td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${import_data.from_name || 'N/A'}</td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${import_data.to_name || 'N/A'}</td>
                    <td class="py-4 px-6 text-sm text-slate-900 dark:text-white font-medium">${import_data.quantity || 0}</td>
                    <td class="py-4 px-6 text-sm">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        import_data.business_type === 'purchase' ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400' :
                        import_data.business_type === 'return' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400' :
                        import_data.business_type === 'transfer_in' ? 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-400' :
                        'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400'
                      }">
                        ${Helpers.capitalize(import_data.business_type?.replace(/_/g, ' ') || 'N/A')}
                      </span>
                    </td>
                    <td class="py-4 px-6 text-sm">
                      ${Helpers.statusBadge(import_data.workflow_status)}
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
}