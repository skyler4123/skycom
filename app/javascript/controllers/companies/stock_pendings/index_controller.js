import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_StockPendings_IndexController extends Companies_LayoutController {
  // StockPendings dashboard — static table hydrating from the index JSON of the current URL.
  // Lean record: no TableConfig or Meilisearch; filters are warehouse + workflow status only.
  // Depends on BE: Companies::StockPendingsController#index (list + warehouse_id/workflow_status)
  // Endpoints: GET <pathname>.json?warehouse_id&workflow_status — traditional GET form, full-page submit
  // Docs: docs/superpowers/specs/2026-10-02-stock-pending-design.md

  /** @type {any[]} */
  pendings = []

  /** @type {Array<{id: string, name: string}>} */
  warehouses = []

  /** @type {any} */
  pagination = {}

  async connect() {
    super.connect()

    try {
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson(`${pathname()}.json?${urlParams.toString()}`)
      this.pendings = response.stock_pendings || []
      this.warehouses = response.warehouses || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load stock pendings")}${__errDetail ? ": " + __errDetail : ""}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  statusBadge(status) {
    const styles = {
      draft: "bg-muted text-muted-foreground ",
      pending: "bg-warning/10 text-warning ",
      in_progress: "bg-primary/10 text-primary ",
      initiated: "bg-primary/10 text-primary ",
      completed: "bg-success/10 text-success ",
      received: "bg-success/10 text-success ",
      cancelled: "bg-danger/10 text-danger "
    }
    const cls = styles[status] || "bg-muted text-muted-foreground "
    return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md ${cls}">${status || "—"}</span>`
  }

  rowHTML(record) {
    const companyId = currentCompany().id
    const heldAt = record.status_changed_at ? new Date(record.status_changed_at).toLocaleString() : "—"
    const releasedAt = record.released_at ? new Date(record.released_at).toLocaleString() : "—"
    return `
      <tr class="border-b border-line hover:bg-muted/50">
        <td class="py-3 px-4 text-sm">
          <a href="${Helpers.company_stock_pending_path(companyId, record.id)}" class="font-medium text-foreground hover:text-primary cursor-pointer">${record.name || translate("Unnamed Stock Pending")}</a>
          <div class="font-mono text-xs text-muted-foreground">${record.code || ""}</div>
        </td>
        <td class="py-3 px-4 text-sm text-muted-foreground">${record.product_name || "—"}</td>
        <td class="py-3 px-4 text-sm text-muted-foreground">${record.warehouse_name || "—"}</td>
        <td class="py-3 px-4 text-sm font-mono text-foreground">${Number(record.quantity || 0).toLocaleString()}</td>
        <td class="py-3 px-4 text-sm">${this.statusBadge(record.workflow_status)}</td>
        <td class="py-3 px-4 text-sm text-muted-foreground">${record.business_type || "—"}</td>
        <td class="py-3 px-4 text-sm text-muted-foreground">${heldAt}</td>
        <td class="py-3 px-4 text-sm text-muted-foreground">${releasedAt}</td>
      </tr>`
  }

  contentHTML() {
    const urlParams = new URLSearchParams(window.location.search)
    const warehouseValue = urlParams.get("warehouse_id") || ""
    const statusValue = urlParams.get("workflow_status") || ""
    const warehouses = this.warehouses
    const statuses = ["draft", "pending", "in_progress", "initiated", "completed", "received", "cancelled"]

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col">
          <div class="flex items-center justify-between mb-6">
            <h2 class="text-xl font-bold text-foreground">${translate("Stock Pendings")}</h2>
            <a href="${Helpers.new_company_stock_pending_path(currentCompany().id)}" class="flex items-center justify-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm whitespace-nowrap cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>${translate("Hold Stock")}
            </a>
          </div>

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end justify-between gap-4 w-full">
              <div class="flex flex-wrap items-center gap-3 w-full lg:w-auto">
                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Warehouse")}</label>
                  <select name="warehouse_id" class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground cursor-pointer">
                    <option value="">${translate("All")}</option>
                    ${selectOptionsHTML(cloneNewKey(warehouses, "id", "value"), warehouseValue)}
                  </select>
                </div>
                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Status")}</label>
                  <select name="workflow_status" class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground cursor-pointer">
                    <option value="">${translate("All")}</option>
                    ${statuses.map(s => `<option value="${s}" ${s === statusValue ? "selected" : ""}>${s}</option>`).join("")}
                  </select>
                </div>
                <div class="flex gap-2 mt-auto">
                  <button type="submit" class="h-[38px] px-6 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm flex items-center gap-2 cursor-pointer">
                    <span class="material-symbols-outlined text-[18px]!">search</span>${translate("Search")}
                  </button>
                </div>
              </div>
            </form>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-xs text-muted-foreground border-b border-line">
                  <th class="py-2 px-4 font-medium">${translate("Name")}</th>
                  <th class="py-2 px-4 font-medium">${translate("Product")}</th>
                  <th class="py-2 px-4 font-medium">${translate("Warehouse")}</th>
                  <th class="py-2 px-4 font-medium">${translate("Quantity")}</th>
                  <th class="py-2 px-4 font-medium">${translate("Status")}</th>
                  <th class="py-2 px-4 font-medium">${translate("Type")}</th>
                  <th class="py-2 px-4 font-medium">${translate("Held At")}</th>
                  <th class="py-2 px-4 font-medium">${translate("Released At")}</th>
                </tr>
              </thead>
              <tbody>
                ${this.pendings.map(p => this.rowHTML(p)).join("")}
              </tbody>
            </table>
          </div>

          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>`
  }
}
