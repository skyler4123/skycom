import { Controller } from "@hotwired/stimulus"

// Store Manager — one branch's retail command screen for one business day.
// Every number comes from the payload; every remaining control either opens a
// real screen or writes a real record. No invented registers, shifts, sensors or
// cloud status.
//
// Serves Stimulus: Companies_Operations_StoreManager_ShowController
// Depends on BE: Companies::Operations::StoreManagerController#show/#queue/
//               #mark_ready/#hand_over/#create_replenishment/#save_shift_close
// Endpoints: Helpers.store_manager_company_operation_path and the
//            store_manager_* action helpers.
// Docs: docs/OPERATIONS.md, docs/business_analysis/06-store-manager.md
export default class Companies_Operations_StoreManager_ShowController extends Controller {
  /** @type {any | null} */ operation = null
  /** @type {any | null} */ appointment = null
  /** @type {any} */ store = {}
  /** @type {string | null} */ companyId = null
  /** @type {string | null} */ operationId = null
  /** @type {string | null} */ branchId = null
  /** @type {string | null} */ selectedDate = null
  /** @type {string} */ orderTab = "all"
  /** @type {string} */ searchQuery = ""
  /** @type {number} */ queuePage = 1
  /** @type {number | null} */ searchTimer = null
  /** @type {number | null} */ refreshTimer = null
  /** @type {boolean} */ refreshFailed = false
  /** @type {string | null} */ actionPending = null
  /** @type {boolean} */ closeSheetOpen = false
  /** @type {any | null} */ replenishmentSheet = null

  async connect() {
    const pathParts = window.location.pathname.split("/")
    this.companyId = this.element.dataset.companyId || pathParts[2]
    this.operationId = this.element.dataset.operationId || pathParts[5]
    this.branchId = new URLSearchParams(window.location.search).get("branch_id")

    try {
      await this.loadConsole()
      this.renderContent()
      this.startRefreshTimer()
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      this.element.innerHTML = `<div class="flex items-center justify-center h-screen text-danger text-lg font-semibold px-6 text-center">${translate("Failed to load the store manager console.")}${detail ? `: ${this.escape(detail)}` : ""}</div>`
    }
  }

  disconnect() {
    if (this.searchTimer) window.clearTimeout(this.searchTimer)
    if (this.refreshTimer) window.clearInterval(this.refreshTimer)
  }

  // --- Data -------------------------------------------------------------------

  async loadConsole(extra = {}) {
    const params = {
      ...(this.branchId ? { branch_id: this.branchId } : {}),
      ...(this.selectedDate ? { date: this.selectedDate } : {}),
      tab: this.orderTab,
      q: this.searchQuery,
      page: this.queuePage,
      ...extra
    }
    const response = await fetchJson(
      Helpers.store_manager_company_operation_path(this.companyId, this.operationId, params)
    )
    this.operation = response.operation
    this.appointment = response.appointment
    this.store = response.store_manager || {}
    this.selectedDate = this.store.date || this.selectedDate
    this.refreshFailed = false
    return response
  }

  async reloadConsole() {
    const scroll = window.scrollY
    await this.loadConsole()
    this.renderContent()
    window.scrollTo(0, scroll)
  }

  startRefreshTimer() {
    if (this.refreshTimer) window.clearInterval(this.refreshTimer)
    this.refreshTimer = window.setInterval(() => this.autoRefresh(), 60_000)
  }

  async autoRefresh() {
    if (this.overlayOpen()) return
    const active = document.activeElement
    if (active && ["INPUT", "TEXTAREA", "SELECT"].includes(active.tagName)) return

    try {
      await this.loadConsole()
      this.renderContent()
    } catch (error) {
      this.refreshFailed = true
      this.updateFooter()
    }
  }

  async refreshConsole() {
    if (this.overlayOpen()) return

    try {
      await this.loadConsole()
      this.renderContent()
      toast({ type: "success", message: translate("Store console refreshed.") })
    } catch (error) {
      this.refreshFailed = true
      this.updateFooter()
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to refresh the store console.") })
    }
  }

  updateFooter() {
    const footer = this.element.querySelector('[data-operation-block="footer"]')
    if (footer) footer.outerHTML = this.renderFooter()
  }

  // --- Derived values ---------------------------------------------------------

  get branchName() {
    return this.store.branch?.name || this.appointment?.location?.name || translate("Branch not resolved")
  }

  get branchCode() {
    return this.store.branch?.code || ""
  }

  get companyName() {
    return this.store.company?.name || Helpers.currentCompany()?.name || translate("Company")
  }

  get currency() {
    return this.store.currency || "usd"
  }

  get location() {
    return this.appointment?.location || {}
  }

  get readOnly() {
    return this.store.read_only === true || !this.store.today
  }

  get dateLabel() {
    return Helpers.dateOnly(this.store.date, "ddd, MMM D, YYYY", this.location)
  }

  get todayIso() {
    return Helpers.locationTime(this.store.now, "YYYY-MM-DD", this.location)
  }

  get kpis() {
    return this.store.kpis || {}
  }

  get queue() {
    return this.store.queue || { orders: [], counts: {}, day_counts: {}, pagination: {} }
  }

  get queueOrders() {
    return this.queue.orders || []
  }

  get queueCounts() {
    return this.queue.counts || {}
  }

  get queuePagination() {
    return this.queue.pagination || {}
  }

  get shelf() {
    return this.store.shelf || { rows: [] }
  }

  get shelfRows() {
    return this.shelf.rows || []
  }

  get cashiers() {
    return this.store.cashiers || []
  }

  get staff() {
    return this.store.staff || []
  }

  get hourly() {
    return this.store.hourly || { buckets: [], peak: null, current_hour: null }
  }

  get footfall() {
    return this.store.footfall || { connected: false, buyers: 0 }
  }

  get shift() {
    return this.store.shift
  }

  get shiftClose() {
    return this.store.shift_close
  }

  get userName() {
    return this.element.dataset.userName || Helpers.currentUser()?.name || Helpers.currentUser()?.email || translate("Employee")
  }

  get userRole() {
    const role = this.element.dataset.userRole || Helpers.currentEmployee()?.category?.name
    return role && role !== "Employees" ? role : translate("No role assigned")
  }

  get maxHourlyOrders() {
    return Math.max(1, ...this.hourly.buckets.map((bucket) => bucket.orders_count || 0))
  }

  get closeData() {
    return this.shiftClose
  }

  get closeSales() {
    return this.closeData?.sales || {}
  }

  get closeStaff() {
    return this.closeData?.staff || []
  }

  get closeShelfRows() {
    return this.closeData?.shelf_rows || []
  }

  get closeHandovers() {
    return this.closeData?.open_handovers || []
  }

  // --- Rendering --------------------------------------------------------------

  renderContent() {
    this.element.innerHTML = `
      <div class="min-h-screen bg-background text-foreground font-sans print:hidden" data-store-manager-app>
        ${this.renderHeader()}
        <main class="w-full px-4 lg:px-6 py-4 flex flex-col gap-4">
          <div class="flex flex-wrap items-end justify-between gap-2" data-operation-block="heading">
            <div>
              <h1 class="font-display text-2xl font-extrabold tracking-tight text-foreground">${translate("Store overview")}</h1>
              <p class="text-[12px] text-muted-foreground">${this.escape(this.branchName)} · ${this.escape(this.dateLabel)}</p>
            </div>
          </div>
          ${this.renderContext()}
          <div data-operation-block="kpis">${this.renderKpis()}</div>
          <div class="grid grid-cols-1 lg:grid-cols-12 gap-4 items-start">
            <div data-store-manager-main-column class="lg:col-span-8 flex flex-col gap-4 min-w-0">
              ${this.renderQueueSection()}
              ${this.renderShelfSection()}
            </div>
            <div data-store-manager-side-column class="lg:col-span-4 flex flex-col gap-4 min-w-0">
              ${this.renderCashiersSection()}
              ${this.renderHourlySection()}
              ${this.renderRosterSection()}
              ${this.renderFootfall()}
            </div>
          </div>
          ${this.renderFooter()}
        </main>
        ${this.renderCloseSheet()}
        ${this.renderReplenishmentSheet()}
      </div>
      ${this.renderPrintRoot()}
    `
  }

  renderHeader() {
    return `
      <header class="sticky top-0 z-40 border-b border-line bg-background/85 backdrop-blur-xl" data-operation-block="header">
        <div class="w-full px-4 lg:px-6">
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
                  <span class="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">${translate("Company")}</span>
                  <span class="text-[13px] font-semibold text-foreground truncate">${this.escape(this.companyName)}</span>
                </div>
              </div>
              <div class="hidden xl:flex items-center gap-1.5 text-muted-foreground min-w-0">
                <span class="material-symbols-outlined text-[18px]">storefront</span>
                <span class="text-[12px] font-medium truncate">${this.escape(this.branchName)}${this.branchCode ? ` · ${this.escape(this.branchCode)}` : ""}</span>
              </div>
            </div>
            <div class="flex items-center gap-2">
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
        </div>
      </header>
    `
  }

  renderContext() {
    return `
      <section class="rounded-xl border border-line bg-card p-3 shadow-sm flex flex-col xl:flex-row xl:items-center justify-between gap-3" data-operation-block="context">
        <div class="flex flex-wrap items-center gap-2.5">
          <div class="flex items-center gap-1.5 text-muted-foreground">
            <span class="material-symbols-outlined text-[18px] text-primary">storefront</span>
            <span class="text-[13px] font-bold text-foreground">${this.escape(this.branchName)}</span>
          </div>
          <span class="hidden sm:block h-5 w-px bg-line"></span>
          ${this.renderShiftChip()}
          <span class="hidden sm:block h-5 w-px bg-line"></span>
          <div class="flex items-center gap-1.5">
            <label class="text-[11px] uppercase tracking-wide text-muted-foreground" for="store-manager-date">${translate("Date")}</label>
            <input id="store-manager-date" type="date" value="${this.escape(this.store.date)}" max="${this.escape(this.todayIso)}"
              data-action="change->${this.identifier}#selectDate"
              class="h-9 rounded-lg border border-line bg-card px-2 text-[12px] text-foreground" />
            ${this.readOnly ? `<span class="rounded-full border border-line bg-muted px-2 py-0.5 text-[10px] font-semibold text-muted-foreground">${translate("Read-only")}</span>` : ""}
          </div>
        </div>
        <div class="flex flex-wrap items-center gap-1.5">
          ${this.readOnly ? this.renderReadOnlyActions() : this.renderTodayActions()}
        </div>
      </section>
    `
  }

  renderShiftChip() {
    if (!this.shift) {
      return `<span class="inline-flex items-center gap-1.5 rounded-lg border border-line bg-muted px-2.5 py-1.5 text-[12px] font-semibold text-muted-foreground">
        <span class="material-symbols-outlined text-[16px]">schedule</span>${translate("No shift scheduled")}
      </span>`
    }

    const starts = this.time(this.shift.starts_at, "HH:mm")
    const ends = this.time(this.shift.ends_at, "HH:mm")
    const name = this.shift.shift_count > 1 ? translate("Multiple shifts") : translate(this.shift.name || "Scheduled shift")
    return `<span class="inline-flex items-center gap-1.5 rounded-lg border border-line bg-muted px-2.5 py-1.5 text-[12px] font-semibold text-foreground" data-store-manager-shift>
      <span class="material-symbols-outlined text-[16px] text-primary">schedule</span>
      ${this.escape(name)} · ${this.escape(starts)}–${this.escape(ends)} · ${this.shift.checked_in_count || 0} ${translate("checked in")}
    </span>`
  }

  renderTodayActions() {
    return `
      <a href="${Helpers.new_company_order_path(this.companyId)}" class="inline-flex items-center gap-1.5 px-3 py-2 min-h-[36px] rounded-lg text-[12px] font-semibold bg-muted text-foreground hover:bg-line transition-colors">
        <span class="material-symbols-outlined text-[17px] text-muted-foreground">add_shopping_cart</span>${translate("New Store Order")}
      </a>
      <button type="button" data-action="click->${this.identifier}#scrollToShelf" class="inline-flex items-center gap-1.5 px-3 py-2 min-h-[36px] rounded-lg text-[12px] font-semibold bg-muted text-foreground hover:bg-line transition-colors">
        <span class="material-symbols-outlined text-[17px] text-muted-foreground">shelves</span>${translate("Show low stock")}
      </button>
      <a href="${Helpers.company_stock_adjustments_path(this.companyId)}" class="inline-flex items-center gap-1.5 px-3 py-2 min-h-[36px] rounded-lg text-[12px] font-semibold bg-muted text-foreground hover:bg-line transition-colors">
        <span class="material-symbols-outlined text-[17px] text-muted-foreground">inventory</span>${translate("Stock Adjustment")}
      </a>
      <button type="button" data-action="click->${this.identifier}#openCloseSheet" class="inline-flex items-center gap-1.5 px-3 py-2 min-h-[36px] rounded-lg text-[12px] font-semibold bg-primary text-primary-foreground hover:brightness-110 transition-all">
        <span class="material-symbols-outlined text-[17px]">point_of_sale</span>${translate("Close shift")}
      </button>
    `
  }

  renderReadOnlyActions() {
    if (!this.shiftClose?.saved) return ""
    return `<button type="button" data-action="click->${this.identifier}#openCloseSheet" class="inline-flex items-center gap-1.5 px-3 py-2 min-h-[36px] rounded-lg text-[12px] font-semibold bg-muted text-foreground hover:bg-line transition-colors">
      <span class="material-symbols-outlined text-[17px]">receipt_long</span>${translate("View close report")}
    </button>`
  }

  renderKpis() {
    const kpis = this.kpis
    const delta = kpis.gross_sales_delta_pct
    const deltaLabel = delta === null || delta === undefined ? "" : `${delta >= 0 ? "+" : ""}${delta}% ${translate("vs yesterday")}`
    const deltaTone = delta === null || delta === undefined || delta >= 0 ? "text-success" : "text-danger"

    return `
      <section class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3">
        ${this.renderKpiCard({
          key: "gross_sales",
          label: translate("Gross sales"),
          value: this.money(kpis.gross_sales_cents),
          icon: "payments",
          tone: "primary",
          footer: deltaLabel ? `<span class="${deltaTone} font-semibold">${this.escape(deltaLabel)}</span>` : ""
        })}
        ${this.renderKpiCard({
          key: "cashiers",
          label: translate("Cashiers"),
          value: String(kpis.cashiers_count || 0),
          icon: "point_of_sale",
          tone: "success",
          footer: `${kpis.paid_orders_count || 0} ${translate("paid orders")}`
        })}
        ${this.renderKpiCard({
          key: "to_hand_over",
          label: translate("To hand over"),
          value: String(kpis.orders_to_hand_over || 0),
          icon: "package_2",
          tone: "warning",
          footer: `${kpis.click_collect_count || 0} ${translate("Click & Collect")} · ${kpis.local_delivery_count || 0} ${translate("Local Delivery")} · ${kpis.phone_hold_count || 0} ${translate("Phone Hold")}`
        })}
        ${this.renderKpiCard({
          key: "shelf_alerts",
          label: translate("Shelf alerts"),
          value: String(kpis.shelf_alerts || 0),
          icon: "notification_important",
          tone: kpis.shelf_alerts > 0 ? "danger" : "success",
          footer: kpis.shelf_alerts > 0 ? translate("Rows at or below their reorder point") : translate("All shelves above their minimum")
        })}
        ${this.renderKpiCard({
          key: "on_duty",
          label: translate("On duty"),
          value: String(kpis.staff_on_duty || 0),
          icon: "badge",
          tone: "info",
          footer: this.readOnly ? translate("Checked in on this date") : translate("Checked in on a shift covering now")
        })}
      </section>
    `
  }

  renderKpiCard({ key, label, value, icon, tone, footer }) {
    const tones = {
      primary: { accent: "bg-primary", icon: "text-primary bg-primary/10" },
      success: { accent: "bg-success", icon: "text-success bg-success/10" },
      warning: { accent: "bg-warning", icon: "text-warning bg-warning/10" },
      danger: { accent: "bg-danger", icon: "text-danger bg-danger/10" },
      info: { accent: "bg-info", icon: "text-info bg-info/10" }
    }
    const toneClass = tones[tone] || tones.primary

    return `
      <div class="relative overflow-hidden rounded-xl border border-line bg-card p-3 shadow-sm flex flex-col justify-between group hover:shadow-md transition-shadow" data-kpi="${key}">
        <span class="absolute left-0 top-0 h-full w-1.5 ${toneClass.accent}"></span>
        <div class="flex items-start justify-between gap-2 pl-1">
          <span class="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">${label}</span>
          <span class="w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${toneClass.icon}">
            <span class="material-symbols-outlined text-[19px]">${icon}</span>
          </span>
        </div>
        <div class="mt-2 pl-1">
          <div class="font-display text-2xl font-extrabold tracking-tight text-foreground" data-kpi-value>${value}</div>
          <div class="flex flex-wrap items-center gap-1.5 mt-1 text-[11px] text-muted-foreground">${footer || ""}</div>
        </div>
      </div>
    `
  }

  // --- Queue ------------------------------------------------------------------

  renderQueueSection() {
    return `
      <section class="rounded-xl border border-line bg-card p-3 sm:p-4 shadow-sm flex flex-col gap-3" data-operation-block="queue">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <div class="min-w-0">
            <div class="flex items-center gap-2">
              <span class="material-symbols-outlined text-[22px] text-primary">local_shipping</span>
              <h2 class="font-display text-lg font-bold text-foreground tracking-tight">${translate("Fulfillment queue")}</h2>
            </div>
            <p class="text-[12px] text-muted-foreground mt-0.5">${translate("Open orders created on this branch day.")}</p>
          </div>
          <div class="flex items-center gap-1.5">
            <button type="button" data-store-manager-refresh data-action="click->${this.identifier}#refreshConsole" class="w-9 h-9 rounded-lg bg-muted hover:bg-line text-muted-foreground flex items-center justify-center transition-colors" title="${translate("Refresh now")}" aria-label="${translate("Refresh now")}">
              <span class="material-symbols-outlined text-[18px]">refresh</span>
            </button>
            <a href="${Helpers.company_orders_path(this.companyId)}" class="text-[11px] font-semibold text-primary hover:underline">${translate("Open orders")}</a>
          </div>
        </div>

        <div class="flex flex-col md:flex-row md:items-center justify-between gap-2 rounded-lg bg-muted p-2">
          <div class="flex items-center gap-1 overflow-x-auto p-0.5" id="store-manager-order-tabs">
            ${this.renderQueueTabs()}
          </div>
          <div class="flex items-center gap-1.5">
            <div class="relative flex-1 md:w-64">
              <span class="material-symbols-outlined absolute left-2.5 top-1/2 -translate-y-1/2 text-[18px] text-muted-foreground pointer-events-none">search</span>
              <input id="store-manager-order-search" type="text" value="${this.escape(this.searchQuery)}"
                data-action="input->${this.identifier}#scheduleSearch keydown.esc->${this.identifier}#clearSearch"
                placeholder="${translate("Scan or type a code")}"
                class="w-full h-9 pl-9 pr-3 rounded-lg bg-card text-foreground placeholder:text-muted-foreground text-[12px] border border-line focus:outline-none focus:ring-2 focus:ring-primary shadow-sm" />
            </div>
            <button type="button" data-action="click->${this.identifier}#focusScanner" class="w-9 h-9 rounded-lg bg-primary text-primary-foreground flex items-center justify-center hover:brightness-110 transition-colors shadow-sm" title="${translate("Focus search")}" aria-label="${translate("Focus search")}">
              <span class="material-symbols-outlined text-[18px]">barcode_scanner</span>
            </button>
          </div>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="bg-muted text-muted-foreground text-[10px] uppercase tracking-wider">
                <th class="py-2.5 px-3 rounded-l-lg font-semibold">${translate("Order · Customer")}</th>
                <th class="py-2.5 px-3 font-semibold">${translate("Items · Invoice")}</th>
                <th class="py-2.5 px-3 font-semibold">${translate("Channel")}</th>
                <th class="py-2.5 px-3 font-semibold">${translate("Fulfilment · Payment")}</th>
                <th class="py-2.5 px-3 text-right rounded-r-lg font-semibold">${translate("Action")}</th>
              </tr>
            </thead>
            <tbody id="store-manager-order-rows" class="text-[12px]">
              ${this.renderQueueRows()}
            </tbody>
          </table>
        </div>

        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pt-1 text-[11px] text-muted-foreground">
          <span>${this.renderQueueCount()}</span>
          <div class="flex items-center gap-2">
            <button type="button" data-action="click->${this.identifier}#previousQueuePage" ${this.queuePagination.previous ? "" : "disabled"}
              class="px-2 py-1 rounded-md bg-muted text-foreground disabled:opacity-40 disabled:cursor-not-allowed">${translate("Previous")}</button>
            <span>${this.queuePagination.pages ? `${translate("Page")} ${this.queuePagination.page} / ${this.queuePagination.pages}` : ""}</span>
            <button type="button" data-action="click->${this.identifier}#nextQueuePage" ${this.queuePagination.next ? "" : "disabled"}
              class="px-2 py-1 rounded-md bg-muted text-foreground disabled:opacity-40 disabled:cursor-not-allowed">${translate("Next")}</button>
          </div>
        </div>
        <div class="flex flex-col gap-1 text-[10px] text-muted-foreground">
          <span>${translate("Payment and cancellation stay on POS and the order page.")}</span>
          ${this.queue.search_capped ? `<span class="text-warning font-semibold">${translate("Search is limited to the first 1,000 matches.")}</span>` : ""}
        </div>
      </section>
    `
  }

  renderQueueTabs() {
    const counts = this.queueCounts
    const tabs = [
      { key: "all", label: translate("All Orders"), count: counts.all || 0 },
      { key: "click_collect", label: translate("Click & Collect"), count: counts.click_collect || 0 },
      { key: "local_delivery", label: translate("Local Delivery"), count: counts.local_delivery || 0 },
      { key: "completed", label: translate("Completed"), count: counts.completed || 0 }
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

  renderQueueRows() {
    const orders = this.queueOrders
    if (orders.length === 0) {
      const message = this.searchQuery
        ? translate("No orders match this search.")
        : (this.orderTab === "completed" ? translate("No orders have been handed over for this date.") : translate("No orders are waiting for handover."))
      return `<tr><td colspan="5" class="py-8 px-3 text-center text-muted-foreground text-[12px]">${message}</td></tr>`
    }
    return orders.map((order) => this.renderQueueRow(order)).join("")
  }

  renderQueueRow(order) {
    const channelTone = {
      click_collect: "bg-success/10 text-success border-success/20",
      local_delivery: "bg-primary/10 text-primary border-primary/20",
      phone_hold: "bg-warning/10 text-warning border-warning/20"
    }[order.channel_key] || "bg-muted text-muted-foreground border-line"

    const fulfillmentTone = {
      success: "bg-success/10 text-success",
      warning: "bg-warning/10 text-warning",
      muted: "bg-muted text-muted-foreground"
    }[order.fulfillment_tone] || "bg-muted text-muted-foreground"

    const paymentTone = order.payment_status === "paid" ? "bg-success/10 text-success" : "bg-warning/10 text-warning"

    return `
      <tr class="border-b border-line last:border-0 hover:bg-muted/60 transition-colors align-top" data-order-code="${this.escape(order.code)}">
        <td class="py-3 px-3">
          <a href="${this.escape(order.order_path)}" class="font-display text-[14px] font-bold text-primary hover:underline">${this.escape(order.code)}</a>
          <div class="text-foreground font-semibold mt-0.5">${this.escape(order.customer_name)}</div>
          <div class="text-[10px] text-muted-foreground truncate max-w-[190px]">${translate("Placed")} ${this.escape(this.time(order.placed_at))} · ${this.escape(order.customer_meta)}</div>
          <div class="text-[10px] text-muted-foreground mt-0.5">${translate("Assigned:")} <strong class="text-foreground">${this.escape(order.assignment)}</strong></div>
        </td>
        <td class="py-3 px-3">
          <div class="text-foreground font-medium">${order.items_count} ${translate("items")}</div>
          <div class="text-muted-foreground text-[11px]">${order.total_cents == null ? translate("Not invoiced") : this.money(order.total_cents, order.currency)}</div>
          ${order.invoice_code ? `<div class="text-[10px] text-muted-foreground truncate max-w-[150px]">${this.escape(order.invoice_code)}</div>` : ""}
        </td>
        <td class="py-3 px-3">
          <span class="inline-flex items-center gap-1 rounded-full border px-2.5 py-1 text-[10px] font-semibold ${channelTone}">
            <span class="material-symbols-outlined text-[13px]">${order.channel_icon}</span>
            ${this.escape(translate(order.channel_label))}
          </span>
        </td>
        <td class="py-3 px-3">
          <div class="flex flex-wrap items-center gap-1">
            <span class="inline-flex items-center rounded-md px-2 py-0.5 text-[10px] font-bold ${fulfillmentTone}">${this.escape(translate(order.fulfillment_label))}</span>
            <span class="inline-flex items-center rounded-md px-2 py-0.5 text-[10px] font-bold ${paymentTone}">${this.escape(translate(order.payment_label))}</span>
          </div>
          ${order.hand_over_blocked_reason ? `<div class="text-[10px] text-warning font-semibold mt-1">${this.escape(translate(order.hand_over_blocked_reason))}</div>` : ""}
        </td>
        <td class="py-3 px-3 text-right">
          <div class="flex flex-col items-end gap-1">
            <a href="${this.escape(order.order_path)}" class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-[11px] font-semibold bg-muted text-foreground hover:bg-line transition-colors">
              ${translate("View order")}
            </a>
            ${order.can_mark_ready ? `<button type="button" data-action="click->${this.identifier}#markReady" data-${this.identifier}-order-id-param="${order.id}"
              class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-[11px] font-semibold bg-muted text-foreground hover:bg-line transition-colors disabled:opacity-50">
              ${translate("Mark ready")}
            </button>` : ""}
            ${order.can_hand_over ? `<button type="button" data-action="click->${this.identifier}#handOver" data-${this.identifier}-order-id-param="${order.id}"
              class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-[11px] font-semibold bg-success text-success-foreground hover:brightness-110 transition-colors disabled:opacity-50">
              ${translate("Hand over")}
            </button>` : ""}
          </div>
        </td>
      </tr>
    `
  }

  renderQueueCount() {
    const pagination = this.queuePagination
    if (!pagination.count) return translate("Showing 0 of 0")
    return `${translate("Showing")} ${pagination.from}–${pagination.to} ${translate("of")} ${pagination.count}`
  }

  // --- Shelf ------------------------------------------------------------------

  renderShelfSection() {
    return `
      <section data-operation-block="shelf" class="rounded-xl border border-line bg-card p-3 sm:p-4 shadow-sm flex flex-col gap-3">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <div class="min-w-0">
            <div class="flex items-center gap-2">
              <span class="material-symbols-outlined text-[22px] text-success">shelves</span>
              <h2 class="font-display text-lg font-bold text-foreground tracking-tight">${translate("Shelf replenishment")}</h2>
            </div>
            <p class="text-[12px] text-muted-foreground mt-0.5">${translate("Rows at or below their reorder point for this branch.")}</p>
          </div>
          <span class="rounded-full bg-success/10 px-3 py-1 text-[11px] font-semibold text-success whitespace-nowrap">
            ${this.shelf.count || 0} ${translate("low rows")}
          </span>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="bg-muted text-muted-foreground text-[10px] uppercase tracking-wider">
                <th class="py-2.5 px-3 rounded-l-lg font-semibold">${translate("SKU · Product")}</th>
                <th class="py-2.5 px-3 text-center font-semibold">${translate("Shelf stock")}</th>
                <th class="py-2.5 px-3 text-center font-semibold">${translate("Min")}</th>
                <th class="py-2.5 px-3 text-center font-semibold">${translate("Warehouse available")}</th>
                <th class="py-2.5 px-3 font-semibold">${translate("Stage")}</th>
                <th class="py-2.5 px-3 text-right rounded-r-lg font-semibold">${translate("Floor action")}</th>
              </tr>
            </thead>
            <tbody class="text-[12px]">
              ${this.renderShelfRows()}
            </tbody>
          </table>
        </div>

        <div class="rounded-lg bg-muted p-2.5 flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-[11px] text-muted-foreground">
          <div class="flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[17px] text-success">sync_alt</span>
            <span>${this.shelf.reorder_rules_present ? `${translate("Default minimum:")} ${this.shelf.default_minimum}` : translate("Every low item has its own reorder point.")}</span>
          </div>
          <a href="${Helpers.company_stocks_path(this.companyId)}" class="text-primary hover:underline font-semibold">${translate("Open stock ledger")}</a>
        </div>
      </section>
    `
  }

  renderShelfRows() {
    if (this.shelf.snapshot_missing) {
      return `<tr><td colspan="6" class="py-8 px-3 text-center text-muted-foreground text-[12px]">${translate("No shelf snapshot was saved for this date.")}</td></tr>`
    }
    if (this.shelfRows.length === 0) {
      return `<tr><td colspan="6" class="py-8 px-3 text-center text-muted-foreground text-[12px]">${translate("No shelf stock is below the minimum threshold.")}</td></tr>`
    }

    return this.shelfRows.map((item) => {
      const stageTone = item.stage_key === "transfer"
        ? "bg-primary/10 text-primary"
        : item.stage_key === "purchase"
          ? "bg-success/10 text-success"
          : "bg-warning/10 text-warning"
      const quantityTone = item.shelf_quantity <= 0
        ? "bg-danger text-danger-foreground"
        : item.shelf_quantity <= item.threshold / 2
          ? "bg-danger/10 text-danger"
          : "bg-warning/10 text-warning"
      const action = this.renderShelfAction(item)

      return `
        <tr class="border-b border-line last:border-0 hover:bg-muted/60 transition-colors align-top" data-stock-code="${this.escape(item.sku)}">
          <td class="py-3 px-3">
            <div class="font-semibold text-foreground">${this.escape(item.product_name)}</div>
            <div class="text-[10px] text-muted-foreground">${translate("SKU:")} ${this.escape(item.sku)}${item.bay ? ` · ${translate("Bay")} ${this.escape(item.bay)}` : ""}</div>
          </td>
          <td class="py-3 px-3 text-center">
            <span class="inline-flex min-w-[34px] justify-center rounded-md px-2 py-1 font-display text-[15px] font-bold ${quantityTone}">${item.shelf_quantity}</span>
          </td>
          <td class="py-3 px-3 text-center text-muted-foreground font-semibold">${item.threshold}</td>
          <td class="py-3 px-3 text-center text-foreground font-bold">${item.warehouse_available}</td>
          <td class="py-3 px-3">
            <div class="inline-flex items-center gap-1.5 rounded-md px-2 py-0.5 text-[10px] font-semibold ${stageTone}">
              <span class="material-symbols-outlined text-[14px]">${item.stage_icon}</span>
              ${this.escape(translate(item.stage_label))}
            </div>
            <div class="text-[10px] text-muted-foreground mt-1">${item.source_warehouse_name ? `${translate("From:")} ${this.escape(item.source_warehouse_name)}` : translate("No warehouse stock")}</div>
          </td>
          <td class="py-3 px-3 text-right">${action}</td>
        </tr>
      `
    }).join("")
  }

  renderShelfAction(item) {
    if (item.document_path) {
      return `<a href="${this.escape(item.document_path)}" class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-[11px] font-semibold bg-muted text-primary hover:bg-line transition-colors">
        ${this.escape(translate(item.action_label))}<span class="material-symbols-outlined text-[14px]">chevron_right</span>
      </a>`
    }
    if (this.readOnly) return `<span class="text-[11px] text-muted-foreground">${translate("Read-only")}</span>`

    return `<button type="button" data-action="click->${this.identifier}#openReplenishment" data-${this.identifier}-stock-id-param="${item.stock_id}"
      class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-[11px] font-semibold bg-muted text-foreground hover:bg-line transition-colors">
      ${this.escape(translate(item.action_label))}<span class="material-symbols-outlined text-[14px]">chevron_right</span>
    </button>`
  }

  // --- Cashiers / hourly / roster / footfall ---------------------------------

  renderCashiersSection() {
    return `
      <section class="rounded-xl border border-line bg-card p-3 shadow-sm flex flex-col gap-2" data-operation-block="cashiers">
        <div class="flex items-center justify-between gap-2 pb-2 border-b border-line">
          <div class="flex items-center gap-2">
            <span class="material-symbols-outlined text-[20px] text-primary">point_of_sale</span>
            <h2 class="font-display text-[15px] font-bold text-foreground">${translate("Cashiers")}</h2>
          </div>
          <span class="text-[10px] font-semibold text-primary">${this.cashiers.length} ${translate("people")}</span>
        </div>
        <div class="flex flex-col gap-2">
          ${this.renderCashierItems()}
        </div>
      </section>
    `
  }

  renderCashierItems() {
    if (this.cashiers.length === 0) {
      return `<div class="rounded-lg bg-muted border border-line p-4 text-center text-[12px] text-muted-foreground">${translate("No paid orders yet for this date.")}</div>`
    }

    return this.cashiers.map((cashier) => `
      <div class="rounded-xl border border-line bg-muted/50 p-2.5 hover:bg-muted transition-colors" data-cashier-id="${cashier.employee_id}">
        <div class="flex items-start justify-between gap-2">
          <div class="min-w-0">
            <h3 class="text-[13px] font-bold text-foreground leading-tight truncate">${this.escape(cashier.name)}</h3>
            <p class="text-[10px] text-muted-foreground truncate">${this.escape(translate(cashier.role || "No role assigned"))}</p>
          </div>
        </div>
        <div class="grid grid-cols-2 gap-2 mt-2 rounded-lg border border-line bg-card p-2">
          <div>
            <span class="text-[10px] text-muted-foreground">${translate("Sales")}</span>
            <div class="text-[14px] font-bold text-foreground">${this.money(cashier.sales_cents)}</div>
          </div>
          <div>
            <span class="text-[10px] text-muted-foreground">${translate("Orders")}</span>
            <div class="text-[14px] font-semibold text-foreground">${cashier.orders_count}</div>
          </div>
        </div>
      </div>
    `).join("") + (this.store.unassigned_orders_count > 0
      ? `<div class="rounded-lg border border-line bg-muted p-2 text-[10px] text-muted-foreground">${this.store.unassigned_orders_count} ${translate("paid orders are not credited to a cashier.")}</div>`
      : "")
  }

  renderHourlySection() {
    return `
      <section class="rounded-xl border border-line bg-card p-3 shadow-sm flex flex-col gap-2" data-operation-block="hourly">
        <div class="flex items-center justify-between gap-2 pb-2 border-b border-line">
          <div class="flex items-center gap-2">
            <span class="material-symbols-outlined text-[20px] text-success">bar_chart</span>
            <h2 class="font-display text-[15px] font-bold text-foreground">${translate("Hourly orders")}</h2>
          </div>
          <span class="text-[10px] text-muted-foreground">${this.hourly.peak ? `${translate("Peak")} ${this.escape(this.hourly.peak.label)} (${this.hourly.peak.orders_count})` : translate("No orders")}</span>
        </div>
        ${this.hourly.buckets.length === 0 ? `<div class="rounded-lg bg-muted border border-line p-4 text-center text-[12px] text-muted-foreground">${translate("No orders on this date.")}</div>` : `
          <div class="h-24 w-full flex items-end gap-1 pt-1">
            ${this.hourly.buckets.map((bucket) => this.renderHourBar(bucket)).join("")}
          </div>
        `}
      </section>
    `
  }

  renderHourBar(bucket) {
    const height = Math.max(6, Math.round((bucket.orders_count / this.maxHourlyOrders) * 72))
    const isCurrent = this.hourly.current_hour != null && bucket.hour === this.hourly.current_hour
    const barClass = isCurrent ? "bg-success" : "bg-primary/50"

    return `
      <div class="flex-1 flex flex-col items-center gap-1 group" title="${bucket.orders_count} ${translate("orders")}">
        <div class="w-full rounded-t transition-all ${barClass} group-hover:bg-primary" style="height: ${height}px"></div>
        <span class="text-[9px] ${isCurrent ? "text-success font-bold" : "text-muted-foreground"}">${isCurrent ? translate("Now") : this.escape(bucket.label)}</span>
      </div>
    `
  }

  renderRosterSection() {
    return `
      <section class="rounded-xl border border-line bg-card p-3 shadow-sm flex flex-col gap-2" data-operation-block="roster">
        <div class="flex items-center justify-between gap-2 pb-2 border-b border-line">
          <div class="flex items-center gap-2">
            <span class="material-symbols-outlined text-[20px] text-primary">diversity_3</span>
            <h2 class="font-display text-[15px] font-bold text-foreground">${translate("On-duty roster")}</h2>
          </div>
          <span class="text-[10px] font-semibold text-primary">${this.staff.length} ${translate("checked in")}</span>
        </div>
        <div class="flex flex-col gap-1.5">
          ${this.renderRosterItems()}
        </div>
        <a href="${Helpers.company_attendance_months_path(this.companyId)}" class="w-full py-2 min-h-[36px] rounded-lg bg-muted hover:bg-line text-foreground text-[11px] font-semibold transition-colors flex items-center justify-center gap-1.5">
          <span class="material-symbols-outlined text-[17px]">manage_accounts</span>${translate("Manage shift attendance")}
        </a>
      </section>
    `
  }

  renderRosterItems() {
    if (this.staff.length === 0) {
      return `<div class="rounded-lg bg-muted border border-line p-4 text-center text-[12px] text-muted-foreground">${this.readOnly ? translate("No one was checked in on this date.") : translate("No one is checked in right now.")}</div>`
    }

    return this.staff.map((employee) => `
      <div class="flex items-center justify-between gap-2 rounded-lg bg-muted/50 hover:bg-muted p-2 transition-colors" data-employee-id="${employee.employee_id}">
        <div class="flex items-center gap-2 min-w-0">
          <div class="w-8 h-8 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-[10px] shrink-0">
            ${this.escape(this.initialsFor(employee.name))}
          </div>
          <div class="min-w-0">
            <div class="text-[12px] font-bold text-foreground truncate">${this.escape(employee.name)}</div>
            <div class="text-[10px] text-muted-foreground truncate">${this.escape(translate(employee.role || "No role assigned"))}</div>
          </div>
        </div>
        <div class="text-right">
          <span class="rounded-full bg-success/10 px-2 py-0.5 text-[10px] font-bold text-success whitespace-nowrap">${translate("Checked in")}</span>
          <div class="text-[9px] text-muted-foreground mt-0.5">${employee.checked_in_at ? this.time(employee.checked_in_at, "h:mm A") : ""}</div>
        </div>
      </div>
    `).join("")
  }

  renderFootfall() {
    return `
      <section class="rounded-xl border border-line bg-muted px-3 py-2 text-[11px] text-muted-foreground flex items-center gap-2" data-operation-block="footfall">
        <span class="material-symbols-outlined text-[16px]">sensor_occupied</span>
        <span>${translate("No door sensor")} · ${this.footfall.buyers || 0} ${translate("buyers")}</span>
      </section>
    `
  }

  renderFooter() {
    const generated = this.store.generated_at ? this.time(this.store.generated_at) : "—"
    return `
      <footer class="rounded-xl border border-line bg-muted p-2.5 shadow-sm flex flex-wrap items-center justify-between gap-2 text-[11px] text-muted-foreground" data-operation-block="footer">
        <span class="flex items-center gap-1.5">
          <span class="material-symbols-outlined text-[15px]">schedule</span>
          <span data-store-manager-refreshed>${translate("Refreshed")} ${this.escape(generated)}</span>
          ${this.refreshFailed ? `<span class="text-danger font-semibold" data-store-manager-refresh-error>${translate("Update failed")}</span>` : ""}
        </span>
        <span class="flex items-center gap-1.5">
          <span class="material-symbols-outlined text-[15px]">receipt_long</span>
          ${translate("Operation:")} ${this.escape(this.operation?.code || "—")}
        </span>
      </footer>
    `
  }

  // --- Close sheet ------------------------------------------------------------

  openCloseSheet() {
    if (!this.shiftClose) return
    this.closeSheetOpen = true
    this.renderContent()
  }

  closeCloseSheet() {
    this.closeSheetOpen = false
    this.renderContent()
  }

  renderCloseSheet() {
    if (!this.closeSheetOpen || !this.shiftClose) return ""

    const close = this.shiftClose
    const sales = close.sales || {}
    const readOnly = close.read_only === true
    const tender = sales.tender_lines || []
    const opening = this.amountValue(close.opening_float_cents)
    const counted = this.amountValue(close.counted_cash_cents)
    const note = close.note || ""

    return `
      <div class="fixed inset-0 z-50 bg-foreground/40 flex items-end sm:items-center justify-center p-0 sm:p-4" data-store-manager-close-sheet>
        <div class="w-full sm:max-w-2xl max-h-[92vh] overflow-y-auto rounded-t-2xl sm:rounded-2xl border border-line bg-card shadow-xl">
          <div class="flex items-start justify-between gap-2 p-4 border-b border-line">
            <div>
              <h2 class="font-display text-lg font-bold text-foreground">${translate("Close shift")}</h2>
              <p class="text-[11px] text-muted-foreground">${this.escape(this.dateLabel)}${close.closed_at ? ` · ${translate("Saved")} ${this.time(close.closed_at)}` : ""}</p>
            </div>
            <button type="button" data-action="click->${this.identifier}#closeCloseSheet" class="w-8 h-8 rounded-lg bg-muted text-foreground flex items-center justify-center" title="${translate("Close")}" aria-label="${translate("Close")}">
              <span class="material-symbols-outlined text-[18px]">close</span>
            </button>
          </div>

          <div class="p-4 flex flex-col gap-4">
            <div class="rounded-xl border border-line bg-muted p-3 flex flex-col gap-1.5 text-[12px]">
              <div class="flex justify-between"><span class="text-muted-foreground">${translate("Gross sales")}</span><strong>${this.money(sales.gross_sales_cents)}</strong></div>
              <div class="flex justify-between"><span class="text-muted-foreground">${translate("Order count")}</span><strong>${sales.orders_count || 0}</strong></div>
              <div class="flex justify-between"><span class="text-muted-foreground">${translate("Discounts")}</span><strong>${this.money(sales.discounts_cents)}</strong></div>
              <div class="flex justify-between"><span class="text-muted-foreground">${translate("Tax")}</span><strong>${this.money(sales.tax_cents)}</strong></div>
            </div>

            <div class="rounded-xl border border-line bg-card p-3 flex flex-col gap-1.5 text-[12px]">
              <h3 class="font-semibold text-foreground">${translate("Sales by tender")}</h3>
              ${tender.length === 0 ? `<p class="text-muted-foreground">${translate("No sales on this date.")}</p>` : tender.map((line) => `
                <div class="flex justify-between"><span class="text-muted-foreground">${this.escape(translate(line.label))}</span><strong>${this.money(line.amount_cents)}</strong></div>
              `).join("")}
            </div>

            <div class="rounded-xl border border-line bg-card p-3 flex flex-col gap-2 text-[12px]">
              ${(sales.cash_sales_cents || 0) === 0 ? `<p class="text-warning font-semibold">${translate("No cash sales")}</p>` : ""}
              <label class="flex items-center justify-between gap-2">
                <span class="text-muted-foreground">${translate("Opening float")}</span>
                <input id="store-manager-opening-float" type="number" min="0" step="0.01" value="${this.escape(opening)}" ${readOnly ? "disabled" : ""}
                  data-action="input->${this.identifier}#updateClosePreview"
                  class="w-32 h-9 rounded-lg border border-line bg-card px-2 text-right disabled:opacity-60" />
              </label>
              <div class="flex justify-between"><span class="text-muted-foreground">${translate("Expected cash")}</span><strong data-store-manager-expected>${this.money(close.expected_cash_cents)}</strong></div>
              <label class="flex items-center justify-between gap-2">
                <span class="text-muted-foreground">${translate("Counted cash")}</span>
                <input id="store-manager-counted-cash" type="number" min="0" step="0.01" value="${this.escape(counted)}" ${readOnly ? "disabled" : ""}
                  data-action="input->${this.identifier}#updateClosePreview"
                  class="w-32 h-9 rounded-lg border border-line bg-card px-2 text-right disabled:opacity-60" />
              </label>
              <div class="flex justify-between"><span class="text-muted-foreground">${translate("Variance")}</span><strong data-store-manager-variance>${this.varianceLabel()}</strong></div>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-2 text-[12px]">
              <div class="rounded-xl border border-line bg-muted p-3">
                <span class="text-muted-foreground">${translate("Still to hand over")}</span>
                <div class="font-bold text-foreground">${close.open_handovers_count || 0}</div>
                ${this.closeHandovers.length === 0 ? "" : `<div class="mt-1 flex flex-col gap-0.5 text-[10px] text-muted-foreground">${this.closeHandovers.map((row) => `<span>${this.escape(row.code)} · ${this.escape(row.customer_name)}</span>`).join("")}</div>`}
              </div>
              <div class="rounded-xl border border-line bg-muted p-3">
                <span class="text-muted-foreground">${translate("Shelf rows short")}</span>
                <div class="font-bold text-foreground">${close.shelf_short_count || 0}</div>
              </div>
            </div>

            <div class="rounded-xl border border-line bg-card p-3 text-[12px]">
              <h3 class="font-semibold text-foreground mb-1">${translate("Checked in")}</h3>
              ${this.closeStaff.length === 0 ? `<p class="text-muted-foreground">${translate("No one was checked in.")}</p>` : `<p class="text-muted-foreground">${this.closeStaff.map((row) => this.escape(row.name)).join(" · ")}</p>`}
            </div>

            <label class="flex flex-col gap-1 text-[12px]">
              <span class="text-muted-foreground">${translate("Note")}</span>
              <textarea id="store-manager-close-note" rows="2" ${readOnly ? "disabled" : ""}
                class="w-full rounded-lg border border-line bg-card px-2 py-1.5 text-foreground disabled:opacity-60">${this.escape(note)}</textarea>
            </label>

            ${readOnly ? "" : `<p class="text-[10px] text-muted-foreground">${translate("Saving again recalculates the figures from current records.")}</p>`}
          </div>

          <div class="sticky bottom-0 flex items-center justify-end gap-2 p-4 border-t border-line bg-card">
            <button type="button" data-action="click->${this.identifier}#printClose" class="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-muted text-foreground text-[12px] font-semibold">
              <span class="material-symbols-outlined text-[17px]">print</span>${translate("Print")}
            </button>
            ${readOnly ? "" : `<button type="button" data-action="click->${this.identifier}#saveClose" class="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-primary text-primary-foreground text-[12px] font-semibold">
              ${translate("Save and close")}
            </button>`}
          </div>
        </div>
      </div>
    `
  }

  updateClosePreview() {
    const expected = this.expectedCashCents()
    const counted = this.countedCashCents()
    const expectedNode = this.element.querySelector("[data-store-manager-expected]")
    const varianceNode = this.element.querySelector("[data-store-manager-variance]")
    if (expectedNode) expectedNode.textContent = this.money(expected)
    if (varianceNode) {
      varianceNode.textContent = counted === null ? "—" : this.money(counted - expected)
      varianceNode.className = counted !== null && counted !== expected ? "text-danger" : ""
    }
  }

  expectedCashCents() {
    const opening = this.centsFromInput(this.element.querySelector("#store-manager-opening-float")?.value)
    const sales = this.closeSales
    return opening + (sales.cash_received_cents || 0) - (sales.change_cents || 0)
  }

  countedCashCents() {
    const raw = this.element.querySelector("#store-manager-counted-cash")?.value
    if (raw === undefined || raw === null || raw === "") return null
    return this.centsFromInput(raw)
  }

  varianceLabel() {
    const close = this.closeData
    if (!close || close.counted_cash_cents === null || close.counted_cash_cents === undefined) return "—"
    return this.money(close.variance_cents || 0)
  }

  async saveClose() {
    if (this.actionPending) return
    const counted = this.countedCashCents()
    if (counted === null) {
      toast({ type: "warning", message: translate("Enter the counted cash.") })
      this.element.querySelector("#store-manager-counted-cash")?.focus()
      return
    }
    const opening = this.centsFromInput(this.element.querySelector("#store-manager-opening-float")?.value)
    const note = this.element.querySelector("#store-manager-close-note")?.value || ""
    this.actionPending = "close"

    try {
      const response = await fetchJson(
        Helpers.store_manager_shift_close_company_operation_path(this.companyId, this.operationId),
        {
          method: "POST",
          body: {
            branch_id: this.branchId,
            shift_close: {
              opening_float_cents: opening,
              counted_cash_cents: counted,
              note
            }
          }
        }
      )
      toast({ type: "success", message: response.message })
      this.actionPending = null
      await this.loadConsole()
      this.closeSheetOpen = true
      this.renderContent()
    } catch (error) {
      this.actionPending = null
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    }
  }

  printClose() {
    const root = this.element.ownerDocument.querySelector("#store-manager-close-print")
    if (!root) return
    const draft = {
      opening: this.centsFromInput(this.element.querySelector("#store-manager-opening-float")?.value),
      counted: this.countedCashCents(),
      note: this.element.querySelector("#store-manager-close-note")?.value || ""
    }
    root.innerHTML = this.printContent(draft)
    window.print()
  }

  renderPrintRoot() {
    if (!this.shiftClose) return ""
    return `<div id="store-manager-close-print" class="hidden print:block text-foreground p-6">${this.printContent()}</div>`
  }

  printContent(draft = null) {
    const close = this.shiftClose
    if (!close) return ""
    const sales = close.sales || {}
    const opening = draft ? draft.opening : (close.opening_float_cents || 0)
    const counted = draft ? draft.counted : (close.counted_cash_cents ?? null)
    const expected = draft
      ? opening + (sales.cash_received_cents || 0) - (sales.change_cents || 0)
      : (close.expected_cash_cents || 0)
    const variance = draft ? (counted === null ? null : counted - expected) : (close.variance_cents || 0)
    const note = draft ? draft.note : (close.note || "")
    const tender = sales.tender_lines || []
    const staff = close.staff || []
    const shiftName = close.shift?.name || this.shift?.name || translate("No shift scheduled")

    return `
      <h1 class="text-xl font-bold">${this.escape(this.branchName)}</h1>
      <p class="text-sm">${translate("Shift close")} · ${this.escape(this.dateLabel)}</p>
      <p class="text-sm">${this.escape(translate(shiftName))}</p>
      <hr class="my-3 border-line" />
      <table class="w-full text-left text-[11px] border-collapse">
        <tbody>
          <tr><td class="py-1">${translate("Gross sales")}</td><td class="py-1 text-right">${this.money(sales.gross_sales_cents)}</td></tr>
          <tr><td class="py-1">${translate("Order count")}</td><td class="py-1 text-right">${sales.orders_count || 0}</td></tr>
          <tr><td class="py-1">${translate("Discounts")}</td><td class="py-1 text-right">${this.money(sales.discounts_cents)}</td></tr>
          <tr><td class="py-1">${translate("Tax")}</td><td class="py-1 text-right">${this.money(sales.tax_cents)}</td></tr>
          ${tender.map((line) => `<tr><td class="py-1">${this.escape(translate(line.label))}</td><td class="py-1 text-right">${this.money(line.amount_cents)}</td></tr>`).join("")}
          <tr><td class="py-1">${translate("Opening float")}</td><td class="py-1 text-right">${this.money(opening)}</td></tr>
          <tr><td class="py-1">${translate("Expected cash")}</td><td class="py-1 text-right">${this.money(expected)}</td></tr>
          <tr><td class="py-1">${translate("Counted cash")}</td><td class="py-1 text-right">${counted === null ? "—" : this.money(counted)}</td></tr>
          <tr><td class="py-1 font-bold">${translate("Variance")}</td><td class="py-1 text-right font-bold">${variance === null ? "—" : this.money(variance)}</td></tr>
          <tr><td class="py-1">${translate("Still to hand over")}</td><td class="py-1 text-right">${close.open_handovers_count || 0}</td></tr>
          ${(close.open_handovers || []).length === 0 ? "" : `<tr><td colspan="2" class="py-1 text-[10px]">${(close.open_handovers || []).map((row) => `${this.escape(row.code)} · ${this.escape(row.customer_name)}`).join(" · ")}</td></tr>`}
          <tr><td class="py-1">${translate("Shelf rows short")}</td><td class="py-1 text-right">${close.shelf_short_count || 0}</td></tr>
        </tbody>
      </table>
      <p class="text-[11px] mt-3"><strong>${translate("Checked in")}:</strong> ${staff.length ? staff.map((row) => this.escape(row.name)).join(", ") : translate("No one was checked in.")}</p>
      <p class="text-[11px] mt-1"><strong>${translate("Note")}:</strong> ${this.escape(note || "—")}</p>
    `
  }

  // --- Replenishment sheet ----------------------------------------------------

  openReplenishment(event) {
    const stockId = event.params.stockId
    const row = this.shelfRows.find((candidate) => String(candidate.stock_id) === String(stockId))
    if (!row) return
    const shortfall = Math.max((row.threshold || 0) - (row.shelf_quantity || 0), 1)
    const defaultQuantity = row.action_key === "transfer"
      ? Math.min(shortfall, Math.max(row.source_available || 0, 1))
      : shortfall
    this.replenishmentSheet = {
      row,
      quantity: String(defaultQuantity),
      supplierId: row.default_supplier?.id || ""
    }
    this.renderContent()
  }

  closeReplenishment() {
    this.replenishmentSheet = null
    this.renderContent()
  }

  renderReplenishmentSheet() {
    if (!this.replenishmentSheet) return ""
    const { row } = this.replenishmentSheet
    const purchase = row.action_key === "purchase"
    const suppliers = this.store.reference?.suppliers || []

    return `
      <div class="fixed inset-0 z-50 bg-foreground/40 flex items-end sm:items-center justify-center p-0 sm:p-4" data-store-manager-replenishment-sheet>
        <div class="w-full sm:max-w-md max-h-[92vh] overflow-y-auto rounded-t-2xl sm:rounded-2xl border border-line bg-card shadow-xl">
          <div class="flex items-start justify-between gap-2 p-4 border-b border-line">
            <div>
              <h2 class="font-display text-lg font-bold text-foreground">${purchase ? translate("Create purchase") : translate("Request transfer")}</h2>
              <p class="text-[11px] text-muted-foreground">${this.escape(row.product_name)} · ${this.escape(row.sku)}</p>
            </div>
            <button type="button" data-action="click->${this.identifier}#closeReplenishment" class="w-8 h-8 rounded-lg bg-muted text-foreground flex items-center justify-center" title="${translate("Close")}" aria-label="${translate("Close")}">
              <span class="material-symbols-outlined text-[18px]">close</span>
            </button>
          </div>

          <div class="p-4 flex flex-col gap-3 text-[12px]">
            <div class="rounded-xl border border-line bg-muted p-3 flex flex-col gap-1">
              <div class="flex justify-between"><span class="text-muted-foreground">${translate("Shelf stock")}</span><strong>${row.shelf_quantity}</strong></div>
              <div class="flex justify-between"><span class="text-muted-foreground">${translate("Min")}</span><strong>${row.threshold}</strong></div>
              <div class="flex justify-between"><span class="text-muted-foreground">${translate("Warehouse available")}</span><strong>${row.warehouse_available}</strong></div>
              ${row.source_warehouse_name ? `<div class="flex justify-between"><span class="text-muted-foreground">${translate("From")}</span><strong>${this.escape(row.source_warehouse_name)}</strong></div>` : ""}
            </div>

            <label class="flex flex-col gap-1">
              <span class="text-muted-foreground">${translate("Quantity")}</span>
              <input id="store-manager-replenishment-quantity" type="number" min="1" step="1" value="${this.escape(this.replenishmentSheet.quantity)}"
                data-action="input->${this.identifier}#updateReplenishmentQuantity"
                class="h-9 rounded-lg border border-line bg-card px-2 text-foreground" />
            </label>

            ${purchase ? `
              <label class="flex flex-col gap-1">
                <span class="text-muted-foreground">${translate("Supplier")}</span>
                ${suppliers.length === 0 ? `<a href="${Helpers.company_suppliers_path(this.companyId)}" class="text-primary font-semibold">${translate("Add a supplier first")}</a>` : `
                  <select id="store-manager-replenishment-supplier" class="h-9 rounded-lg border border-line bg-card px-2 text-foreground">
                    <option value="">${translate("Choose a supplier")}</option>
                    ${suppliers.map((supplier) => `<option value="${this.escape(supplier.id)}" ${String(supplier.id) === String(this.replenishmentSheet.supplierId) ? "selected" : ""}>${this.escape(supplier.name)}</option>`).join("")}
                  </select>
                `}
              </label>
            ` : ""}
          </div>

          <div class="sticky bottom-0 flex items-center justify-end gap-2 p-4 border-t border-line bg-card">
            <button type="button" data-action="click->${this.identifier}#closeReplenishment" class="px-3 py-2 rounded-lg bg-muted text-foreground text-[12px] font-semibold">${translate("Cancel")}</button>
            <button type="button" data-action="click->${this.identifier}#confirmReplenishment" class="px-3 py-2 rounded-lg bg-primary text-primary-foreground text-[12px] font-semibold">${translate("Confirm")}</button>
          </div>
        </div>
      </div>
    `
  }

  updateReplenishmentQuantity(event) {
    if (this.replenishmentSheet) this.replenishmentSheet.quantity = event.target.value
  }

  async confirmReplenishment() {
    if (!this.replenishmentSheet || this.actionPending) return
    const row = this.replenishmentSheet.row
    const quantity = Number(this.element.querySelector("#store-manager-replenishment-quantity")?.value)
    const supplierId = this.element.querySelector("#store-manager-replenishment-supplier")?.value || null
    if (!Number.isInteger(quantity) || quantity < 1) {
      toast({ type: "warning", message: translate("Quantity must be a whole number greater than 0.") })
      return
    }
    if (row.action_key === "purchase" && !supplierId) {
      toast({ type: "warning", message: translate("Choose a supplier.") })
      return
    }
    this.actionPending = "replenishment"

    try {
      const response = await fetchJson(
        Helpers.store_manager_replenishments_company_operation_path(this.companyId, this.operationId),
        {
          method: "POST",
          body: {
            branch_id: this.branchId,
            replenishment: { stock_id: row.stock_id, quantity, supplier_id: supplierId }
          }
        }
      )
      toast({ type: "success", message: response.message })
      this.actionPending = null
      this.replenishmentSheet = null
      await this.reloadConsole()
    } catch (error) {
      this.actionPending = null
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    }
  }

  // --- Queue interactions -----------------------------------------------------

  scheduleSearch(event) {
    this.searchQuery = event.target.value || ""
    if (this.searchTimer) window.clearTimeout(this.searchTimer)
    this.searchTimer = window.setTimeout(() => this.fetchQueue({ page: 1 }), 250)
  }

  async clearSearch(event) {
    if (event) event.preventDefault()
    this.searchQuery = ""
    this.queuePage = 1
    const input = this.element.querySelector("#store-manager-order-search")
    if (input) input.value = ""
    await this.fetchQueue({ page: 1 })
  }

  setOrderTab(event) {
    this.orderTab = event.params.tab
    this.queuePage = 1
    this.fetchQueue({ page: 1 })
  }

  previousQueuePage() {
    if (!this.queuePagination.previous) return
    this.queuePage = this.queuePagination.previous
    this.fetchQueue()
  }

  nextQueuePage() {
    if (!this.queuePagination.next) return
    this.queuePage = this.queuePagination.next
    this.fetchQueue()
  }

  async fetchQueue(overrides = {}) {
    const wasFocused = document.activeElement?.id === "store-manager-order-search"
    const params = {
      branch_id: this.branchId,
      date: this.store.date,
      tab: this.orderTab,
      q: this.searchQuery,
      page: this.queuePage,
      ...overrides
    }
    try {
      const response = await fetchJson(
        Helpers.store_manager_queue_company_operation_path(this.companyId, this.operationId, params)
      )
      this.store.queue = response
      const section = this.element.querySelector('[data-operation-block="queue"]')
      if (section) section.outerHTML = this.renderQueueSection()
      this.restoreSearchFocus(wasFocused)
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    }
  }

  restoreSearchFocus(wasFocused) {
    const input = this.element.querySelector("#store-manager-order-search")
    if (!input) return
    input.value = this.searchQuery
    if (wasFocused) {
      input.focus()
      input.setSelectionRange(input.value.length, input.value.length)
    }
  }

  focusScanner() {
    const input = this.element.querySelector("#store-manager-order-search")
    if (!input) return
    input.focus()
    input.select()
  }

  async markReady(event) {
    await this.orderAction(event.params.orderId, "mark_ready")
  }

  async handOver(event) {
    await this.orderAction(event.params.orderId, "hand_over")
  }

  async orderAction(orderId, action) {
    if (this.actionPending) return
    this.actionPending = `${action}-${orderId}`
    const path = action === "mark_ready"
      ? Helpers.store_manager_order_mark_ready_company_operation_path(this.companyId, this.operationId, orderId)
      : Helpers.store_manager_order_hand_over_company_operation_path(this.companyId, this.operationId, orderId)

    try {
      const response = await fetchJson(path, {
        method: "POST",
        body: { branch_id: this.branchId }
      })
      toast({ type: "success", message: response.message })
      this.actionPending = null
      await this.reloadConsole()
    } catch (error) {
      this.actionPending = null
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    }
  }

  // --- Context interactions ---------------------------------------------------

  async selectDate(event) {
    const value = event.target.value
    if (!value || value > this.todayIso) {
      event.target.value = this.store.date
      return
    }
    this.selectedDate = value
    this.orderTab = "all"
    this.searchQuery = ""
    this.queuePage = 1
    try {
      await this.loadConsole()
      this.renderContent()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    }
  }

  scrollToShelf() {
    this.element.querySelector('[data-operation-block="shelf"]')?.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  overlayOpen() {
    return this.closeSheetOpen || this.replenishmentSheet !== null
  }

  // --- Helpers ----------------------------------------------------------------

  time(value, format = "h:mm A") {
    return Helpers.locationTime(value, format, this.location)
  }

  money(minorUnits, currency = this.currency) {
    return Helpers.formatMoney(minorUnits || 0, currency)
  }

  amountValue(cents) {
    if (cents === null || cents === undefined) return ""
    return String(Helpers.minorToMajor(cents, this.currency))
  }

  centsFromInput(value) {
    if (value === undefined || value === null || value === "") return 0
    const amount = Number(value)
    if (!Number.isFinite(amount) || amount < 0) return 0
    return this.currency === "vnd" ? Math.round(amount) : Math.round(amount * 100)
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
