import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Stocks_IndexController extends Companies_LayoutController {
  static targets = ["stocksList"]

  /** @type {(Stock & { product_name: string, warehouse_name: string, branch_name: string })[]} */
  stocks = []

  async connect() {
    super.connect()

    try {
      /** @type {{ stocks: Stock[], pagination: any }} */
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson({
        params: { category_id: urlParams.get('category_id') || this.defaultFilterCategory()?.id }
      })

      this.stocks = response.stocks || []
      this.pagination = response.pagination || {}

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })

    } catch (error) {
      toast({ type: "error", message: "Failed to load stocks" })
    }
  }

  stocksCategories() {
    return currentCategories().filter(c => c.resource_name === "products")
  }

  defaultFilterCategory() {
    return this.stocksCategories()[0]
  }

  contentHTML() {
    const categoryFilter = this.stocksCategories()

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


              <div class="flex gap-2 mt-auto">
                <button type="submit" class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm flex items-center gap-2">
                  <span class="material-symbols-outlined text-[18px]">search</span>
                  Search
                </button>
              </div>
            </div>
          </form>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Product</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Warehouse</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Quantity</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Reorder</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">SKU</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Barcode</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Type</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="stocksList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.stocks.map(stock => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td class="py-4 px-6 text-sm">
                      <p class="font-medium text-slate-900 dark:text-white">${stock.product_name || 'N/A'}</p>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${stock.warehouse_name || 'N/A'}</td>
                    <td class="py-4 px-6 text-sm">
                      <span class="font-medium ${stock.quantity <= stock.reorder ? 'text-red-600 dark:text-red-400' : 'text-slate-900 dark:text-white'}">
                        ${stock.quantity || 0}
                      </span>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-500">${stock.reorder || 0}</td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">${stock.sku || 'N/A'}</td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">${stock.barcode || 'N/A'}</td>
                    <td class="py-4 px-6 text-sm">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        stock.business_type === 'inventory' ? 'bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-300' :
                        stock.business_type === 'raw_material' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-300' :
                        stock.business_type === 'finished_good' ? 'bg-purple-100 text-purple-800 dark:bg-purple-900/50 dark:text-purple-300' :
                        stock.business_type === 'return' ? 'bg-orange-100 text-orange-800 dark:bg-orange-900/50 dark:text-orange-300' :
                        'bg-gray-100 text-gray-800'
                      }">
                        ${Helpers.capitalize(stock.business_type || 'inventory')}
                      </span>
                    </td>
                    <td class="py-4 px-6 text-sm">
                      ${Helpers.statusBadge(stock.workflow_status)}
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