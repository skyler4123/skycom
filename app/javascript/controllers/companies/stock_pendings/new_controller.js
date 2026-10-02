import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_StockPendings_NewController extends Companies_LayoutController {
  // Manual/event hold creation — warehouse picker scopes the stock picker to one shelf.
  // Depends on BE: Companies::StockPendingsController#new (warehouses + stocks) + #create
  // Endpoints: GET new_company_stock_pending_path.json, POST create_company_stock_pendings_path
  // Docs: docs/superpowers/specs/2026-10-02-stock-pending-design.md

  /** @type {Array<{id: string, name: string}>} */
  warehouses = []

  /** @type {Array<{id: string, product_id: string, product_name: string, warehouse_id: string, warehouse_name: string, quantity: number, pending: number, available: number}>} */
  stocks = []

  /** @type {string | null} */
  warehouseId = null

  /** @type {string | null} */
  stockId = null

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(`${Helpers.new_company_stock_pending_path(currentCompany().id)}.json`)
      this.warehouses = response.warehouses || []
      this.stocks = response.stocks || []
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load stock pendings") })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  onWarehouseChange(event) {
    this.warehouseId = event.target.value || null
    this.stockId = null
    this.renderContent()
  }

  onStockChange(event) {
    this.stockId = event.target.value || null
  }

  warehouseStocks() {
    if (!this.warehouseId) return []
    return this.stocks.filter(s => s.warehouse_id === this.warehouseId)
  }

  selectedStock() {
    return this.stocks.find(s => s.id === this.stockId) || null
  }

  async handleSubmit(event) {
    event.preventDefault()
    const companyId = currentCompany().id
    const form = new FormData(event.target)
    const payload = {
      stock_pending: {
        stock_id: form.get("stock_pending[stock_id]"),
        quantity: Number(form.get("stock_pending[quantity]")),
        business_type: form.get("stock_pending[business_type]"),
        name: form.get("stock_pending[name]"),
        reason: form.get("stock_pending[reason]")
      }
    }

    try {
      const response = await fetchJson(Helpers.create_company_stock_pendings_path(companyId), {
        method: "POST",
        body: payload
      })
      toast({ type: "success", message: response.message || translate("Stock pending created") })
      window.location.href = Helpers.company_stock_pending_path(companyId, response.stock_pending.id)
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to create stock pending") })
    }
  }

  contentHTML() {
    const inputClass = "w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none"
    const labelClass = "text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider"
    const selected = this.selectedStock()

    return `
      <div class="p-4 overflow-y-auto">
        <form data-action="submit->${this.identifier}#handleSubmit" class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 space-y-6">
          <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Stock Pending")}</h2>

          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-1">
              <label class="${labelClass}">${translate("Warehouse")}</label>
              <select data-action="change->${this.identifier}#onWarehouseChange" class="${inputClass} cursor-pointer">
                <option value="">—</option>
                ${this.warehouses.map(w => `<option value="${w.id}" ${w.id === this.warehouseId ? "selected" : ""}>${w.name}</option>`).join("")}
              </select>
            </div>
            <div class="space-y-1">
              <label class="${labelClass}">${translate("Stock")}</label>
              <select name="stock_pending[stock_id]" data-action="change->${this.identifier}#onStockChange" class="${inputClass} cursor-pointer">
                <option value="">—</option>
                ${this.warehouseStocks().map(s => `<option value="${s.id}" ${s.id === this.stockId ? "selected" : ""}>${s.product_name} (${translate("Available")}: ${s.available})</option>`).join("")}
              </select>
            </div>
            <div class="space-y-1">
              <label class="${labelClass}">${translate("Quantity")}</label>
              <input type="number" min="1" step="1" name="stock_pending[quantity]" value="1" class="${inputClass}">
            </div>
            <div class="space-y-1">
              <label class="${labelClass}">${translate("Type")}</label>
              <select name="stock_pending[business_type]" class="${inputClass} cursor-pointer">
                <option value="manual">${translate("Manual")}</option>
                <option value="event">${translate("Event")}</option>
              </select>
            </div>
            <div class="col-span-2 space-y-1">
              <label class="${labelClass}">${translate("Name")}</label>
              <input type="text" name="stock_pending[name]" placeholder="${translate("New Stock Pending")}" class="${inputClass}">
            </div>
            <div class="col-span-2 space-y-1">
              <label class="${labelClass}">${translate("Reason")}</label>
              <textarea name="stock_pending[reason]" rows="3" class="${inputClass}"></textarea>
            </div>
          </div>

          ${selected ? `<p class="text-sm text-slate-500 dark:text-slate-400">${translate("Available")}: ${selected.available}</p>` : ""}

          <div class="flex justify-end gap-3 pt-2">
            <a href="${Helpers.company_stock_pendings_path(currentCompany().id)}" class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">${translate("Cancel")}</a>
            <button type="submit" class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">${translate("Create")}</button>
          </div>
        </form>
      </div>`
  }
}
