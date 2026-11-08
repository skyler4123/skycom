import { Controller } from "@hotwired/stimulus"

// Store Manager — the branch-level retail command screen. Renders today's
// sales KPIs, the fulfillment queue, shelf replenishment alerts, register
// activity, hourly order volume and the on-duty roster.
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
  /** @type {string} */ orderTab = "all"
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
      this.element.innerHTML = `<div class="flex items-center justify-center h-screen text-danger text-lg font-semibold">${translate("Failed to load the store manager console.")}${detail ? `: ${this.escape(detail)}` : ""}</div>`
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

  async reloadConsole() {
    await this.loadConsole()
    this.renderContent()
  }

  // --- Derived values ---------------------------------------------------------------

  get branchName() {
    return this.store.branch?.name
      || this.appointment?.location?.name
      || this.appointment?.branch?.name
      || translate("Branch not resolved")
  }

  get branchCode() {
    return this.store.branch?.code || this.operation?.code || ""
  }

  get currency() {
    return this.store.currency || "usd"
  }

  get kpis() {
    return this.store.kpis || {}
  }

  get orders() {
    return this.store.orders || []
  }

  get replenishments() {
    return this.store.replenishments || []
  }

  get registers() {
    return this.store.registers || []
  }

  get staff() {
    return this.store.staff || []
  }

  get hourly() {
    return this.store.hourly || []
  }

  get footfall() {
    return this.store.footfall || {}
  }

  get companyName() {
    return Helpers.currentCompany()?.name || translate("Company")
  }

  get userName() {
    return this.element.dataset.userName || Helpers.currentUser()?.name || Helpers.currentUser()?.email || translate("Manager")
  }

  get userRole() {
    const role = this.element.dataset.userRole || Helpers.currentEmployee()?.category?.name
    return role && role !== "Employees" ? role : translate("Store Manager")
  }

  get currentHour() {
    const value = this.store.generated_at
    const date = value ? new Date(value) : new Date()
    return Number.isNaN(date.getTime()) ? new Date().getUTCHours() : date.getUTCHours()
  }

  get currentShift() {
    const hour = this.currentHour
    if (hour < 12) return translate("Morning (08:00 - 17:00)")
    if (hour < 17) return translate("Afternoon (12:00 - 21:00)")
    return translate("Evening (17:00 - 01:00)")
  }

  get orderCounts() {
    const counts = this.store.order_counts
    if (counts) return counts

    return {
      all: this.orders.length,
      click_collect: this.orders.filter((order) => order.channel === "click_collect").length,
      delivery: this.orders.filter((order) => order.channel === "delivery").length,
      completed: this.orders.filter((order) => ["paid", "completed"].includes(order.workflow_status)).length
    }
  }

  get ordersTotal() {
    return this.store.orders_total ?? this.orders.length
  }

  get filteredOrders() {
    const query = this.searchQuery.trim().toLowerCase()
    return this.orders.filter((order) => {
      if (this.orderTab === "click_collect" && order.channel !== "click_collect") return false
      if (this.orderTab === "delivery" && order.channel !== "delivery") return false
      if (this.orderTab === "completed" && !["paid", "completed"].includes(order.workflow_status)) return false

      if (!query) return true

      return [
        order.code,
        order.customer_name,
        order.customer_meta,
        order.channel_label,
        order.status_label,
        order.assignment
      ].join(" ").toLowerCase().includes(query)
    })
  }

  get maxHourlyOrders() {
    return Math.max(1, ...this.hourly.map((bucket) => bucket.orders_count || 0))
  }

  // --- Rendering --------------------------------------------------------------------

  renderContent() {
    this.element.innerHTML = `
      <div class="min-h-screen bg-background text-foreground font-sans">
        ${this.renderHeader()}
        <main class="mx-auto w-full max-w-[1440px] px-4 lg:px-6 py-4 flex flex-col gap-4">
          ${this.renderContextBanner()}
          ${this.renderKpis()}
          <div class="grid grid-cols-1 lg:grid-cols-12 gap-4 items-start">
            <div data-store-manager-main-column class="lg:col-span-8 flex flex-col gap-4 min-w-0">
              ${this.renderFulfillmentSection()}
              ${this.renderReplenishmentSection()}
            </div>
            <div data-store-manager-side-column class="lg:col-span-4 flex flex-col gap-4 min-w-0">
              ${this.renderRegistersPanel()}
              ${this.renderFootfallPanel()}
              ${this.renderStaffPanel()}
            </div>
          </div>
          ${this.renderAuditStrip()}
        </main>
      </div>
    `
  }

  renderHeader() {
    const navItems = [
      { key: "overview", label: translate("Store Overview"), icon: "storefront", active: true },
      { key: "pos", label: translate("Counter & POS Terminals"), icon: "point_of_sale" },
      { key: "orders", label: translate("Orders & Fulfillment"), icon: "local_shipping" },
      { key: "replenishment", label: translate("Store Replenishment"), icon: "shelves" },
      { key: "inventory", label: translate("Inventory & Stock Ledger"), icon: "inventory_2" },
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
                <span class="text-[12px] font-medium truncate">${this.escape(this.branchName)}${this.branchCode ? ` • ${this.escape(this.branchCode)}` : ""}</span>
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
      <button type="button" data-action="click->${this.identifier}#selectNav" data-${this.identifier}-key-param="${item.key}" data-${this.identifier}-label-param="${this.escape(item.label)}"
        class="px-3 py-1.5 min-h-[34px] rounded-lg text-[12px] transition-colors whitespace-nowrap flex items-center gap-1.5 ${item.active ? activeClasses : idleClasses}">
        <span class="material-symbols-outlined text-[16px]">${item.icon}</span>
        <span>${item.label}</span>
      </button>
    `
  }

  renderContextBanner() {
    return `
      <section class="rounded-xl border border-line bg-card p-3 shadow-sm flex flex-col xl:flex-row xl:items-center justify-between gap-3">
        <div class="flex flex-wrap items-center gap-2.5">
          <div class="flex items-center gap-2 rounded-lg border border-line bg-background px-3 py-1.5">
            <span class="w-2 h-2 rounded-full bg-success animate-pulse"></span>
            <span class="text-[11px] font-bold uppercase tracking-wider text-foreground">${translate("Store Open")} • ${translate("Fully Operational")}</span>
          </div>
          <span class="hidden sm:block h-5 w-px bg-line"></span>
          <div class="flex items-center gap-1.5 text-muted-foreground">
            <span class="material-symbols-outlined text-[18px] text-primary">storefront</span>
            <span class="text-[11px] uppercase tracking-wide">${translate("Branch:")}</span>
            <span class="text-[13px] font-semibold text-foreground">${this.escape(this.branchName)}</span>
          </div>
          <span class="hidden sm:block h-5 w-px bg-line"></span>
          <div class="flex items-center gap-1.5 text-muted-foreground">
            <span class="material-symbols-outlined text-[18px] text-success">schedule</span>
            <span class="text-[11px] uppercase tracking-wide">${translate("Current Shift:")}</span>
            <span class="text-[13px] font-semibold text-foreground">${this.currentShift}</span>
          </div>
        </div>
        <div class="flex flex-wrap items-center gap-1.5">
          ${this.renderQuickAction("new_order", "add_shopping_cart", translate("New Store Order"), "bg-primary text-primary-foreground hover:brightness-110", true)}
          ${this.renderQuickAction("restock", "swap_horiz", translate("Request Restock"), "bg-muted text-foreground hover:bg-line")}
          ${this.renderQuickAction("adjustment", "inventory", translate("Stock Adjustment"), "bg-muted text-foreground hover:bg-line")}
          ${this.renderQuickAction("report", "print", translate("Daily Shift Report"), "bg-muted text-foreground hover:bg-line")}
          ${this.renderQuickAction("float", "account_balance_wallet", translate("Float Audit"), "bg-muted text-foreground hover:bg-line")}
        </div>
      </section>
    `
  }

  renderQuickAction(key, icon, label, classes, primary = false) {
    return `
      <button type="button" data-action="click->${this.identifier}#quickAction" data-${this.identifier}-key-param="${key}"
        class="inline-flex items-center gap-1.5 px-3 py-2 min-h-[36px] rounded-lg text-[12px] font-semibold transition-all shadow-sm active:scale-[0.98] ${classes}">
        <span class="material-symbols-outlined text-[17px] ${primary ? "" : "text-muted-foreground"}">${icon}</span>
        <span class="hidden sm:inline">${label}</span>
      </button>
    `
  }

  renderKpis() {
    const kpis = this.kpis
    const delta = kpis.gross_sales_delta_pct
    const deltaLabel = delta === null || delta === undefined
      ? translate("No prior day baseline")
      : `${delta >= 0 ? "+" : ""}${delta}% ${translate("vs yesterday")}`
    const deltaTone = delta === null || delta === undefined || delta >= 0 ? "text-success" : "text-danger"

    return `
      <section class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3">
        ${this.renderKpiCard({
          label: translate("Gross Sales Today"),
          value: this.money(kpis.gross_sales_cents),
          icon: "payments",
          tone: "primary",
          footer: `<span class="${deltaTone} font-semibold">${deltaLabel}</span>`
        })}
        ${this.renderKpiCard({
          label: translate("Active POS Counters"),
          value: `${kpis.active_pos_counters || 0} ${translate("Lanes")}`,
          icon: "point_of_sale",
          tone: "success",
          footer: `${kpis.transactions_count || 0} ${translate("transactions processed")}`
        })}
        ${this.renderKpiCard({
          label: translate("Orders To Fulfill"),
          value: `${kpis.orders_to_fulfill || 0} ${translate("Pending")}`,
          icon: "package_2",
          tone: "warning",
          footer: `<span class="text-primary font-semibold">${kpis.click_collect_count || 0} ${translate("Click & Collect")}</span><span class="text-muted-foreground">•</span><span class="text-success font-semibold">${kpis.delivery_count || 0} ${translate("Delivery")}</span>`
        })}
        ${this.renderKpiCard({
          label: translate("Shelf Stock Alerts"),
          value: `${kpis.shelf_alerts || 0} ${translate("Low")}`,
          icon: "notification_important",
          tone: kpis.shelf_alerts > 0 ? "danger" : "success",
          footer: kpis.shelf_alerts > 0
            ? translate("Restock requisitions need attention")
            : translate("All shelves above threshold")
        })}
        ${this.renderKpiCard({
          label: translate("Store Staff On Duty"),
          value: `${kpis.staff_on_duty || 0} ${translate("Team")}`,
          icon: "badge",
          tone: "info",
          footer: `${this.registers.length} ${translate("registers")} • ${this.staff.length} ${translate("roster entries")}`
        })}
      </section>
    `
  }

  renderKpiCard({ label, value, icon, tone, footer }) {
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
      </div>
    `
  }

  renderFulfillmentSection() {
    return `
      <section class="rounded-xl border border-line bg-card p-3 sm:p-4 shadow-sm flex flex-col gap-3">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <div class="min-w-0">
            <div class="flex items-center gap-2">
              <span class="material-symbols-outlined text-[22px] text-primary">local_shipping</span>
              <h2 class="font-display text-lg font-bold text-foreground tracking-tight">${translate("Store Fulfillment & Customer Orders Queue")}</h2>
            </div>
            <p class="text-[12px] text-muted-foreground mt-0.5">${translate("Real-time local dispatch, click & collect and front-counter reserves")}</p>
          </div>
          <div class="flex items-center gap-1.5">
            <span class="rounded-full bg-primary/10 px-2.5 py-1 text-[11px] font-semibold text-primary">${translate("Priority Feed")}</span>
            <button type="button" data-action="click->${this.identifier}#refreshConsole" class="w-9 h-9 rounded-lg bg-muted hover:bg-line text-muted-foreground flex items-center justify-center transition-colors" title="${translate("Refresh orders")}">
              <span class="material-symbols-outlined text-[18px]">refresh</span>
            </button>
          </div>
        </div>

        <div class="flex flex-col md:flex-row md:items-center justify-between gap-2 rounded-lg bg-muted p-2">
          <div class="flex items-center gap-1 overflow-x-auto p-0.5" id="store-manager-order-tabs">
            ${this.renderOrderTabs()}
          </div>
          <div class="flex items-center gap-1.5">
            <div class="relative flex-1 md:w-64">
              <span class="material-symbols-outlined absolute left-2.5 top-1/2 -translate-y-1/2 text-[18px] text-muted-foreground pointer-events-none">search</span>
              <input id="store-manager-order-search" type="text" value="${this.escape(this.searchQuery)}"
                data-action="input->${this.identifier}#updateSearch keydown.esc->${this.identifier}#clearSearch"
                placeholder="${translate("Scan SKU or Order #...")}"
                class="w-full h-9 pl-9 pr-3 rounded-lg bg-card text-foreground placeholder:text-muted-foreground text-[12px] border border-line focus:outline-none focus:ring-2 focus:ring-primary shadow-sm" />
            </div>
            <button type="button" data-action="click->${this.identifier}#focusScanner" class="w-9 h-9 rounded-lg bg-primary text-primary-foreground flex items-center justify-center hover:brightness-110 transition-colors shadow-sm" title="${translate("Focus barcode scanner input")}">
              <span class="material-symbols-outlined text-[18px]">barcode_scanner</span>
            </button>
          </div>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="bg-muted text-muted-foreground text-[10px] uppercase tracking-wider">
                <th class="py-2.5 px-3 rounded-l-lg font-semibold">${translate("Order ID • Customer")}</th>
                <th class="py-2.5 px-3 font-semibold">${translate("Cargo Details")}</th>
                <th class="py-2.5 px-3 font-semibold">${translate("Channel Type")}</th>
                <th class="py-2.5 px-3 font-semibold">${translate("Live Status • Assignment")}</th>
                <th class="py-2.5 px-3 text-right rounded-r-lg font-semibold">${translate("Manager Action")}</th>
              </tr>
            </thead>
            <tbody id="store-manager-order-rows" class="text-[12px]">
              ${this.renderOrderRows()}
            </tbody>
          </table>
        </div>

        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pt-1 text-[11px] text-muted-foreground">
          <span>${translate("Displaying")} <span data-store-manager-order-count>${this.filteredOrders.length}</span> ${translate("records of")} ${this.ordersTotal} ${translate("today's queue entries")}</span>
          <a href="/companies/${this.companyId}/orders" class="text-primary hover:underline font-semibold flex items-center gap-1">
            ${translate("View all orders")} <span class="material-symbols-outlined text-[15px]">arrow_forward</span>
          </a>
        </div>
      </section>
    `
  }

  renderOrderTabs() {
    const counts = this.orderCounts
    const tabs = [
      { key: "all", label: translate("All Orders"), count: counts.all },
      { key: "click_collect", label: translate("Click & Collect"), count: counts.click_collect },
      { key: "delivery", label: translate("Local Delivery"), count: counts.delivery },
      { key: "completed", label: translate("Completed"), count: counts.completed }
    ]

    return tabs.map((tab) => {
      const active = tab.key === this.orderTab
      return `
        <button type="button" data-action="click->${this.identifier}#setOrderTab" data-${this.identifier}-tab-param="${tab.key}"
          class="px-2.5 py-1.5 min-h-[30px] rounded-md text-[11px] font-semibold whitespace-nowrap transition-all ${active ? "bg-card text-primary shadow-sm border border-line" : "text-muted-foreground hover:bg-card/60 hover:text-foreground"}">
          ${tab.label} (${tab.count})
        </button>
      `
    }).join("")
  }

  renderOrderRows() {
    const orders = this.filteredOrders
    if (orders.length === 0) {
      return `
        <tr>
          <td colspan="5" class="py-8 px-3 text-center text-muted-foreground text-[12px]">${translate("No orders match this view.")}</td>
        </tr>
      `
    }
    return orders.map((order) => this.renderOrderRow(order)).join("")
  }

  renderOrderRow(order) {
    const channelTone = {
      click_collect: "bg-success/10 text-success border-success/20",
      delivery: "bg-primary/10 text-primary border-primary/20",
      phone_hold: "bg-warning/10 text-warning border-warning/20"
    }[order.channel] || "bg-muted text-muted-foreground border-line"

    const statusTone = {
      primary: "bg-primary/10 text-primary",
      success: "bg-success/10 text-success",
      warning: "bg-warning/10 text-warning",
      danger: "bg-danger/10 text-danger",
      info: "bg-info/10 text-info",
      muted: "bg-muted text-muted-foreground"
    }[order.status_tone] || "bg-muted text-muted-foreground"

    const isCompleted = ["paid", "completed"].includes(order.workflow_status)
    const actionClasses = isCompleted
      ? "bg-muted text-foreground hover:bg-line"
      : "bg-primary text-primary-foreground hover:brightness-110"

    return `
      <tr class="border-b border-line last:border-0 hover:bg-muted/60 transition-colors align-top">
        <td class="py-3 px-3">
          <a href="${this.escape(order.order_path)}" class="font-display text-[14px] font-bold text-primary hover:underline">${this.escape(order.code)}</a>
          <div class="text-foreground font-semibold mt-0.5">${this.escape(order.customer_name)}</div>
          <div class="text-[10px] text-muted-foreground truncate max-w-[190px]">${translate("Placed")} ${this.escape(order.placed_at)} • ${this.escape(translate(order.customer_meta))}</div>
        </td>
        <td class="py-3 px-3">
          <div class="text-foreground font-medium">${order.items_count} ${translate("Items")}</div>
          <div class="text-muted-foreground text-[11px]">${this.money(order.total_cents, order.currency)}</div>
          <div class="text-[10px] text-muted-foreground truncate max-w-[150px]">${translate("Order")} ${this.escape(order.code)}</div>
        </td>
        <td class="py-3 px-3">
          <span class="inline-flex items-center gap-1 rounded-full border px-2.5 py-1 text-[10px] font-semibold ${channelTone}">
            <span class="material-symbols-outlined text-[13px]">${order.channel_icon}</span>
            ${this.escape(translate(order.channel_label))}
          </span>
        </td>
        <td class="py-3 px-3">
          <span class="inline-flex items-center gap-1.5 rounded-md px-2 py-0.5 text-[10px] font-bold ${statusTone}">
            <span class="w-1.5 h-1.5 rounded-full bg-current"></span>
            ${this.escape(translate(order.status_label))}
          </span>
          <div class="text-[10px] text-muted-foreground mt-1">${translate("Assigned:")} <strong class="text-foreground">${this.escape(translate(order.assignment))}</strong></div>
        </td>
        <td class="py-3 px-3 text-right">
          <a href="${this.escape(order.order_path)}"
            class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-[11px] font-semibold transition-colors shadow-sm ${actionClasses}">
            ${this.escape(translate(order.action_label))}
            <span class="material-symbols-outlined text-[14px]">chevron_right</span>
          </a>
        </td>
      </tr>
    `
  }

  renderReplenishmentSection() {
    return `
      <section data-store-manager-replenishment class="rounded-xl border border-line bg-card p-3 sm:p-4 shadow-sm flex flex-col gap-3">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <div class="min-w-0">
            <div class="flex items-center gap-2">
              <span class="material-symbols-outlined text-[22px] text-success">shelves</span>
              <h2 class="font-display text-lg font-bold text-foreground tracking-tight">${translate("Shelf Replenishment Requisitions")}</h2>
            </div>
            <p class="text-[12px] text-muted-foreground mt-0.5">${translate("Low shelf stock at this branch, with warehouse availability for the same product")}</p>
          </div>
          <span class="rounded-full bg-success/10 px-3 py-1 text-[11px] font-semibold text-success whitespace-nowrap">
            ${this.kpis.shelf_alerts || this.replenishments.length} ${translate("Low Shelf Triggers Active")}
          </span>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="bg-muted text-muted-foreground text-[10px] uppercase tracking-wider">
                <th class="py-2.5 px-3 rounded-l-lg font-semibold">${translate("SKU • Retail Product")}</th>
                <th class="py-2.5 px-3 text-center font-semibold">${translate("Shelf Stock")}</th>
                <th class="py-2.5 px-3 text-center font-semibold">${translate("Min Threshold")}</th>
                <th class="py-2.5 px-3 text-center font-semibold">${translate("WH Available")}</th>
                <th class="py-2.5 px-3 font-semibold">${translate("Requisition Stage")}</th>
                <th class="py-2.5 px-3 text-right rounded-r-lg font-semibold">${translate("Floor Action")}</th>
              </tr>
            </thead>
            <tbody class="text-[12px]">
              ${this.renderReplenishmentRows()}
            </tbody>
          </table>
        </div>

        <div class="rounded-lg bg-muted p-2.5 flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-[11px] text-muted-foreground">
          <div class="flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[17px] text-success">sync_alt</span>
            <span>${translate("Warehouse availability reflects stock rows outside this branch.")}</span>
          </div>
          <a href="/companies/${this.companyId}/stocks" class="text-primary hover:underline font-semibold">${translate("Open stock ledger")}</a>
        </div>
      </section>
    `
  }

  renderReplenishmentRows() {
    if (this.replenishments.length === 0) {
      return `
        <tr>
          <td colspan="6" class="py-8 px-3 text-center text-muted-foreground text-[12px]">${translate("No shelf stock is below the minimum threshold.")}</td>
        </tr>
      `
    }

    return this.replenishments.map((item) => {
      const stageTone = {
        empty: "bg-danger/10 text-danger",
        reserved: "bg-warning/10 text-warning",
        low: "bg-warning/10 text-warning"
      }[item.stage] || "bg-muted text-muted-foreground"
      const quantityTone = item.shelf_quantity <= 0
        ? "bg-danger text-danger-foreground"
        : item.shelf_quantity <= item.threshold / 2
          ? "bg-danger/10 text-danger"
          : "bg-warning/10 text-warning"

      return `
        <tr class="border-b border-line last:border-0 hover:bg-muted/60 transition-colors align-top">
          <td class="py-3 px-3">
            <div class="font-semibold text-foreground">${this.escape(item.product_name)}</div>
            <div class="text-[10px] text-muted-foreground">${translate("SKU:")} ${this.escape(item.sku)} • ${item.bay ? `${translate("Bay")} ${this.escape(item.bay)}` : "—"}</div>
          </td>
          <td class="py-3 px-3 text-center">
            <span class="inline-flex min-w-[34px] justify-center rounded-md px-2 py-1 font-display text-[15px] font-bold ${quantityTone}">${item.shelf_quantity}</span>
          </td>
          <td class="py-3 px-3 text-center text-muted-foreground font-semibold">${item.threshold} ${translate("units")}</td>
          <td class="py-3 px-3 text-center text-foreground font-bold">${item.warehouse_available} ${translate("units")}</td>
          <td class="py-3 px-3">
            <div class="inline-flex items-center gap-1.5 rounded-md px-2 py-0.5 text-[10px] font-semibold ${stageTone}">
              <span class="material-symbols-outlined text-[14px]">${item.stage_icon}</span>
              ${this.escape(translate(item.stage_label))}
            </div>
            <div class="text-[10px] text-muted-foreground mt-1">${translate("WH:")} ${this.escape(item.warehouse_name)}</div>
          </td>
          <td class="py-3 px-3 text-right">
            <a href="${this.escape(item.stock_path)}"
              class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-[11px] font-semibold transition-colors shadow-sm bg-primary text-primary-foreground hover:brightness-110">
              ${this.escape(translate(item.action_label))}
              <span class="material-symbols-outlined text-[14px]">chevron_right</span>
            </a>
          </td>
        </tr>
      `
    }).join("")
  }

  renderRegistersPanel() {
    return `
      <section class="rounded-xl border border-line bg-card p-3 shadow-sm flex flex-col gap-2">
        <div class="flex items-center justify-between gap-2 pb-2 border-b border-line">
          <div class="flex items-center gap-2">
            <span class="material-symbols-outlined text-[20px] text-primary">point_of_sale</span>
            <h2 class="font-display text-[15px] font-bold text-foreground">${translate("Active Register & POS Status")}</h2>
          </div>
          <span class="w-2.5 h-2.5 rounded-full bg-success"></span>
        </div>
        <div class="flex flex-col gap-2">
          ${this.renderRegisterItems()}
        </div>
        <div class="rounded-lg bg-primary/5 border border-primary/10 p-2.5 flex items-start gap-2">
          <span class="material-symbols-outlined text-[18px] text-primary">lock</span>
          <div class="flex flex-col gap-0.5">
            <span class="text-[12px] font-bold text-primary">${translate("Cash management")}</span>
            <span class="text-[11px] text-muted-foreground">${translate("Safe drops and drawer floats are handled from the POS operation.")}</span>
          </div>
        </div>
      </section>
    `
  }

  renderRegisterItems() {
    if (this.registers.length === 0) {
      return `<div class="rounded-lg bg-muted border border-line p-4 text-center text-[12px] text-muted-foreground">${translate("No register activity today.")}</div>`
    }

    return this.registers.map((register) => `
      <div class="rounded-xl border border-line bg-muted/50 p-2.5 hover:bg-muted transition-colors">
        <div class="flex items-start justify-between gap-2">
          <div class="flex items-center gap-2 min-w-0">
            <span class="w-7 h-7 rounded-lg bg-primary text-primary-foreground flex items-center justify-center font-bold text-[10px] shrink-0">${this.escape(register.number)}</span>
            <div class="min-w-0">
              <h3 class="text-[13px] font-bold text-foreground leading-tight truncate">${this.escape(translate(register.name))}</h3>
              <p class="text-[10px] text-muted-foreground truncate">${translate("Cashier:")} <strong class="text-foreground">${this.escape(register.cashier)}</strong></p>
            </div>
          </div>
          <span class="inline-flex items-center gap-1 rounded-full bg-success/10 px-2 py-0.5 text-[10px] font-bold text-success">
            ${translate("Synced")}
          </span>
        </div>
        <div class="grid grid-cols-2 gap-2 mt-2 rounded-lg border border-line bg-card p-2">
          <div>
            <span class="text-[10px] text-muted-foreground">${translate("Shift Sales")}</span>
            <div class="text-[14px] font-bold text-foreground">${this.money(register.sales_cents, register.currency)}</div>
          </div>
          <div>
            <span class="text-[10px] text-muted-foreground">${translate("Orders Processed")}</span>
            <div class="text-[14px] font-semibold text-foreground">${register.orders_count}</div>
          </div>
        </div>
      </div>
    `).join("")
  }

  renderFootfallPanel() {
    const footfall = this.footfall
    const connected = footfall.connected === true

    return `
      <section class="rounded-xl border border-line bg-card p-3 shadow-sm flex flex-col gap-2">
        <div class="flex items-center justify-between gap-2 pb-2 border-b border-line">
          <div class="flex items-center gap-2">
            <span class="material-symbols-outlined text-[20px] text-success">sensor_occupied</span>
            <h2 class="font-display text-[15px] font-bold text-foreground">${translate("Footfall & Conversion")}</h2>
          </div>
          <span class="rounded-full border border-warning/20 bg-warning/10 px-2 py-0.5 text-[10px] font-semibold text-warning">
            ${connected ? translate("Sensor connected") : translate("Sensor not connected")}
          </span>
        </div>

        <div class="grid grid-cols-2 gap-2">
          <div class="rounded-xl border border-line bg-muted p-2.5">
            <span class="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">${translate("Today's Visitors")}</span>
            <div class="font-display text-2xl font-extrabold text-foreground mt-1">${connected ? footfall.visitors : "—"}</div>
            <div class="text-[10px] text-muted-foreground mt-0.5">${translate("Optical sensor")}</div>
          </div>
          <div class="rounded-xl border border-line bg-muted p-2.5">
            <span class="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">${translate("Store Conversion")}</span>
            <div class="font-display text-2xl font-extrabold text-primary mt-1">${connected && footfall.conversion_pct !== null ? `${footfall.conversion_pct}%` : "—"}</div>
            <div class="text-[10px] text-muted-foreground mt-0.5">${footfall.buyers || 0} ${translate("buyers")}</div>
          </div>
        </div>

        <div class="rounded-xl border border-line bg-muted p-2.5 flex flex-col gap-2">
          <div class="flex items-center justify-between gap-2 text-[10px] text-muted-foreground">
            <span class="font-semibold">${translate("Hourly Order Volume")}</span>
            <span>${translate("Peak:")} ${this.peakHourLabel}</span>
          </div>
          <div class="h-20 w-full flex items-end gap-1 pt-1">
            ${this.hourly.map((bucket) => this.renderHourBar(bucket)).join("")}
          </div>
        </div>

        <p class="text-[10px] text-muted-foreground">${this.escape(translate(footfall.note || ""))}</p>
      </section>
    `
  }

  get peakHourLabel() {
    const peak = this.hourly.reduce((best, bucket) => {
      if (!best || bucket.orders_count > best.orders_count) return bucket
      return best
    }, null)

    if (!peak || peak.orders_count === 0) return "—"
    return `${peak.label} (${peak.orders_count})`
  }

  renderHourBar(bucket) {
    const height = Math.max(6, Math.round((bucket.orders_count / this.maxHourlyOrders) * 64))
    const currentHour = this.currentHour
    const isCurrent = bucket.hour === currentHour
    const isFuture = bucket.hour > currentHour
    const barClass = isCurrent
      ? "bg-success"
      : isFuture
        ? "bg-line opacity-60"
        : "bg-primary/50"

    return `
      <div class="flex-1 flex flex-col items-center gap-1 group" title="${bucket.orders_count} ${translate("orders")}">
        <div class="w-full rounded-t transition-all ${barClass} group-hover:bg-primary" style="height: ${height}px"></div>
        <span class="text-[9px] ${isCurrent ? "text-success font-bold" : "text-muted-foreground"}">${isCurrent ? translate("Now") : bucket.label}</span>
      </div>
    `
  }

  renderStaffPanel() {
    return `
      <section class="rounded-xl border border-line bg-card p-3 shadow-sm flex flex-col gap-2">
        <div class="flex items-center justify-between gap-2 pb-2 border-b border-line">
          <div class="flex items-center gap-2">
            <span class="material-symbols-outlined text-[20px] text-primary">diversity_3</span>
            <h2 class="font-display text-[15px] font-bold text-foreground">${translate("On-Duty Shift Roster")}</h2>
          </div>
          <span class="text-[10px] font-semibold text-primary">${this.staff.length} ${translate("Staff")}</span>
        </div>
        <div class="flex flex-col gap-1.5">
          ${this.renderStaffItems()}
        </div>
        <button type="button" data-action="click->${this.identifier}#openAttendance"
          class="w-full py-2 min-h-[36px] rounded-lg bg-muted hover:bg-line text-foreground text-[11px] font-semibold transition-colors flex items-center justify-center gap-1.5">
          <span class="material-symbols-outlined text-[17px]">manage_accounts</span>
          ${translate("Manage Shift Attendance & Overtime")}
        </button>
      </section>
    `
  }

  renderStaffItems() {
    if (this.staff.length === 0) {
      return `<div class="rounded-lg bg-muted border border-line p-4 text-center text-[12px] text-muted-foreground">${translate("No employees are assigned to this branch.")}</div>`
    }

    return this.staff.map((employee) => {
      const statusTone = {
        success: "bg-success/10 text-success",
        primary: "bg-primary/10 text-primary"
      }[employee.status_tone] || "bg-muted text-muted-foreground"

      return `
        <div class="flex items-center justify-between gap-2 rounded-lg bg-muted/50 hover:bg-muted p-2 transition-colors">
          <div class="flex items-center gap-2 min-w-0">
            <div class="w-8 h-8 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-[10px] shrink-0">
              ${this.escape(this.initialsFor(employee.name))}
            </div>
            <div class="min-w-0">
              <div class="text-[12px] font-bold text-foreground truncate">${this.escape(employee.name)}</div>
              <div class="text-[10px] text-muted-foreground truncate">${this.escape(translate(employee.role))} • ${this.escape(employee.code)}</div>
            </div>
          </div>
          <span class="rounded-full px-2 py-0.5 text-[10px] font-bold whitespace-nowrap ${statusTone}">${this.escape(translate(employee.status_label))}</span>
        </div>
      `
    }).join("")
  }

  renderAuditStrip() {
    const generatedAt = this.store.generated_at
      ? this.timeLabel(this.store.generated_at)
      : this.timeLabel(new Date().toISOString())

    return `
      <section class="rounded-xl border border-line bg-muted p-3 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-2 text-[11px] text-muted-foreground">
        <div class="flex flex-wrap items-center gap-2">
          <span class="flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[17px] text-success">cloud_done</span>
            ${translate("Live data synced from the regional cloud.")}
          </span>
          <span class="hidden lg:inline text-line">•</span>
          <span class="hidden lg:flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[16px]">schedule</span>
            ${translate("Refreshed at")} ${this.escape(generatedAt)}
          </span>
          <span class="hidden lg:inline text-line">•</span>
          <span class="hidden lg:flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[16px]">receipt_long</span>
            ${translate("Operation:")} ${this.escape(this.operation?.code || "—")}
          </span>
        </div>
        <div class="flex items-center gap-2">
          <span class="font-semibold text-foreground">${translate("Branch:")} ${this.escape(this.branchName)}</span>
          <button type="button" data-action="click->${this.identifier}#diagnostics" class="rounded bg-card px-2.5 py-1 text-[10px] font-semibold text-foreground border border-line hover:bg-line transition-colors">
            ${translate("Diagnostics")}
          </button>
        </div>
      </section>
    `
  }

  // --- Interactions -----------------------------------------------------------------

  selectNav(event) {
    if (event.params.key === "overview") return
    toast({ type: "info", message: `${event.params.label} ${translate("is coming soon.")}` })
  }

  async refreshConsole(event) {
    if (event) event.preventDefault()
    try {
      await this.reloadConsole()
      toast({ type: "success", message: translate("Store console refreshed.") })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to refresh the store console.") })
    }
  }

  setOrderTab(event) {
    this.orderTab = event.params.tab
    const tabs = document.getElementById("store-manager-order-tabs")
    const rows = document.getElementById("store-manager-order-rows")
    const footer = this.element.querySelector("[data-store-manager-order-count]")

    if (tabs) tabs.innerHTML = this.renderOrderTabs()
    if (rows) rows.innerHTML = this.renderOrderRows()
    if (footer) footer.textContent = this.filteredOrders.length
  }

  updateSearch(event) {
    this.searchQuery = event.target.value || ""
    const rows = document.getElementById("store-manager-order-rows")
    if (rows) rows.innerHTML = this.renderOrderRows()
    const footer = this.element.querySelector("[data-store-manager-order-count]")
    if (footer) footer.textContent = this.filteredOrders.length
  }

  clearSearch(event) {
    if (event) event.preventDefault()
    this.searchQuery = ""
    const input = document.getElementById("store-manager-order-search")
    if (input) input.value = ""
    const rows = document.getElementById("store-manager-order-rows")
    if (rows) rows.innerHTML = this.renderOrderRows()
    const footer = this.element.querySelector("[data-store-manager-order-count]")
    if (footer) footer.textContent = this.filteredOrders.length
  }

  focusScanner() {
    const input = document.getElementById("store-manager-order-search")
    if (!input) return
    input.focus()
    input.select()
    toast({ type: "info", message: translate("Scanner input ready. Scan or type an order number.") })
  }

  quickAction(event) {
    const key = event.params.key

    if (key === "new_order") {
      window.location.href = `/companies/${this.companyId}/orders/new`
      return
    }
    if (key === "restock") {
      this.element.querySelector("[data-store-manager-replenishment]")?.scrollIntoView({ behavior: "smooth", block: "start" })
      return
    }
    if (key === "adjustment") {
      window.location.href = `/companies/${this.companyId}/stock_adjustments`
      return
    }
    if (key === "report") {
      toast({ type: "info", message: translate("Daily shift report export is not connected yet.") })
      return
    }
    if (key === "float") {
      toast({ type: "info", message: translate("Float audit is handled from the POS operation.") })
    }
  }

  openAttendance() {
    window.location.href = `/companies/${this.companyId}/attendance_months`
  }

  diagnostics() {
    toast({ type: "info", message: translate("Store manager diagnostics are not connected yet.") })
  }

  // --- Helpers ----------------------------------------------------------------------

  money(minorUnits, currency = this.currency) {
    return Helpers.formatMoney(minorUnits || 0, currency)
  }

  timeLabel(value) {
    const date = new Date(value)
    if (Number.isNaN(date.getTime())) return "—"
    return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
  }

  initialsFor(name) {
    const parts = String(name || "").trim().split(/\s+/).filter(Boolean)
    if (parts.length === 0) return "?"
    return parts.slice(0, 2).map((part) => part[0].toUpperCase()).join("")
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
