// Depends on BE: Companies::TaxesController#index/summary/invoices/purchases/stock_exports + Companies::TaxConfigsController#show/update
import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Taxes_IndexController extends Companies_LayoutController {
  /** @type {any | null} */
  taxConfig = null

  /** @type {any | null} */
  summary = null

  /** @type {string} */
  tab = "invoices"

  /** @type {string} */
  from = ""

  /** @type {string} */
  to = ""

  /** @type {any[]} */
  invoices = []

  /** @type {any[]} */
  purchases = []

  /** @type {any[]} */
  stockExports = []

  /** @type {any | null} */
  pagination = null

  async connect() {
    super.connect()

    const params = new URLSearchParams(window.location.search)
    this.tab = params.get("tab") || "invoices"
    this.from = params.get("from") || new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString().slice(0, 10)
    this.to = params.get("to") || new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0).toISOString().slice(0, 10)

    const companyId = window.location.pathname.split("/")[2]

    try {
      const summaryResponse = await fetchJson(`${Helpers.company_tax_summary_path(companyId)}.json?from=${this.from}&to=${this.to}`)
      this.summary = summaryResponse.summary
      await this.loadTabData(companyId)
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Failed to load tax data" })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  async loadTabData(companyId) {
    const url = this.tab === "invoices"
      ? `${Helpers.company_tax_invoices_path(companyId)}.json?from=${this.from}&to=${this.to}`
      : this.tab === "purchases"
        ? `${Helpers.company_tax_purchases_path(companyId)}.json?from=${this.from}&to=${this.to}`
        : `${Helpers.company_tax_stock_exports_path(companyId)}.json?from=${this.from}&to=${this.to}`

    const response = await fetchJson(url)
    if (this.tab === "invoices") this.invoices = response.invoices || []
    if (this.tab === "purchases") this.purchases = response.purchases || []
    if (this.tab === "stock_exports") this.stockExports = response.stock_exports || []
    this.pagination = response.pagination || null
  }

  switchTab(event) {
    const tab = event?.target?.dataset?.tab || event?.params?.tab || this.tab
    const params = new URLSearchParams(window.location.search)
    params.set("tab", tab)
    params.set("from", this.from)
    params.set("to", this.to)
    window.location.href = `${pathname()}?${params.toString()}`
  }

  async applyPeriod(event) {
    event.preventDefault()
    const form = event.target
    const data = new FormData(form)
    this.from = data.get("from")
    this.to = data.get("to")
    const params = new URLSearchParams(window.location.search)
    params.set("tab", this.tab)
    params.set("from", this.from)
    params.set("to", this.to)
    window.location.href = `${pathname()}?${params.toString()}`
  }

  exportCsv() {
    const records = this.tab === "invoices" ? this.invoices
      : this.tab === "purchases" ? this.purchases : this.stockExports

    if (!records || records.length === 0) {
      toast({ type: "error", message: "No records to export" })
      return
    }

    let cols = []
    if (this.tab === "invoices") {
      cols = [
        { key: "code", label: "Invoice Code" },
        { key: "created_at", label: "Created At" },
        { key: "payment_status", label: "Payment Status" },
        { key: "price_cents", label: "Price Cents" },
        { key: "currency", label: "Currency" }
      ]
    } else if (this.tab === "purchases") {
      cols = [
        { key: "code", label: "Purchase Code" },
        { key: "name", label: "Name" },
        { key: "created_at", label: "Created At" },
        { key: "workflow_status", label: "Workflow Status" },
        { key: "total_price", label: "Total Price" }
      ]
    } else {
      cols = [
        { key: "code", label: "Export Code" },
        { key: "name", label: "Name" },
        { key: "created_at", label: "Created At" },
        { key: "business_type", label: "Business Type" },
        { key: "quantity", label: "Quantity" }
      ]
    }

    downloadCSV(records, cols, `tax-${this.tab}-${this.from}-to-${this.to}.csv`)
  }

  contentHTML() {
    const s = this.summary || {}
    const inv = s.invoices || {}
    const pur = s.purchases || {}
    const stk = s.stock_exports || {}

    const tabButton = (key, label) => `
      <button type="button" data-action="click->${this.identifier}#switchTab" data-tab="${key}"
        class="px-4 py-2 text-sm font-medium rounded-lg ${this.tab === key ? 'bg-primary text-primary-foreground' : 'bg-muted text-foreground'}">
        ${label}
      </button>
    `

    let rowsHtml = ""
    if (this.tab === "invoices") {
      rowsHtml = this.invoices.map(r => `
        <tr class="border-b border-line">
          <td class="py-2 px-4 text-sm">${r.code || "—"}</td>
          <td class="py-2 px-4 text-sm">${r.created_at ? new Date(r.created_at).toLocaleString() : "—"}</td>
          <td class="py-2 px-4 text-sm">${r.payment_status || "—"}</td>
          <td class="py-2 px-4 text-sm">${r.price_cents ?? "—"}</td>
        </tr>
      `).join("")
    } else if (this.tab === "purchases") {
      rowsHtml = this.purchases.map(r => `
        <tr class="border-b border-line">
          <td class="py-2 px-4 text-sm">${r.code || "—"}</td>
          <td class="py-2 px-4 text-sm">${r.name || "—"}</td>
          <td class="py-2 px-4 text-sm">${r.created_at ? new Date(r.created_at).toLocaleString() : "—"}</td>
          <td class="py-2 px-4 text-sm">${r.workflow_status || "—"}</td>
          <td class="py-2 px-4 text-sm">${r.total_price ?? "—"}</td>
        </tr>
      `).join("")
    } else {
      rowsHtml = this.stockExports.map(r => `
        <tr class="border-b border-line">
          <td class="py-2 px-4 text-sm">${r.code || "—"}</td>
          <td class="py-2 px-4 text-sm">${r.name || "—"}</td>
          <td class="py-2 px-4 text-sm">${r.created_at ? new Date(r.created_at).toLocaleString() : "—"}</td>
          <td class="py-2 px-4 text-sm">${r.business_type || "—"}</td>
          <td class="py-2 px-4 text-sm">${r.quantity ?? "—"}</td>
        </tr>
      `).join("")
    }

    const cfg = this.taxConfig || {}

    return `
      <div class="p-4 overflow-y-auto space-y-6">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="p-4 bg-card rounded-xl border border-line">
            <p class="text-xs text-muted-foreground uppercase">Invoices</p>
            <p class="text-lg font-bold">${inv.count ?? 0}</p>
            <p class="text-sm text-muted-foreground">Total cents: ${inv.total_cents ?? 0}</p>
          </div>
          <div class="p-4 bg-card rounded-xl border border-line">
            <p class="text-xs text-muted-foreground uppercase">Purchases</p>
            <p class="text-lg font-bold">${pur.count ?? 0}</p>
            <p class="text-sm text-muted-foreground">Total: ${pur.total_amount ?? 0}</p>
          </div>
          <div class="p-4 bg-card rounded-xl border border-line">
            <p class="text-xs text-muted-foreground uppercase">Stock Exports</p>
            <p class="text-lg font-bold">${stk.count ?? 0}</p>
            <p class="text-sm text-muted-foreground">Quantity: ${stk.total_quantity ?? 0}</p>
          </div>
        </div>

        <form data-action="submit->${this.identifier}#applyPeriod" class="flex flex-wrap items-end gap-3">
          <div>
            <label class="text-xs text-muted-foreground uppercase">From</label>
            <input type="date" name="from" value="${this.from}" class="px-3 py-2 border rounded-lg text-sm" />
          </div>
          <div>
            <label class="text-xs text-muted-foreground uppercase">To</label>
            <input type="date" name="to" value="${this.to}" class="px-3 py-2 border rounded-lg text-sm" />
          </div>
          <button type="submit" class="px-4 py-2 bg-primary text-primary-foreground rounded-lg text-sm">Apply</button>
          <button type="button" data-action="click->${this.identifier}#exportCsv" class="px-4 py-2 bg-muted rounded-lg text-sm">Export CSV</button>
        </form>

        <div class="flex gap-2">
          ${tabButton("invoices", "Sales / Output")}
          ${tabButton("purchases", "Purchases / Input")}
          ${tabButton("stock_exports", "COGS / Stock Issues")}
        </div>

        <div class="bg-card rounded-xl border border-line overflow-x-auto">
          <table class="w-full text-left">
            <tbody>
              ${rowsHtml || `<tr><td class="py-8 text-center text-muted-foreground" colspan="5">No records</td></tr>`}
            </tbody>
          </table>
        </div>

      </div>
    `
  }
}
