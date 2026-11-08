import { Controller } from "@hotwired/stimulus"

// Inventory — the warehouse-level stock command screen. Renders the granular
// stock ledger, vital inventory metrics, inbound/outbound freight docks, zone
// capacity map and the audit summary.
//
// Serves Stimulus: Companies_Operations_Inventory_ShowController
// Depends on BE: Companies::Operations::InventoryController#show
//               (operation + appointment + config + inventory payload)
// Endpoints: Helpers.inventory_company_operation_path
// Docs: docs/OPERATIONS.md, docs/STOCK.md
export default class Companies_Operations_Inventory_ShowController extends Controller {
  /** @type {any | null} */ operation = null
  /** @type {any | null} */ appointment = null
  /** @type {any} */ inventory = {}
  /** @type {string | null} */ companyId = null
  /** @type {string | null} */ operationId = null
  /** @type {string | null} */ warehouseId = null
  /** @type {string} */ stockTab = "all"
  /** @type {string} */ searchQuery = ""

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

  async reloadConsole() {
    await this.loadConsole()
    this.renderContent()
  }

  // --- Derived values ---------------------------------------------------------------

  get locationName() {
    return this.inventory.location?.name
      || this.appointment?.warehouse?.name
      || this.appointment?.location?.name
      || translate("Warehouse not resolved")
  }

  get locationCode() {
    return this.inventory.location?.code || this.operation?.code || ""
  }

  get locationKind() {
    return this.inventory.location?.kind || this.appointment?.kind || "warehouse"
  }

  get currency() {
    return this.inventory.currency || "usd"
  }

  get metrics() {
    return this.inventory.metrics || {}
  }

  get stocks() {
    return this.inventory.stocks || []
  }

  get docks() {
    return this.inventory.docks || {}
  }

  get inboundDocks() {
    return this.docks.inbound || []
  }

  get outboundDocks() {
    return this.docks.outbound || []
  }

  get zones() {
    return this.inventory.zones || []
  }

  get audit() {
    return this.inventory.audit || {}
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

  get lowStockCount() {
    return this.inventory.low_stock_count ?? this.metrics.stock_criticality ?? 0
  }

  get filteredStocks() {
    const query = this.searchQuery.trim().toLowerCase()

    return this.stocks.filter((stock) => {
      if (this.stockTab === "low" && !["low", "critical", "reorder"].includes(stock.status)) return false
      if (this.stockTab === "critical" && stock.status !== "critical") return false
      if (this.stockTab === "in_stock" && stock.status !== "in_stock") return false

      if (!query) return true

      return [
        stock.name,
        stock.code,
        stock.bin_location,
        stock.status_label
      ].join(" ").toLowerCase().includes(query)
    })
  }

  // --- Rendering --------------------------------------------------------------------

  renderContent() {
    this.element.innerHTML = `
      <div class="min-h-screen overflow-x-hidden bg-background text-foreground font-sans">
        ${this.renderHeader()}
        <main class="mx-auto w-full max-w-[1440px] px-4 lg:px-6 py-4 flex flex-col gap-4">
          ${this.renderContextBar()}
          ${this.renderKpis()}
          <div class="grid grid-cols-1 lg:grid-cols-12 gap-4 items-start">
            <div data-inventory-main-column class="lg:col-span-8 flex flex-col gap-4 min-w-0">
              ${this.renderLedgerSection()}
              ${this.renderBomSection()}
            </div>
            <div data-inventory-side-column class="lg:col-span-4 flex flex-col gap-4 min-w-0">
              ${this.renderDocksPanel()}
              ${this.renderZonesPanel()}
              ${this.renderAuditPanel()}
            </div>
          </div>
        </main>
      </div>
    `

    requestAnimationFrame(() => {
      this.element.querySelector("[data-inventory-nav-active]")?.scrollIntoView({ inline: "center", block: "nearest" })
    })
  }

  renderHeader() {
    const navItems = [
      { key: "overview", label: translate("Store Overview"), icon: "storefront" },
      { key: "pos", label: translate("Counter & POS Terminals"), icon: "point_of_sale" },
      { key: "orders", label: translate("Orders & Fulfillment"), icon: "local_shipping" },
      { key: "replenishment", label: translate("Store Replenishment"), icon: "shelves" },
      { key: "inventory", label: translate("Inventory & Stock Ledger"), icon: "inventory_2", active: true },
      { key: "transfers", label: translate("Warehouse Transfers"), icon: "swap_horiz" },
      { key: "procurement", label: translate("BOM & Procurement"), icon: "shopping_cart" }
    ]

    return `
      <header class="sticky top-0 z-40 border-b border-line bg-background/85 backdrop-blur-xl">
        <div class="mx-auto w-full max-w-[1440px] px-4 lg:px-6">
          <div class="h-16 flex items-center justify-between gap-3">
            <div class="flex items-center gap-3 xl:gap-4 min-w-0">
              <a href="${Helpers.company_operations_path(this.companyId)}" class="flex items-center gap-2 shrink-0">
                <span class="w-9 h-9 rounded-lg bg-primary text-primary-foreground flex items-center justify-center">
                  <span class="material-symbols-outlined text-[20px]">hub</span>
                </span>
                <span class="font-display text-lg font-extrabold tracking-tight text-primary">SKYCOM</span>
              </a>
              <div class="hidden md:flex items-center gap-2 rounded-lg border border-line bg-muted px-3 py-1.5 min-w-0">
                <span class="material-symbols-outlined text-[18px] text-muted-foreground">corporate_fare</span>
                <div class="flex flex-col min-w-0">
                  <span class="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">${translate("Tenant Organization")}</span>
                  <span class="text-[13px] font-semibold text-foreground truncate">${this.escape(this.companyName)}</span>
                </div>
              </div>
              <div class="hidden xl:flex items-center gap-1.5 text-muted-foreground min-w-0">
                <span class="material-symbols-outlined text-[18px]">warehouse</span>
                <span class="text-[12px] font-medium truncate">${this.escape(this.locationName)}${this.locationCode ? ` • ${this.escape(this.locationCode)}` : ""}</span>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <span class="hidden sm:inline-flex items-center gap-1.5 rounded-full border border-success/20 bg-success/10 px-2 py-1 text-[11px] font-semibold text-success">
                <span class="w-1.5 h-1.5 rounded-full bg-success animate-pulse"></span>
                ${translate("Cloud Sync Active")}
              </span>
              <button type="button" class="w-10 h-10 rounded-lg bg-muted hover:bg-line text-foreground flex items-center justify-center transition-colors" ${Helpers.darkmodeTrigger()} title="${translate("Toggle dark mode")}"></button>
              <div class="flex items-center gap-2 pl-1">
                <div class="hidden sm:flex flex-col items-end">
                  <span class="text-[12px] font-bold text-foreground">${this.escape(this.userName)}</span>
                  <span class="text-[10px] text-muted-foreground">${this.escape(this.userRole)}</span>
                </div>
                <div class="w-8 h-8 rounded-full bg-primary text-primary-foreground flex items-center justify-center">
                  <span class="material-symbols-outlined text-[18px]">person</span>
                </div>
              </div>
            </div>
          </div>
          <nav class="h-10 flex items-center gap-1 overflow-x-auto pb-1">
            ${navItems.map((item) => this.renderNavItem(item)).join("")}
          </nav>
        </div>
      </header>
    `
  }

  renderNavItem(item) {
    const activeClasses = "bg-primary text-primary-foreground font-semibold shadow-sm"
    const idleClasses = "text-muted-foreground hover:bg-muted hover:text-foreground"

    return `
      <button type="button" data-action="click->${this.identifier}#selectNav" data-${this.identifier}-key-param="${item.key}" data-${this.identifier}-label-param="${this.escape(item.label)}"${item.active ? " data-inventory-nav-active" : ""}
        class="px-2.5 py-1.5 min-h-[34px] rounded-lg text-[11px] transition-colors whitespace-nowrap flex items-center gap-1.5 ${item.active ? activeClasses : idleClasses}">
        <span class="material-symbols-outlined text-[16px]">${item.icon}</span>
        <span>${item.label}</span>
      </button>
    `
  }

  renderContextBar() {
    const utilization = this.inventory.global_utilization ?? 0
    const zonesCount = this.metrics.total_skus_zones || this.zones.length

    return `
      <section class="rounded-xl border border-line bg-card p-3 shadow-sm flex flex-col lg:flex-row lg:items-center justify-between gap-3">
        <div class="flex flex-wrap items-center gap-3">
          <div class="flex items-center gap-2.5">
            <span class="w-10 h-10 rounded-lg bg-primary text-primary-foreground flex items-center justify-center shadow-sm">
              <span class="material-symbols-outlined text-[22px]">inventory_2</span>
            </span>
            <div>
              <div class="flex flex-wrap items-center gap-1.5">
                <span class="font-display text-[15px] font-bold text-foreground">${this.escape(this.locationName)}${this.locationCode ? ` (${this.escape(this.locationCode)})` : ""}</span>
                <span class="inline-flex items-center gap-1 rounded-full border border-success/20 bg-success/10 px-2 py-0.5 text-[10px] font-semibold text-success">
                  <span class="w-1.5 h-1.5 rounded-full bg-success"></span>
                  ${translate("Primary Fulfillment Node")}
                </span>
              </div>
              <div class="flex flex-wrap items-center gap-1.5 text-[11px] text-muted-foreground">
                <span>${translate("Tenant:")} ${this.escape(this.companyName)}</span>
                <span>•</span>
                <span class="text-success font-semibold">${translate("Sync: Real-time")}</span>
              </div>
            </div>
          </div>
          <div class="flex flex-wrap items-center gap-1.5">
            ${this.renderTelemetryPill("grid_goldenratio", translate("Stock Row Utilization"), `${utilization}%`, `${zonesCount} ${zonesCount === 1 ? translate("zone") : translate("zones")}`, "primary")}
            ${this.renderTelemetryPill("sensors", translate("Freight Gates"), `${this.inboundDocks.length + this.outboundDocks.length} / ${zonesCount}`, translate("active docks"), "success")}
          </div>
        </div>
        <div class="flex flex-wrap items-center gap-1.5">
          ${this.renderQuickAction("receive", "move_to_inbox", translate("Receive Inbound"), "bg-primary text-primary-foreground hover:brightness-110", true)}
          ${this.renderQuickAction("transfer", "unarchive", translate("Outbound Transfer"), "bg-muted text-foreground hover:bg-line")}
          ${this.renderQuickAction("scan", "qr_code_scanner", translate("Scan RFID"), "bg-muted text-foreground hover:bg-line")}
          ${this.renderQuickAction("audit", "fact_check", translate("Audit Cycle Count"), "bg-muted text-foreground hover:bg-line")}
        </div>
      </section>
    `
  }

  renderTelemetryPill(icon, label, value, sublabel, tone) {
    const toneClass = {
      primary: "text-primary",
      success: "text-success",
      warning: "text-warning",
      danger: "text-danger"
    }[tone] || "text-primary"

    return `
      <div class="rounded-lg border border-line bg-muted px-2.5 py-1.5 flex items-center gap-2">
        <span class="material-symbols-outlined text-[18px] ${toneClass}">${icon}</span>
        <div>
          <div class="text-[9px] font-semibold uppercase tracking-wider text-muted-foreground">${label}</div>
          <div class="text-[13px] font-bold text-foreground">${value} <span class="text-[10px] font-normal text-muted-foreground">${sublabel}</span></div>
        </div>
      </div>
    `
  }

  renderQuickAction(key, icon, label, classes, primary = false) {
    return `
      <button type="button" data-action="click->${this.identifier}#quickAction" data-${this.identifier}-key-param="${key}"
        class="inline-flex items-center gap-1.5 px-3 py-2 min-h-[36px] rounded-lg text-[12px] font-semibold transition-all shadow-sm active:scale-[0.98] ${classes}">
        <span class="material-symbols-outlined text-[17px] ${primary ? "" : "text-muted-foreground"}">${icon}</span>
        <span>${label}</span>
      </button>
    `
  }

  renderKpis() {
    const metrics = this.metrics

    return `
      <section class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3">
        ${this.renderKpiCard({
          label: translate("Total SKUs Active"),
          value: this.number(metrics.total_skus_active),
          icon: "shelves",
          tone: "primary",
          footer: `${translate("Across")} ${metrics.total_skus_zones || 0} ${translate("facility zones")}`,
          progress: Math.min(100, (metrics.total_skus_active || 0) > 0 ? 94 : 0)
        })}
        ${this.renderKpiCard({
          label: translate("Stock Criticality"),
          value: `${this.number(metrics.stock_criticality)} <span class="text-[12px] font-normal text-muted-foreground">${translate("Triggers")}</span>`,
          icon: "warning",
          tone: (metrics.stock_criticality || 0) > 0 ? "danger" : "success",
          footer: `${this.number(metrics.zero_stock_outages)} ${translate("Zero-Stock Outages")}`,
          progress: Math.min(100, (metrics.stock_criticality || 0) * 10)
        })}
        ${this.renderKpiCard({
          label: translate("Inbound Gate Intake"),
          value: `${this.number(metrics.inbound_shipments)} <span class="text-[12px] font-normal text-muted-foreground">${translate("Shipments")}</span>`,
          icon: "rv_hookup",
          tone: "success",
          footer: `${this.number(metrics.inbound_units)} ${translate("Units")} • ${this.number(metrics.inbound_docked)} ${translate("Docked")}`,
          progress: Math.min(100, (metrics.inbound_shipments || 0) * 20)
        })}
        ${this.renderKpiCard({
          label: translate("Outbound Freight"),
          value: `${this.number(metrics.outbound_dispatches)} <span class="text-[12px] font-normal text-muted-foreground">${translate("Dispatches")}</span>`,
          icon: "local_shipping",
          tone: "info",
          footer: `${this.number(metrics.outbound_cartons)} ${translate("Cartons")} • ${this.number(metrics.outbound_staged)} ${translate("Staged")}`,
          progress: Math.min(100, (metrics.outbound_dispatches || 0) * 20)
        })}
        ${this.renderKpiCard({
          label: translate("BOM Line Shortage"),
          value: `${this.number(metrics.bom_shortage_work_orders)} <span class="text-[12px] font-normal text-muted-foreground">${translate("Work Orders")}</span>`,
          icon: "construction",
          tone: "warning",
          footer: `${this.number(metrics.bom_missing_parts)} ${translate("Missing Vital Parts")}`,
          progress: Math.min(100, (metrics.bom_shortage_work_orders || 0) * 20)
        })}
      </section>
    `
  }

  renderKpiCard({ label, value, icon, tone, footer, progress }) {
    const tones = {
      primary: { accent: "bg-primary", icon: "text-primary bg-primary/10" },
      success: { accent: "bg-success", icon: "text-success bg-success/10" },
      warning: { accent: "bg-warning", icon: "text-warning bg-warning/10" },
      danger: { accent: "bg-danger", icon: "text-danger bg-danger/10" },
      info: { accent: "bg-info", icon: "text-info bg-info/10" }
    }
    const toneClass = tones[tone] || tones.primary

    return `
      <div class="relative overflow-hidden rounded-xl border border-line bg-card p-3 shadow-sm flex flex-col justify-between group hover:shadow-md transition-shadow">
        <span class="absolute left-0 top-0 h-full w-1.5 ${toneClass.accent}"></span>
        <div class="flex items-start justify-between gap-2 pl-1">
          <span class="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">${label}</span>
          <span class="w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${toneClass.icon}">
            <span class="material-symbols-outlined text-[19px]">${icon}</span>
          </span>
        </div>
        <div class="mt-2 pl-1">
          <div class="font-display text-2xl font-extrabold tracking-tight text-foreground">${value}</div>
          <div class="flex flex-wrap items-center gap-1.5 mt-1 text-[11px] text-muted-foreground">${footer}</div>
        </div>
        <div class="mt-2 ml-1 h-1 w-full rounded-full bg-muted overflow-hidden">
          <div class="${toneClass.accent} h-full" style="width: ${progress}%"></div>
        </div>
      </div>
    `
  }

  renderLedgerSection() {
    return `
      <section class="rounded-xl border border-line bg-card p-3 sm:p-4 shadow-sm flex flex-col gap-3">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <div class="min-w-0">
            <div class="flex items-center gap-2">
              <span class="material-symbols-outlined text-[22px] text-primary">inventory</span>
              <h2 class="font-display text-lg font-bold text-foreground tracking-tight">${translate("Stock Ledger & Granular Bin Registry")}</h2>
            </div>
            <p class="text-[12px] text-muted-foreground mt-0.5">${translate("Live telemetry and reservation accounting across all warehouse aisles.")}</p>
          </div>
          <div class="flex items-center gap-1.5">
            <button type="button" data-action="click->${this.identifier}#exportCsv" class="inline-flex items-center gap-1 rounded-lg bg-muted hover:bg-line px-2.5 py-1.5 min-h-[34px] text-[11px] font-semibold text-foreground transition-colors">
              <span class="material-symbols-outlined text-[16px] text-muted-foreground">file_download</span>
              ${translate("Export CSV")}
            </button>
            <button type="button" data-action="click->${this.identifier}#density" class="inline-flex items-center gap-1 rounded-lg bg-muted hover:bg-line px-2.5 py-1.5 min-h-[34px] text-[11px] font-semibold text-foreground transition-colors">
              <span class="material-symbols-outlined text-[16px] text-muted-foreground">tune</span>
              ${translate("Density")}
            </button>
            <button type="button" data-action="click->${this.identifier}#refreshConsole" class="w-9 h-9 rounded-lg bg-muted hover:bg-line text-muted-foreground flex items-center justify-center transition-colors" title="${translate("Refresh stock ledger")}">
              <span class="material-symbols-outlined text-[18px]">refresh</span>
            </button>
          </div>
        </div>

        <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-2 rounded-lg bg-muted p-2">
          <div class="flex items-center gap-2 flex-1">
            <div class="relative flex-1">
              <span class="material-symbols-outlined absolute left-2.5 top-1/2 -translate-y-1/2 text-[18px] text-muted-foreground pointer-events-none">search</span>
              <input id="inventory-stock-search" type="text" value="${this.escape(this.searchQuery)}"
                data-action="input->${this.identifier}#updateSearch keydown.esc->${this.identifier}#clearSearch"
                placeholder="${translate("Search by SKU, Product Name or Bin Code...")}"
                class="w-full h-9 pl-9 pr-3 rounded-lg bg-card text-foreground placeholder:text-muted-foreground text-[12px] border border-line focus:outline-none focus:ring-2 focus:ring-primary shadow-sm" />
            </div>
            <span class="hidden sm:inline-flex items-center gap-1 rounded-lg bg-card border border-line px-2 py-1.5 text-[10px] font-semibold text-success whitespace-nowrap">
              <span class="material-symbols-outlined text-[15px]">wifi_tethering</span>
              ${translate("RFID Live Mode")}
            </span>
          </div>
          <div id="inventory-stock-tabs" class="flex items-center gap-1 overflow-x-auto p-0.5">
            ${this.renderStockTabs()}
          </div>
        </div>

        <div class="overflow-x-auto -mx-3 sm:-mx-4 px-3 sm:px-4">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="bg-muted text-muted-foreground text-[10px] uppercase tracking-wider">
                <th class="py-2.5 px-3 rounded-l-lg font-semibold">${translate("SKU & Item Specification")}</th>
                <th class="py-2.5 px-3 font-semibold">${translate("Bin Location")}</th>
                <th class="py-2.5 px-3 text-right font-semibold">${translate("On Hand")}</th>
                <th class="py-2.5 px-3 text-right font-semibold">${translate("Allocated")}</th>
                <th class="py-2.5 px-3 text-right font-semibold">${translate("Available")}</th>
                <th class="py-2.5 px-3 text-right font-semibold">${translate("Min Safe")}</th>
                <th class="py-2.5 px-3 font-semibold">${translate("Inventory Status")}</th>
                <th class="py-2.5 px-3 text-right rounded-r-lg font-semibold">${translate("Action")}</th>
              </tr>
            </thead>
            <tbody id="inventory-stock-rows" class="text-[12px]">
              ${this.renderStockRows()}
            </tbody>
          </table>
        </div>

        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pt-1 text-[11px] text-muted-foreground">
          <span>${translate("Showing")} <span data-inventory-stock-count>${this.filteredStocks.length}</span> ${translate("of")} ${this.stocks.length} ${translate("line items")} • ${translate("Cycle verified against")} ${this.escape(this.locationName)}</span>
          <div class="flex items-center gap-1">
            <a href="/companies/${this.companyId}/stocks" class="rounded bg-muted px-2.5 py-1 text-[11px] font-semibold text-foreground hover:bg-line transition-colors">${translate("Open stock ledger")}</a>
          </div>
        </div>
      </section>
    `
  }

  renderStockTabs() {
    const counts = {
      all: this.stocks.length,
      low: this.lowStockCount,
      critical: this.stocks.filter((stock) => stock.status === "critical").length,
      in_stock: this.stocks.filter((stock) => stock.status === "in_stock").length
    }
    const tabs = [
      { key: "all", label: translate("All"), count: counts.all },
      { key: "low", label: translate("Low Stock"), count: counts.low },
      { key: "critical", label: translate("Critical"), count: counts.critical },
      { key: "in_stock", label: translate("In Stock"), count: counts.in_stock }
    ]

    return tabs.map((tab) => {
      const active = tab.key === this.stockTab
      const tone = tab.key === "critical" || tab.key === "low" ? "text-danger" : "text-muted-foreground"
      return `
        <button type="button" data-action="click->${this.identifier}#setStockTab" data-${this.identifier}-tab-param="${tab.key}"
          class="px-2.5 py-1.5 min-h-[30px] rounded-md text-[11px] font-semibold whitespace-nowrap transition-all ${active ? "bg-card text-primary shadow-sm border border-line" : `${tone} hover:bg-card/60 hover:text-foreground`}">
          ${tab.label} (${tab.count})
        </button>
      `
    }).join("")
  }

  renderStockRows() {
    const stocks = this.filteredStocks
    if (stocks.length === 0) {
      return `
        <tr>
          <td colspan="8" class="py-8 px-3 text-center text-muted-foreground text-[12px]">${translate("No stock rows match this view.")}</td>
        </tr>
      `
    }

    return stocks.map((stock) => this.renderStockRow(stock)).join("")
  }

  renderStockRow(stock) {
    const statusTone = {
      critical: "bg-danger text-danger-foreground",
      low: "bg-danger/10 text-danger",
      reorder: "bg-warning/10 text-warning",
      in_stock: "bg-success/10 text-success"
    }[stock.status] || "bg-muted text-muted-foreground"

    const availableTone = stock.available <= 0
      ? "text-danger font-bold"
      : stock.available <= stock.min_safe
        ? "text-warning font-semibold"
        : "text-success font-semibold"

    const action = stock.available <= stock.min_safe
      ? `<a href="${this.escape(stock.stock_path)}" class="inline-flex items-center gap-1 rounded-md bg-primary/10 hover:bg-primary/20 px-2.5 py-1 text-[11px] font-semibold text-primary transition-colors">${translate("PO Reorder")}</a>`
      : `<a href="${this.escape(stock.stock_path)}" class="inline-flex items-center gap-1 rounded-md bg-muted hover:bg-line px-2.5 py-1 text-[11px] font-semibold text-foreground transition-colors">${translate("Transfer")}</a>`

    return `
      <tr class="border-b border-line last:border-0 hover:bg-muted/60 transition-colors align-top ${stock.status === "critical" ? "bg-danger/5" : ""}">
        <td class="py-3 px-3">
          <div class="font-semibold text-foreground">${this.escape(stock.name)}</div>
          <div class="text-[10px] text-muted-foreground flex flex-wrap items-center gap-1">
            <span>${this.escape(stock.code)}</span>
            <span>•</span>
            <span>${this.moneyPlain(stock.price, stock.currency)} / ${translate("unit")}</span>
          </div>
        </td>
        <td class="py-3 px-3">
          <span class="inline-flex items-center gap-1 rounded bg-muted px-2 py-0.5 text-[11px] font-medium text-foreground">
            <span class="material-symbols-outlined text-[14px] text-muted-foreground">grid_view</span>
            ${this.escape(stock.bin_location)}
          </span>
        </td>
        <td class="py-3 px-3 text-right font-semibold text-foreground">${this.number(stock.on_hand)}</td>
        <td class="py-3 px-3 text-right text-muted-foreground">${this.number(stock.allocated)}</td>
        <td class="py-3 px-3 text-right ${availableTone}">${this.number(stock.available)}</td>
        <td class="py-3 px-3 text-right text-muted-foreground">${this.number(stock.min_safe)}</td>
        <td class="py-3 px-3">
          <span class="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-semibold ${statusTone}">
            <span class="w-1.5 h-1.5 rounded-full bg-current"></span>
            ${this.escape(translate(stock.status_label))}
          </span>
        </td>
        <td class="py-3 px-3 text-right">
          <div class="flex items-center justify-end gap-1">
            ${action}
            <a href="${this.escape(stock.stock_path)}" class="w-7 h-7 rounded-md hover:bg-muted text-muted-foreground flex items-center justify-center transition-colors" title="${translate("Adjust Balance")}">
              <span class="material-symbols-outlined text-[17px]">edit</span>
            </a>
          </div>
        </td>
      </tr>
    `
  }

  renderBomSection() {
    return `
      <section class="rounded-xl border border-line bg-card p-3 sm:p-4 shadow-sm flex flex-col gap-3">
        <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-2">
          <div class="flex items-start gap-2">
            <span class="w-10 h-10 rounded-lg bg-warning/10 text-warning flex items-center justify-center shrink-0">
              <span class="material-symbols-outlined text-[22px]">precision_manufacturing</span>
            </span>
            <div>
              <div class="flex flex-wrap items-center gap-1.5">
                <h3 class="font-display text-lg font-bold text-foreground tracking-tight">${translate("BOM Line Shortage Analyzer")}</h3>
                <span class="rounded-full bg-warning/10 px-2 py-0.5 text-[10px] font-bold text-warning">${translate("Assembly Hold")}</span>
              </div>
              <p class="text-[12px] text-muted-foreground mt-0.5">${translate("Production component shortages against the live warehouse balance.")}</p>
            </div>
          </div>
          <button type="button" data-action="click->${this.identifier}#autoGeneratePos"
            class="inline-flex items-center gap-1.5 rounded-lg bg-primary px-3 py-2 min-h-[36px] text-[12px] font-semibold text-primary-foreground shadow-sm hover:brightness-110 transition-all shrink-0">
            <span class="material-symbols-outlined text-[17px]">bolt</span>
            ${translate("Auto-Generate Bulk POs")}
          </button>
        </div>
        <div class="rounded-lg border border-line bg-muted p-3 flex items-start gap-2">
          <span class="material-symbols-outlined text-[18px] text-success">check_circle</span>
          <div>
            <div class="text-[12px] font-semibold text-foreground">${translate("No BOM shortages right now.")}</div>
            <div class="text-[11px] text-muted-foreground">${translate("Production work orders will appear here when component demand exceeds the warehouse balance.")}</div>
          </div>
        </div>
      </section>
    `
  }

  renderDocksPanel() {
    return `
      <section class="rounded-xl border border-line bg-card p-3 shadow-sm flex flex-col gap-2">
        <div class="flex items-center justify-between gap-2 pb-2 border-b border-line">
          <div class="flex items-center gap-2">
            <span class="material-symbols-outlined text-[20px] text-primary">dock</span>
            <h2 class="font-display text-[15px] font-bold text-foreground">${translate("Active Freight Docks")}</h2>
          </div>
          <span class="rounded-full bg-muted px-2 py-0.5 text-[10px] font-semibold text-muted-foreground">${translate("Live gates")}</span>
        </div>

        <div class="flex items-center justify-between">
          <span class="text-[10px] font-bold uppercase tracking-wider text-success flex items-center gap-1">
            <span class="material-symbols-outlined text-[15px]">call_received</span>
            ${translate("Inbound Dock Intake")} (${this.inboundDocks.length})
          </span>
        </div>
        <div class="flex flex-col gap-2">
          ${this.renderInboundDocks()}
        </div>

        <div class="h-px bg-line my-1"></div>

        <div class="flex items-center justify-between">
          <span class="text-[10px] font-bold uppercase tracking-wider text-primary flex items-center gap-1">
            <span class="material-symbols-outlined text-[15px]">call_made</span>
            ${translate("Outbound Dispatch Dock")} (${this.outboundDocks.length})
          </span>
        </div>
        <div class="flex flex-col gap-2">
          ${this.renderOutboundDocks()}
        </div>
      </section>
    `
  }

  renderInboundDocks() {
    if (this.inboundDocks.length === 0) {
      return `<div class="rounded-lg border border-line bg-muted p-3 text-center text-[11px] text-muted-foreground">${translate("No inbound shipments are docked.")}</div>`
    }

    return this.inboundDocks.map((dock) => `
      <div class="rounded-lg border border-line bg-muted p-2.5 flex flex-col gap-1">
        <div class="flex items-center justify-between gap-2">
          <span class="text-[12px] font-bold text-foreground">#${this.escape(dock.code)} • ${this.escape(dock.gate)}</span>
          <span class="rounded-full bg-success/10 px-2 py-0.5 text-[9px] font-bold text-success">${this.escape(translate(dock.status_label))}</span>
        </div>
        <div class="text-[11px] text-muted-foreground">${this.escape(dock.supplier)}</div>
        <div class="text-[10px] text-foreground">${dock.pallets} ${translate("pallets")} • ${this.number(dock.units)} ${translate("units")}</div>
        <div>
          <div class="flex justify-between text-[9px] text-muted-foreground mb-1">
            <span>${translate("QC RFID Gate Scan")}</span>
            <span class="font-semibold text-success">${dock.progress}% ${translate("offloaded")}</span>
          </div>
          <div class="h-1.5 w-full rounded-full bg-line overflow-hidden">
            <div class="h-full bg-success" style="width: ${dock.progress}%"></div>
          </div>
        </div>
      </div>
    `).join("")
  }

  renderOutboundDocks() {
    if (this.outboundDocks.length === 0) {
      return `<div class="rounded-lg border border-line bg-muted p-3 text-center text-[11px] text-muted-foreground">${translate("No outbound dispatches are scheduled.")}</div>`
    }

    return this.outboundDocks.map((dock) => `
      <div class="rounded-lg border border-line bg-muted p-2.5 flex flex-col gap-1">
        <div class="flex items-center justify-between gap-2">
          <span class="text-[12px] font-bold text-foreground">#${this.escape(dock.code)} • ${this.escape(dock.bay)}</span>
          <span class="rounded-full bg-primary/10 px-2 py-0.5 text-[9px] font-bold text-primary">${this.escape(translate(dock.status_label))}</span>
        </div>
        <div class="text-[11px] text-muted-foreground">${this.escape(dock.destination)}</div>
        <div class="text-[10px] text-foreground">${dock.cartons} ${translate("cartons")} • ${this.number(dock.weight)} ${translate("kg")} • ${this.escape(dock.carrier)}</div>
        <div class="h-1.5 w-full rounded-full bg-line overflow-hidden mt-1">
          <div class="h-full bg-primary" style="width: ${dock.progress}%"></div>
        </div>
      </div>
    `).join("")
  }

  renderZonesPanel() {
    return `
      <section class="rounded-xl border border-line bg-card p-3 shadow-sm flex flex-col gap-2">
        <div class="flex items-center justify-between gap-2 pb-2 border-b border-line">
          <div class="flex items-center gap-2">
            <span class="material-symbols-outlined text-[20px] text-success">space_dashboard</span>
            <h2 class="font-display text-[15px] font-bold text-foreground">${translate("Zone Capacity Map")}</h2>
          </div>
          <span class="text-[10px] font-semibold text-muted-foreground">${translate("Bay Volumetrics")}</span>
        </div>
        <div class="flex flex-col gap-2.5">
          ${this.renderZones()}
        </div>
        <div class="mt-1 rounded-lg border border-line bg-muted p-2.5 flex items-center justify-between gap-2">
          <div class="flex items-center gap-2">
            <span class="material-symbols-outlined text-[22px] text-primary">donut_large</span>
            <div>
              <div class="text-[14px] font-bold text-foreground">${this.inventory.global_utilization ?? 0}% ${translate("Total")}</div>
              <div class="text-[10px] text-muted-foreground">${translate("Global Slot Utilization")}</div>
            </div>
          </div>
          <button type="button" data-action="click->${this.identifier}#reoptimize" class="text-[11px] font-semibold text-primary hover:underline">${translate("Re-optimize")}</button>
        </div>
      </section>
    `
  }

  renderZones() {
    if (this.zones.length === 0) {
      return `<div class="rounded-lg border border-line bg-muted p-3 text-center text-[11px] text-muted-foreground">${translate("No warehouse zones are configured.")}</div>`
    }

    return this.zones.map((zone) => {
      const barTone = {
        danger: "bg-danger",
        primary: "bg-primary",
        success: "bg-success"
      }[zone.tone] || "bg-primary"
      const textTone = {
        danger: "text-danger",
        primary: "text-foreground",
        success: "text-success"
      }[zone.tone] || "text-foreground"

      return `
        <div>
          <div class="flex items-center justify-between text-[11px] mb-1">
            <span class="font-semibold text-foreground truncate">${this.escape(zone.name)}</span>
            <span class="font-bold ${textTone}">${zone.occupancy}% ${translate("Full")}</span>
          </div>
          <div class="h-2 w-full rounded-full bg-muted overflow-hidden">
            <div class="${barTone} h-full" style="width: ${zone.occupancy}%"></div>
          </div>
          <span class="text-[10px] text-muted-foreground mt-0.5 block">${this.escape(zone.note)}</span>
        </div>
      `
    }).join("")
  }

  renderAuditPanel() {
    const audit = this.audit
    const available = audit.available === true

    return `
      <section class="rounded-xl border border-line bg-card p-3 shadow-sm flex flex-col gap-2">
        <div class="flex items-center justify-between gap-2">
          <div class="flex items-center gap-2">
            <span class="material-symbols-outlined text-[20px] text-success">verified_user</span>
            <h2 class="font-display text-[15px] font-bold text-foreground">${translate("Audit & RFID Integrity")}</h2>
          </div>
          <span class="rounded-full ${available ? "bg-success/10 text-success" : "bg-muted text-muted-foreground"} px-2 py-0.5 text-[10px] font-bold">
            ${available ? `${audit.clean_pct}% ${translate("Clean")}` : translate("No audit recorded")}
          </span>
        </div>
        <div class="text-[11px] text-muted-foreground">
          ${available
            ? `${translate("Last comprehensive cycle audit completed")} <strong class="text-foreground">${audit.last_audit_days_ago} ${translate("days ago")}</strong> ${translate("by")} ${this.escape(audit.auditor || translate("Warehouse Lead"))}. ${audit.discrepancies ?? 0} ${translate("minor discrepancies logged out of")} ${this.number(audit.total_lines)} ${translate("lines")}.`
            : `${translate("No cycle audit has been recorded for this warehouse yet.")} ${this.number(audit.total_lines)} ${translate("line items are ready for the first count.")}`}
        </div>
        <div class="flex items-center justify-between gap-2 pt-1">
          <a href="/companies/${this.companyId}/stocks" class="inline-flex items-center gap-1 text-[11px] font-semibold text-primary hover:underline">
            <span class="material-symbols-outlined text-[16px]">visibility</span>
            ${translate("View Full Audit Log")}
          </a>
          <button type="button" data-action="click->${this.identifier}#scheduleCount" class="rounded-lg bg-muted hover:bg-line px-3 py-1.5 text-[11px] font-semibold text-foreground transition-colors">
            ${translate("Schedule Count")}
          </button>
        </div>
      </section>
    `
  }

  // --- Interactions -----------------------------------------------------------------

  selectNav(event) {
    if (event.params.key === "inventory") return
    toast({ type: "info", message: `${event.params.label} ${translate("is coming soon.")}` })
  }

  async refreshConsole(event) {
    if (event) event.preventDefault()
    try {
      await this.reloadConsole()
      toast({ type: "success", message: translate("Inventory console refreshed.") })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to refresh the inventory console.") })
    }
  }

  setStockTab(event) {
    this.stockTab = event.params.tab
    const tabs = document.getElementById("inventory-stock-tabs")
    const rows = document.getElementById("inventory-stock-rows")
    const footer = this.element.querySelector("[data-inventory-stock-count]")

    if (tabs) tabs.innerHTML = this.renderStockTabs()
    if (rows) rows.innerHTML = this.renderStockRows()
    if (footer) footer.textContent = this.filteredStocks.length
  }

  updateSearch(event) {
    this.searchQuery = event.target.value || ""
    const rows = document.getElementById("inventory-stock-rows")
    if (rows) rows.innerHTML = this.renderStockRows()
    const footer = this.element.querySelector("[data-inventory-stock-count]")
    if (footer) footer.textContent = this.filteredStocks.length
  }

  clearSearch(event) {
    if (event) event.preventDefault()
    this.searchQuery = ""
    const input = document.getElementById("inventory-stock-search")
    if (input) input.value = ""
    const rows = document.getElementById("inventory-stock-rows")
    if (rows) rows.innerHTML = this.renderStockRows()
    const footer = this.element.querySelector("[data-inventory-stock-count]")
    if (footer) footer.textContent = this.filteredStocks.length
  }

  quickAction(event) {
    const key = event.params.key

    if (key === "receive") {
      window.location.href = `/companies/${this.companyId}/stock_imports/new`
      return
    }
    if (key === "transfer") {
      window.location.href = `/companies/${this.companyId}/stock_transfers/new`
      return
    }
    if (key === "scan") {
      const input = document.getElementById("inventory-stock-search")
      if (input) {
        input.focus()
        input.select()
      }
      toast({ type: "info", message: translate("Scanner input ready. Scan or type a SKU.") })
      return
    }
    if (key === "audit") {
      window.location.href = `/companies/${this.companyId}/stocks`
    }
  }

  exportCsv() {
    window.location.href = `/companies/${this.companyId}/stocks?export=1`
  }

  density() {
    toast({ type: "info", message: translate("Density controls are not connected yet.") })
  }

  autoGeneratePos() {
    toast({ type: "info", message: translate("No BOM shortages to order for this warehouse.") })
  }

  reoptimize() {
    toast({ type: "info", message: translate("Zone re-optimization is not connected yet.") })
  }

  scheduleCount() {
    window.location.href = `/companies/${this.companyId}/stocks`
  }

  // --- Helpers ----------------------------------------------------------------------

  moneyPlain(amount, currency = this.currency) {
    return Helpers.formatMoney(Math.round((amount || 0) * 100), currency)
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
