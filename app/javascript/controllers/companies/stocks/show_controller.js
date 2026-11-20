import { Controller } from "@hotwired/stimulus"

// Stock row — one stock record: its identity, quantities, location, price and
// the most recent ledger entries for the same warehouse + product.
//
// Serves Stimulus: Companies_Stocks_ShowController
// Depends on BE: Companies::StocksController#show (stock row + movements)
// Endpoints: Helpers.company_stock_path
// Docs: docs/STOCK.md, docs/OPERATIONS.md
export default class Companies_Stocks_ShowController extends Controller {
  /** @type {any} */ stock = {}
  /** @type {any[]} */ ledger = []
  /** @type {string | null} */ companyId = null
  /** @type {string | null} */ stockId = null

  async connect() {
    const pathParts = window.location.pathname.split("/").filter(Boolean)
    this.companyId = pathParts[1]
    this.stockId = pathParts[3]

    try {
      const response = await fetchJson(`${Helpers.company_stock_path(this.companyId, this.stockId)}.json`)
      this.stock = response.stock || {}
      this.ledger = response.ledger || []
      this.renderContent()
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      this.element.innerHTML = `<div class="flex items-center justify-center h-screen text-danger text-lg font-semibold">${translate("Failed to load the stock row.")}${detail ? `: ${this.escape(detail)}` : ""}</div>`
    }
  }

  renderContent() {
    this.element.innerHTML = `
      <div class="min-h-screen bg-background text-foreground font-sans">
        ${this.renderHeader()}
        <main class="w-full px-4 lg:px-6 py-4 flex flex-col gap-4">
          <section data-operation-block="quantities" class="rounded-xl border border-line bg-card p-3 sm:p-4 shadow-sm flex flex-col gap-3">
            ${this.renderQuantities()}
          </section>
          <section data-operation-block="movements" class="rounded-xl border border-line bg-card p-3 sm:p-4 shadow-sm flex flex-col gap-3">
            ${this.renderMovements()}
          </section>
        </main>
      </div>
    `
  }

  renderHeader() {
    return `
      <header class="sticky top-0 z-40 border-b border-line bg-background/85 backdrop-blur-xl">
        <div class="w-full px-4 lg:px-6">
          <div class="min-h-16 py-2.5 flex flex-wrap items-center justify-between gap-3">
            <div class="flex items-center gap-3 min-w-0">
              <a href="${Helpers.company_operations_path(this.companyId)}" class="flex items-center gap-2 shrink-0">
                <span class="w-9 h-9 rounded-lg bg-primary text-primary-foreground flex items-center justify-center">
                  <span class="material-symbols-outlined text-[20px]">hub</span>
                </span>
                <span class="font-display text-lg font-extrabold tracking-tight text-primary">SKYCOM</span>
              </a>
              <div class="min-w-0">
                <h1 class="font-display text-lg font-bold text-foreground leading-tight">${this.escape(this.stock.name || "—")}</h1>
                <div class="flex flex-wrap items-center gap-1.5 text-[11px] text-muted-foreground">
                  <span>${this.escape(this.stock.code || "—")}</span>
                  ${this.stock.warehouse_name ? `<span>•</span><span>${this.escape(this.stock.warehouse_name)}</span>` : ""}
                  ${this.stock.location ? `<span>•</span><span>${this.escape(this.stock.location)}</span>` : ""}
                </div>
              </div>
            </div>
            <div class="flex flex-wrap items-center gap-2">
              ${this.renderStatusChip()}
              <a href="${Helpers.company_stocks_path(this.companyId)}"
                class="inline-flex items-center gap-1 rounded-lg bg-muted hover:bg-line px-2.5 py-1.5 min-h-[34px] text-[11px] font-semibold text-foreground transition-colors">
                <span class="material-symbols-outlined text-[16px] text-muted-foreground">list_alt</span>
                ${translate("Open stock list")}
              </a>
            </div>
          </div>
        </div>
      </header>
    `
  }

  renderStatusChip() {
    return `
      <span class="inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[11px] font-semibold ${this.statusClasses(this.stock.status)}">
        <span class="w-1.5 h-1.5 rounded-full bg-current"></span>
        ${this.escape(translate(this.stock.status_label))}
      </span>
    `
  }

  renderQuantities() {
    const cells = [
      { label: translate("On Hand"), value: this.number(this.stock.on_hand) },
      { label: translate("Reserved"), value: this.number(this.stock.reserved) },
      { label: translate("Available"), value: this.number(this.stock.available), tone: this.availableTone() },
      { label: translate("Minimum"), value: this.number(this.stock.minimum) },
      { label: translate("Price"), value: Helpers.formatMoney(this.stock.price_cents || 0, this.stock.currency) },
      { label: translate("Location"), value: this.stock.location || "—" },
      { label: translate("Warehouse"), value: this.stock.warehouse_name || "—" },
      { label: translate("Branch"), value: this.stock.branch_name || "—" }
    ]

    return `
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-3">
        ${cells.map((cell) => `
          <div class="rounded-lg border border-line bg-muted p-2.5">
            <div class="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">${cell.label}</div>
            <div class="text-[15px] font-bold text-foreground ${cell.tone || ""}">${this.escape(cell.value)}</div>
          </div>
        `).join("")}
      </div>
    `
  }

  renderMovements() {
    return `
      <div class="flex items-center justify-between gap-2 pb-2 border-b border-line">
        <div class="flex items-center gap-2">
          <span class="material-symbols-outlined text-[20px] text-primary">receipt_long</span>
          <h2 class="font-display text-[15px] font-bold text-foreground">${translate("Recent movements")}</h2>
        </div>
        <div class="flex items-center gap-2">
          <a href="${Helpers.new_company_stock_import_path(this.companyId)}" class="inline-flex items-center gap-1 rounded-lg bg-muted hover:bg-line px-2.5 py-1.5 text-[11px] font-semibold text-foreground transition-colors">${translate("Open receiving")}</a>
          <a href="${Helpers.new_company_stock_transfer_path(this.companyId)}" class="inline-flex items-center gap-1 rounded-lg bg-muted hover:bg-line px-2.5 py-1.5 text-[11px] font-semibold text-foreground transition-colors">${translate("Open transfer")}</a>
        </div>
      </div>
      ${this.ledger.length === 0
        ? `<div class="rounded-lg border border-line bg-muted p-3 text-center text-[11px] text-muted-foreground">${translate("No movements recorded for this stock row.")}</div>`
        : this.renderMovementTable()}
    `
  }

  renderMovementTable() {
    return `
      <div class="overflow-x-auto -mx-3 sm:-mx-4 px-3 sm:px-4">
        <table class="w-full min-w-[560px] text-left border-collapse">
          <thead>
            <tr class="bg-muted text-muted-foreground text-[10px] uppercase tracking-wider">
              <th class="py-2.5 px-3 rounded-l-lg font-semibold">${translate("Date")}</th>
              <th class="py-2.5 px-3 font-semibold">${translate("Type")}</th>
              <th class="py-2.5 px-3 text-right font-semibold">${translate("Quantity")}</th>
              <th class="py-2.5 px-3 rounded-r-lg font-semibold">${translate("Document")}</th>
            </tr>
          </thead>
          <tbody class="text-[12px]">
            ${this.ledger.map((row) => `
              <tr class="border-b border-line last:border-0">
                <td class="py-2.5 px-3 text-muted-foreground">${this.escape(Helpers.companyTime(row.occurred_at))}</td>
                <td class="py-2.5 px-3 font-semibold text-foreground">${this.escape(translate(row.transaction_type_label))}</td>
                <td class="py-2.5 px-3 text-right font-semibold text-foreground">${this.number(row.quantity)}</td>
                <td class="py-2.5 px-3 text-muted-foreground">${this.escape(row.document_code || "—")}</td>
              </tr>
            `).join("")}
          </tbody>
        </table>
      </div>
    `
  }

  availableTone() {
    return {
      out: "text-danger",
      low: "text-warning",
      in_stock: "text-success"
    }[this.stock.status] || "text-foreground"
  }

  statusClasses(status) {
    return {
      out: "bg-danger/10 text-danger",
      low: "bg-warning/10 text-warning",
      in_stock: "bg-success/10 text-success"
    }[status] || "bg-muted text-muted-foreground"
  }

  number(value) {
    return Number(value || 0).toLocaleString()
  }

  escape(value) {
    return String(value ?? "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;")
  }
}
