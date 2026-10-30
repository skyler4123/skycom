import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_StockTransfers_ShowController extends Companies_LayoutController {
  // Stock transfer detail — read-only document view with lines + paired ledger tables
  // plus two-phase workflow buttons (Initiate / Receive / Cancel via member POSTs).
  // Depends on BE: Companies::StockTransfersController#show (lines + ledger),
  //                #initiate, #receive, #cancel
  // Endpoints: GET company_stock_transfer_path.json,
  //            POST initiate/receive/cancel_company_stock_transfer_path
  // Docs: docs/STOCK.md §4.3
  /** @type {any | null} */
  stockTransfer = null

  /** @type {Array<{key: string, name: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const recordId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_stock_transfer_path(companyId, recordId)}.json`)
      this.stockTransfer = response.stock_transfer

      if (this.stockTransfer?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.stockTransfer.category_id)
        this.propertyMetadata = propertyMapping?.metadata?.properties || []
      }

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load stock transfer.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    return this.showHTML()
  }

  editable() {
    const s = this.stockTransfer?.workflow_status
    return s === "draft" || s === "pending"
  }

  async runPhase(action) {
    const companyId = window.location.pathname.split("/")[2]
    const paths = {
      initiate: Helpers.initiate_company_stock_transfer_path(companyId, this.stockTransfer.id),
      receive: Helpers.receive_company_stock_transfer_path(companyId, this.stockTransfer.id),
      cancel: Helpers.cancel_company_stock_transfer_path(companyId, this.stockTransfer.id)
    }
    try {
      const response = await fetchJson(paths[action], { method: "POST", body: {} })
      reloadThenToast({ type: "success", message: response.message || translate(`Transfer ${action}d`) })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Transfer action failed") })
    }
  }

  initiate() { this.runPhase("initiate") }
  receive() { this.runPhase("receive") }
  cancel() { this.runPhase("cancel") }

  phaseButtonsHTML() {
    const s = this.stockTransfer?.workflow_status
    if (s === "draft" || s === "pending")
      return `<button type="button" data-action="click->${this.identifier}#initiate"
        class="px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm transition-colors cursor-pointer">${translate("Initiate")}</button>`
    if (s === "initiated")
      return `
        <button type="button" data-action="click->${this.identifier}#receive"
          class="px-4 py-2 bg-success hover:bg-success/90 text-success-foreground rounded-lg font-bold text-sm transition-colors cursor-pointer">${translate("Receive")}</button>
        <button type="button" data-action="click->${this.identifier}#cancel"
          class="px-4 py-2 bg-danger hover:bg-danger/90 text-danger-foreground rounded-lg font-bold text-sm transition-colors cursor-pointer">${translate("Cancel")}</button>`
    return ``
  }

  formatDisplayValue(value, type) {
    if (value === null || value === undefined) return '<span class="text-muted-foreground/60">—</span>'
    switch (type) {
      case 'boolean':
        return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md ${value ? 'bg-success/10 text-success ' : 'bg-background text-foreground '}">${value ? translate("True") : translate("False")}</span>`
      case 'integer':
        return `<span class="font-mono text-foreground">${Number(value).toLocaleString()}</span>`
      case 'decimal':
        return `<span class="font-mono font-medium text-primary">${Number(value).toFixed(2)}</span>`
      case 'datetime': {
        return `<span class="text-sm text-foreground">${new Date(value).toLocaleString()}</span>`
      }
      default:
        return `<span class="text-sm text-foreground">${value}</span>`
    }
  }

  showHTML() {
    const doc = this.stockTransfer
    if (!doc) return `<div class="p-8 text-center">${translate("Stock transfer not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const category = currentCategories().find(c => c.id === doc.category_id)

    const linesTable = `
      <div class="border-t border-line pt-6 mt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Lines")}</h3>
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="text-xs text-muted-foreground border-b border-line">
              <th class="py-2 px-2 font-medium">${translate("Product")}</th>
              <th class="py-2 px-2 font-medium">${translate("Warehouse")}</th>
              <th class="py-2 px-2 text-right font-medium">${translate("Quantity")}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-line">
            ${(doc.lines || []).map(l => `
              <tr>
                <td class="py-2 px-2 text-sm text-foreground">${l.product_name || "—"}</td>
                <td class="py-2 px-2 text-sm text-muted-foreground">${l.warehouse_name || "—"}</td>
                <td class="py-2 px-2 text-sm text-right font-mono">${l.quantity ?? "—"}</td>
              </tr>`).join('')}
          </tbody>
        </table>
      </div>`

    const ledgerTable = (doc.ledger || []).length ? `
      <div class="border-t border-line pt-6 mt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Ledger")}</h3>
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="text-xs text-muted-foreground border-b border-line">
              <th class="py-2 px-2 font-medium">${translate("Direction")}</th>
              <th class="py-2 px-2 font-medium">${translate("Type")}</th>
              <th class="py-2 px-2 text-right font-medium">${translate("Quantity")}</th>
              <th class="py-2 px-2 text-right font-medium">${translate("At")}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-line">
            ${doc.ledger.map(t => `
              <tr>
                <td class="py-2 px-2 text-sm capitalize">${t.direction || "—"}</td>
                <td class="py-2 px-2 text-sm capitalize">${t.transaction_type || "—"}</td>
                <td class="py-2 px-2 text-sm text-right font-mono">${t.quantity ?? "—"}</td>
                <td class="py-2 px-2 text-sm text-right text-muted-foreground">${t.created_at ? new Date(t.created_at).toLocaleString() : "—"}</td>
              </tr>`).join('')}
          </tbody>
        </table>
      </div>` : ""

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-line pt-6 mt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => `
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-success ">
                <span class="material-symbols-outlined text-[20px]">${field.type === 'boolean' ? 'check_circle' : field.type === 'datetime' ? 'calendar_month' : 'text_fields'}</span>
              </div>
              <div class="min-w-0 flex-1">
                <p class="text-xs font-medium text-muted-foreground">${field.name}</p>
                <p class="text-sm font-semibold text-foreground">${this.formatDisplayValue(doc[field.key], field.type)}</p>
              </div>
            </div>`).join('')}
        </div>
      </div>` : ""

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_stock_transfers_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Stock Transfers")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl bg-success/10 flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-success ">input</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-foreground">${doc.name || translate("Unnamed Stock Transfer")}</h2>
              <p class="font-semibold text-success ">${doc.description || ''}</p>
              <div class="mt-2 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-success/10 px-3 py-1 text-xs font-bold text-success uppercase">${doc.code || "N/A"}</span>
                ${Helpers.statusBadge(doc.workflow_status)}
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-line pt-6 sm:grid-cols-2">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-success ">
                <span class="material-symbols-outlined">warehouse</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Source warehouse")}</p>
                <p class="text-sm font-semibold text-foreground">${doc.warehouse_name || "N/A"}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-success ">
                <span class="material-symbols-outlined">output</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Destination warehouse")}</p>
                <p class="text-sm font-semibold text-foreground">${doc.destination_warehouse_name || "N/A"}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-success ">
                <span class="material-symbols-outlined">folder</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Category")}</p>
                <p class="text-sm font-semibold text-foreground">${category?.name || doc.category_name || "N/A"}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-success ">
                <span class="material-symbols-outlined">inventory_2</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Quantity")}</p>
                <p class="text-sm font-semibold text-foreground">${doc.quantity ?? 0}</p>
              </div>
            </div>
          </div>

          ${dynamicFields}
          ${linesTable}
          ${ledgerTable}

          ${this.phaseButtonsHTML() ? `<div class="mt-8 flex flex-wrap gap-3 pt-6 border-t border-line">${this.phaseButtonsHTML()}</div>` : ""}

          ${this.editable() ? `
          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-line">
            <a href="${Helpers.edit_company_stock_transfer_path(companyId, doc.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Transfer")}
            </a>
          </div>` : ""}
        </div>
      </div>`
  }
}
