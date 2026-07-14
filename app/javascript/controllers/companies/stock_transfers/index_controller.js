import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_StockTransfers_IndexController extends Companies_LayoutController {
  static targets = ["transfersList"]

  /** @type {(StockTransfer & { product_name: string, branch_name: string, from_name: string, to_name: string })[]} */
  transfers = []

  async connect() {
    super.connect()

    try {
      /** @type {{ stock_transfers: StockTransfer[], pagination: any }} */
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson({
        params: { category_id: urlParams.get('category_id') || this.defaultFilterCategory()?.id }
      })

      this.transfers = response.stock_transfers || []
      this.pagination = response.pagination || {}

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })

    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load stock transfers") }${__errDetail ? ": " + __errDetail : ""}` })
    }
  }

  stockTransfersCategories() {
    return currentCategories().filter(c => c.resource_name === "stock_transfers")
  }

  defaultFilterCategory() {
    return this.stockTransfersCategories()[0]
  }

  contentHTML() {
    const categoryFilter = this.stockTransfersCategories()

    const urlParams = new URLSearchParams(window.location.search)
    const categoryValue = urlParams.get('category_id') || this.defaultFilterCategory()?.id

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <form method="get" action="${pathname()}" class="flex flex-wrap items-end gap-3 mb-6 w-full">
            <div class="flex flex-wrap items-center gap-3">
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("Category")}</label>
                <select name="category_id" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                  ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), categoryValue)}
                </select>
              </div>


              <div class="flex gap-2 mt-auto">
                <button type="submit" class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm flex items-center gap-2">
                  <span class="material-symbols-outlined text-[18px]">search</span>
                  ${translate("Search")}
                </button>
              </div>
            </div>
          </form>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Code")}</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Product")}</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Category")}</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("From")}</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("To")}</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Quantity")}</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Type")}</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Status")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="transfersList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.transfers.map(transfer => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td class="py-4 px-6 text-sm">
                      <span class="font-mono font-medium text-slate-900 dark:text-white">${transfer.code || translate('N/A')}</span>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${transfer.product_name || translate('N/A')}</td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${transfer.category_name || '—'}</td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${transfer.from_name || translate('N/A')}</td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${transfer.to_name || translate('N/A')}</td>
                    <td class="py-4 px-6 text-sm text-slate-900 dark:text-white font-medium">${transfer.quantity || 0}</td>
                    <td class="py-4 px-6 text-sm">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        transfer.business_type === 'transfer' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-300' :
                        transfer.business_type === 'adjustment' ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/50 dark:text-yellow-300' :
                        transfer.business_type === 'return' ? 'bg-orange-100 text-orange-800 dark:bg-orange-900/50 dark:text-orange-300' :
                        transfer.business_type === 'exchange' ? 'bg-purple-100 text-purple-800 dark:bg-purple-900/50 dark:text-purple-300' :
                        'bg-gray-100 text-gray-800'
                      }">
                        ${Helpers.capitalize(transfer.business_type || 'transfer')}
                      </span>
                    </td>
                    <td class="py-4 px-6 text-sm">
                      ${Helpers.statusBadge(transfer.workflow_status)}
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