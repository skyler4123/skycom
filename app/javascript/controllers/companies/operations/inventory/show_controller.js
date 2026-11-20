import { Controller } from "@hotwired/stimulus"

// Inventory — the warehouse-level stock command screen. Four KPI cards, the
// server-paged stock ledger, inbound/outbound stacks and the cycle-count card;
// every write finishes in a drawer or the full-screen count sheet.
//
// Serves Stimulus: Companies_Operations_Inventory_ShowController
// Depends on BE: Companies::Operations::InventoryController#show/ledger/export
//               + create_receipt/post_receipt/create_transfer/receive_transfer/
//                 create_export/create_adjustment/create_reorder/start_count/
//                 show_count/update_count/submit_count
//               (operation + appointment + config + inventory payload)
// Endpoints: Helpers.inventory_company_operation_path
//            Helpers.inventory_ledger_company_operation_path
//            Helpers.inventory_export_company_operation_path
//            Helpers.inventory_receipts_company_operation_path
//            Helpers.inventory_receipt_post_company_operation_path
//            Helpers.inventory_transfers_company_operation_path
//            Helpers.inventory_transfer_receive_company_operation_path
//            Helpers.inventory_exports_company_operation_path
//            Helpers.inventory_adjustments_company_operation_path
//            Helpers.inventory_reorder_company_operation_path
//            Helpers.inventory_counts_company_operation_path
//            Helpers.inventory_count_company_operation_path
//            Helpers.inventory_count_submit_company_operation_path
// Docs: docs/OPERATIONS.md, docs/STOCK.md, docs/business_analysis/05-inventory.md
export default class Companies_Operations_Inventory_ShowController extends Controller {
  /** @type {any | null} */ operation = null
  /** @type {any | null} */ appointment = null
  /** @type {any} */ inventory = {}
  /** @type {{stocks: any[], pagination: any, counts: any}} */ ledger = { stocks: [], pagination: {}, counts: {} }
  /** @type {string | null} */ companyId = null
  /** @type {string | null} */ operationId = null
  /** @type {string | null} */ warehouseId = null
  /** @type {string} */ filter = "all"
  /** @type {string} */ query = ""
  /** @type {number} */ page = 1

  /** @type {any | null} */ drawer = null
  /** @type {any | null} */ count = null
  /** @type {any[]} */ drawerSearchResults = []
  /** @type {boolean} */ drawerSearchLoaded = false
  /** @type {boolean} */ submitting = false
  /** @type {number | null} */ searchTimer = null

  connect() {
    const pathParts = window.location.pathname.split("/")
    this.companyId = this.element.dataset.companyId || pathParts[2]
    this.operationId = this.element.dataset.operationId || pathParts[5]
    this.warehouseId = new URLSearchParams(window.location.search).get("warehouse_id")
    this.onKeydown = this.onKeydown.bind(this)
    document.addEventListener("keydown", this.onKeydown)

    this.bootstrap()
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeydown)
    if (this.searchTimer) window.clearTimeout(this.searchTimer)
  }

  async bootstrap() {
    try {
      await this.loadConsole()
      this.ledger = {
        stocks: this.inventory.stocks || [],
        pagination: this.inventory.pagination || {},
        counts: this.inventory.counts || {},
        search_capped: this.inventory.search_capped === true
      }
      this.renderContent()
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      this.element.innerHTML = `<div class="flex h-screen items-center justify-center bg-background px-6 text-center text-lg font-semibold text-danger">${translate("Failed to load the inventory console.")}${detail ? `: ${this.escape(detail)}` : ""}</div>`
    }
  }

  async loadConsole() {
    const params = this.warehouseId ? { warehouse_id: this.warehouseId } : {}
    const response = await fetchJson(
      Helpers.inventory_company_operation_path(this.companyId, this.operationId, params)
    )
    this.operation = response.operation
    this.appointment = response.appointment
    this.inventory = response.inventory || {}
    return response
  }

  async loadLedger() {
    const params = {
      warehouse_id: this.warehouseId,
      filter: this.filter,
      page: this.page
    }
    if (this.query.trim()) params.q = this.query.trim()

    const response = await fetchJson(
      Helpers.inventory_ledger_company_operation_path(this.companyId, this.operationId, params)
    )
    this.ledger = {
      stocks: response.stocks || [],
      pagination: response.pagination || {},
      counts: response.counts || {},
      search_capped: response.search_capped === true
    }
    return response
  }

  async refreshAll() {
    await this.loadConsole()
    await this.loadLedger()
    this.renderContent()
    if (this.count) this.renderCountSheet()
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

  get currency() {
    return this.inventory.currency || "usd"
  }

  get metrics() {
    return this.inventory.metrics || {}
  }

  get stocks() {
    return this.ledger.stocks || []
  }

  get pagination() {
    return this.ledger.pagination || {}
  }

  get counts() {
    return this.ledger.counts || {}
  }

  get inbound() {
    return this.inventory.inbound || {}
  }

  get outbound() {
    return this.inventory.outbound || {}
  }

  get openCount() {
    return this.inventory.open_count || null
  }

  get lastCount() {
    return this.inventory.last_count || null
  }

  get reference() {
    return this.inventory.reference || {}
  }

  get companyName() {
    return Helpers.currentCompany()?.name || translate("Company")
  }

  get userName() {
    return this.element.dataset.userName || Helpers.currentUser()?.name || Helpers.currentUser()?.email || translate("Manager")
  }

  get userRole() {
    const role = this.element.dataset.userRole || Helpers.currentEmployee()?.category?.name
    return role && role !== "Employees" ? role : translate("Inventory Manager")
  }

  // --- Rendering --------------------------------------------------------------------

  renderContent() {
    this.element.innerHTML = `
      <div class="min-h-screen overflow-x-hidden bg-background font-sans text-foreground">
        ${this.renderHeader()}
        <main class="flex w-full flex-col gap-4 px-4 py-4 lg:px-6">
          <div data-operation-block="context">${this.renderContextBar()}</div>
          <div data-operation-block="kpis">${this.renderKpis()}</div>
          <div class="grid grid-cols-1 items-start gap-4 lg:grid-cols-12">
            <div data-inventory-main-column class="flex min-w-0 flex-col gap-4 lg:col-span-8">
              <div data-operation-block="ledger">${this.renderLedgerSection()}</div>
            </div>
            <div data-inventory-side-column class="flex min-w-0 flex-col gap-4 lg:col-span-4">
              <div data-operation-block="inbound">${this.renderInboundPanel()}</div>
              <div data-operation-block="outbound">${this.renderOutboundPanel()}</div>
              <div data-operation-block="last-count">${this.renderCountPanel()}</div>
            </div>
          </div>
        </main>
      </div>
      <div id="inventory-drawer-root"></div>
      <div id="inventory-count-root"></div>
    `
    this.renderDrawer()
    this.renderCountSheet()
  }

  renderHeader() {
    return `
      <header class="sticky top-0 z-40 border-b border-line bg-background/85 backdrop-blur-xl">
        <div class="w-full px-4 lg:px-6">
          <div class="flex h-16 items-center justify-between gap-3">
            <div class="flex min-w-0 items-center gap-3 xl:gap-4">
              <a href="${Helpers.company_operations_path(this.companyId)}" class="flex shrink-0 items-center gap-2">
                <span class="flex h-9 w-9 items-center justify-center rounded-lg bg-primary text-primary-foreground">
                  <span class="material-symbols-outlined text-[20px]">hub</span>
                </span>
                <span class="font-display text-lg font-extrabold tracking-tight text-primary">SKYCOM</span>
              </a>
              <div class="hidden min-w-0 items-center gap-2 rounded-lg border border-line bg-muted px-3 py-1.5 md:flex">
                <span class="material-symbols-outlined text-[18px] text-muted-foreground">corporate_fare</span>
                <div class="flex min-w-0 flex-col">
                  <span class="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">${translate("Company")}</span>
                  <span class="truncate text-[13px] font-semibold text-foreground">${this.escape(this.companyName)}</span>
                </div>
              </div>
              <div class="hidden min-w-0 items-center gap-1.5 text-muted-foreground xl:flex">
                <span class="material-symbols-outlined text-[18px]">warehouse</span>
                <span class="truncate text-[12px] font-medium">${this.escape(this.locationName)}${this.locationCode ? ` · ${this.escape(this.locationCode)}` : ""}</span>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <button type="button" class="flex h-10 w-10 items-center justify-center rounded-lg bg-muted text-foreground transition-colors hover:bg-line" ${Helpers.darkmodeTrigger()} title="${translate("Toggle dark mode")}"></button>
              <div class="flex items-center gap-2 pl-1">
                <div class="hidden flex-col items-end sm:flex">
                  <span class="text-[12px] font-bold text-foreground">${this.escape(this.userName)}</span>
                  <span class="text-[10px] text-muted-foreground">${this.escape(this.userRole)}</span>
                </div>
                <div class="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-primary-foreground">
                  <span class="material-symbols-outlined text-[18px]">person</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </header>
    `
  }

  renderContextBar() {
    return `
      <section class="flex flex-col justify-between gap-3 rounded-xl border border-line bg-card p-3 shadow-sm lg:flex-row lg:items-center">
        <div class="flex min-w-0 items-center gap-2.5">
          <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-primary text-primary-foreground shadow-sm">
            <span class="material-symbols-outlined text-[22px]">inventory_2</span>
          </span>
          <div class="min-w-0">
            <div class="font-display text-[15px] font-bold text-foreground">${this.escape(this.locationName)}${this.locationCode ? ` (${this.escape(this.locationCode)})` : ""}</div>
            <div class="text-[11px] text-muted-foreground">${translate("Last refreshed")} ${this.escape(this.time(this.inventory.generated_at))}</div>
          </div>
        </div>
        <div class="flex flex-wrap items-center gap-1.5">
          <button type="button" data-action="click->${this.identifier}#openReceive" class="inline-flex min-h-[36px] items-center gap-1.5 rounded-lg bg-primary px-3 py-2 text-[12px] font-semibold text-primary-foreground shadow-sm transition-all hover:brightness-110 active:scale-[0.98]">
            <span class="material-symbols-outlined text-[17px]">move_to_inbox</span>
            ${translate("Receive")}
          </button>
          <button type="button" data-action="click->${this.identifier}#openTransfer" class="inline-flex min-h-[36px] items-center gap-1.5 rounded-lg bg-muted px-3 py-2 text-[12px] font-semibold text-foreground shadow-sm transition-colors hover:bg-line active:scale-[0.98]">
            <span class="material-symbols-outlined text-[17px] text-muted-foreground">unarchive</span>
            ${translate("Transfer out")}
          </button>
          <button type="button" data-action="click->${this.identifier}#openCountSheet" class="inline-flex min-h-[36px] items-center gap-1.5 rounded-lg bg-muted px-3 py-2 text-[12px] font-semibold text-foreground shadow-sm transition-colors hover:bg-line active:scale-[0.98]">
            <span class="material-symbols-outlined text-[17px] text-muted-foreground">fact_check</span>
            ${this.openCount ? translate("Continue count") : translate("Count")}
          </button>
        </div>
      </section>
    `
  }

  renderKpis() {
    return `
      <section class="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
        ${this.renderKpiCard({
          label: translate("Stock rows"),
          value: this.number(this.metrics.stock_rows),
          footer: `${this.number(this.metrics.units_on_hand)} ${translate("units on hand")}`,
          icon: "shelves",
          tone: "primary"
        })}
        ${this.renderKpiCard({
          label: translate("Needs attention"),
          value: this.number(this.metrics.needs_attention),
          footer: `${this.number(this.metrics.at_zero_available)} ${translate("at zero available")}`,
          icon: "warning",
          tone: (this.metrics.needs_attention || 0) > 0 ? "warning" : "success"
        })}
        ${this.renderKpiCard({
          label: translate("Inbound open"),
          value: this.number(this.metrics.inbound_open),
          footer: `${this.number(this.metrics.inbound_units)} ${translate("units to receive")}`,
          icon: "call_received",
          tone: "info"
        })}
        ${this.renderKpiCard({
          label: translate("Outbound open"),
          value: this.number(this.metrics.outbound_open),
          footer: `${this.number(this.metrics.outbound_units)} ${translate("units to leave")}`,
          icon: "call_made",
          tone: "info"
        })}
      </section>
    `
  }

  renderKpiCard({ label, value, footer, icon, tone }) {
    const tones = {
      primary: { accent: "bg-primary", icon: "bg-primary/10 text-primary" },
      success: { accent: "bg-success", icon: "bg-success/10 text-success" },
      warning: { accent: "bg-warning", icon: "bg-warning/10 text-warning" },
      danger: { accent: "bg-danger", icon: "bg-danger/10 text-danger" },
      info: { accent: "bg-info", icon: "bg-info/10 text-info" }
    }
    const toneClass = tones[tone] || tones.primary

    return `
      <div class="relative flex flex-col justify-between overflow-hidden rounded-xl border border-line bg-card p-3 shadow-sm">
        <span class="absolute left-0 top-0 h-full w-1.5 ${toneClass.accent}"></span>
        <div class="flex items-start justify-between gap-2 pl-1">
          <span class="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">${label}</span>
          <span class="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg ${toneClass.icon}">
            <span class="material-symbols-outlined text-[19px]">${icon}</span>
          </span>
        </div>
        <div class="mt-2 pl-1">
          <div class="font-display text-2xl font-extrabold tracking-tight text-foreground">${value}</div>
          <div class="mt-1 text-[11px] text-muted-foreground">${footer}</div>
        </div>
      </div>
    `
  }

  renderLedgerSection() {
    return `
      <section class="flex flex-col gap-3 rounded-xl border border-line bg-card p-3 shadow-sm sm:p-4">
        <div class="flex flex-col justify-between gap-2 sm:flex-row sm:items-center">
          <div class="min-w-0">
            <div class="flex items-center gap-2">
              <span class="material-symbols-outlined text-[22px] text-primary">inventory</span>
              <h2 class="font-display text-lg font-bold tracking-tight text-foreground">${translate("Stock")}</h2>
            </div>
            <p class="mt-0.5 text-[12px] text-muted-foreground">${translate("On hand, reserved, and available for")} ${this.escape(this.locationName)}.</p>
          </div>
          <div class="flex items-center gap-1.5">
            <a href="${Helpers.inventory_export_company_operation_path(this.companyId, this.operationId, this.exportParams())}" class="inline-flex min-h-[34px] items-center gap-1 rounded-lg bg-muted px-2.5 py-1.5 text-[11px] font-semibold text-foreground transition-colors hover:bg-line">
              <span class="material-symbols-outlined text-[16px] text-muted-foreground">file_download</span>
              ${translate("Export")}
            </a>
            <button type="button" data-action="click->${this.identifier}#refreshConsole" class="flex h-9 w-9 items-center justify-center rounded-lg bg-muted text-muted-foreground transition-colors hover:bg-line" title="${translate("Refresh stock ledger")}">
              <span class="material-symbols-outlined text-[18px]">refresh</span>
            </button>
          </div>
        </div>

        <div class="flex flex-col justify-between gap-2 rounded-lg bg-muted p-2 lg:flex-row lg:items-center">
          <div class="relative flex-1">
            <span class="pointer-events-none absolute left-2.5 top-1/2 -translate-y-1/2 text-[18px] text-muted-foreground material-symbols-outlined">search</span>
            <input id="inventory-stock-search" type="search" value="${this.escape(this.query)}"
              data-action="input->${this.identifier}#updateSearch"
              placeholder="${translate("Search by item name, code, or location...")}"
              class="h-9 w-full rounded-lg border border-line bg-card pl-9 pr-3 text-[12px] text-foreground shadow-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary" />
          </div>
          <div id="inventory-stock-tabs" class="flex items-center gap-1 overflow-x-auto p-0.5">
            ${this.renderStockTabs()}
          </div>
        </div>

        <div class="-mx-3 overflow-x-auto px-3 sm:-mx-4 sm:px-4">
          <table class="w-full border-collapse text-left">
            <thead>
              <tr class="bg-muted text-[10px] uppercase tracking-wider text-muted-foreground">
                <th class="rounded-l-lg px-3 py-2.5 font-semibold">${translate("Item")}</th>
                <th class="px-3 py-2.5 font-semibold">${translate("Location")}</th>
                <th class="px-3 py-2.5 text-right font-semibold">${translate("On hand")}</th>
                <th class="px-3 py-2.5 text-right font-semibold">${translate("Reserved")}</th>
                <th class="px-3 py-2.5 text-right font-semibold">${translate("Available")}</th>
                <th class="px-3 py-2.5 text-right font-semibold">${translate("Reorder at")}</th>
                <th class="px-3 py-2.5 font-semibold">${translate("Status")}</th>
                <th class="rounded-r-lg px-3 py-2.5 text-right font-semibold">${translate("Action")}</th>
              </tr>
            </thead>
            <tbody id="inventory-stock-rows" class="text-[12px]">
              ${this.renderStockRows()}
            </tbody>
          </table>
        </div>

        <div class="flex flex-col gap-1 text-[11px] text-muted-foreground">
          <div id="inventory-search-capped">${this.searchCappedNote()}</div>
          <p>${this.reorderFootnote()}</p>
        </div>

        <div id="inventory-ledger-footer" class="flex flex-col justify-between gap-2 border-t border-line pt-2 text-[11px] text-muted-foreground sm:flex-row sm:items-center">
          ${this.renderLedgerFooter()}
        </div>
      </section>
    `
  }

  reorderFootnote() {
    const point = this.inventory.reorder_default ?? 10
    if (this.inventory.reorder_rules_present) {
      return `${translate("Items without their own reorder point use")} ${point}.`
    }
    return `${translate("Same reorder point for every item:")} ${point}.`
  }

  searchCappedNote() {
    if (!this.ledger.search_capped) return ""
    return `<p class="text-[11px] text-warning">${translate("Search is limited to the first 1,000 matches. Narrow the search to see more.")}</p>`
  }

  renderStockTabs() {
    const tabs = [
      { key: "all", label: translate("All"), count: this.counts.all || 0 },
      { key: "low", label: translate("Low"), count: this.counts.low || 0 },
      { key: "out", label: translate("Out"), count: this.counts.out || 0 },
      { key: "in_stock", label: translate("In stock"), count: this.counts.in_stock || 0 }
    ]

    return tabs.map((tab) => {
      const active = tab.key === this.filter
      return `
        <button type="button" data-action="click->${this.identifier}#setFilter" data-filter="${tab.key}"
          class="min-h-[30px] whitespace-nowrap rounded-md px-2.5 py-1.5 text-[11px] font-semibold transition-all ${active ? "border border-line bg-card text-primary shadow-sm" : "text-muted-foreground hover:bg-card/60 hover:text-foreground"}">
          ${tab.label} (${tab.count})
        </button>
      `
    }).join("")
  }

  renderStockRows() {
    if (this.stocks.length === 0) {
      return `
        <tr>
          <td colspan="8" class="px-3 py-8 text-center text-[12px] text-muted-foreground" data-ledger-empty>${this.ledgerEmptyMessage()}</td>
        </tr>
      `
    }

    return this.stocks.map((stock) => this.renderStockRow(stock)).join("")
  }

  ledgerEmptyMessage() {
    const query = this.query.trim()
    if (query && !query.includes(" ")) {
      return `${translate("Code not found:")} ${this.escape(query)}`
    }
    return translate("No stock rows match this view.")
  }

  renderStockRow(stock) {
    const statusTone = {
      out: "bg-danger/10 text-danger",
      low: "bg-warning/10 text-warning",
      in_stock: "bg-success/10 text-success"
    }[stock.status] || "bg-muted text-muted-foreground"

    const availableTone = stock.available <= 0
      ? "font-bold text-danger"
      : stock.status === "low"
        ? "font-semibold text-warning"
        : "font-semibold text-success"

    const purchaseChip = stock.open_purchase
      ? `<div class="mt-0.5 text-[10px] font-semibold text-primary">${translate("Purchase")} ${this.escape(stock.open_purchase.code)} ${translate("drafted")}</div>`
      : ""

    const action = stock.open_purchase
      ? `<a href="${this.escape(stock.open_purchase.path)}" class="inline-flex items-center gap-1 rounded-md bg-primary/10 px-2.5 py-1 text-[11px] font-semibold text-primary transition-colors hover:bg-primary/20">${translate("Open purchase")} ${this.escape(stock.open_purchase.code)}</a>`
      : stock.status === "low" || stock.status === "out"
        ? `<button type="button" data-action="click->${this.identifier}#openReorder" data-stock-id="${this.escape(stock.id)}" class="inline-flex items-center gap-1 rounded-md bg-primary/10 px-2.5 py-1 text-[11px] font-semibold text-primary transition-colors hover:bg-primary/20">${translate("Reorder")}</button>`
        : ""

    return `
      <tr class="border-b border-line align-top transition-colors last:border-0 hover:bg-muted/60 ${stock.status === "out" ? "bg-danger/5" : ""}" data-stock-row data-stock-code="${this.escape(stock.code)}">
        <td class="px-3 py-3">
          <div class="font-semibold text-foreground">${this.escape(stock.name)}</div>
          <div class="text-[10px] text-muted-foreground">${this.escape(stock.code)}</div>
          ${purchaseChip}
        </td>
        <td class="px-3 py-3">
          <span class="inline-flex items-center gap-1 rounded bg-muted px-2 py-0.5 text-[11px] font-medium text-foreground">
            <span class="material-symbols-outlined text-[14px] text-muted-foreground">grid_view</span>
            ${stock.location ? this.escape(stock.location) : translate("No location")}
          </span>
        </td>
        <td class="px-3 py-3 text-right font-semibold text-foreground">${this.number(stock.on_hand)}</td>
        <td class="px-3 py-3 text-right text-muted-foreground">${this.number(stock.reserved)}</td>
        <td class="px-3 py-3 text-right ${availableTone}">${this.number(stock.available)}</td>
        <td class="px-3 py-3 text-right text-muted-foreground">${this.number(stock.reorder_point)}</td>
        <td class="px-3 py-3">
          <span class="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-semibold ${statusTone}">
            <span class="h-1.5 w-1.5 rounded-full bg-current"></span>
            ${this.escape(translate(stock.status_label))}
          </span>
        </td>
        <td class="px-3 py-3 text-right">
          <div class="flex flex-wrap items-center justify-end gap-1">
            ${action}
            <button type="button" data-action="click->${this.identifier}#openAdjust" data-stock-id="${this.escape(stock.id)}" class="inline-flex items-center gap-1 rounded-md bg-muted px-2.5 py-1 text-[11px] font-semibold text-foreground transition-colors hover:bg-line">
              ${translate("Adjust")}
            </button>
          </div>
        </td>
      </tr>
    `
  }

  renderLedgerFooter() {
    const pagination = this.pagination
    const from = pagination.from || 0
    const to = pagination.to || 0
    const count = pagination.count || 0
    const previousDisabled = !pagination.previous
    const nextDisabled = !pagination.next

    return `
      <span>${translate("Showing")} ${this.number(from)}–${this.number(to)} ${translate("of")} ${this.number(count)}</span>
      <div class="flex items-center gap-1">
        <button type="button" data-action="click->${this.identifier}#previousPage" ${previousDisabled ? "disabled" : ""}
          class="rounded bg-muted px-2.5 py-1 text-[11px] font-semibold text-foreground transition-colors hover:bg-line disabled:cursor-not-allowed disabled:opacity-50">
          ${translate("Previous")}
        </button>
        <button type="button" data-action="click->${this.identifier}#nextPage" ${nextDisabled ? "disabled" : ""}
          class="rounded bg-muted px-2.5 py-1 text-[11px] font-semibold text-foreground transition-colors hover:bg-line disabled:cursor-not-allowed disabled:opacity-50">
          ${translate("Next")}
        </button>
      </div>
    `
  }

  renderInboundPanel() {
    const openImports = this.inbound.open_imports || []
    const incoming = this.inbound.incoming_transfers || []
    const recent = this.inbound.recent || []

    return `
      <section class="flex flex-col gap-2 rounded-xl border border-line bg-card p-3 shadow-sm">
        <div class="flex items-center justify-between gap-2 border-b border-line pb-2">
          <div class="flex items-center gap-2">
            <span class="material-symbols-outlined text-[20px] text-success">call_received</span>
            <h2 class="font-display text-[15px] font-bold text-foreground">${translate("Inbound")}</h2>
          </div>
          <span class="rounded-full bg-muted px-2 py-0.5 text-[10px] font-semibold text-muted-foreground">${openImports.length + incoming.length}</span>
        </div>
        ${openImports.length + incoming.length === 0
          ? `<div class="rounded-lg border border-line bg-muted p-3 text-center text-[11px] text-muted-foreground">${translate("Nothing waiting to receive.")}</div>`
          : openImports.map((card) => this.renderImportCard(card)).join("") + incoming.map((card) => this.renderTransferCard(card)).join("")}
        ${this.renderRecentCards(recent, translate("Received"))}
      </section>
    `
  }

  renderImportCard(card) {
    return `
      <div class="flex flex-col gap-1 rounded-lg border border-line bg-muted p-2.5">
        <div class="flex items-center justify-between gap-2">
          <span class="text-[12px] font-bold text-foreground">${this.escape(card.code)}</span>
          ${this.statusChip(card.status_label)}
        </div>
        <div class="text-[11px] text-muted-foreground">${card.party ? this.escape(card.party) : translate("No supplier")} · ${this.escape(this.date(card.date))}</div>
        <div class="flex items-center justify-between gap-2">
          <span class="text-[10px] text-foreground">${this.number(card.units)} ${translate("units")}</span>
          <button type="button" data-action="click->${this.identifier}#openReceipt" data-receipt-id="${this.escape(card.id)}"
            class="rounded bg-card px-2 py-1 text-[10px] font-semibold text-primary transition-colors hover:bg-line">
            ${translate("Open")}
          </button>
        </div>
      </div>
    `
  }

  renderTransferCard(card) {
    const incoming = card.direction === "in" && card.open
    return `
      <div class="flex flex-col gap-1 rounded-lg border border-line bg-muted p-2.5">
        <div class="flex items-center justify-between gap-2">
          <span class="text-[12px] font-bold text-foreground">${this.escape(card.code)}</span>
          ${this.statusChip(card.status_label)}
        </div>
        <div class="text-[11px] text-muted-foreground">${card.party ? this.escape(card.party) : "—"} · ${this.escape(this.date(card.date))}</div>
        <div class="flex items-center justify-between gap-2">
          <span class="text-[10px] text-foreground">${this.number(card.units)} ${translate("units")}</span>
          ${incoming
            ? `<button type="button" data-action="click->${this.identifier}#receiveTransfer" data-transfer-id="${this.escape(card.id)}"
                class="rounded bg-primary px-2 py-1 text-[10px] font-semibold text-primary-foreground transition-all hover:brightness-110">
                ${translate("Mark received")}
              </button>`
            : ""}
        </div>
      </div>
    `
  }

  renderOutboundPanel() {
    const open = this.outbound.open || []
    const recent = this.outbound.recent || []

    return `
      <section class="flex flex-col gap-2 rounded-xl border border-line bg-card p-3 shadow-sm">
        <div class="flex items-center justify-between gap-2 border-b border-line pb-2">
          <div class="flex items-center gap-2">
            <span class="material-symbols-outlined text-[20px] text-primary">call_made</span>
            <h2 class="font-display text-[15px] font-bold text-foreground">${translate("Outbound")}</h2>
          </div>
          <span class="rounded-full bg-muted px-2 py-0.5 text-[10px] font-semibold text-muted-foreground">${open.length}</span>
        </div>
        ${open.length === 0
          ? `<div class="rounded-lg border border-line bg-muted p-3 text-center text-[11px] text-muted-foreground">${translate("Nothing waiting to leave.")}</div>`
          : open.map((card) => this.renderOutboundCard(card)).join("")}
        ${this.renderRecentCards(recent, translate("Completed"))}
      </section>
    `
  }

  renderOutboundCard(card) {
    return `
      <div class="flex flex-col gap-1 rounded-lg border border-line bg-muted p-2.5">
        <div class="flex items-center justify-between gap-2">
          <span class="text-[12px] font-bold text-foreground">${this.escape(card.code)}</span>
          <span class="text-[9px] font-bold uppercase tracking-wider text-muted-foreground">${card.kind === "export" ? translate("Export") : translate("Transfer")}</span>
        </div>
        <div class="flex items-center gap-1">
          ${this.statusChip(card.status_label)}
        </div>
        <div class="text-[11px] text-muted-foreground">${card.party ? this.escape(card.party) : "—"} · ${this.escape(this.date(card.date))}</div>
        <div class="text-[10px] text-foreground">${this.number(card.units)} ${translate("units")}</div>
      </div>
    `
  }

  renderRecentCards(cards, label) {
    if (!cards || cards.length === 0) return ""

    return `
      <div class="mt-1 border-t border-line pt-2">
        <div class="mb-1 text-[9px] font-bold uppercase tracking-wider text-muted-foreground">${label}</div>
        <div class="flex flex-col gap-1">
          ${cards.map((card) => `
            <div class="flex items-center justify-between gap-2 rounded-lg border border-line bg-muted px-2 py-1.5">
              <div class="min-w-0">
                <div class="flex items-center gap-1">
                  <span class="truncate text-[11px] font-semibold text-foreground">${this.escape(card.code)}</span>
                  ${card.kind === "export" ? `<span class="text-[9px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Export")}</span>` : card.kind === "transfer" ? `<span class="text-[9px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Transfer")}</span>` : ""}
                </div>
                <div class="truncate text-[10px] text-muted-foreground">${card.party ? this.escape(card.party) : "—"} · ${this.escape(this.date(card.date))}</div>
              </div>
              ${this.statusChip(card.status_label)}
            </div>
          `).join("")}
        </div>
      </div>
    `
  }

  renderCountPanel() {
    const open = this.openCount
    const last = this.lastCount

    if (open) {
      return `
        <section class="flex flex-col gap-2 rounded-xl border border-line bg-card p-3 shadow-sm">
          <div class="flex items-center justify-between gap-2">
            <div class="flex items-center gap-2">
              <span class="material-symbols-outlined text-[20px] text-warning">fact_check</span>
              <h2 class="font-display text-[15px] font-bold text-foreground">${translate("Last count")}</h2>
            </div>
            ${this.statusChip("In progress")}
          </div>
          <p class="text-[12px] font-semibold text-foreground">${translate("Count in progress")} · ${this.number(open.rows_counted)} ${translate("of")} ${this.number(open.rows_total)} ${translate("entered")}</p>
          <p class="text-[11px] text-muted-foreground">${this.escape(open.employee_name || translate("Not recorded"))} · ${this.escape(this.date(open.started_at))}</p>
          <button type="button" data-action="click->${this.identifier}#continueCount" class="inline-flex items-center justify-center gap-1.5 rounded-lg bg-primary px-3 py-2 text-[11px] font-semibold text-primary-foreground transition-all hover:brightness-110">
            <span class="material-symbols-outlined text-[16px]">play_arrow</span>
            ${translate("Continue count")}
          </button>
        </section>
      `
    }

    if (last) {
      return `
        <section class="flex flex-col gap-2 rounded-xl border border-line bg-card p-3 shadow-sm">
          <div class="flex items-center justify-between gap-2">
            <div class="flex items-center gap-2">
              <span class="material-symbols-outlined text-[20px] text-success">task_alt</span>
              <h2 class="font-display text-[15px] font-bold text-foreground">${translate("Last count")}</h2>
            </div>
            ${this.statusChip("Completed")}
          </div>
          <p class="text-[12px] text-foreground">${this.escape(this.date(last.completed_at))} · ${this.escape(last.employee_name || translate("Not recorded"))}</p>
          <div class="flex flex-wrap items-center gap-2 text-[11px] text-muted-foreground">
            <span>${this.number(last.rows_counted)} ${translate("rows counted")}</span>
            <span>·</span>
            <span>${translate("Net variance")} <strong class="${last.net_variance < 0 ? "text-danger" : last.net_variance > 0 ? "text-success" : "text-foreground"}">${this.signed(last.net_variance)}</strong></span>
          </div>
          ${last.failed_count > 0 ? `<p class="text-[10px] text-warning">${this.number(last.failed_count)} ${translate("lines skipped — see the count result.")}</p>` : ""}
          ${this.startCountButton()}
        </section>
      `
    }

    return `
      <section class="flex flex-col gap-2 rounded-xl border border-line bg-card p-3 shadow-sm">
        <div class="flex items-center gap-2">
          <span class="material-symbols-outlined text-[20px] text-muted-foreground">fact_check</span>
          <h2 class="font-display text-[15px] font-bold text-foreground">${translate("Last count")}</h2>
        </div>
        <p class="text-[12px] text-muted-foreground">${translate("No count recorded")} · ${this.number(this.metrics.stock_rows)} ${translate("rows in this warehouse.")}</p>
        ${this.startCountButton()}
      </section>
    `
  }

  startCountButton() {
    const noRows = (this.metrics.stock_rows || 0) === 0
    return `
      <button type="button" data-action="click->${this.identifier}#startCount" ${noRows ? "disabled" : ""}
        class="inline-flex items-center justify-center gap-1.5 rounded-lg bg-primary px-3 py-2 text-[11px] font-semibold text-primary-foreground transition-all hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-50">
        <span class="material-symbols-outlined text-[16px]">play_arrow</span>
        ${translate("Start count")}
      </button>
      ${noRows ? `<p class="text-[10px] text-muted-foreground">${translate("Add stock rows before starting a count.")}</p>` : ""}
    `
  }

  statusChip(label) {
    const key = String(label || "").toLowerCase()
    const tone = ["received", "completed", "in stock", "shipped"].includes(key)
      ? "bg-success/10 text-success"
      : ["in transit", "receiving", "processing", "in progress"].includes(key)
        ? "bg-warning/10 text-warning"
        : ["out", "cancelled", "failed"].includes(key)
          ? "bg-danger/10 text-danger"
          : "bg-muted text-muted-foreground"

    return `<span class="whitespace-nowrap rounded-full px-2 py-0.5 text-[9px] font-bold ${tone}">${this.escape(translate(label))}</span>`
  }

  // --- Drawers ----------------------------------------------------------------------

  renderDrawer() {
    const root = document.getElementById("inventory-drawer-root")
    if (!root) return

    if (!this.drawer) {
      root.innerHTML = ""
      return
    }

    root.innerHTML = `
      <div class="fixed inset-0 z-50 flex justify-end bg-foreground/40" data-action="click->${this.identifier}#closeDrawerOnBackdrop">
        <div class="flex h-full w-full flex-col overflow-y-auto border-l border-line bg-card shadow-xl sm:max-w-md" role="dialog" aria-modal="true" data-operation-block="drawer">
          ${this.renderDrawerBody()}
        </div>
      </div>
    `

    const importWithoutLines = this.drawer.type === "receive" && this.drawer.mode === "import" && this.drawer.import?.has_lines === false
    const newReceipt = this.drawer.type === "receive" && this.drawer.mode === "new"
    const otherDrawer = [ "transfer", "adjust", "reorder" ].includes(this.drawer.type)

    if (!this.drawer.stock && !this.drawerSearchLoaded && (importWithoutLines || newReceipt || otherDrawer)) {
      this.loadDrawerItems("")
    }
  }

  renderDrawerBody() {
    if (this.drawer.type === "receive") return this.renderReceiveDrawer()
    if (this.drawer.type === "transfer") return this.renderTransferDrawer()
    if (this.drawer.type === "adjust") return this.renderAdjustDrawer()
    return this.renderReorderDrawer()
  }

  drawerHeader(title, subtitle) {
    return `
      <div class="flex items-start justify-between gap-3 border-b border-line p-4">
        <div>
          <h2 class="font-display text-lg font-bold text-foreground">${title}</h2>
          <p class="mt-0.5 text-[11px] text-muted-foreground">${subtitle}</p>
        </div>
        <button type="button" data-action="click->${this.identifier}#closeDrawer" class="flex h-8 w-8 items-center justify-center rounded-lg text-muted-foreground hover:bg-muted" title="${translate("Close")}">
          <span class="material-symbols-outlined text-[20px]">close</span>
        </button>
      </div>
    `
  }

  drawerError() {
    return `<div id="inventory-drawer-error" class="hidden rounded-lg border border-danger/30 bg-danger/10 p-2.5 text-[11px] font-semibold text-danger"></div>`
  }

  drawerFooter(primaryLabel) {
    return `
      <div class="mt-auto flex items-center justify-end gap-2 border-t border-line p-4">
        <button type="button" data-action="click->${this.identifier}#closeDrawer" class="rounded-lg bg-muted px-3 py-2 text-[12px] font-semibold text-foreground transition-colors hover:bg-line">
          ${translate("Cancel")}
        </button>
        <button type="submit" class="rounded-lg bg-primary px-3 py-2 text-[12px] font-semibold text-primary-foreground transition-all hover:brightness-110 disabled:opacity-60">
          ${primaryLabel}
        </button>
      </div>
    `
  }

  renderReceiveDrawer() {
    const isImport = this.drawer.mode === "import"
    const card = this.drawer.import
    const fields = isImport
      ? this.renderImportResumeFields(card)
      : this.renderReceiveFields()

    return `
      ${this.drawerHeader(
        isImport ? `${translate("Receive")} ${this.escape(card.code)}` : `${translate("Receive into")} ${this.escape(this.locationName)}`,
        isImport ? `${card.party ? this.escape(card.party) : translate("No supplier")} · ${this.number(card.units)} ${translate("units")}` : translate("Post a receipt to increase on hand.")
      )}
      ${Helpers.form({
        action: this.receiptAction(isImport, card),
        method: "POST",
        attributes: `data-action="submit->${this.identifier}#submitReceipt" class="flex min-h-full flex-col"`,
        html: `
          <div class="flex flex-col gap-3 p-4">
            ${this.drawerError()}
            ${fields}
          </div>
          ${this.drawerFooter(translate("Post receipt"))}
        `
      })}
    `
  }

  renderImportResumeFields(card) {
    if (card.has_lines) {
      return `
        <div class="rounded-lg border border-line bg-muted p-3 text-[12px] text-foreground">
          ${translate("This receipt already has its line items.")} ${translate("Post it to receive")} ${this.number(card.units)} ${translate("units.")}
        </div>
      `
    }

    return `
      <p class="text-[11px] text-muted-foreground">${translate("This receipt has no line items yet. Choose the item and quantity to receive.")}</p>
      ${this.renderItemPicker("receive", false)}
      ${this.inputField("receipt_quantity", "Quantity", "number", "1", { min: "1", step: "1" })}
      ${this.inputField("receipt_location", "Location (optional)", "text", "")}
    `
  }

  renderReceiveFields() {
    return `
      ${this.renderItemPicker("receive", false)}
      ${this.inputField("receipt_quantity", "Quantity", "number", "1", { min: "1", step: "1" })}
      <div class="flex flex-col gap-1">
        <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground" for="inventory-receipt-supplier">${translate("Supplier (optional)")}</label>
        <select id="inventory-receipt-supplier" class="h-9 rounded-lg border border-line bg-card px-2 text-[12px] text-foreground">
          <option value="">${translate("No supplier")}</option>
          ${(this.reference.suppliers || []).map((supplier) => `<option value="${this.escape(supplier.id)}">${this.escape(supplier.name)}</option>`).join("")}
        </select>
      </div>
      ${this.inputField("receipt_location", "Location (optional)", "text", "")}
      ${this.textAreaField("receipt_note", "Note (optional)")}
    `
  }

  renderTransferDrawer() {
    const noDestinations = (this.reference.warehouses || []).length === 0
    const mode = noDestinations ? "export" : this.drawer.mode
    if (noDestinations && this.drawer.mode !== "export") this.drawer.mode = "export"

    const fields = mode === "export" ? this.renderExportFields() : this.renderTransferFields()

    return `
      ${this.drawerHeader(
        translate("Transfer out"),
        translate("Move stock to another warehouse, or export it out of the company.")
      )}
      <div class="flex flex-col gap-3 p-4">
        ${this.drawerError()}
        <div class="grid grid-cols-1 gap-2 sm:grid-cols-2">
          <button type="button" data-action="click->${this.identifier}#setTransferMode" data-mode="transfer" ${noDestinations ? "disabled" : ""}
            class="rounded-lg border p-2.5 text-left text-[11px] ${mode === "transfer" ? "border-primary bg-primary/10 text-primary" : "border-line bg-muted text-foreground"} disabled:cursor-not-allowed disabled:opacity-50">
            <span class="block font-bold">${translate("Another warehouse")}</span>
            <span class="block text-[10px] opacity-80">${noDestinations ? translate("Add another warehouse to transfer stock.") : translate("In transit until the destination receives it.")}</span>
          </button>
          <button type="button" data-action="click->${this.identifier}#setTransferMode" data-mode="export"
            class="rounded-lg border p-2.5 text-left text-[11px] ${mode === "export" ? "border-primary bg-primary/10 text-primary" : "border-line bg-muted text-foreground"}">
            <span class="block font-bold">${translate("Leaving the company")}</span>
            <span class="block text-[10px] opacity-80">${translate("Source on hand drops. Nothing arrives elsewhere.")}</span>
          </button>
        </div>
        ${Helpers.form({
          action: mode === "export" ? this.exportAction() : this.transferAction(),
          method: "POST",
          attributes: `data-action="submit->${this.identifier}#${mode === "export" ? "submitExport" : "submitTransfer"}" class="flex flex-col gap-3"`,
          html: fields
        })}
        <div class="flex items-center justify-end gap-2 border-t border-line pt-3">
          <button type="button" data-action="click->${this.identifier}#closeDrawer" class="rounded-lg bg-muted px-3 py-2 text-[12px] font-semibold text-foreground hover:bg-line">${translate("Cancel")}</button>
          <button type="button" data-action="click->${this.identifier}#${mode === "export" ? "submitExport" : "submitTransfer"}" class="rounded-lg bg-primary px-3 py-2 text-[12px] font-semibold text-primary-foreground hover:brightness-110">
            ${mode === "export" ? translate("Export") : translate("Transfer")}
          </button>
        </div>
      </div>
    `
  }

  renderTransferFields() {
    const selected = this.drawer.stock
    return `
      ${this.renderItemPicker("transfer", false)}
      ${selected ? `<p class="text-[11px] text-muted-foreground">${translate("Available now")}: <strong class="text-foreground">${this.number(selected.available)}</strong></p>` : ""}
      ${this.inputField("transfer_quantity", "Quantity", "number", "1", { min: "1", step: "1" })}
      <div class="flex flex-col gap-1">
        <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground" for="inventory-transfer-destination">${translate("Destination warehouse")}</label>
        <select id="inventory-transfer-destination" required class="h-9 rounded-lg border border-line bg-card px-2 text-[12px] text-foreground">
          <option value="">${translate("Choose a warehouse")}</option>
          ${(this.reference.warehouses || []).map((warehouse) => `<option value="${this.escape(warehouse.id)}">${this.escape(warehouse.name)}${warehouse.code ? ` (${this.escape(warehouse.code)})` : ""}</option>`).join("")}
        </select>
      </div>
      ${this.textAreaField("transfer_note", "Note (optional)")}
    `
  }

  renderExportFields() {
    return `
      ${this.renderItemPicker("transfer", false)}
      ${this.inputField("export_quantity", "Quantity", "number", "1", { min: "1", step: "1" })}
      ${this.inputField("export_reference", "Reference (required)", "text", "")}
      ${this.textAreaField("export_note", "Note (optional)")}
    `
  }

  renderAdjustDrawer() {
    const stock = this.drawer.stock
    return `
      ${this.drawerHeader(translate("Adjust stock"), `${this.escape(stock.name)} · ${this.escape(stock.code)}`)}
      ${Helpers.form({
        action: this.adjustmentAction(),
        method: "POST",
        attributes: `data-action="submit->${this.identifier}#submitAdjustment" class="flex min-h-full flex-col"`,
        html: `
          <div class="flex flex-col gap-3 p-4">
            ${this.drawerError()}
            <div class="rounded-lg border border-line bg-muted p-3 text-[12px]">
              <div class="flex items-center justify-between"><span class="text-muted-foreground">${translate("Current on hand")}</span><strong class="text-foreground">${this.number(stock.on_hand)}</strong></div>
              <div class="mt-1 flex items-center justify-between"><span class="text-muted-foreground">${translate("Reserved")}</span><strong class="text-foreground">${this.number(stock.reserved)}</strong></div>
            </div>
            ${this.inputField("adjust_new_on_hand", "New on hand", "number", String(stock.on_hand), { min: "0", step: "1" })}
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground" for="inventory-adjust-reason">${translate("Reason")}</label>
              <select id="inventory-adjust-reason" required class="h-9 rounded-lg border border-line bg-card px-2 text-[12px] text-foreground">
                <option value="">${translate("Choose a reason")}</option>
                ${(this.inventory.adjustment_reasons || [ "Count correction", "Damage", "Found", "Other" ]).map((reason) => `<option value="${this.escape(reason)}">${this.escape(translate(reason))}</option>`).join("")}
              </select>
            </div>
            ${this.textAreaField("adjust_note", "Note (required for Other)")}
          </div>
          ${this.drawerFooter(translate("Post adjustment"))}
        `
      })}
    `
  }

  renderReorderDrawer() {
    const stock = this.drawer.stock
    const shortfall = Math.max((stock.reorder_point || 0) - (stock.available || 0), 0)
    const supplier = stock.default_supplier

    return `
      ${this.drawerHeader(translate("Reorder"), `${this.escape(stock.name)} · ${this.escape(stock.code)}`)}
      ${Helpers.form({
        action: this.reorderAction(),
        method: "POST",
        attributes: `data-action="submit->${this.identifier}#submitReorder" class="flex min-h-full flex-col"`,
        html: `
          <div class="flex flex-col gap-3 p-4">
            ${this.drawerError()}
            <div class="rounded-lg border border-line bg-muted p-3 text-[12px]">
              <div class="flex items-center justify-between"><span class="text-muted-foreground">${translate("Available")}</span><strong class="text-foreground">${this.number(stock.available)}</strong></div>
              <div class="mt-1 flex items-center justify-between"><span class="text-muted-foreground">${translate("Reorder at")}</span><strong class="text-foreground">${this.number(stock.reorder_point)}</strong></div>
              <div class="mt-1 flex items-center justify-between"><span class="text-muted-foreground">${translate("Short by")}</span><strong class="text-warning">${this.number(shortfall)}</strong></div>
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Supplier")}</label>
              ${supplier
                ? `<div class="flex h-9 items-center justify-between rounded-lg border border-line bg-muted px-2 text-[12px] text-foreground"><span>${this.escape(supplier.name)}</span><span class="text-[10px] text-muted-foreground">${translate("Product default")}</span></div>`
                : `<select id="inventory-reorder-supplier" required class="h-9 rounded-lg border border-line bg-card px-2 text-[12px] text-foreground">
                    <option value="">${translate("Choose a supplier")}</option>
                    ${(this.reference.suppliers || []).map((record) => `<option value="${this.escape(record.id)}">${this.escape(record.name)}</option>`).join("")}
                  </select>`}
            </div>
            ${this.inputField("reorder_quantity", "Quantity", "number", String(shortfall || 1), { min: "1", step: "1" })}
          </div>
          ${this.drawerFooter(translate("Create purchase"))}
        `
      })}
    `
  }

  renderItemPicker(purpose, required = true) {
    const selected = this.drawer.stock
    if (selected) {
      return `
        <div class="rounded-lg border border-line bg-muted p-3">
          <div class="flex items-start justify-between gap-2">
            <div>
              <div class="text-[12px] font-bold text-foreground">${this.escape(selected.name)}</div>
              <div class="text-[10px] text-muted-foreground">${this.escape(selected.code)} · ${selected.location ? this.escape(selected.location) : translate("No location")}</div>
              <div class="mt-1 text-[10px] text-foreground">${translate("On hand")} ${this.number(selected.on_hand)} · ${translate("Available")} ${this.number(selected.available)}</div>
            </div>
            <button type="button" data-action="click->${this.identifier}#clearDrawerStock" class="rounded bg-card px-2 py-1 text-[10px] font-semibold text-primary hover:bg-line">${translate("Change")}</button>
          </div>
        </div>
      `
    }

    return `
      <div class="flex flex-col gap-1">
        <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground" for="inventory-item-search">${translate("Item")}</label>
        <input id="inventory-item-search" type="search" ${required ? "required" : ""} autocomplete="off"
          data-action="input->${this.identifier}#updateDrawerSearch"
          placeholder="${translate("Search by item name, code, or location...")}"
          class="h-9 w-full rounded-lg border border-line bg-card px-2 text-[12px] text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary" />
        <div id="inventory-item-results" class="max-h-48 overflow-y-auto rounded-lg border border-line bg-muted p-1">
          ${this.renderItemResults(purpose)}
        </div>
      </div>
    `
  }

  renderItemResults(purpose) {
    if (this.drawerSearchResults.length === 0) {
      return `<div class="p-2 text-center text-[11px] text-muted-foreground">${translate("No items match this view.")}</div>`
    }

    return this.drawerSearchResults.map((stock) => {
      const disabled = purpose === "receive" && !stock.receivable
      return `
        <button type="button" data-action="click->${this.identifier}#selectDrawerStock" data-stock-id="${this.escape(stock.id)}" ${disabled ? "disabled" : ""}
          class="flex w-full items-center justify-between gap-2 rounded px-2 py-1.5 text-left text-[11px] transition-colors hover:bg-card disabled:cursor-not-allowed disabled:opacity-50">
          <span class="min-w-0">
            <span class="block truncate font-semibold text-foreground">${this.escape(stock.name)}</span>
            <span class="block truncate text-[10px] text-muted-foreground">${this.escape(stock.code)}${stock.location ? ` · ${this.escape(stock.location)}` : ""}</span>
          </span>
          <span class="shrink-0 text-[10px] text-muted-foreground">${disabled ? translate("Service item") : `${translate("On hand")} ${this.number(stock.on_hand)}`}</span>
        </button>
      `
    }).join("")
  }

  inputField(id, label, type = "text", value = "", options = {}) {
    const attrs = Object.entries(options).map(([key, val]) => `${key}="${this.escape(val)}"`).join(" ")
    const fieldId = `inventory-${id.replace(/_/g, "-")}`
    return `
      <div class="flex flex-col gap-1">
        <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground" for="${fieldId}">${translate(label)}</label>
        <input id="${fieldId}" name="${id}" type="${type}" value="${this.escape(value)}" ${attrs}
          data-action="input->${this.identifier}#clearFieldError"
          class="h-9 rounded-lg border border-line bg-card px-2 text-[12px] text-foreground focus:outline-none focus:ring-2 focus:ring-primary" />
        <p id="${fieldId}-error" class="hidden text-[10px] font-semibold text-danger"></p>
      </div>
    `
  }

  textAreaField(id, label) {
    return `
      <div class="flex flex-col gap-1">
        <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground" for="inventory-${id.replace(/_/g, "-")}">${translate(label)}</label>
        <textarea id="inventory-${id.replace(/_/g, "-")}" name="${id}" rows="2"
          class="rounded-lg border border-line bg-card px-2 py-1.5 text-[12px] text-foreground focus:outline-none focus:ring-2 focus:ring-primary"></textarea>
      </div>
    `
  }

  // --- Count sheet ------------------------------------------------------------------

  renderCountSheet() {
    const root = document.getElementById("inventory-count-root")
    if (!root) return

    if (!this.count) {
      root.innerHTML = ""
      return
    }

    root.innerHTML = `
      <div class="fixed inset-0 z-50 overflow-y-auto bg-background" data-operation-block="count-sheet">
        <div class="mx-auto flex min-h-full w-full max-w-6xl flex-col px-4 py-4">
          <div class="flex items-center justify-between gap-3 border-b border-line pb-3">
            <div>
              <h2 class="font-display text-lg font-bold text-foreground">${translate("Cycle count")} · ${this.escape(this.locationName)}</h2>
              <p class="text-[11px] text-muted-foreground">${this.number(this.count.rows_counted)} ${translate("of")} ${this.number(this.count.rows_total)} ${translate("entered")} · ${translate("Saved progress survives refresh.")}</p>
            </div>
            <button type="button" data-action="click->${this.identifier}#closeCountSheet" class="flex h-9 w-9 items-center justify-center rounded-lg bg-muted text-muted-foreground hover:bg-line" title="${translate("Close")}">
              <span class="material-symbols-outlined text-[20px]">close</span>
            </button>
          </div>

          <div id="inventory-count-error" class="mt-3 hidden rounded-lg border border-danger/30 bg-danger/10 p-2.5 text-[11px] font-semibold text-danger"></div>

          <div class="mt-3 flex flex-wrap items-center gap-3 rounded-lg border border-line bg-card p-2.5">
            <label class="inline-flex items-center gap-1.5 text-[11px] font-semibold text-foreground">
              <input id="inventory-count-low-filter" type="checkbox" data-action="change->${this.identifier}#filterCountLines" class="h-4 w-4 rounded border-line" />
              ${translate("Low only")}
            </label>
            <label class="inline-flex items-center gap-1.5 text-[11px] font-semibold text-foreground">
              ${translate("Location")}
              <select id="inventory-count-location-filter" data-action="change->${this.identifier}#filterCountLines" class="h-8 rounded-lg border border-line bg-card px-2 text-[11px] text-foreground">
                <option value="">${translate("All locations")}</option>
                ${this.countLocations().map((location) => `<option value="${this.escape(location)}">${this.escape(location)}</option>`).join("")}
              </select>
            </label>
            <span class="ml-auto text-[11px] text-muted-foreground">${translate("Net variance")}: <strong id="inventory-count-net" class="text-foreground">${this.signed(this.count.net_variance)}</strong></span>
          </div>

          <div class="mt-3 overflow-x-auto rounded-xl border border-line bg-card">
            <table class="w-full text-left text-[12px]">
              <thead class="bg-muted text-[10px] uppercase tracking-wider text-muted-foreground">
                <tr>
                  <th class="px-3 py-2 font-semibold">${translate("Item")}</th>
                  <th class="px-3 py-2 font-semibold">${translate("Location")}</th>
                  <th class="px-3 py-2 text-right font-semibold">${translate("Expected on hand")}</th>
                  <th class="px-3 py-2 text-right font-semibold">${translate("Counted")}</th>
                  <th class="px-3 py-2 text-right font-semibold">${translate("Variance")}</th>
                </tr>
              </thead>
              <tbody>
                ${(this.count.lines || []).map((line) => this.renderCountLine(line)).join("")}
              </tbody>
            </table>
          </div>

          <div class="sticky bottom-0 mt-3 flex flex-wrap items-center justify-end gap-2 border-t border-line bg-background py-3">
            <button type="button" data-action="click->${this.identifier}#closeCountSheet" class="rounded-lg bg-muted px-3 py-2 text-[12px] font-semibold text-foreground hover:bg-line">${translate("Close")}</button>
            <button type="button" data-action="click->${this.identifier}#saveCount" class="rounded-lg bg-muted px-3 py-2 text-[12px] font-semibold text-foreground hover:bg-line">${translate("Save progress")}</button>
            <button type="button" data-action="click->${this.identifier}#submitCount" class="rounded-lg bg-primary px-3 py-2 text-[12px] font-semibold text-primary-foreground hover:brightness-110">${translate("Submit count")}</button>
          </div>
        </div>
      </div>
    `
  }

  renderCountLine(line) {
    const location = line.location || translate("No location")
    return `
      <tr class="border-b border-line last:border-0" data-count-row data-count-low="${line.low ? "true" : "false"}" data-count-location="${this.escape(line.location || "")}">
        <td class="px-3 py-2">
          <div class="font-semibold text-foreground">${this.escape(line.name)}</div>
          <div class="text-[10px] text-muted-foreground">${this.escape(line.code)}</div>
        </td>
        <td class="px-3 py-2 text-muted-foreground">${this.escape(location)}</td>
        <td class="px-3 py-2 text-right text-foreground">${this.number(line.expected_quantity)}</td>
        <td class="px-3 py-2 text-right">
          <input type="number" min="0" step="1" value="${line.counted_quantity ?? ""}" data-count-line-id="${this.escape(line.id)}" data-count-expected="${line.expected_quantity}"
            data-action="input->${this.identifier}#updateCountVariance"
            class="h-8 w-20 rounded-lg border border-line bg-card px-2 text-right text-[12px] text-foreground focus:outline-none focus:ring-2 focus:ring-primary" />
        </td>
        <td class="px-3 py-2 text-right font-semibold ${line.variance_quantity < 0 ? "text-danger" : line.variance_quantity > 0 ? "text-success" : "text-muted-foreground"}" data-count-variance>
          ${this.signed(line.variance_quantity)}
        </td>
      </tr>
    `
  }

  countLocations() {
    return [...new Set((this.count?.lines || []).map((line) => line.location).filter(Boolean))].sort()
  }

  // --- Interactions -----------------------------------------------------------------

  async refreshConsole(event) {
    if (event) event.preventDefault()
    try {
      await this.refreshAll()
      toast({ type: "success", message: translate("Inventory refreshed.") })
    } catch (error) {
      this.toastError(error, translate("Failed to refresh the inventory console."))
    }
  }

  updateSearch(event) {
    this.query = event.target.value || ""
    this.page = 1
    if (this.searchTimer) window.clearTimeout(this.searchTimer)
    this.searchTimer = window.setTimeout(() => this.loadLedgerAndRender(), 250)
  }

  async setFilter(event) {
    this.filter = event.params.filter || event.currentTarget.dataset.filter || "all"
    this.page = 1
    await this.loadLedgerAndRender()
  }

  async nextPage() {
    if (!this.pagination.next) return
    this.page = this.pagination.next
    await this.loadLedgerAndRender()
  }

  async previousPage() {
    if (!this.pagination.previous) return
    this.page = this.pagination.previous
    await this.loadLedgerAndRender()
  }

  async loadLedgerAndRender() {
    try {
      await this.loadLedger()
      this.renderLedgerParts()
    } catch (error) {
      this.toastError(error, translate("Failed to refresh the stock ledger."))
    }
  }

  renderLedgerParts() {
    const tabs = document.getElementById("inventory-stock-tabs")
    const rows = document.getElementById("inventory-stock-rows")
    const footer = document.getElementById("inventory-ledger-footer")
    const capped = document.getElementById("inventory-search-capped")

    if (tabs) tabs.innerHTML = this.renderStockTabs()
    if (rows) rows.innerHTML = this.renderStockRows()
    if (footer) footer.innerHTML = this.renderLedgerFooter()
    if (capped) capped.innerHTML = this.searchCappedNote()
  }

  exportParams() {
    const params = { warehouse_id: this.warehouseId, filter: this.filter }
    if (this.query.trim()) params.q = this.query.trim()
    return params
  }

  openReceive() {
    this.openDrawer({ type: "receive", mode: "new", stock: null, import: null })
  }

  openTransfer() {
    const noDestinations = (this.reference.warehouses || []).length === 0
    this.openDrawer({ type: "transfer", mode: noDestinations ? "export" : "transfer", stock: null })
  }

  openAdjust(event) {
    const stock = this.stockById(event.params.stockId || event.currentTarget.dataset.stockId)
    if (!stock) return
    this.openDrawer({ type: "adjust", stock })
  }

  openReorder(event) {
    const stock = this.stockById(event.params.stockId || event.currentTarget.dataset.stockId)
    if (!stock) return
    this.openDrawer({ type: "reorder", stock })
  }

  openReceipt(event) {
    const receiptId = event.params.receiptId || event.currentTarget.dataset.receiptId
    const card = (this.inbound.open_imports || []).find((record) => String(record.id) === String(receiptId))
    if (!card) return
    this.openDrawer({ type: "receive", mode: "import", stock: null, import: card })
  }

  openDrawer(drawer) {
    this.drawer = drawer
    this.drawerSearchResults = []
    this.drawerSearchLoaded = false
    this.renderDrawer()
    requestAnimationFrame(() => {
      document.getElementById("inventory-item-search")?.focus()
    })
  }

  closeDrawer(event) {
    if (event) event.preventDefault()
    this.drawer = null
    this.renderDrawer()
  }

  closeDrawerOnBackdrop(event) {
    if (event.target !== event.currentTarget) return
    this.closeDrawer()
  }

  clearDrawerStock(event) {
    if (event) event.preventDefault()
    if (!this.drawer) return
    this.drawer.stock = null
    this.drawerSearchLoaded = false
    this.renderDrawer()
  }

  selectDrawerStock(event) {
    const id = event.params.stockId || event.currentTarget.dataset.stockId
    const stock = this.drawerSearchResults.find((record) => String(record.id) === String(id)) || this.stockById(id)
    if (!stock) return
    this.drawer.stock = stock
    this.renderDrawer()
  }

  updateDrawerSearch(event) {
    const query = event.target.value || ""
    if (this.searchTimer) window.clearTimeout(this.searchTimer)
    this.searchTimer = window.setTimeout(() => this.loadDrawerItems(query), 250)
  }

  async loadDrawerItems(query) {
    try {
      const params = { warehouse_id: this.warehouseId, filter: "all", page: 1, per_page: 20 }
      if (query.trim()) params.q = query.trim()
      const response = await fetchJson(
        Helpers.inventory_ledger_company_operation_path(this.companyId, this.operationId, params)
      )
      this.drawerSearchResults = response.stocks || []
      this.drawerSearchLoaded = true
      const results = document.getElementById("inventory-item-results")
      if (results) results.innerHTML = this.renderItemResults(this.drawer?.type === "receive" ? "receive" : "transfer")
    } catch (error) {
      this.toastError(error, translate("Failed to search items."))
    }
  }

  setTransferMode(event) {
    const mode = event.params.mode || event.currentTarget.dataset.mode
    if (mode === "transfer" && (this.reference.warehouses || []).length === 0) return
    this.drawer.mode = mode
    this.renderDrawer()
  }

  // --- Writes -----------------------------------------------------------------------

  async submitReceipt(event) {
    event.preventDefault()
    if (!this.drawer || this.submitting) return

    if (this.drawer.mode === "import") {
      await this.submitPostImport()
      return
    }

    const stock = this.drawer.stock
    const quantity = this.fieldValue("inventory-receipt-quantity")
    if (!stock) return this.clientError(translate("Choose an item to receive."))
    if (!this.positiveInteger(quantity)) return this.clientError(translate("Quantity must be a whole number greater than 0."), "inventory-receipt-quantity")

    await this.sendWrite(
      Helpers.inventory_receipts_company_operation_path(this.companyId, this.operationId, { warehouse_id: this.warehouseId }),
      { receipt: {
        stock_id: stock.id,
        quantity,
        supplier_id: this.fieldValue("inventory-receipt-supplier"),
        location: this.fieldValue("inventory-receipt-location"),
        note: this.fieldValue("inventory-receipt-note")
      } }
    )
  }

  async submitPostImport() {
    const card = this.drawer?.import
    if (!card) return

    const body = { receipt: { location: this.fieldValue("inventory-receipt-location") } }
    if (!card.has_lines) {
      const stock = this.drawer.stock
      const quantity = this.fieldValue("inventory-receipt-quantity")
      if (!stock) return this.clientError(translate("Choose an item to receive."))
      if (!this.positiveInteger(quantity)) return this.clientError(translate("Quantity must be a whole number greater than 0."), "inventory-receipt-quantity")
      body.receipt.stock_id = stock.id
      body.receipt.quantity = quantity
    }

    await this.sendWrite(
      Helpers.inventory_receipt_post_company_operation_path(this.companyId, this.operationId, card.id, { warehouse_id: this.warehouseId }),
      body
    )
  }

  async submitTransfer(event) {
    if (event) event.preventDefault()
    if (!this.drawer || this.submitting) return

    const stock = this.drawer.stock
    const quantity = this.fieldValue("inventory-transfer-quantity")
    const destination = this.fieldValue("inventory-transfer-destination")
    if (!stock) return this.clientError(translate("Choose an item to transfer."))
    if (!this.positiveInteger(quantity)) return this.clientError(translate("Quantity must be a whole number greater than 0."), "inventory-transfer-quantity")
    if (!destination) return this.clientError(translate("Choose a destination warehouse."), "inventory-transfer-destination")

    await this.sendWrite(
      Helpers.inventory_transfers_company_operation_path(this.companyId, this.operationId, { warehouse_id: this.warehouseId }),
      { transfer: {
        stock_id: stock.id,
        quantity,
        destination_warehouse_id: destination,
        note: this.fieldValue("inventory-transfer-note")
      } }
    )
  }

  async submitExport(event) {
    if (event) event.preventDefault()
    if (!this.drawer || this.submitting) return

    const stock = this.drawer.stock
    const quantity = this.fieldValue("inventory-export-quantity")
    const reference = this.fieldValue("inventory-export-reference")
    if (!stock) return this.clientError(translate("Choose an item to export."))
    if (!this.positiveInteger(quantity)) return this.clientError(translate("Quantity must be a whole number greater than 0."), "inventory-export-quantity")
    if (!reference.trim()) return this.clientError(translate("Enter a reference for this export."), "inventory-export-reference")

    await this.sendWrite(
      Helpers.inventory_exports_company_operation_path(this.companyId, this.operationId, { warehouse_id: this.warehouseId }),
      { stock_export: {
        stock_id: stock.id,
        quantity,
        reference,
        note: this.fieldValue("inventory-export-note")
      } }
    )
  }

  async submitAdjustment(event) {
    if (event) event.preventDefault()
    if (!this.drawer || this.submitting) return

    const stock = this.drawer.stock
    const newOnHand = this.fieldValue("inventory-adjust-new-on-hand")
    const reason = this.fieldValue("inventory-adjust-reason")
    const note = this.fieldValue("inventory-adjust-note")
    if (!stock) return this.clientError(translate("Choose an item to adjust."))
    if (newOnHand === "" || Number.isNaN(Number(newOnHand))) return this.clientError(translate("Enter the new on hand."), "inventory-adjust-new-on-hand")
    if (Number(newOnHand) < 0) return this.clientError(translate("New on hand must be 0 or more."), "inventory-adjust-new-on-hand")
    if (Number(newOnHand) < (stock.reserved || 0)) return this.clientError(`${translate("On hand cannot be less than the")} ${stock.reserved} ${translate("reserved.")}`, "inventory-adjust-new-on-hand")
    if (!reason) return this.clientError(translate("Choose a reason."), "inventory-adjust-reason")
    if (reason === "Other" && !note.trim()) return this.clientError(translate("Add a note for Other."), "inventory-adjust-note")

    await this.sendWrite(
      Helpers.inventory_adjustments_company_operation_path(this.companyId, this.operationId, { warehouse_id: this.warehouseId }),
      { adjustment: { stock_id: stock.id, new_on_hand: newOnHand, reason, note } }
    )
  }

  async submitReorder(event) {
    if (event) event.preventDefault()
    if (!this.drawer || this.submitting) return

    const stock = this.drawer.stock
    const quantity = this.fieldValue("inventory-reorder-quantity")
    const supplier = stock?.default_supplier?.id || this.fieldValue("inventory-reorder-supplier")
    if (!stock) return this.clientError(translate("Choose an item to reorder."))
    if (!this.positiveInteger(quantity)) return this.clientError(translate("Quantity must be a whole number greater than 0."), "inventory-reorder-quantity")
    if (!supplier) return this.clientError(translate("Choose a supplier."), "inventory-reorder-supplier")

    await this.sendWrite(
      Helpers.inventory_reorder_company_operation_path(this.companyId, this.operationId, { warehouse_id: this.warehouseId }),
      { reorder: { stock_id: stock.id, supplier_id: supplier, quantity } }
    )
  }

  async receiveTransfer(event) {
    const transferId = event.params.transferId || event.currentTarget.dataset.transferId
    if (!transferId || this.submitting) return
    this.submitting = true

    try {
      const response = await fetchJson(
        Helpers.inventory_transfer_receive_company_operation_path(this.companyId, this.operationId, transferId, { warehouse_id: this.warehouseId }),
        { method: "POST", body: {} }
      )
      toast({ type: "success", message: response.message })
      await this.refreshAll()
    } catch (error) {
      this.toastError(error, translate("Failed to receive the transfer."))
    } finally {
      this.submitting = false
    }
  }

  async sendWrite(url, body) {
    this.submitting = true
    this.setDrawerError("")
    try {
      const response = await fetchJson(url, { method: "POST", body })
      toast({ type: "success", message: response.message })
      this.drawer = null
      this.renderDrawer()
      await this.refreshAll()
    } catch (error) {
      this.toastError(error, translate("Could not save the change."))
    } finally {
      this.submitting = false
    }
  }

  // --- Count actions ----------------------------------------------------------------

  async openCountSheet() {
    if (this.openCount) {
      await this.continueCount()
    } else {
      await this.startCount()
    }
  }

  async startCount(event) {
    if (event) event.preventDefault()
    if (this.submitting) return
    this.submitting = true

    try {
      const response = await fetchJson(
        Helpers.inventory_counts_company_operation_path(this.companyId, this.operationId, { warehouse_id: this.warehouseId }),
        { method: "POST", body: { count: {} } }
      )
      this.count = response.count
      this.drawer = null
      this.renderContent()
      toast({ type: "success", message: response.message })
    } catch (error) {
      this.toastError(error, translate("Failed to start the count."))
      await this.refreshAll()
    } finally {
      this.submitting = false
    }
  }

  async continueCount(event) {
    if (event) event.preventDefault()
    if (!this.openCount) return

    try {
      const response = await fetchJson(
        Helpers.inventory_count_company_operation_path(this.companyId, this.operationId, this.openCount.id, { warehouse_id: this.warehouseId })
      )
      this.count = response.count
      this.drawer = null
      this.renderContent()
    } catch (error) {
      this.toastError(error, translate("Failed to load the count."))
    }
  }

  async saveCount(event) {
    if (event) event.preventDefault()
    if (!this.count || this.submitting) return

    await this.sendCount(
      Helpers.inventory_count_company_operation_path(this.companyId, this.operationId, this.count.id, { warehouse_id: this.warehouseId }),
      "PATCH"
    )
  }

  async submitCount(event) {
    if (event) event.preventDefault()
    if (!this.count || this.submitting) return
    this.submitting = true

    try {
      const response = await fetchJson(
        Helpers.inventory_count_submit_company_operation_path(this.companyId, this.operationId, this.count.id, { warehouse_id: this.warehouseId }),
        { method: "POST", body: { count: { lines: this.collectCountLines() } } }
      )
      const warnings = response.errors || []
      if (warnings.length > 0) {
        toast({ type: "error", message: `${response.message} ${warnings.join(", ")}` })
      } else {
        toast({ type: "success", message: response.message })
      }
      this.count = null
      this.renderCountSheet()
      await this.refreshAll()
    } catch (error) {
      this.setCountError(this.errorMessage(error, translate("Failed to submit the count.")))
      this.toastError(error, translate("Failed to submit the count."))
    } finally {
      this.submitting = false
    }
  }

  async sendCount(url, method) {
    this.submitting = true
    this.setCountError("")

    try {
      const response = await fetchJson(url, { method, body: { count: { lines: this.collectCountLines() } } })
      this.count = response.count
      this.renderCountSheet()
      toast({ type: "success", message: response.message })
    } catch (error) {
      this.setCountError(this.errorMessage(error, translate("Failed to save the count.")))
      this.toastError(error, translate("Failed to save the count."))
    } finally {
      this.submitting = false
    }
  }

  closeCountSheet(event) {
    if (event) event.preventDefault()
    this.count = null
    this.renderCountSheet()
    this.refreshAll()
  }

  updateCountVariance(event) {
    const input = event.currentTarget
    const expected = Number(input.dataset.countExpected || 0)
    const row = input.closest("[data-count-row]")
    const target = row?.querySelector("[data-count-variance]")
    if (!target) return

    if (input.value === "") {
      target.textContent = "0"
      target.className = "px-3 py-2 text-right font-semibold text-muted-foreground"
      return
    }

    const variance = Number(input.value) - expected
    target.textContent = this.signed(variance)
    target.className = `px-3 py-2 text-right font-semibold ${variance < 0 ? "text-danger" : variance > 0 ? "text-success" : "text-muted-foreground"}`
  }

  filterCountLines() {
    const lowOnly = document.getElementById("inventory-count-low-filter")?.checked
    const location = document.getElementById("inventory-count-location-filter")?.value || ""

    document.querySelectorAll("[data-count-row]").forEach((row) => {
      const lowMatch = !lowOnly || row.dataset.countLow === "true"
      const locationMatch = !location || row.dataset.countLocation === location
      row.classList.toggle("hidden", !(lowMatch && locationMatch))
    })
  }

  collectCountLines() {
    return Array.from(document.querySelectorAll("[data-count-line-id]")).map((input) => ({
      id: input.dataset.countLineId,
      counted_quantity: input.value === "" ? null : input.value
    }))
  }

  // --- Helpers ----------------------------------------------------------------------

  stockById(id) {
    return this.stocks.find((stock) => String(stock.id) === String(id)) ||
      this.drawerSearchResults.find((stock) => String(stock.id) === String(id)) ||
      null
  }

  fieldValue(id) {
    const element = document.getElementById(id)
    return element ? String(element.value ?? "").trim() : ""
  }

  positiveInteger(value) {
    return /^\d+$/.test(String(value)) && Number(value) > 0
  }

  clientError(message, fieldId) {
    if (fieldId) {
      const fieldError = document.getElementById(`${fieldId}-error`)
      if (fieldError) {
        fieldError.textContent = message
        fieldError.classList.remove("hidden")
      }
      document.getElementById(fieldId)?.focus()
    } else {
      this.setDrawerError(message)
    }
    toast({ type: "error", message })
  }

  clearFieldError(event) {
    const fieldId = event.currentTarget.id
    const fieldError = document.getElementById(`${fieldId}-error`)
    if (!fieldError) return
    fieldError.textContent = ""
    fieldError.classList.add("hidden")
  }

  setDrawerError(message) {
    const error = document.getElementById("inventory-drawer-error")
    if (!error) return
    if (!message) {
      error.textContent = ""
      error.classList.add("hidden")
      return
    }
    error.textContent = message
    error.classList.remove("hidden")
  }

  setCountError(message) {
    const error = document.getElementById("inventory-count-error")
    if (!error) return
    if (!message) {
      error.textContent = ""
      error.classList.add("hidden")
      return
    }
    error.textContent = message
    error.classList.remove("hidden")
  }

  toastError(error, fallback) {
    toast({ type: "error", message: this.errorMessage(error, fallback) })
    this.setDrawerError(this.errorMessage(error, fallback))
  }

  errorMessage(error, fallback) {
    return error.errors?.join(", ") || error.message || fallback
  }

  receiptAction(isImport, card) {
    if (isImport) {
      return Helpers.inventory_receipt_post_company_operation_path(this.companyId, this.operationId, card.id, { warehouse_id: this.warehouseId })
    }
    return Helpers.inventory_receipts_company_operation_path(this.companyId, this.operationId, { warehouse_id: this.warehouseId })
  }

  transferAction() {
    return Helpers.inventory_transfers_company_operation_path(this.companyId, this.operationId, { warehouse_id: this.warehouseId })
  }

  exportAction() {
    return Helpers.inventory_exports_company_operation_path(this.companyId, this.operationId, { warehouse_id: this.warehouseId })
  }

  adjustmentAction() {
    return Helpers.inventory_adjustments_company_operation_path(this.companyId, this.operationId, { warehouse_id: this.warehouseId })
  }

  reorderAction() {
    return Helpers.inventory_reorder_company_operation_path(this.companyId, this.operationId, { warehouse_id: this.warehouseId })
  }

  onKeydown(event) {
    if (event.key !== "Escape") return
    if (this.count) {
      this.count = null
      this.renderCountSheet()
    } else if (this.drawer) {
      this.closeDrawer()
    }
  }

  time(value) {
    return Helpers.locationTime(value, Helpers.TIMESTAMP_FORMAT, this.location)
  }

  date(value) {
    if (!value) return "—"
    return Helpers.dateOnly(value, Helpers.DATE_FORMAT, this.location)
  }

  number(value) {
    return Number(value || 0).toLocaleString()
  }

  signed(value) {
    const number = Number(value || 0)
    return number > 0 ? `+${this.number(number)}` : this.number(number)
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
