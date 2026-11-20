import { Controller } from "@hotwired/stimulus"

// Inventory — the one-page warehouse console: what is on hand, what is short,
// and the most recent receipts and dispatches for one warehouse.
//
// The ledger is server-filtered and server-searched (bucket + q on the console
// payload), so a tab count and the rows under it always describe the whole
// warehouse, never just the first screen. Export CSV downloads the same view.
//
// Serves Stimulus: Companies_Operations_Inventory_ShowController
// Depends on BE: Companies::Operations::InventoryController#show
//               (operation + appointment + config + inventory payload)
//               Companies::Operations::InventoryController#ledger (filtered CSV)
// Endpoints: Helpers.inventory_company_operation_path,
//            Helpers.inventory_ledger_company_operations_path
// Docs: docs/OPERATIONS.md, docs/STOCK.md, docs/business_analysis/05-inventory.md
export default class Companies_Operations_Inventory_ShowController extends Controller {
  /** @type {any | null} */ operation = null
  /** @type {any | null} */ appointment = null
  /** @type {any} */ inventory = {}
  /** @type {string | null} */ companyId = null
  /** @type {string | null} */ operationId = null
  /** @type {string | null} */ warehouseId = null
  /** @type {string} */ bucket = "all"
  /** @type {string} */ searchQuery = ""
  /** @type {number} */ ledgerRequestId = 0
  /** @type {number | null} */ searchTimer = null

  async connect() {
    const pathParts = window.location.pathname.split("/")
    this.companyId = this.element.dataset.companyId || pathParts[2]
    this.operationId = this.element.dataset.operationId || pathParts[5]
    this.warehouseId = new URLSearchParams(window.location.search).get("warehouse_id")

    try {
      await this.loadConsole()
      this.renderContent()
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      this.element.innerHTML = `<div class="flex items-center justify-center h-screen text-danger text-lg font-semibold">${translate("Failed to load the inventory console.")}${detail ? `: ${this.escape(detail)}` : ""}</div>`
    }
  }

  disconnect() {
    if (this.searchTimer) window.clearTimeout(this.searchTimer)
  }

  async loadConsole({ q = this.searchQuery, bucket = this.bucket } = {}) {
    const params = { q, bucket }
    if (this.warehouseId) params.warehouse_id = this.warehouseId

    const response = await fetchJson(
      Helpers.inventory_company_operation_path(this.companyId, this.operationId, params)
    )
    this.operation = response.operation
    this.appointment = response.appointment
    this.inventory = response.inventory || {}
    this.bucket = this.inventory.ledger?.bucket || "all"
    return response
  }

  // --- Derived values ---------------------------------------------------------------

  get location() {
    return this.inventory.location || this.appointment?.location || null
  }

  get locationName() {
    return this.location?.name || translate("Warehouse not resolved")
  }

  get locationCode() {
    return this.location?.code || ""
  }

  get branchName() {
    return this.inventory.branch?.name || ""
  }

  get companyName() {
    return Helpers.currentCompany()?.name || ""
  }

  get kpis() {
    return this.inventory.kpis || {}
  }

  get recentInbound() {
    return this.inventory.recent_inbound || []
  }

  get recentOutbound() {
    return this.inventory.recent_outbound || []
  }

  get cycleCounts() {
    return this.inventory.cycle_counts || { available: false, stock_rows: 0 }
  }

  get ledger() {
    return this.inventory.ledger || { rows: [], counts: {}, total: 0, limit: 0, capped: false, bucket: "all", q: "" }
  }

  get stockRows() {
    return this.ledger.rows || []
  }

  get counts() {
    return this.ledger.counts || {}
  }

  get userName() {
    return this.element.dataset.userName || Helpers.currentUser()?.name || Helpers.currentUser()?.email || ""
  }

  get userRole() {
    const role = this.element.dataset.userRole || Helpers.currentEmployee()?.category?.name
    return role && role !== "Employees" ? role : ""
  }

  get updatedLabel() {
    const generatedAt = this.inventory.generated_at
    if (!generatedAt) return ""
    return `${translate("Updated")} ${this.time(generatedAt)}`
  }

  // --- Rendering --------------------------------------------------------------------

  renderContent() {
    this.element.innerHTML = `
      <div class="min-h-screen overflow-x-hidden bg-background text-foreground font-sans">
        ${this.renderHeader()}
        <main class="w-full px-4 lg:px-6 py-4 flex flex-col gap-4">
          ${this.renderActions()}
          <section data-operation-block="kpis" class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3">
            ${this.renderKpis()}
          </section>
          <div class="grid grid-cols-1 lg:grid-cols-12 gap-4 items-start">
            <div data-inventory-main-column class="lg:col-span-8 flex flex-col gap-4 min-w-0">
              <section data-operation-block="ledger">${this.renderLedger()}</section>
            </div>
            <div data-inventory-side-column class="lg:col-span-4 flex flex-col gap-4 min-w-0">
              <section data-operation-block="recent-inbound">${this.renderRecentPanel("inbound")}</section>
              <section data-operation-block="recent-outbound">${this.renderRecentPanel("outbound")}</section>
              <section data-operation-block="cycle-counts">${this.renderCycleCounts()}</section>
            </div>
          </div>
        </main>
      </div>
    `
  }

  renderHeader() {
    const warehouse = `${this.escape(this.locationName)}${this.locationCode ? ` (${this.escape(this.locationCode)})` : ""}`
    const meta = [ this.branchName, this.companyName ].filter(Boolean).map((value) => this.escape(value))

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
                <h1 class="font-display text-lg font-bold text-foreground leading-tight">${translate("Inventory")}</h1>
                <div class="flex flex-wrap items-center gap-1.5 text-[11px] text-muted-foreground">
                  <span class="font-semibold text-foreground">${warehouse}</span>
                  ${meta.map((value) => `<span>•</span><span>${value}</span>`).join("")}
                </div>
                <div class="flex items-center gap-1.5 text-[11px] text-muted-foreground mt-0.5">
                  <span id="inventory-updated-at">${this.escape(this.updatedLabel)}</span>
                  <button type="button" data-action="click->${this.identifier}#refreshConsole"
                    class="w-6 h-6 rounded-md hover:bg-muted text-muted-foreground flex items-center justify-center transition-colors"
                    aria-label="${translate("Refresh")}" title="${translate("Refresh")}" ${Helpers.tooltip(translate("Refresh"))}>
                    <span class="material-symbols-outlined text-[16px]">refresh</span>
                  </button>
                </div>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <button type="button" class="w-10 h-10 rounded-lg bg-muted hover:bg-line text-foreground flex items-center justify-center transition-colors" ${Helpers.darkmodeTrigger()} title="${translate("Toggle dark mode")}"></button>
              <div class="flex items-center gap-2 pl-1">
                <div class="hidden sm:flex flex-col items-end">
                  <span class="text-[12px] font-bold text-foreground">${this.escape(this.userName)}</span>
                  ${this.userRole ? `<span class="text-[10px] text-muted-foreground">${this.escape(this.userRole)}</span>` : ""}
                </div>
                <div class="w-8 h-8 rounded-full bg-primary text-primary-foreground flex items-center justify-center">
                  <span class="material-symbols-outlined text-[18px]">person</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </header>
    `
  }

  renderActions() {
    return `
      <div class="flex flex-wrap items-center gap-2">
        ${this.renderActionLink(Helpers.new_company_stock_import_path(this.companyId), "move_to_inbox", translate("Open receiving"), true)}
        ${this.renderActionLink(Helpers.new_company_stock_transfer_path(this.companyId), "unarchive", translate("Open transfer"))}
        ${this.renderActionLink(Helpers.company_stocks_path(this.companyId), "list_alt", translate("Open stock list"))}
      </div>
    `
  }

  renderActionLink(href, icon, label, primary = false) {
    const classes = primary
      ? "bg-primary text-primary-foreground hover:brightness-110"
      : "bg-muted text-foreground hover:bg-line"

    return `
      <a href="${href}" class="inline-flex items-center gap-1.5 px-3 py-2 min-h-[36px] rounded-lg text-[12px] font-semibold transition-all shadow-sm active:scale-[0.98] ${classes}">
        <span class="material-symbols-outlined text-[17px] ${primary ? "" : "text-muted-foreground"}">${icon}</span>
        <span>${label}</span>
      </a>
    `
  }

  renderKpis() {
    return `
      ${this.renderKpiCard({
        key: "stock_rows",
        label: translate("Stock rows"),
        value: this.number(this.kpis.stock_rows),
        icon: "shelves",
        tone: "primary"
      })}
      ${this.renderKpiCard({
        key: "low_or_out",
        label: translate("Low or out"),
        value: this.number(this.kpis.low_or_out),
        icon: "warning",
        tone: (this.kpis.low_or_out || 0) > 0 ? "danger" : "success",
        footer: `${this.number(this.kpis.out)} ${translate("out")}`
      })}
      ${this.renderKpiCard({
        key: "recent_inbound",
        label: translate("Recent inbound"),
        value: this.number(this.kpis.recent_inbound?.count),
        icon: "call_received",
        tone: "success",
        footer: `${this.number(this.kpis.recent_inbound?.units)} ${translate("units")}`
      })}
      ${this.renderKpiCard({
        key: "recent_outbound",
        label: translate("Recent outbound"),
        value: this.number(this.kpis.recent_outbound?.count),
        icon: "call_made",
        tone: "info",
        footer: `${this.number(this.kpis.recent_outbound?.units)} ${translate("units")}`
      })}
    `
  }

  renderKpiCard({ key, label, value, icon, tone, footer = "" }) {
    const tones = {
      primary: { icon: "text-primary bg-primary/10", accent: "bg-primary" },
      success: { icon: "text-success bg-success/10", accent: "bg-success" },
      warning: { icon: "text-warning bg-warning/10", accent: "bg-warning" },
      danger: { icon: "text-danger bg-danger/10", accent: "bg-danger" },
      info: { icon: "text-primary bg-primary/10", accent: "bg-primary" }
    }
    const toneClass = tones[tone] || tones.primary

    return `
      <div data-kpi="${key}" class="relative overflow-hidden rounded-xl border border-line bg-card p-3 shadow-sm flex flex-col justify-between">
        <span class="absolute left-0 top-0 h-full w-1.5 ${toneClass.accent}"></span>
        <div class="flex items-start justify-between gap-2 pl-1">
          <span class="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">${label}</span>
          <span class="w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${toneClass.icon}">
            <span class="material-symbols-outlined text-[19px]">${icon}</span>
          </span>
        </div>
        <div class="mt-2 pl-1">
          <div class="font-display text-2xl font-extrabold tracking-tight text-foreground">${value}</div>
          ${footer ? `<div class="text-[11px] text-muted-foreground mt-1">${footer}</div>` : ""}
        </div>
      </div>
    `
  }

  renderLedger() {
    return `
      <div class="rounded-xl border border-line bg-card p-3 sm:p-4 shadow-sm flex flex-col gap-3">
        <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-2">
          <div class="min-w-0">
            <h2 class="font-display text-lg font-bold text-foreground tracking-tight">${translate("Stock ledger")}</h2>
            <p class="text-[12px] text-muted-foreground mt-0.5">
              ${translate("On hand, reserved, and available in")} ${this.escape(this.locationName)}. ${translate("A row is low when available is")} ${this.number(this.kpis.minimum ?? 0)} ${translate("or less. That minimum is the same for every product.")}
            </p>
          </div>
          <a id="inventory-ledger-export" href="${this.escape(this.exportHref())}"
            class="inline-flex items-center gap-1 rounded-lg bg-muted hover:bg-line px-2.5 py-1.5 min-h-[34px] text-[11px] font-semibold text-foreground transition-colors shrink-0">
            <span class="material-symbols-outlined text-[16px] text-muted-foreground">file_download</span>
            ${translate("Export CSV")}
          </a>
        </div>

        <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-2 rounded-lg bg-muted p-2">
          <div class="relative flex-1">
            <span class="material-symbols-outlined absolute left-2.5 top-1/2 -translate-y-1/2 text-[18px] text-muted-foreground pointer-events-none">search</span>
            <input id="inventory-stock-search" type="text" value="${this.escape(this.searchQuery)}"
              data-action="input->${this.identifier}#onSearchInput keydown.enter->${this.identifier}#onSearchSubmit keydown.esc->${this.identifier}#clearSearch"
              placeholder="${translate("Search name, code, or location")}"
              class="w-full h-9 pl-9 pr-3 rounded-lg bg-card text-foreground placeholder:text-muted-foreground text-[12px] border border-line focus:outline-none focus:ring-2 focus:ring-primary shadow-sm" />
          </div>
          <div id="inventory-ledger-tabs" class="flex items-center gap-1 overflow-x-auto p-0.5">
            ${this.renderTabs()}
          </div>
        </div>

        <div class="overflow-x-auto -mx-3 sm:-mx-4 px-3 sm:px-4">
          <table class="w-full min-w-[720px] text-left border-collapse">
            <thead>
              <tr class="bg-muted text-muted-foreground text-[10px] uppercase tracking-wider">
                <th class="py-2.5 px-3 rounded-l-lg font-semibold">${translate("Product")}</th>
                <th class="py-2.5 px-3 font-semibold">${translate("Location")}</th>
                <th class="py-2.5 px-3 text-right font-semibold">${translate("On Hand")}</th>
                <th class="py-2.5 px-3 text-right font-semibold">${translate("Reserved")}</th>
                <th class="py-2.5 px-3 text-right font-semibold">${translate("Available")}</th>
                <th class="py-2.5 px-3 text-right font-semibold">${translate("Minimum")}</th>
                <th class="py-2.5 px-3 font-semibold">${translate("Status")}</th>
                <th class="py-2.5 px-3 text-right rounded-r-lg font-semibold">${translate("Open")}</th>
              </tr>
            </thead>
            <tbody id="inventory-ledger-rows" class="text-[12px]">${this.renderRows()}</tbody>
          </table>
        </div>

        <div id="inventory-ledger-footer">${this.renderFooter()}</div>
      </div>
    `
  }

  renderTabs() {
    const tabs = [
      { key: "all", label: translate("All") },
      { key: "low", label: translate("Low") },
      { key: "out", label: translate("Out") },
      { key: "in_stock", label: translate("In stock") }
    ]

    return tabs.map((tab) => {
      const active = tab.key === this.inventory.ledger?.bucket
      const classes = active
        ? "bg-card text-primary shadow-sm border border-line"
        : "text-muted-foreground hover:bg-card/60 hover:text-foreground"

      return `
        <button type="button" data-action="click->${this.identifier}#setBucket" data-${this.identifier}-bucket-param="${tab.key}"
          aria-current="${active}" class="px-2.5 py-1.5 min-h-[30px] rounded-md text-[11px] font-semibold whitespace-nowrap transition-all ${classes}">
          ${tab.label} (${this.number(this.counts[tab.key])})
        </button>
      `
    }).join("")
  }

  renderRows() {
    if (this.stockRows.length === 0) {
      return `
        <tr>
          <td colspan="8" class="py-8 px-3 text-center text-muted-foreground text-[12px]">${translate("No stock rows match this view.")}</td>
        </tr>
      `
    }

    return this.stockRows.map((stock) => this.renderRow(stock)).join("")
  }

  renderRow(stock) {
    const availableTone = stock.status === "out"
      ? "text-danger font-bold"
      : stock.status === "low"
        ? "text-warning font-semibold"
        : "text-success font-semibold"

    return `
      <tr class="border-b border-line last:border-0 hover:bg-muted/60 transition-colors align-top">
        <td class="py-2.5 px-3">
          <div class="font-semibold text-foreground">${this.escape(stock.name || "—")}</div>
          <div class="text-[10px] text-muted-foreground flex flex-wrap items-center gap-1">
            <span>${this.escape(stock.code || "—")}</span>
            <span>•</span>
            <span>${Helpers.formatMoney(stock.price_cents || 0, stock.currency)}</span>
          </div>
        </td>
        <td class="py-2.5 px-3 text-[11px] text-muted-foreground">${this.escape(stock.location || "—")}</td>
        <td class="py-2.5 px-3 text-right font-semibold text-foreground">${this.number(stock.on_hand)}</td>
        <td class="py-2.5 px-3 text-right text-muted-foreground">${this.number(stock.reserved)}</td>
        <td class="py-2.5 px-3 text-right ${availableTone}">${this.number(stock.available)}</td>
        <td class="py-2.5 px-3 text-right text-muted-foreground">${this.number(stock.minimum)}</td>
        <td class="py-2.5 px-3">
          <span class="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-semibold ${this.statusClasses(stock.status)}">
            <span class="w-1.5 h-1.5 rounded-full bg-current"></span>
            ${this.escape(translate(stock.status_label))}
          </span>
        </td>
        <td class="py-2.5 px-3 text-right">
          <a href="${this.escape(stock.stock_path)}" class="inline-flex items-center gap-1 rounded-md bg-muted hover:bg-line px-2.5 py-1 text-[11px] font-semibold text-foreground transition-colors">${translate("Open")}</a>
        </td>
      </tr>
    `
  }

  renderFooter() {
    const rows = this.stockRows.length
    const total = this.ledger.total || 0
    const capped = this.ledger.capped === true

    return `
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pt-1 text-[11px] text-muted-foreground">
        <span>${translate("Showing")} ${this.number(rows)} ${translate("of")} ${this.number(total)}</span>
        ${capped ? `
          <div class="flex flex-wrap items-center gap-2">
            <span>${translate("This list is capped.")}</span>
            <a href="${Helpers.company_stocks_path(this.companyId)}" class="rounded bg-muted px-2.5 py-1 text-[11px] font-semibold text-foreground hover:bg-line transition-colors">${translate("Open stock list")}</a>
          </div>
        ` : ""}
      </div>
    `
  }

  renderRecentPanel(direction) {
    const inbound = direction === "inbound"
    const records = inbound ? this.recentInbound : this.recentOutbound
    const title = inbound ? translate("Recent inbound") : translate("Recent outbound")
    const empty = inbound ? translate("No recent receipts.") : translate("No recent dispatches.")
    const icon = inbound ? "call_received" : "call_made"
    const tone = inbound ? "text-success" : "text-primary"

    return `
      <div class="rounded-xl border border-line bg-card p-3 shadow-sm flex flex-col gap-2">
        <div class="flex items-center gap-2 pb-2 border-b border-line">
          <span class="material-symbols-outlined text-[20px] ${tone}">${icon}</span>
          <h2 class="font-display text-[15px] font-bold text-foreground">${title}</h2>
        </div>
        ${records.length === 0
          ? `<div class="rounded-lg border border-line bg-muted p-3 text-center text-[11px] text-muted-foreground">${empty}</div>`
          : `<div class="flex flex-col gap-2">${records.map((record) => this.renderRecentRecord(record)).join("")}</div>`}
      </div>
    `
  }

  renderRecentRecord(record) {
    return `
      <div class="rounded-lg border border-line bg-muted p-2.5 flex items-center justify-between gap-2">
        <div class="min-w-0">
          <div class="text-[12px] font-semibold text-foreground truncate">${this.escape(record.code || "—")}</div>
          <div class="text-[11px] text-muted-foreground">${this.number(record.quantity)} ${translate("units")} • ${this.escape(this.time(record.occurred_at))}</div>
        </div>
        <span class="rounded-full bg-card border border-line px-2 py-0.5 text-[10px] font-semibold text-muted-foreground whitespace-nowrap">
          ${this.escape(translate(record.status_label))}
        </span>
      </div>
    `
  }

  renderCycleCounts() {
    const stockRows = this.cycleCounts.stock_rows || 0

    return `
      <div class="rounded-xl border border-line bg-card p-3 shadow-sm flex flex-col gap-2">
        <div class="flex items-center gap-2 pb-2 border-b border-line">
          <span class="material-symbols-outlined text-[20px] text-muted-foreground">fact_check</span>
          <h2 class="font-display text-[15px] font-bold text-foreground">${translate("Cycle counts")}</h2>
        </div>
        <p class="text-[11px] text-muted-foreground">${translate("Cycle counts are not available yet.")}</p>
        <p class="text-[11px] text-muted-foreground">
          ${this.number(stockRows)} ${translate("stock rows are in this warehouse.")} ${translate("Skycom does not record a count or a variance.")}
        </p>
      </div>
    `
  }

  // --- Interactions -----------------------------------------------------------------

  setBucket(event) {
    this.bucket = event.params.bucket
    this.refreshLedger()
  }

  onSearchInput(event) {
    this.searchQuery = event.target.value || ""
    if (this.searchTimer) window.clearTimeout(this.searchTimer)
    this.searchTimer = window.setTimeout(() => this.refreshLedger(), 250)
  }

  onSearchSubmit(event) {
    if (event) event.preventDefault()
    if (this.searchTimer) window.clearTimeout(this.searchTimer)
    this.refreshLedger()
  }

  clearSearch(event) {
    if (event) event.preventDefault()
    this.searchQuery = ""
    const input = document.getElementById("inventory-stock-search")
    if (input) input.value = ""
    this.refreshLedger()
  }

  async refreshLedger() {
    const requestId = ++this.ledgerRequestId

    try {
      await this.loadConsole()
      if (requestId !== this.ledgerRequestId) return

      this.replaceHTML("inventory-ledger-tabs", this.renderTabs())
      this.replaceHTML("inventory-ledger-rows", this.renderRows())
      this.replaceHTML("inventory-ledger-footer", this.renderFooter())
      this.updateExportHref()
    } catch (error) {
      if (requestId !== this.ledgerRequestId) return
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to refresh the stock ledger.") })
    }
  }

  async refreshConsole(event) {
    if (event) event.preventDefault()

    try {
      await this.loadConsole()
      this.renderContent()
      toast({ type: "success", message: translate("Inventory refreshed.") })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to refresh the inventory console.") })
    }
  }

  updateExportHref() {
    const link = document.getElementById("inventory-ledger-export")
    if (link) link.href = this.exportHref()
  }

  exportHref() {
    const params = { bucket: this.ledger.bucket || "all" }
    if (this.warehouseId) params.warehouse_id = this.warehouseId
    const query = (this.ledger.q || this.searchQuery || "").trim()
    if (query) params.q = query

    return Helpers.inventory_ledger_company_operations_path(this.companyId, this.operationId, params)
  }

  replaceHTML(id, html) {
    const element = document.getElementById(id)
    if (element) element.innerHTML = html
  }

  // --- Helpers ----------------------------------------------------------------------

  statusClasses(status) {
    return {
      out: "bg-danger/10 text-danger",
      low: "bg-warning/10 text-warning",
      in_stock: "bg-success/10 text-success"
    }[status] || "bg-muted text-muted-foreground"
  }

  time(value) {
    return Helpers.locationTime(value, undefined, this.location)
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
