import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_StockPendings_ShowController extends Companies_LayoutController {
  // Stock pending detail — read-only hold view with anchored ledger rows + release/cancel.
  // Depends on BE: Companies::StockPendingsController#show (record + ledger)
  // Endpoints: GET company_stock_pending_path.json,
  //            POST release/cancel_company_stock_pending_path
  // Docs: docs/superpowers/specs/2026-10-02-stock-pending-design.md

  /** @type {any | null} */
  stockPending = null

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const companyId = pathParts[2]
    const recordId = pathParts[4]

    try {
      const response = await fetchJson(`${Helpers.company_stock_pending_path(companyId, recordId)}.json`)
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
    return this.showHTML()
  }

  holding() {
    const s = this.stockPending?.workflow_status
    return s === "pending" || s === "in_progress" || s === "initiated" || s === "draft"
  }

  async runAction(action) {
    const companyId = window.location.pathname.split("/")[2]
    const paths = {
      release: Helpers.release_company_stock_pending_path(companyId, this.stockPending.id),
      cancel: Helpers.cancel_company_stock_pending_path(companyId, this.stockPending.id)
    }
    const messages = { release: translate("Pending released"), cancel: translate("Pending cancelled") }
    try {
      await fetchJson(paths[action], { method: "POST", body: {} })
      reloadThenToast({ type: "success", message: messages[action] })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Pending action failed") })
    }
  }

  release() { this.runAction("release") }
  cancel() { this.runAction("cancel") }

  actionButtonsHTML() {
    if (!this.holding()) return ""
    return `
      <button type="button" data-action="click->${this.identifier}#release" class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">${translate("Release")}</button>
      <button type="button" data-action="click->${this.identifier}#cancel" class="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">${translate("Cancel")}</button>`
  }

  ledgerRowsHTML() {
    const rows = this.stockPending?.ledger || []
    if (rows.length === 0) return `<p class="text-sm text-slate-400">—</p>`
    return `
      <table class="w-full text-left border-collapse">
        <thead>
          <tr class="text-xs text-slate-500 border-b border-slate-200 dark:border-slate-700">
            <th class="py-2 px-2 font-medium">${translate("Type")}</th>
            <th class="py-2 px-2 font-medium">${translate("Quantity")}</th>
            <th class="py-2 px-2 font-medium">${translate("Held At")}</th>
          </tr>
        </thead>
        <tbody>
          ${rows.map(t => `
            <tr class="border-b border-slate-100 dark:border-slate-800">
              <td class="py-2 px-2 text-sm font-mono text-slate-600 dark:text-slate-300">${t.transaction_type}</td>
              <td class="py-2 px-2 text-sm font-mono text-slate-900 dark:text-slate-100">${Number(t.quantity || 0).toLocaleString()}</td>
              <td class="py-2 px-2 text-sm text-slate-600 dark:text-slate-300">${t.created_at ? new Date(t.created_at).toLocaleString() : "—"}</td>
            </tr>`).join("")}
        </tbody>
      </table>`
  }

  showHTML() {
    const doc = this.stockPending
    if (!doc) return `<div class="p-8 text-center">${translate("Stock Pending")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const heldAt = doc.status_changed_at ? new Date(doc.status_changed_at).toLocaleString() : "—"
    const releasedAt = doc.released_at ? new Date(doc.released_at).toLocaleString() : "—"

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_stock_pendings_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>${translate("Back to Stock Pendings")}
          </a>

          <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-4 mb-6">
            <div>
              <h2 class="text-2xl font-black text-slate-900 dark:text-white">${doc.name || translate("Unnamed Stock Pending")}</h2>
              <p class="font-mono text-sm text-slate-400">${doc.code || ""}</p>
              <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">${doc.reason || ""}</p>
            </div>
            <div class="flex gap-3">${this.actionButtonsHTML()}</div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-slate-700 pt-6 sm:grid-cols-2">
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Product")}</p>
              <p class="text-sm font-semibold text-slate-900 dark:text-white">${doc.product_name || "—"}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Warehouse")}</p>
              <p class="text-sm font-semibold text-slate-900 dark:text-white">${doc.warehouse_name || "—"}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Quantity")}</p>
              <p class="text-sm font-semibold font-mono text-slate-900 dark:text-white">${Number(doc.quantity || 0).toLocaleString()}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Status")}</p>
              <p class="text-sm font-semibold text-slate-900 dark:text-white">${doc.workflow_status || "—"}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Type")}</p>
              <p class="text-sm font-semibold text-slate-900 dark:text-white">${doc.business_type || "—"}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Held At")}</p>
              <p class="text-sm font-semibold text-slate-900 dark:text-white">${heldAt}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Released At")}</p>
              <p class="text-sm font-semibold text-slate-900 dark:text-white">${releasedAt}</p>
            </div>
          </div>

          <div class="border-t border-slate-200 dark:border-slate-700 pt-6 mt-6">
            <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Ledger")}</h3>
            ${this.ledgerRowsHTML()}
          </div>

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-slate-200 dark:border-slate-700">
            <a href="${Helpers.edit_company_stock_pending_path(companyId, doc.id)}" class="inline-flex items-center px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer">${translate("Edit Stock Pending")}</a>
          </div>
        </div>
      </div>`
  }
}
