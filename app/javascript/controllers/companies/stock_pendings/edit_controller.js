import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_StockPendings_EditController extends Companies_LayoutController {
  // Stock pending edit — name/reason only. Quantity, stock, warehouse and
  // business type are immutable once held (BE rejects with 422).
  // Depends on BE: Companies::StockPendingsController#edit (record) + #update
  // Endpoints: GET edit_company_stock_pending_path.json, PATCH company_stock_pending_path
  // Docs: docs/superpowers/specs/2026-10-02-stock-pending-design.md

  /** @type {any | null} */
  stockPending = null

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const companyId = pathParts[2]
    const recordId = pathParts[4]

    try {
      const response = await fetchJson(`${Helpers.edit_company_stock_pending_path(companyId, recordId)}.json`)
      this.stockPending = response.stock_pending
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load stock pending.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    return this.editHTML()
  }

  async handleSubmit(event) {
    event.preventDefault()
    const companyId = window.location.pathname.split("/")[2]
    const form = new FormData(event.target)

    try {
      const response = await fetchJson(Helpers.company_stock_pending_path(companyId, this.stockPending.id), {
        method: "PATCH",
        body: {
          stock_pending: {
            name: form.get("stock_pending[name]"),
            reason: form.get("stock_pending[reason]")
          }
        }
      })
      toast({ type: "success", message: response.message || translate("Stock pending updated") })
      window.location.href = Helpers.company_stock_pending_path(companyId, response.stock_pending.id)
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update stock pending") })
    }
  }

  editHTML() {
    const doc = this.stockPending
    if (!doc) return `<div class="p-8 text-center">${translate("Stock Pending")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const inputClass = "w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none"
    const labelClass = "text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider"

    return `
      <div class="p-4 overflow-y-auto">
        <form data-action="submit->${this.identifier}#handleSubmit" class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 space-y-6">
          <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Stock Pending")}</h2>
          <p class="text-sm text-slate-500 dark:text-slate-400">${doc.product_name || ""} · ${translate("Quantity")}: ${Number(doc.quantity || 0).toLocaleString()}</p>

          <div class="grid grid-cols-1 gap-4">
            <div class="space-y-1">
              <label class="${labelClass}">${translate("Name")}</label>
              <input type="text" name="stock_pending[name]" value="${doc.name || ""}" class="${inputClass}">
            </div>
            <div class="space-y-1">
              <label class="${labelClass}">${translate("Reason")}</label>
              <textarea name="stock_pending[reason]" rows="3" class="${inputClass}">${doc.reason || ""}</textarea>
            </div>
          </div>

          <div class="flex justify-end gap-3 pt-2">
            <a href="${Helpers.company_stock_pending_path(companyId, doc.id)}" class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">${translate("Cancel")}</a>
            <button type="submit" class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">${translate("Save Changes")}</button>
          </div>
        </form>
      </div>`
  }
}
