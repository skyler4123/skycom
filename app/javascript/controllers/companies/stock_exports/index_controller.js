import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_StockExports_IndexController extends Companies_LayoutController {
  static targets = ["exportsList"]

  /** @type {(StockExport & { product_name: string, branch_name: string, from_name: string, to_name: string })[]} */
  exports = []

  async connect() {
    super.connect()

    try {
      /** @type {{ stock_exports: StockExport[], pagination: any }} */
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson({
        params: { category_id: urlParams.get('category_id') || this.defaultFilterCategory()?.id }
      })

      this.exports = response.stock_exports || []
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
      toast({ type: "error", message: `${ translate("Failed to load stock exports") }${__errDetail ? ": " + __errDetail : ""}` })
    }
  }

  stockExportsCategories() {
    return currentCategories().filter(c => c.resource_name === "stock_exports")
  }

  defaultFilterCategory() {
    return this.stockExportsCategories()[0]
  }

  contentHTML() {
    const categoryFilter = this.stockExportsCategories()

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
              <tbody data-${this.identifier}-target="exportsList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.exports.map(export_data => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td class="py-4 px-6 text-sm">
                      <span class="font-mono font-medium text-slate-900 dark:text-white">${export_data.code || translate('N/A')}</span>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${export_data.product_name || translate('N/A')}</td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${export_data.category_name || '—'}</td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${export_data.from_name || translate('N/A')}</td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${export_data.to_name || translate('N/A')}</td>
                    <td class="py-4 px-6 text-sm text-slate-900 dark:text-white font-medium">${export_data.quantity || 0}</td>
                    <td class="py-4 px-6 text-sm">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        export_data.business_type === 'sale' ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400' :
                        export_data.business_type === 'transfer_out' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400' :
                        export_data.business_type === 'return_to_supplier' ? 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400' :
                        export_data.business_type === 'damaged' || export_data.business_type === 'expired' ? 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400' :
                        'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400'
                      }">
                        ${Helpers.capitalize(export_data.business_type?.replace(/_/g, ' ') || translate('N/A'))}
                      </span>
                    </td>
                    <td class="py-4 px-6 text-sm">
                      ${Helpers.statusBadge(export_data.workflow_status)}
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