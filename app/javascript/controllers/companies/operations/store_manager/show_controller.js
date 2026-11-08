import { Controller } from "@hotwired/stimulus"

// Store Manager — full-screen warehouse console for the branch-scoped Store
// Manager operation. Renders the live stock directory (Stock), inbound
// StockImport documents, outbound StockExport documents and the KPI strip
// derived from those relations.
//
// Serves Stimulus: Companies_Operations_StoreManager_ShowController
// Depends on BE: Companies::Operations::StoreManagerController#show
//               (operation + appointment + config + store_manager payload)
// Endpoints: Helpers.store_manager_company_operation_path
// Docs: docs/OPERATIONS.md, docs/STOCK.md
export default class Companies_Operations_StoreManager_ShowController extends Controller {
  /** @type {any | null} */ operation = null
  /** @type {any | null} */ appointment = null
  /** @type {any} */ store = {}
  /** @type {string | null} */ companyId = null
  /** @type {string | null} */ operationId = null
  /** @type {string | null} */ branchId = null
  /** @type {string} */ searchQuery = ""

  async connect() {
    const pathParts = window.location.pathname.split("/")
    this.companyId = this.element.dataset.companyId || pathParts[2]
    this.operationId = this.element.dataset.operationId || pathParts[5]
    this.branchId = new URLSearchParams(window.location.search).get("branch_id")

    try {
      await this.loadConsole()
      this.renderContent()
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      this.element.innerHTML = `<div class="flex items-center justify-center h-screen text-danger text-lg font-semibold">${translate("Failed to load the store manager console.")}${detail ? ": " + this.escape(detail) : ""}</div>`
    }
  }

  async loadConsole() {
    const params = this.branchId ? { branch_id: this.branchId } : {}
    const response = await fetchJson(
      Helpers.store_manager_company_operation_path(this.companyId, this.operationId, params)
    )
    this.operation = response.operation
    this.appointment = response.appointment
    this.store = response.store_manager || {}
    return response
  }

  // --- Derived values ---------------------------------------------------------------

  get branchName() {
    return this.store.branch?.name
      || this.appointment?.location?.name
      || this.appointment?.branch?.name
      || translate("Branch not resolved")
  }

  get warehouses() {
    return this.store.warehouses || []
  }

  get stocks() {
    return this.store.stocks || []
  }

  get inbound() {
    return this.store.inbound || []
  }

  get outbound() {
    return this.store.outbound || []
  }

  get kpis() {
    return this.store.kpis || {}
  }

  get filteredStocks() {
    const query = this.searchQuery.trim().toLowerCase()
    if (!query) return this.sortedStocks

    return this.sortedStocks.filter((stock) => {
      return [
        stock.name,
        stock.code,
        stock.category_name,
        stock.warehouse_name,
        stock.bin
      ].some((value) => String(value || "").toLowerCase().includes(query))
    })
  }

  get sortedStocks() {
    const rank = { stockout: 0, low: 1, in_stock: 2 }
    return [...this.stocks].sort((a, b) => {
      const byStatus = (rank[a.status] ?? 3) - (rank[b.status] ?? 3)
      if (byStatus !== 0) return byStatus
      return Number(a.available || 0) - Number(b.available || 0)
    })
  }

  // --- Rendering -------------------------------------------------------------------

  renderContent() {
    this.element.innerHTML = this.contentHTML()
  }

  contentHTML() {
    return `
      <div class="min-h-screen bg-background text-foreground flex flex-col">
        ${this.renderHeader()}
        <main class="flex-1 w-full px-4 lg:px-6 py-5">
          ${this.renderHeadline()}
          ${this.renderKpis()}
          ${this.renderActionBar()}
          <div class="grid grid-cols-1 xl:grid-cols-12 gap-4 items-start">
            <section class="xl:col-span-8 min-w-0">
              ${this.renderStockPanel()}
            </section>
            <aside class="xl:col-span-4 flex flex-col gap-4 min-w-0">
              ${this.renderInboundPanel()}
              ${this.renderOutboundPanel()}
            </aside>
          </div>
        </main>
        ${this.renderFooter()}
      </div>
    `
  }

  renderHeader() {
    return `
      <header class="sticky top-0 z-30 border-b border-line bg-card">
        <div class="w-full px-4 lg:px-6 h-16 flex items-center justify-between gap-4">
          <div class="flex items-center gap-3 min-w-0">
            <div class="w-9 h-9 rounded-lg bg-primary text-primary-foreground flex items-center justify-center shadow-sm shrink-0">
              <span class="material-symbols-outlined text-[20px]">warehouse</span>
            </div>
            <div class="flex flex-col leading-tight min-w-0">
              <span class="font-bold tracking-tight truncate">${translate("Store Manager Console")}</span>
              <span class="text-[11px] text-muted-foreground truncate">${this.escape(this.branchName)}</span>
            </div>
          </div>
          <div class="flex items-center gap-2 shrink-0">
            <span class="hidden sm:inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-success/10 text-success border border-success/20 text-[11px] font-semibold">
              <span class="w-1.5 h-1.5 rounded-full bg-success"></span>
              ${translate("Live inventory")}
            </span>
            <a href="${Helpers.company_operations_path(this.companyId)}"
              class="inline-flex items-center gap-1.5 px-3 py-2 min-h-[40px] rounded-lg bg-muted text-foreground text-[13px] font-semibold hover:bg-line transition-colors touch-manipulation">
              <span class="material-symbols-outlined text-[18px]">arrow_back</span>
              <span class="hidden sm:inline">${translate("Back to Operations")}</span>
            </a>
          </div>
        </div>
      </header>
    `
  }

  renderHeadline() {
    return `
      <div class="flex flex-col lg:flex-row lg:items-end justify-between gap-3 mb-4">
        <div>
          <div class="flex flex-wrap items-center gap-2 text-[11px] text-muted-foreground">
            <span class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-primary/10 text-primary border border-primary/20 font-semibold">
              <span class="material-symbols-outlined text-[14px]">storefront</span>
              ${translate("Store Manager")}
            </span>
            <span>·</span>
            <span>${translate("Branch:")} <strong class="text-foreground">${this.escape(this.branchName)}</strong></span>
            <span>·</span>
            <span>${this.warehouses.length} ${this.warehouses.length === 1 ? translate("warehouse") : translate("warehouses")}</span>
          </div>
          <h1 class="text-2xl font-bold tracking-tight mt-1">${translate("Warehouse Operations Overview")}</h1>
          <p class="text-[13px] text-muted-foreground mt-0.5">${translate("Live stock balances, inbound shipments and outbound orders for this branch.")}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          ${this.warehouses.map((warehouse) => `
            <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-card border border-line text-[11px] font-semibold text-foreground">
              <span class="material-symbols-outlined text-[15px] text-primary">warehouse</span>
              ${this.escape(warehouse.name)}
            </span>
          `).join("")}
        </div>
      </div>
    `
  }

  renderKpis() {
    const low = Number(this.kpis.low_stock_count || 0)
    const stockout = Number(this.kpis.stockout_count || 0)
    const inboundUnits = Number(this.kpis.inbound_units_due || 0)
    const outboundUnits = Number(this.kpis.outbound_units || 0)

    return `
      <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3 mb-4">
        ${this.renderKpiCard({
          label: translate("Active Inventory"),
          value: Number(this.kpis.active_skus || 0),
          unit: translate("SKUs"),
          icon: "inventory_2",
          tone: "primary",
          footer: `<span class="material-symbols-outlined text-[14px]">grid_view</span> ${this.warehouses.length} ${this.warehouses.length === 1 ? translate("warehouse") : translate("warehouses")}`
        })}
        ${this.renderKpiCard({
          label: translate("Critical Stock Health"),
          value: low,
          unit: translate("Low"),
          icon: "warning",
          tone: low > 0 || stockout > 0 ? "danger" : "success",
          footer: `<span class="w-2 h-2 rounded-full bg-danger inline-block"></span> ${stockout} ${translate("stockout items")}`
        })}
        ${this.renderKpiCard({
          label: translate("Inbound (Import)"),
          value: Number(this.kpis.inbound_shipments || 0),
          unit: translate("Shipments"),
          icon: "move_to_inbox",
          tone: "success",
          footer: `<span class="material-symbols-outlined text-[14px]">south_east</span> ${inboundUnits} ${translate("units due")}`
        })}
        ${this.renderKpiCard({
          label: translate("Outbound (Export)"),
          value: Number(this.kpis.outbound_orders || 0),
          unit: translate("Orders"),
          icon: "local_shipping",
          tone: "primary",
          footer: `<span class="material-symbols-outlined text-[14px]">north_east</span> ${outboundUnits} ${translate("units scheduled")}`
        })}
      </div>
    `
  }

  renderKpiCard({ label, value, unit, icon, tone, footer }) {
    const tones = {
      primary: "text-primary",
      success: "text-success",
      warning: "text-warning",
      danger: "text-danger"
    }
    const toneClass = tones[tone] || tones.primary

    return `
      <div class="relative overflow-hidden rounded-xl bg-card border border-line shadow-sm p-4 flex flex-col justify-between group hover:shadow-md transition-shadow">
        <div class="absolute right-2 top-2 opacity-10 group-hover:opacity-20 transition-opacity">
          <span class="material-symbols-outlined text-[48px] ${toneClass}">${icon}</span>
        </div>
        <div class="flex items-center justify-between gap-2">
          <span class="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">${label}</span>
        </div>
        <div class="mt-3">
          <div class="flex items-baseline gap-2">
            <span class="text-3xl font-extrabold tracking-tight ${toneClass}">${value}</span>
            <span class="text-[11px] text-muted-foreground">${unit}</span>
          </div>
          <div class="text-[11px] text-muted-foreground flex items-center gap-1 mt-1.5">${footer}</div>
        </div>
      </div>
    `
  }

  renderActionBar() {
    return `
      <div class="w-full rounded-xl bg-card border border-line shadow-sm p-3 flex flex-wrap items-center justify-between gap-2 mb-4">
        <div class="flex flex-wrap items-center gap-2">
          <a href="${Helpers.company_stock_imports_path(this.companyId)}"
            class="inline-flex items-center gap-1.5 px-3 py-2 min-h-[40px] rounded-lg bg-primary text-primary-foreground text-[13px] font-semibold shadow-sm hover:brightness-110 active:scale-95 transition-all touch-manipulation">
            <span class="material-symbols-outlined text-[18px]">add_circle</span>
            <span>${translate("Receive Inbound")}</span>
          </a>
          <a href="${Helpers.company_stock_exports_path(this.companyId)}"
            class="inline-flex items-center gap-1.5 px-3 py-2 min-h-[40px] rounded-lg bg-muted text-foreground text-[13px] font-semibold hover:bg-line active:scale-95 transition-all touch-manipulation">
            <span class="material-symbols-outlined text-[18px] text-primary">outbox</span>
            <span>${translate("Create Outbound")}</span>
          </a>
          <a href="${Helpers.company_stocks_path(this.companyId)}"
            class="inline-flex items-center gap-1.5 px-3 py-2 min-h-[40px] rounded-lg bg-muted text-foreground text-[13px] font-semibold hover:bg-line active:scale-95 transition-all touch-manipulation">
            <span class="material-symbols-outlined text-[18px] text-muted-foreground">tune</span>
            <span>${translate("Stock Directory")}</span>
          </a>
        </div>
        <div class="text-[11px] text-muted-foreground flex items-center gap-1.5">
          <span class="material-symbols-outlined text-[16px]">sync</span>
          ${translate("Availabilities refresh from the live stock counter on load.")}
        </div>
      </div>
    `
  }

  renderStockPanel() {
    return `
      <div class="rounded-xl bg-card border border-line shadow-sm p-4 flex flex-col gap-3">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <div>
            <h2 class="text-lg font-bold text-foreground">${translate("On-Hand Stock")}</h2>
            <p class="text-[12px] text-muted-foreground">${translate("Live warehouse balances and safety triggers")}</p>
          </div>
          <div class="relative w-full sm:w-72">
            <span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-[18px] text-muted-foreground pointer-events-none">search</span>
            <input type="search" value="${this.escape(this.searchQuery)}"
              data-action="input->${this.identifier}#updateSearch keydown.esc->${this.identifier}#clearSearch"
              placeholder="${translate("Search by SKU, item or warehouse...")}"
              class="w-full h-10 pl-9 pr-3 rounded-lg bg-muted text-foreground placeholder:text-muted-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary transition-all" />
          </div>
        </div>
        <div class="overflow-x-auto -mx-4 px-4">
          <table class="w-full text-left border-collapse min-w-[720px]">
            <thead>
              <tr class="bg-muted text-muted-foreground text-[10px] uppercase tracking-wider">
                <th class="py-2.5 px-3 rounded-l-lg">${translate("SKU / Item Name")}</th>
                <th class="py-2.5 px-3">${translate("Location")}</th>
                <th class="py-2.5 px-3 text-right">${translate("Available")}</th>
                <th class="py-2.5 px-3 text-right">${translate("Reserved")}</th>
                <th class="py-2.5 px-3 text-right">${translate("Unit Cost")}</th>
                <th class="py-2.5 px-3 text-center rounded-r-lg">${translate("Status")}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-line text-[13px]">
              ${this.renderStockRows()}
            </tbody>
          </table>
        </div>
        <div class="flex items-center justify-between text-[11px] text-muted-foreground pt-1">
          <span>${translate("Showing")} ${this.filteredStocks.length} ${translate("of")} ${this.kpis.active_skus || this.stocks.length} ${translate("stock records")}</span>
          <span>${translate("Availability = quantity minus pending reservations")}</span>
        </div>
      </div>
    `
  }

  renderStockRows() {
    const stocks = this.filteredStocks
    if (stocks.length === 0) {
      return `
        <tr>
          <td colspan="6" class="py-8 text-center text-[13px] text-muted-foreground">
            ${this.searchQuery ? translate("No stock matches this search.") : translate("No stock records for this branch yet.")}
          </td>
        </tr>
      `
    }

    return stocks.map((stock) => {
      const status = this.stockStatusMeta(stock.status)
      return `
        <tr data-store-manager-stock class="hover:bg-muted/60 transition-colors">
          <td class="py-3 px-3">
            <div class="font-semibold text-foreground">${this.escape(stock.name || "—")}</div>
            <div class="text-[11px] text-muted-foreground flex flex-wrap items-center gap-1.5 mt-0.5">
              <span class="font-mono text-muted-foreground">${this.escape(stock.code || "—")}</span>
              ${stock.category_name ? `<span>·</span><span>${this.escape(stock.category_name)}</span>` : ""}
            </div>
          </td>
          <td class="py-3 px-3">
            <span class="inline-flex items-center gap-1 px-2 py-1 rounded bg-muted text-foreground font-mono text-[11px]">
              <span class="material-symbols-outlined text-[14px] text-muted-foreground">shelves</span>
              ${this.escape(stock.warehouse_name || "—")}${stock.bin ? ` · ${this.escape(stock.bin)}` : ""}
            </span>
          </td>
          <td class="py-3 px-3 text-right font-bold ${status.valueClass}">${stock.available} ${translate("pcs")}</td>
          <td class="py-3 px-3 text-right text-muted-foreground">${stock.reserved} ${translate("pcs")}</td>
          <td class="py-3 px-3 text-right font-mono text-foreground">${this.formatMoney(stock.unit_cost, stock.currency)}</td>
          <td class="py-3 px-3 text-center">
            <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-semibold ${status.badgeClass}">
              <span class="w-1.5 h-1.5 rounded-full ${status.dotClass}"></span>
              ${translate(status.label)}
            </span>
          </td>
        </tr>
      `
    }).join("")
  }

  stockStatusMeta(status) {
    const meta = {
      stockout: {
        label: "Stockout",
        valueClass: "text-danger",
        badgeClass: "bg-danger/10 text-danger border border-danger/20",
        dotClass: "bg-danger"
      },
      low: {
        label: "Low stock",
        valueClass: "text-warning",
        badgeClass: "bg-warning/10 text-warning border border-warning/20",
        dotClass: "bg-warning"
      },
      in_stock: {
        label: "In stock",
        valueClass: "text-foreground",
        badgeClass: "bg-success/10 text-success border border-success/20",
        dotClass: "bg-success"
      }
    }
    return meta[status] || meta.in_stock
  }

  renderInboundPanel() {
    return `
      <div class="rounded-xl bg-card border border-line shadow-sm p-4 flex flex-col gap-2">
        <div class="flex items-center justify-between pb-2 border-b border-line">
          <div class="flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[20px] text-success">move_to_inbox</span>
            <h2 class="text-[15px] font-bold text-foreground">${translate("Inbound (Import)")}</h2>
          </div>
          <span class="text-[11px] text-success font-bold">${this.kpis.inbound_shipments || 0} ${translate("open")}</span>
        </div>
        <div class="flex flex-col gap-2">
          ${this.renderInboundItems()}
        </div>
      </div>
    `
  }

  renderInboundItems() {
    if (this.inbound.length === 0) {
      return `<div class="text-center text-[12px] text-muted-foreground py-4">${translate("No inbound shipments.")}</div>`
    }

    return this.inbound.map((shipment) => `
      <div data-store-manager-inbound class="p-3 rounded-lg bg-muted border border-line flex flex-col gap-1.5">
        <div class="flex items-start justify-between gap-2">
          <div class="min-w-0">
            <div class="text-[13px] font-bold text-foreground truncate">${this.escape(shipment.supplier || "—")}</div>
            <div class="text-[11px] text-muted-foreground font-mono">${this.escape(shipment.code || "—")}</div>
          </div>
          <span class="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-success/10 text-success border border-success/20 whitespace-nowrap">
            ${this.escape(this.humanize(shipment.status))}
          </span>
        </div>
        <div class="flex items-center justify-between text-[11px] text-muted-foreground">
          <span>${Number(shipment.units || 0)} ${translate("units")}</span>
          <span>${this.escape(this.humanize(shipment.business_type))}</span>
        </div>
        <div class="w-full bg-card rounded-full h-1.5 overflow-hidden">
          <div class="bg-success h-full rounded-full" style="width: ${this.progressFor(shipment.status)}%"></div>
        </div>
      </div>
    `).join("")
  }

  renderOutboundPanel() {
    return `
      <div class="rounded-xl bg-card border border-line shadow-sm p-4 flex flex-col gap-2">
        <div class="flex items-center justify-between pb-2 border-b border-line">
          <div class="flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[20px] text-primary">local_shipping</span>
            <h2 class="text-[15px] font-bold text-foreground">${translate("Outbound (Export)")}</h2>
          </div>
          <span class="text-[11px] text-primary font-bold">${this.kpis.outbound_orders || 0} ${translate("open")}</span>
        </div>
        <div class="flex flex-col gap-2">
          ${this.renderOutboundItems()}
        </div>
      </div>
    `
  }

  renderOutboundItems() {
    if (this.outbound.length === 0) {
      return `<div class="text-center text-[12px] text-muted-foreground py-4">${translate("No outbound orders.")}</div>`
    }

    return this.outbound.map((order) => `
      <div data-store-manager-outbound class="p-3 rounded-lg bg-muted border border-line flex flex-col gap-1.5">
        <div class="flex items-start justify-between gap-2">
          <div class="min-w-0">
            <div class="text-[13px] font-bold text-foreground truncate">${this.escape(order.destination || "—")}</div>
            <div class="text-[11px] text-muted-foreground font-mono">${this.escape(order.code || "—")}</div>
          </div>
          <span class="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-primary/10 text-primary border border-primary/20 whitespace-nowrap">
            ${this.escape(this.humanize(order.status))}
          </span>
        </div>
        <div class="flex items-center justify-between text-[11px] text-muted-foreground">
          <span>${Number(order.units || 0)} ${translate("units")}</span>
          <span>${this.escape(this.humanize(order.business_type))}</span>
        </div>
        <div class="w-full bg-card rounded-full h-1.5 overflow-hidden">
          <div class="bg-primary h-full rounded-full" style="width: ${this.progressFor(order.status)}%"></div>
        </div>
      </div>
    `).join("")
  }

  renderFooter() {
    return `
      <footer class="w-full bg-muted border-t border-line py-2 px-4 lg:px-6 mt-4">
        <div class="flex flex-col sm:flex-row items-center justify-between gap-1 text-[11px] text-muted-foreground">
          <div>© ${new Date().getFullYear()} Skycom ERP Technologies Inc. ${translate("All rights reserved.")} · ${translate("Store Manager")} v1.0</div>
          <div class="flex items-center gap-3">
            <span class="flex items-center gap-1"><span class="w-2 h-2 rounded-full bg-success"></span>${translate("Inventory online")}</span>
            <span>${translate("Branch:")} ${this.escape(this.branchName)}</span>
          </div>
        </div>
      </footer>
    `
  }

  // --- Interactions ----------------------------------------------------------------

  updateSearch(event) {
    this.searchQuery = event.target.value || ""
    this.renderStockPanelIntoPlace()
  }

  clearSearch(event) {
    if (event) event.preventDefault()
    this.searchQuery = ""
    this.renderStockPanelIntoPlace()
  }

  renderStockPanelIntoPlace() {
    const section = this.element.querySelector("section")
    if (!section) return
    section.innerHTML = this.renderStockPanel()
    const input = section.querySelector('input[type="search"]')
    if (input) {
      input.focus()
      input.setSelectionRange(input.value.length, input.value.length)
    }
  }

  // --- Formatting ------------------------------------------------------------------

  formatMoney(value, currency) {
    const code = String(currency || "USD").toUpperCase()
    try {
      return new Intl.NumberFormat("en-US", { style: "currency", currency: code }).format(Number(value || 0))
    } catch (error) {
      return `${Number(value || 0).toFixed(2)} ${code}`
    }
  }

  humanize(value) {
    return String(value || "—")
      .replace(/_/g, " ")
      .replace(/\b\w/g, (letter) => letter.toUpperCase())
  }

  progressFor(status) {
    return {
      draft: 15,
      pending: 30,
      confirmed: 45,
      in_progress: 65,
      received: 80,
      shipped: 90,
      completed: 100,
      cancelled: 100
    }[status] || 25
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
