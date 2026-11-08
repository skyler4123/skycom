import { Controller } from "@hotwired/stimulus"

// Reception — full-screen front-desk console for the branch-scoped Reception
// operation. The page renders the operational KPI ribbon, the live visitor
// queue, room/appointment coordination, parcel intake and the speed-dial hub.
//
// This first pass ships demo data in the frontend (no Visitor/Parcel models
// exist yet). The shape mirrors the intended domain so it can be swapped for
// Customers (visitors), Facilities (rooms) and Events (appointments) without
// rewriting the layout.
//
// Serves Stimulus: Companies_Operations_Reception_ShowController
// Depends on BE: Companies::Operations::ReceptionController#show
//               (hydrates operation + appointment + config)
// Endpoints: Helpers.reception_company_operation_path
// Docs: docs/OPERATIONS.md
export default class Companies_Operations_Reception_ShowController extends Controller {
  /** @type {any | null} */ operation = null
  /** @type {any | null} */ appointment = null
  /** @type {any[]} */ visitors = []
  /** @type {any[]} */ deliveries = []
  /** @type {any[]} */ rooms = []
  /** @type {any[]} */ appointments = []
  /** @type {any} */ reference = {}
  /** @type {any} */ counts = {}
  /** @type {string | null} */ companyId = null
  /** @type {string | null} */ operationId = null
  /** @type {string | null} */ branchId = null
  /** @type {string} */ searchQuery = ""
  /** @type {string} */ activeTab = "lobby"
  /** @type {boolean} */ walkinOpen = false
  /** @type {boolean} */ deliveryFormOpen = false

  async connect() {
    const pathParts = window.location.pathname.split("/")
    this.companyId = this.element.dataset.companyId || pathParts[2]
    this.operationId = this.element.dataset.operationId || pathParts[5]
    this.branchId = new URLSearchParams(window.location.search).get("branch_id")

    this.boundShortcut = (event) => {
      if (event.key !== "/" || event.metaKey || event.ctrlKey || event.altKey) return
      const target = event.target
      const typing = target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement || target instanceof HTMLSelectElement
      if (typing) return
      event.preventDefault()
      document.getElementById("reception-quick-search")?.focus()
    }
    window.addEventListener("keydown", this.boundShortcut)

    try {
      await this.loadConsole()
      this.renderContent()
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      this.element.innerHTML = `<div class="flex items-center justify-center h-screen text-danger text-lg font-semibold">${translate("Failed to load the reception console.")}${detail ? ": " + this.escape(detail) : ""}</div>`
    }
  }

  disconnect() {
    if (this.boundShortcut) window.removeEventListener("keydown", this.boundShortcut)
  }

  // --- Demo data -------------------------------------------------------------------

async loadConsole() {
  const params = this.branchId ? { branch_id: this.branchId } : {}
  const response = await fetchJson(Helpers.reception_company_operation_path(this.companyId, this.operationId, params))
  this.operation = response.operation
  this.appointment = response.appointment
  this.reference = response.reference || {}
  this.hydrateReception(response.reception || {})
  return response
}

async reloadConsole() {
  const scrollY = window.scrollY
  await this.loadConsole()
  this.renderContent()
  window.scrollTo(0, scrollY)
}

hydrateReception(reception) {
  this.visitors = reception.visits || []
  this.deliveries = reception.parcels || []
  this.rooms = reception.rooms || []
  this.appointments = reception.appointments || []
  this.counts = reception.counts || {}
}

  // --- Counts ----------------------------------------------------------------------

  get lobbyVisitors() { return this.visitors.filter((visitor) => visitor.status === "lobby") }
  get activeVisitors() { return this.visitors.filter((visitor) => visitor.status === "active") }
  get upcomingVisitors() { return this.visitors.filter((visitor) => visitor.status === "upcoming") }
  get departedVisitors() { return this.visitors.filter((visitor) => visitor.status === "departed") }
  get insideCount() { return this.counts.inside ?? this.activeVisitors.length }
  get roomAvailableCount() { return this.counts.rooms_available ?? this.rooms.filter((room) => room.status === "available").length }
  get roomBusyCount() { return this.rooms.filter((room) => room.status === "busy").length }
  get lockerFreeCount() { return Math.max(0, 8 - this.deliveries.length) }

  get averageWait() {
    const waits = this.lobbyVisitors.map((visitor) => visitor.waitMin).filter((value) => value > 0)
    if (waits.length === 0) return 0
    return (waits.reduce((sum, value) => sum + value, 0) / waits.length).toFixed(1)
  }

  get expectedToday() { return this.counts.expected_today ?? this.visitors.length }
  get remainingToday() { return this.counts.remaining ?? this.lobbyVisitors.length + this.activeVisitors.length + this.upcomingVisitors.length }
  get expectedProgress() {
    if (this.expectedToday === 0) return 0
    return Math.max(0, Math.min(100, Math.round(((this.expectedToday - this.remainingToday) / this.expectedToday) * 100)))
  }

  // --- Rendering -------------------------------------------------------------------

  renderContent() {
    this.element.innerHTML = this.contentHTML()
    this.applyFilters()
  }

  contentHTML() {
    return `
      <div class="bg-background text-foreground min-h-screen flex flex-col">
        ${this.renderHeader()}
        <main class="flex-1 pt-[7.5rem] pb-6 w-full px-4 lg:px-6">
          ${this.renderHeadline()}
          <div id="reception-kpi-ribbon">${this.renderKpis()}</div>
          ${this.renderEmptyNotice()}
          <div class="grid grid-cols-1 xl:grid-cols-12 gap-4 items-start">
            <section class="xl:col-span-8 flex flex-col gap-3 min-w-0">
              ${this.renderQueueToolbar()}
              <div id="reception-visitor-list" class="flex flex-col gap-2.5">${this.renderVisitorCards()}</div>
              ${this.renderWalkinStation()}
            </section>
            <aside class="xl:col-span-4 flex flex-col gap-4 min-w-0">
              ${this.renderRoomsPanel()}
              ${this.renderDeliveriesPanel()}
              ${this.renderSpeedDialPanel()}
            </aside>
          </div>
        </main>
        ${this.renderFooter()}
      </div>
    `
  }

  renderHeader() {
    const userName = this.element.dataset.userName || (typeof window.currentUser === "function" ? window.currentUser()?.name : window.currentUser?.name) || translate("Front Desk")
    const userRole = this.element.dataset.userRole || translate("Front Office Lead")
    return `
      <header class="fixed top-0 left-0 right-0 z-40 bg-card/95 backdrop-blur border-b border-line shadow-sm">
        <div class="h-16 w-full px-4 lg:px-6 flex items-center justify-between gap-4">
          <div class="flex items-center gap-3 min-w-0">
            <div class="flex items-center gap-2 shrink-0">
              <div class="w-9 h-9 rounded-lg bg-primary flex items-center justify-center text-primary-foreground shadow-sm">
                <span class="material-symbols-outlined text-[20px]">concierge</span>
              </div>
              <div class="flex flex-col leading-none">
                <span class="font-bold tracking-tight truncate">${translate("Skycom FrontDesk")}</span>
                <span class="text-[11px] text-muted-foreground">${translate("Enterprise Hospitality ERP")}</span>
              </div>
            </div>
            <div class="h-7 w-px bg-line hidden md:block"></div>
            <div class="hidden md:flex items-center gap-2 px-3 py-1.5 rounded-lg bg-muted">
              <span class="material-symbols-outlined text-[18px] text-primary">domain</span>
              <div class="flex flex-col text-left leading-tight">
                <span class="text-[10px] uppercase tracking-wider text-muted-foreground">${translate("Location")}</span>
                <span class="text-[12px] font-semibold text-foreground">${this.escape(this.branchName)}</span>
              </div>
            </div>
          </div>
          <div class="flex-1 max-w-lg hidden lg:block">
            <div class="relative flex items-center w-full">
              <span class="material-symbols-outlined absolute left-3 text-[20px] text-muted-foreground pointer-events-none">search</span>
              <input id="reception-quick-search" type="search" value="${this.escape(this.searchQuery)}"
                data-reception-search
                data-action="input->${this.identifier}#updateSearch keydown.esc->${this.identifier}#clearSearch"
                placeholder="${translate("Quick search visitors, staff, deliveries or bookings (Press '/' to focus)...")}"
                class="w-full h-10 pl-10 pr-3 rounded-lg bg-muted text-foreground placeholder:text-muted-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary transition-all" />
            </div>
          </div>
          <div class="flex items-center gap-2 shrink-0">
            <div class="hidden xl:flex items-center gap-2 px-3 py-1.5 rounded-full bg-muted">
              <span class="w-2 h-2 rounded-full bg-success animate-pulse"></span>
              <span class="text-[11px] font-semibold text-foreground">${translate("Shift:")} ${this.currentShift}</span>
            </div>
            <button type="button" data-action="click->${this.identifier}#focusLobby"
              class="relative h-10 w-10 flex items-center justify-center rounded-lg text-muted-foreground hover:bg-muted hover:text-foreground transition-colors touch-manipulation"
              title="${translate("Waiting guests in lobby")}">
              <span class="material-symbols-outlined text-[22px]">notifications</span>
              ${this.lobbyVisitors.length > 0 ? `<span class="absolute top-1 right-1 flex items-center justify-center min-w-[18px] h-[18px] px-1 rounded-full bg-danger text-danger-foreground text-[10px] font-bold">${this.lobbyVisitors.length}</span>` : ""}
            </button>
            <div class="h-7 w-px bg-line hidden sm:block"></div>
            <div class="hidden sm:flex items-center gap-2">
              <div class="flex flex-col text-right leading-tight">
                <span class="text-[12px] font-semibold text-foreground">${this.escape(userName)}</span>
                <span class="text-[10px] text-muted-foreground">${this.escape(userRole)}</span>
              </div>
              <div class="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-primary-foreground">
                <span class="material-symbols-outlined text-[18px]">person</span>
              </div>
            </div>
            <button type="button" class="w-10 h-10 rounded-lg bg-muted hover:bg-line text-foreground flex items-center justify-center transition-colors touch-manipulation" ${Helpers.darkmodeTrigger()} title="${translate("Toggle dark mode")}"></button>
          </div>
        </div>
        <div class="w-full px-4 lg:px-6 border-t border-line bg-muted/40">
          <nav class="flex items-center gap-1 h-11 overflow-x-auto">
            ${this.renderNavItem("console", translate("Reception Console"), "concierge", true)}
            ${this.renderNavItem("visitors", translate("Visitor Log"), "groups")}
            ${this.renderNavItem("appointments", translate("Appointments & Rooms"), "calendar_month")}
            ${this.renderNavItem("deliveries", translate("Deliveries & Packages"), "local_shipping")}
            ${this.renderNavItem("security", translate("Security & Badges"), "badge")}
          </nav>
        </div>
      </header>
    `
  }

  renderNavItem(key, label, icon, active = false) {
    const activeClasses = "bg-primary text-primary-foreground font-bold shadow-sm"
    const idleClasses = "text-muted-foreground hover:bg-card hover:text-foreground"
    return `
      <button type="button" data-action="click->${this.identifier}#selectNav" data-${this.identifier}-key-param="${key}" data-${this.identifier}-label-param="${this.escape(label)}"
        class="px-3 py-1.5 min-h-[36px] rounded-lg text-[13px] transition-colors whitespace-nowrap flex items-center gap-1.5 touch-manipulation ${active ? activeClasses : idleClasses}">
        <span class="material-symbols-outlined text-[17px]">${icon}</span>
        <span>${label}</span>
      </button>
    `
  }

  renderHeadline() {
    return `
      <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-3 py-2 mb-3">
        <div class="flex flex-col">
          <div class="flex items-center gap-2">
            <span class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-success/10 text-success border border-success/20 text-[11px] font-semibold">
              <span class="w-1.5 h-1.5 rounded-full bg-success animate-pulse"></span>
              ${translate("Terminal Active")}
            </span>
            <span class="text-[11px] text-muted-foreground truncate">· ${this.escape(this.branchName)} · ${translate("Desk Station A1 (Central Turnstile)")}</span>
          </div>
          <h1 class="text-2xl font-bold text-foreground tracking-tight mt-1">${translate("Reception Operations Console")}</h1>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button type="button" data-action="click->${this.identifier}#toggleWalkin"
            class="flex items-center gap-1.5 px-3 py-2 min-h-[40px] rounded-lg bg-primary text-primary-foreground text-[13px] font-semibold shadow-sm hover:brightness-110 active:scale-95 transition-all touch-manipulation">
            <span class="material-symbols-outlined text-[18px]">person_add</span>
            <span>${translate("Quick Walk-In Check-In")}</span>
          </button>
          <button type="button" data-action="click->${this.identifier}#toggleDeliveryForm"
            class="flex items-center gap-1.5 px-3 py-2 min-h-[40px] rounded-lg bg-muted text-foreground text-[13px] font-semibold hover:bg-line active:scale-95 transition-all touch-manipulation">
            <span class="material-symbols-outlined text-[18px] text-warning">local_shipping</span>
            <span>${translate("Log Delivery")}</span>
          </button>
          <button type="button" data-action="click->${this.identifier}#issueBadge"
            class="flex items-center gap-1.5 px-3 py-2 min-h-[40px] rounded-lg bg-muted text-foreground text-[13px] font-semibold hover:bg-line active:scale-95 transition-all touch-manipulation">
            <span class="material-symbols-outlined text-[18px] text-primary">badge</span>
            <span>${translate("Issue Temp Badge")}</span>
          </button>
          <button type="button" data-action="click->${this.identifier}#broadcast"
            class="h-10 w-10 flex items-center justify-center rounded-lg bg-muted text-foreground hover:bg-line transition-colors touch-manipulation"
            title="${translate("Emergency broadcast to lobby display")}">
            <span class="material-symbols-outlined text-[20px] text-muted-foreground">campaign</span>
          </button>
        </div>
      </div>
    `
  }

  renderEmptyNotice() {
    if (this.visitors.length > 0 || this.deliveries.length > 0) return ""
    return `
      <div class="rounded-xl border border-line bg-card p-4 mb-3 flex items-start gap-3">
        <div class="w-9 h-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center shrink-0">
          <span class="material-symbols-outlined text-[20px]">info</span>
        </div>
        <div class="flex flex-col gap-0.5">
          <span class="text-sm font-bold text-foreground">${translate("No reception activity yet")}</span>
          <span class="text-[12px] text-muted-foreground">${translate("Walk-in check-ins and today's scheduled events will appear here. Create an Event for this branch or use the walk-in station.")}</span>
        </div>
      </div>
    `
  }

  renderKpis() {
    const inside = this.insideCount
    const lobby = this.lobbyVisitors.length
    const remaining = this.remainingToday
    const total = this.expectedToday
    const progress = this.expectedProgress
    const parcels = this.deliveries.length
    const roomsTotal = this.counts.rooms_total ?? this.rooms.length
    const roomsAvailable = this.roomAvailableCount
    const roomsReadyPercent = roomsTotal === 0 ? 0 : Math.round((roomsAvailable / roomsTotal) * 100)

    return `
      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3 mb-4">
        ${this.renderKpiCard({
          label: translate("Inside Building"),
          value: inside,
          unit: translate("Visitors"),
          icon: "groups",
          tone: "primary",
          footer: `<span class="material-symbols-outlined text-[14px]">south</span> ${this.counts.departed ?? this.departedVisitors.length} ${translate("checked out")}`
        })}
        ${this.renderKpiCard({
          label: translate("Lobby Waiting"),
          value: lobby,
          unit: translate("Guests"),
          icon: "chair",
          tone: lobby > 0 ? "warning" : "success",
          action: lobby > 0,
          footer: `<span class="material-symbols-outlined text-[14px]">timer</span> ${translate("Avg wait:")} ${this.averageWait} ${translate("mins")}`
        })}
        ${this.renderKpiCard({
          label: translate("Expected Today"),
          value: remaining,
          unit: translate("Remaining"),
          icon: "event_upcoming",
          tone: "primary",
          aside: `${total} ${translate("Sched")}`,
          progress: progress,
          footer: `${translate("Progress")}: ${progress}%`
        })}
        ${this.renderKpiCard({
          label: translate("Parcel Intake"),
          value: parcels,
          unit: translate("Held at Desk"),
          icon: "inventory_2",
          tone: "warning",
          aside: `<span class="material-symbols-outlined text-[16px] text-muted-foreground">shelves</span>`,
          footer: `<span class="w-2 h-2 rounded-full bg-success inline-block"></span> ${this.lockerFreeCount} ${translate("lockers available")}`
        })}
        ${this.renderKpiCard({
          label: translate("Facility Rooms"),
          value: roomsAvailable,
          unit: `/ ${roomsTotal} ${translate("Ready")}`,
          icon: "meeting_room",
          tone: "success",
          aside: `${roomsReadyPercent}% ${translate("Free")}`,
          footer: `<span class="material-symbols-outlined text-[14px] text-warning">lock_clock</span> ${this.roomBusyCount} ${translate("in active sessions")}`
        })}
      </div>
    `
  }

  renderKpiCard({ label, value, unit, icon, tone, footer, aside = "", progress = null, action = false }) {
    const tones = {
      primary: "text-primary",
      success: "text-success",
      warning: "text-warning",
      danger: "text-danger",
      info: "text-info"
    }
    const toneClass = tones[tone] || tones.primary

    return `
      <div class="relative overflow-hidden rounded-xl bg-card border border-line shadow-sm p-3 flex flex-col justify-between group hover:shadow-md transition-shadow">
        <div class="absolute right-2 top-2 opacity-10 group-hover:opacity-20 transition-opacity">
          <span class="material-symbols-outlined text-[48px] ${toneClass}">${icon}</span>
        </div>
        <div class="flex items-center justify-between gap-2">
          <span class="text-[11px] font-semibold text-muted-foreground">${label}</span>
          ${action ? `<span class="px-1.5 py-0.5 rounded text-[10px] bg-warning/10 text-warning font-bold animate-pulse">${translate("Action")}</span>` : `<span class="text-[10px] text-muted-foreground font-mono">${aside}</span>`}
        </div>
        <div class="mt-2">
          <div class="flex items-baseline gap-1.5">
            <span class="text-3xl font-extrabold tracking-tight ${toneClass}">${value}</span>
            <span class="text-[11px] text-muted-foreground">${unit}</span>
          </div>
          ${progress === null ? "" : `
            <div class="w-full bg-muted rounded-full h-1.5 mt-2 overflow-hidden">
              <div class="bg-primary h-full rounded-full" style="width: ${progress}%"></div>
            </div>
          `}
          <div class="text-[11px] text-muted-foreground flex items-center gap-1 mt-1.5">${footer}</div>
        </div>
      </div>
    `
  }

  renderQueueToolbar() {
    return `
      <div class="rounded-xl bg-card border border-line shadow-sm p-3 flex flex-col gap-2">
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-2">
          <div class="relative flex-1">
            <span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-[18px] text-muted-foreground pointer-events-none">search</span>
            <input id="reception-filter-input" type="text" value="${this.escape(this.searchQuery)}"
              data-reception-search
              data-action="input->${this.identifier}#updateSearch keydown.esc->${this.identifier}#clearSearch"
              placeholder="${translate("Filter by visitor name, company, host, or badge #...")}"
              class="w-full h-10 pl-9 pr-3 rounded-lg bg-muted text-foreground placeholder:text-muted-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary transition-all" />
          </div>
          <div id="reception-queue-tabs" class="flex items-center gap-1 p-1 rounded-lg bg-muted overflow-x-auto">
            ${this.renderQueueTabs()}
          </div>
        </div>
        <div class="flex flex-wrap items-center justify-between gap-2 text-[11px] text-muted-foreground">
          <div class="flex items-center gap-2">
            <span>${translate("Showing:")} <strong class="text-foreground" data-reception-tab-label>${this.activeTabLabel}</strong></span>
            <span class="w-1 h-1 rounded-full bg-line"></span>
            <span class="text-warning font-semibold flex items-center gap-1">
              <span class="w-1.5 h-1.5 rounded-full bg-warning"></span> ${this.vipCount} ${translate("VIP flagged")}
            </span>
          </div>
          <div class="flex items-center gap-3">
            <span class="flex items-center gap-1"><span class="material-symbols-outlined text-[14px]">tune</span> ${translate("Density: Standard")}</span>
            <span class="flex items-center gap-1"><span class="material-symbols-outlined text-[14px]">refresh</span> ${translate("Auto-sync: 15s")}</span>
          </div>
        </div>
      </div>
    `
  }

  get activeTabLabel() {
    const labels = {
      lobby: translate("Active Lobby Queue"),
      active: translate("Inside Building"),
      upcoming: translate("Next Hour"),
      departed: translate("Departed")
    }
    return labels[this.activeTab] || labels.lobby
  }

  get vipCount() { return this.visitors.filter((visitor) => visitor.vip && visitor.status !== "departed").length }

  renderQueueTabs() {
    const tabs = [
      { key: "lobby", label: translate("In Lobby"), count: this.lobbyVisitors.length },
      { key: "active", label: translate("Active in Bldg"), count: this.activeVisitors.length },
      { key: "upcoming", label: translate("Next Hour"), count: this.upcomingVisitors.length },
      { key: "departed", label: translate("Departed"), count: this.departedVisitors.length }
    ]

    return tabs.map((tab) => {
      const active = tab.key === this.activeTab
      return `
        <button type="button" data-action="click->${this.identifier}#setTab" data-${this.identifier}-tab-param="${tab.key}"
          class="px-2 py-1 min-h-[32px] rounded-md text-[11px] font-semibold whitespace-nowrap transition-all touch-manipulation ${active ? "bg-card text-foreground shadow-sm border border-line" : "text-muted-foreground hover:text-foreground"}">
          ${tab.label} (${tab.count})
        </button>
      `
    }).join("")
  }

  renderVisitorCards() {
    const visible = this.filteredVisitors()
    if (visible.length === 0) {
      return `<div class="rounded-xl border border-line bg-card p-8 text-center text-sm text-muted-foreground">${translate("No visitors match this view.")}</div>`
    }
    return visible.map((visitor) => this.renderVisitorCard(visitor)).join("")
  }

  filteredVisitors() {
    const query = this.searchQuery.trim().toLowerCase()
    return this.visitors.filter((visitor) => {
      const matchesTab = visitor.status === this.activeTab
      const matchesQuery = !query || visitor.search.includes(query)
      return matchesTab && matchesQuery
    })
  }

  renderVisitorCard(visitor) {
    const borderTone = visitor.vip ? "border-l-warning" : {
      lobby: "border-l-warning",
      active: "border-l-success",
      upcoming: "border-l-info",
      departed: "border-l-line"
    }[visitor.status] || "border-l-line"

    const statusChip = {
      lobby: `<span class="flex items-center gap-1 text-warning font-semibold"><span class="material-symbols-outlined text-[15px]">timer</span> ${translate("Waiting")} ${visitor.waitMin} ${translate("mins")}</span>`,
      active: `<span class="flex items-center gap-1 text-success font-medium"><span class="material-symbols-outlined text-[15px]">check_circle</span> ${translate("Inside")}</span>`,
      upcoming: `<span class="flex items-center gap-1 text-info font-medium"><span class="material-symbols-outlined text-[15px]">event</span> ${translate("Expected")} ${this.escape(visitor.arrival)}</span>`,
      departed: `<span class="flex items-center gap-1 text-muted-foreground"><span class="material-symbols-outlined text-[15px]">logout</span> ${translate("Departed")}</span>`
    }[visitor.status] || ""

    const actions = this.renderVisitorActions(visitor)

    return `
      <div data-reception-visitor data-status="${visitor.status}" data-search="${this.escape(visitor.search)}"
        class="rounded-xl bg-card border border-line border-l-4 ${borderTone} shadow-sm hover:shadow-md transition-all p-3 flex flex-col md:flex-row md:items-center justify-between gap-3">
        <div class="flex items-start gap-3 min-w-0">
          <div class="relative shrink-0">
            <div class="w-12 h-12 rounded-full bg-muted text-foreground flex items-center justify-center font-bold text-sm">
              ${this.escape(this.initialsFor(visitor.name))}
            </div>
            ${visitor.vip
              ? `<span class="absolute -bottom-1 -right-1 w-5 h-5 rounded-full bg-warning text-warning-foreground flex items-center justify-center font-bold text-[10px]" title="${translate("VIP Client")}">★</span>`
              : `<span class="absolute -bottom-1 -right-1 w-5 h-5 rounded-full ${this.statusDotClass(visitor.status)} flex items-center justify-center font-bold text-[9px]" title="${this.escape(visitor.status)}">${this.statusShort(visitor.status)}</span>`}
          </div>
          <div class="flex flex-col min-w-0">
            <div class="flex flex-wrap items-center gap-1.5">
              <span class="text-[15px] font-bold text-foreground truncate">${this.escape(visitor.name)}</span>
              <span class="px-2 py-0.5 rounded-full text-[10px] font-semibold ${visitor.vip ? "bg-warning/10 text-warning border border-warning/20" : "bg-muted text-muted-foreground border border-line"}">${this.escape(translate(visitor.kind))}</span>
              <span class="px-2 py-0.5 rounded text-[10px] bg-muted text-muted-foreground font-mono border border-line">${translate("Pass")} #${this.escape(visitor.badge)}</span>
            </div>
            <div class="flex flex-wrap items-center gap-x-2 gap-y-1 mt-1 text-[12px] text-muted-foreground">
              <span class="font-medium text-foreground">${this.escape(visitor.company)}</span>
              <span>·</span>
              <span class="flex items-center gap-1">
                <span class="material-symbols-outlined text-[15px] text-primary">person</span>
                ${translate("Host:")} <strong class="text-foreground">${this.escape(visitor.host)}</strong> (${this.escape(translate(visitor.hostRole))})
              </span>
              <span>·</span>
              ${statusChip}
            </div>
            <div class="flex flex-wrap items-center gap-x-3 gap-y-1 mt-1.5 text-[11px] text-muted-foreground">
              <span>${translate("Arrival:")} <strong class="text-foreground">${this.escape(visitor.arrival)}</strong></span>
              <span>·</span>
              <span>${this.escape(this.visitorNote(visitor))}</span>
              <span>·</span>
              <span>${translate("Zone:")} <strong class="text-foreground">${this.escape(translate(visitor.zone))}</strong></span>
            </div>
          </div>
        </div>
        <div class="flex items-center gap-1.5 shrink-0 pt-2 md:pt-0 border-t md:border-t-0 border-line">
          ${actions}
        </div>
      </div>
    `
  }

  renderVisitorActions(visitor) {
    const button = (action, icon, label, extraClass = "", params = "") => `
      <button type="button" data-action="click->${this.identifier}#${action}" data-${this.identifier}-id-param="${visitor.id}"${params}
        class="px-3 py-1.5 min-h-[36px] rounded-lg text-[12px] font-semibold flex items-center gap-1 transition-all touch-manipulation ${extraClass}">
        <span class="material-symbols-outlined text-[16px]">${icon}</span>
        <span>${label}</span>
      </button>
    `
    const iconButton = (action, icon, title) => `
      <button type="button" data-action="click->${this.identifier}#${action}" data-${this.identifier}-id-param="${visitor.id}"
        class="h-10 w-10 flex items-center justify-center rounded-lg bg-muted text-foreground hover:bg-line transition-colors touch-manipulation"
        title="${title}">
        <span class="material-symbols-outlined text-[18px]">${icon}</span>
      </button>
    `

    if (visitor.status === "lobby") {
      return `
        ${button("notifyHost", "notifications_active", translate("Re-Notify Host"), "bg-primary text-primary-foreground hover:brightness-110 active:scale-95 shadow-sm")}
        ${iconButton("printBadge", "print", translate("Print visitor badge"))}
        ${iconButton("checkoutVisitor", "login", translate("Check in visitor"))}
      `
    }

    if (visitor.status === "active") {
      return `
        ${button("checkoutVisitor", "logout", translate("Complete Check-Out"), "bg-muted text-foreground hover:bg-line active:scale-95")}
        ${iconButton("manageKey", "vpn_key", translate("Manage key or access"))}
        ${iconButton("printBadge", "badge", translate("Badge details"))}
      `
    }

    if (visitor.status === "upcoming") {
      return `
        ${button("notifyHost", "notifications_active", translate("Notify Host"), "bg-muted text-foreground hover:bg-line active:scale-95")}
        ${iconButton("printBadge", "print", translate("Pre-print visitor badge"))}
      `
    }

    return `
      ${button("checkoutVisitor", "undo", translate("Re-open Visit"), "bg-muted text-foreground hover:bg-line active:scale-95")}
      ${iconButton("printBadge", "print", translate("Print visitor badge"))}
    `
  }

  statusDotClass(status) {
    return {
      lobby: "bg-warning text-warning-foreground",
      active: "bg-success text-success-foreground",
      upcoming: "bg-info text-info-foreground",
      departed: "bg-muted text-muted-foreground"
    }[status] || "bg-muted text-muted-foreground"
  }

  statusShort(status) {
    return {
      lobby: translate("W"),
      active: translate("IN"),
      upcoming: translate("EXP"),
      departed: translate("OUT")
    }[status] || ""
  }

  renderWalkinStation() {
    return `
      <div id="reception-walkin-station" class="${this.walkinOpen ? "" : "hidden"} rounded-xl bg-muted border border-line p-4 flex flex-col gap-3">
        <div class="flex items-center justify-between gap-3">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-primary text-primary-foreground flex items-center justify-center">
              <span class="material-symbols-outlined text-[20px]">badge</span>
            </div>
            <div>
              <h2 class="text-[15px] font-bold text-foreground leading-tight">${translate("Instant Walk-In Guest Badge Station")}</h2>
              <span class="text-[11px] text-muted-foreground">${translate("Generates a digital badge and notifies the host on dispatch")}</span>
            </div>
          </div>
          <button type="button" data-action="click->${this.identifier}#toggleWalkin"
            class="h-10 w-10 flex items-center justify-center rounded-lg bg-card text-muted-foreground hover:text-foreground border border-line touch-manipulation"
            title="${translate("Close")}">
            <span class="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>
        <form data-action="submit->${this.identifier}#submitWalkin" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-2">
          <div>
            <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("Full Guest Name")}</label>
            <input name="visitor[name]" type="text" required
              class="w-full h-10 px-2.5 rounded-lg bg-card text-foreground placeholder:text-muted-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary"
              placeholder="${translate("e.g. Jessica Tan")}" />
          </div>
          <div>
            <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("Company / Organization")}</label>
            <input name="visitor[company]" type="text" required
              class="w-full h-10 px-2.5 rounded-lg bg-card text-foreground placeholder:text-muted-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary"
              placeholder="${translate("e.g. Deloitte Consulting")}" />
          </div>
          <div>
            <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("Internal Host (Staff)")}</label>
            <select name="visitor[host_id]"
              class="w-full h-10 px-2.5 rounded-lg bg-card text-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary">
              <option value="">${translate("General Front Desk Escort")}</option>
              ${(this.reference.hosts || []).map((host) => `
                <option value="${this.escape(host.id)}">${this.escape(host.name)}${host.role ? ` (${this.escape(translate(host.role))})` : ""}</option>
              `).join("")}
            </select>
          </div>
          <div>
            <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("Access Level & Zone")}</label>
            <select name="visitor[facility_id]"
              class="w-full h-10 px-2.5 rounded-lg bg-card text-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary">
              <option value="">${translate("Standard Visitor (Lobby & 3F Meeting)")}</option>
              ${(this.reference.facilities || []).map((facility) => `
                <option value="${this.escape(facility.id)}">${this.escape(facility.name)}${facility.category ? ` · ${this.escape(translate(facility.category))}` : ""}</option>
              `).join("")}
            </select>
          </div>
          <div class="sm:col-span-2 lg:col-span-4 flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-2 pt-1">
            <div class="flex flex-wrap items-center gap-3">
              <label class="flex items-center gap-2 text-[11px] text-foreground">
                <input name="visitor[notify]" type="checkbox" checked class="w-4 h-4 rounded accent-primary" />
                ${translate("Send arrival SMS to host")}
              </label>
              <label class="flex items-center gap-2 text-[11px] text-foreground">
                <input name="visitor[print]" type="checkbox" checked class="w-4 h-4 rounded accent-primary" />
                ${translate("Auto-print adhesive ID badge")}
              </label>
            </div>
            <button type="submit"
              class="px-4 py-2 min-h-[42px] rounded-lg bg-primary text-primary-foreground text-[13px] font-semibold hover:brightness-110 active:scale-95 transition-all flex items-center justify-center gap-2 shadow-sm touch-manipulation">
              <span class="material-symbols-outlined text-[18px]">verified</span>
              <span>${translate("Check-In & Print Badge")}</span>
            </button>
          </div>
        </form>
      </div>
    `
  }

  renderRoomsPanel() {
    return `
      <div class="rounded-xl bg-card border border-line shadow-sm p-3 flex flex-col gap-2">
        <div class="flex items-center justify-between pb-2 border-b border-line">
          <div class="flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[20px] text-primary">meeting_room</span>
            <h2 class="text-[15px] font-bold text-foreground">${translate("Upcoming & Rooms")}</h2>
          </div>
          <span class="text-[11px] text-success font-bold">${this.roomAvailableCount} ${translate("Available")}</span>
        </div>
        <div class="grid grid-cols-3 gap-1.5">
          ${this.rooms.map((room) => this.renderRoom(room)).join("")}
        </div>
        <div class="flex flex-col gap-2 mt-1">
          <span class="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">${translate("Next Incoming Appointments")}</span>
          ${this.appointments.map((appointment) => this.renderAppointment(appointment)).join("")}
        </div>
        <button type="button" data-action="click->${this.identifier}#selectNav" data-${this.identifier}-key-param="appointments" data-${this.identifier}-label-param="${translate("Appointments & Rooms")}"
          class="w-full py-1.5 min-h-[34px] rounded-lg bg-muted text-foreground text-[11px] font-semibold hover:bg-line transition-colors flex items-center justify-center gap-1 touch-manipulation">
          <span class="material-symbols-outlined text-[16px]">calendar_month</span>
          <span>${translate("View all")} ${this.expectedToday} ${translate("appointments for today")}</span>
        </button>
      </div>
    `
  }

  renderRoom(room) {
    const tone = {
      available: "text-success",
      busy: "text-danger",
      reserved: "text-warning"
    }[room.status] || "text-muted-foreground"
    const label = room.status === "available"
      ? translate("Available")
      : room.status === "busy"
        ? `${translate("Busy until")} ${room.time_label}`
        : `${translate("Reserved")} ${room.time_label}`

    return `
      <div class="p-2 rounded-lg bg-muted border border-line flex flex-col items-center text-center">
        <span class="text-[10px] font-bold text-foreground truncate w-full">${this.escape(room.name)}</span>
        <span class="text-[10px] font-semibold ${tone} mt-0.5">${this.escape(label)}</span>
      </div>
    `
  }

  appointmentInLabel(appointment) {
    if (appointment.minutes_until === null || appointment.minutes_until === undefined) {
      return translate(appointment.in || "")
    }
    return `${translate("In")} ${appointment.minutes_until} ${translate("min")}`
  }

  renderAppointment(appointment) {
    return `
      <div class="p-2 rounded-lg bg-muted border border-line hover:bg-line/40 transition-colors flex items-start gap-2">
        <div class="w-12 text-center shrink-0 pt-0.5">
          <span class="text-[13px] font-bold text-foreground block leading-tight">${this.escape(appointment.time)}</span>
          <span class="text-[9px] text-muted-foreground font-medium">${this.escape(this.appointmentInLabel(appointment))}</span>
        </div>
        <div class="flex-1 min-w-0">
          <div class="flex items-center justify-between gap-2">
            <span class="text-[12px] font-bold text-foreground truncate">${this.escape(translate(appointment.title))}</span>
            <span class="px-1.5 py-0.5 rounded text-[9px] bg-primary/10 text-primary font-semibold whitespace-nowrap">${this.escape(translate(appointment.status))}</span>
          </div>
          <p class="text-[11px] text-muted-foreground truncate mt-0.5">${translate("Host:")} ${this.escape(appointment.host)} · ${this.escape(appointment.room)}</p>
        </div>
      </div>
    `
  }

  renderDeliveriesPanel() {
    return `
      <div class="rounded-xl bg-card border border-line shadow-sm p-3 flex flex-col gap-2">
        <div class="flex items-center justify-between pb-2 border-b border-line">
          <div class="flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[20px] text-warning">local_shipping</span>
            <h2 class="text-[15px] font-bold text-foreground">${translate("Couriers & Deliveries")}</h2>
          </div>
          <span class="text-[11px] text-warning font-bold">${this.deliveries.length} ${translate("Awaiting Pickup")}</span>
        </div>
        <div id="reception-delivery-list" class="flex flex-col gap-2">
          ${this.renderDeliveryItems()}
        </div>
        <div id="reception-delivery-form" class="${this.deliveryFormOpen ? "" : "hidden"} rounded-lg bg-muted border border-line p-2.5">
          <form data-action="submit->${this.identifier}#submitDelivery" class="flex flex-col gap-2">
            <div class="grid grid-cols-2 gap-2">
              <div>
                <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("Carrier")}</label>
                <input name="parcel[carrier]" type="text" required placeholder="${translate("DHL, FedEx...")}"
                  class="w-full h-9 px-2 rounded-lg bg-card text-foreground text-[12px] border border-line focus:outline-none focus:ring-2 focus:ring-primary" />
              </div>
              <div>
                <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("Recipient")}</label>
                <select name="parcel[employee_id]" required
                  class="w-full h-9 px-2 rounded-lg bg-card text-foreground text-[12px] border border-line focus:outline-none focus:ring-2 focus:ring-primary">
                  <option value="">${translate("Employee name")}</option>
                  ${(this.reference.hosts || []).map((host) => `
                    <option value="${this.escape(host.id)}">${this.escape(host.name)}</option>
                  `).join("")}
                </select>
              </div>
            </div>
            <div>
              <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("Item summary")}</label>
              <input name="parcel[item]" type="text" required placeholder="${translate("e.g. Legal documents · Signed packet")}"
                class="w-full h-9 px-2 rounded-lg bg-card text-foreground text-[12px] border border-line focus:outline-none focus:ring-2 focus:ring-primary" />
            </div>
            <div class="flex items-center justify-end gap-1.5">
              <button type="button" data-action="click->${this.identifier}#toggleDeliveryForm"
                class="px-2.5 py-1.5 min-h-[34px] rounded-lg bg-card text-foreground text-[11px] font-semibold border border-line hover:bg-line touch-manipulation">
                ${translate("Cancel")}
              </button>
              <button type="submit"
                class="px-2.5 py-1.5 min-h-[34px] rounded-lg bg-primary text-primary-foreground text-[11px] font-semibold hover:brightness-110 flex items-center gap-1 touch-manipulation">
                <span class="material-symbols-outlined text-[15px]">add</span>
                ${translate("Log package")}
              </button>
            </div>
          </form>
        </div>
        <div class="flex items-center justify-between pt-1">
          <button type="button" data-action="click->${this.identifier}#toggleDeliveryForm"
            class="min-h-[32px] text-[11px] text-primary font-bold hover:underline flex items-center gap-1 touch-manipulation">
            <span class="material-symbols-outlined text-[16px]">qr_code_scanner</span>
            ${translate("Log delivery / scan waybill")}
          </button>
          <span class="text-[11px] text-muted-foreground">${translate("Locker capacity:")} ${Math.min(100, Math.round((this.deliveries.length / 8) * 100))}%</span>
        </div>
      </div>
    `
  }

  renderDeliveryItems() {
    if (this.deliveries.length === 0) {
      return `<div class="text-center text-[12px] text-muted-foreground py-3">${translate("No parcels waiting at the desk.")}</div>`
    }

    const tones = {
      warning: "bg-warning/10 text-warning",
      primary: "bg-primary/10 text-primary",
      success: "bg-success/10 text-success",
      info: "bg-info/10 text-info"
    }

    return this.deliveries.map((delivery) => `
      <div class="p-2 rounded-lg bg-muted border border-line flex items-center justify-between gap-2">
        <div class="flex items-center gap-2 min-w-0">
          <div class="w-8 h-8 rounded-lg ${tones[delivery.tone] || tones.primary} flex items-center justify-center shrink-0 font-bold text-[10px]">
            ${this.escape(delivery.carrier)}
          </div>
          <div class="flex flex-col min-w-0">
            <span class="text-[12px] font-bold text-foreground truncate">${this.escape(translate(delivery.title))}</span>
            <span class="text-[11px] text-muted-foreground truncate">${translate("For:")} <strong class="text-foreground">${this.escape(delivery.recipient)}</strong></span>
            <span class="text-[10px] text-success font-semibold truncate">${this.escape(translate(delivery.location))}${delivery.received_at ? ` · ${this.escape(delivery.received_at)}` : ""}</span>
          </div>
        </div>
        <div class="flex items-center gap-1 shrink-0">
          <button type="button" data-action="click->${this.identifier}#deliveryAction" data-${this.identifier}-id-param="${delivery.id}"
            class="px-2 py-1 rounded-md bg-card text-primary text-[10px] font-semibold border border-line hover:bg-line transition-colors">
            ${this.escape(delivery.action)}
          </button>
          <button type="button" data-action="click->${this.identifier}#pickUpParcel" data-${this.identifier}-id-param="${delivery.id}"
            class="h-9 w-9 flex items-center justify-center rounded-md bg-card text-success border border-line hover:bg-line transition-colors touch-manipulation"
            title="${translate("Mark picked up")}">
            <span class="material-symbols-outlined text-[16px]">inventory_2</span>
          </button>
        </div>
      </div>
    `).join("")
  }

  renderSpeedDialPanel() {
    const lines = [
      { label: translate("Security Command"), ext: "101", icon: "shield", tone: "danger" },
      { label: translate("Facilities Urgent"), ext: "104", icon: "handyman", tone: "warning" },
      { label: translate("Valet / Parking"), ext: "109", icon: "local_parking", tone: "info" },
      { label: translate("First Aid Post"), ext: "911", icon: "medical_services", tone: "success" }
    ]
    const tones = {
      danger: "bg-danger/10 text-danger",
      warning: "bg-warning/10 text-warning",
      info: "bg-info/10 text-info",
      success: "bg-success/10 text-success"
    }

    return `
      <div class="rounded-xl bg-card border border-line shadow-sm p-3 flex flex-col gap-2">
        <div class="flex items-center justify-between pb-2 border-b border-line">
          <div class="flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[20px] text-danger">phone_in_talk</span>
            <h2 class="text-[15px] font-bold text-foreground">${translate("Speed Dial & Emergency Desk")}</h2>
          </div>
          <span class="px-2 py-0.5 rounded text-[10px] bg-success/10 text-success border border-success/20 font-mono font-bold">${translate("VOIP UP")}</span>
        </div>
        <div class="grid grid-cols-2 gap-1.5">
          ${lines.map((line) => `
            <button type="button" data-action="click->${this.identifier}#dialLine" data-${this.identifier}-label-param="${this.escape(line.label)}" data-${this.identifier}-ext-param="${line.ext}"
              class="p-2 min-h-[44px] rounded-lg bg-muted border border-line hover:bg-line/40 flex items-center gap-2 text-left transition-colors group touch-manipulation">
              <div class="w-8 h-8 rounded-full ${tones[line.tone]} flex items-center justify-center shrink-0 group-hover:scale-105 transition-transform">
                <span class="material-symbols-outlined text-[18px]">${line.icon}</span>
              </div>
              <div class="flex flex-col min-w-0">
                <span class="text-[11px] font-bold text-foreground truncate">${line.label}</span>
                <span class="text-[10px] text-muted-foreground font-mono">${translate("Ext.")} #${line.ext}</span>
              </div>
            </button>
          `).join("")}
        </div>
        <div class="p-2 rounded-lg bg-muted border border-line flex items-center justify-between text-[11px] text-muted-foreground">
          <span class="flex items-center gap-1">
            <span class="w-2 h-2 rounded-full bg-success"></span>
            ${translate("PA System: Channel 1 connected")}
          </span>
          <button type="button" data-action="click->${this.identifier}#chime" class="min-h-[32px] text-primary font-bold hover:underline touch-manipulation">${translate("Test Chime")}</button>
        </div>
      </div>
    `
  }

  renderFooter() {
    return `
      <footer class="w-full bg-muted border-t border-line py-2 px-4 lg:px-6">
        <div class="flex flex-col sm:flex-row items-center justify-between gap-1 text-[11px] text-muted-foreground">
          <div>© ${new Date().getFullYear()} Skycom ERP Technologies Inc. ${translate("All rights reserved.")} · ${translate("Enterprise Reception")} v1.0</div>
          <div class="flex items-center gap-3">
            <span class="flex items-center gap-1"><span class="w-2 h-2 rounded-full bg-success"></span>${translate("Terminal Operational")}</span>
            <span>${translate("Emergency Ext:")} 9110</span>
            <span>${translate("FrontDesk Support")}</span>
          </div>
        </div>
      </footer>
    `
  }

  // --- Interactions ----------------------------------------------------------------

  updateSearch(event) {
    this.searchQuery = event.target.value || ""
    document.querySelectorAll("[data-reception-search]").forEach((input) => {
      if (input !== event.target) input.value = this.searchQuery
    })
    this.applyFilters()
  }

  clearSearch(event) {
    if (event) event.preventDefault()
    this.searchQuery = ""
    document.querySelectorAll("[data-reception-search]").forEach((input) => { input.value = "" })
    this.applyFilters()
  }

  applyFilters() {
    document.querySelectorAll("[data-reception-visitor]").forEach((card) => {
      const matchesQuery = !this.searchQuery || card.dataset.search.includes(this.searchQuery.trim().toLowerCase())
      card.classList.toggle("hidden", !matchesQuery)
    })
  }

  setTab(event) {
    this.activeTab = event.params.tab
    this.searchQuery = ""
    document.querySelectorAll("[data-reception-search]").forEach((input) => { input.value = "" })
    document.getElementById("reception-queue-tabs").innerHTML = this.renderQueueTabs()
    document.getElementById("reception-visitor-list").innerHTML = this.renderVisitorCards()
    const toolbar = document.querySelector("[data-reception-tab-label]")
    if (toolbar) toolbar.textContent = this.activeTabLabel
    this.applyFilters()
  }

  focusLobby() {
    this.setTab({ params: { tab: "lobby" } })
    document.getElementById("reception-visitor-list")?.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  toggleWalkin() {
    const station = document.getElementById("reception-walkin-station")
    if (!station) return
    this.walkinOpen = !this.walkinOpen
    station.classList.toggle("hidden", !this.walkinOpen)
    if (this.walkinOpen) {
      station.scrollIntoView({ behavior: "smooth", block: "center" })
      setTimeout(() => station.querySelector('input[name="visitor[name]"]')?.focus(), 250)
    }
  }

  async submitWalkin(event) {
    event.preventDefault()
    const form = event.target
    const data = new FormData(form)
    const name = String(data.get("visitor[name]") || "").trim()
    const company = String(data.get("visitor[company]") || "").trim()
    const hostId = String(data.get("visitor[host_id]") || "").trim()
    const facilityId = String(data.get("visitor[facility_id]") || "").trim()
    const notify = data.get("visitor[notify]") === "on"
    const print = data.get("visitor[print]") === "on"

    if (!name) {
      toast({ type: "error", message: translate("Guest name is required.") })
      form.querySelector('input[name="visitor[name]"]')?.focus()
      return
    }
    if (!company) {
      toast({ type: "error", message: translate("Company or organization is required.") })
      form.querySelector('input[name="visitor[company]"]')?.focus()
      return
    }

    try {
      const response = await fetchJson(
        Helpers.reception_check_in_company_operation_path(this.companyId, this.operationId),
        {
          method: "POST",
          body: {
            branch_id: this.branchId,
            visitor: {
              name,
              company,
              host_id: hostId || null,
              facility_id: facilityId || null,
              notify,
              print
            }
          }
        }
      )

      form.reset()
      this.walkinOpen = false
      document.getElementById("reception-walkin-station")?.classList.add("hidden")
      toast({ type: "success", message: response.message || `${translate("Walk-in check-in complete for")} ${name}.` })
      await this.reloadConsole()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to check in the guest.") })
    }
  }

  async notifyHost(event) {
    const visitor = this.findVisitor(event.params.id)
    if (!visitor) return

    try {
      const response = await fetchJson(
        Helpers.reception_notify_host_company_operation_path(this.companyId, this.operationId),
        {
          method: "POST",
          body: { branch_id: this.branchId, event_id: visitor.event_id }
        }
      )
      toast({ type: "success", message: response.message || translate("Host notification logged.") })
      await this.reloadConsole()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to notify the host.") })
    }
  }

  printBadge(event) {
    const visitor = this.findVisitor(event.params.id)
    if (!visitor) return
    toast({ type: "success", message: `${translate("Badge")} ${visitor.badge} ${translate("sent to the printer for")} ${visitor.name}.` })
  }

  async checkoutVisitor(event) {
    const visitor = this.findVisitor(event.params.id)
    if (!visitor) return

    const action = visitor.status === "departed"
      ? "reopen"
      : visitor.status === "lobby"
        ? "check_in"
        : "check_out"

    try {
      const response = await fetchJson(
        Helpers.reception_advance_company_operation_path(this.companyId, this.operationId),
        {
          method: "POST",
          body: { branch_id: this.branchId, event_id: visitor.event_id, transition: action }
        }
      )
      toast({ type: "success", message: response.message || translate("Visit updated.") })
      await this.reloadConsole()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to update the visit.") })
    }
  }

  manageKey(event) {
    const visitor = this.findVisitor(event.params.id)
    if (!visitor) return
    toast({ type: "info", message: `${translate("Key station unlocked for")} ${visitor.name}. ${translate("Return keys before check-out.")}` })
  }

  async deliveryAction(event) {
    const delivery = this.deliveries.find((item) => item.id === event.params.id)
    if (!delivery) return

    try {
      const response = await fetchJson(
        Helpers.reception_parcel_notify_company_operation_path(this.companyId, this.operationId, delivery.id),
        {
          method: "POST",
          body: { branch_id: this.branchId }
        }
      )
      toast({ type: "success", message: response.message || `${translate("Notify")}: ${delivery.recipient}` })
      await this.reloadConsole()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to notify the recipient.") })
    }
  }

  async pickUpParcel(event) {
    const delivery = this.deliveries.find((item) => item.id === event.params.id)
    if (!delivery) return

    try {
      const response = await fetchJson(
        Helpers.reception_parcel_pick_up_company_operation_path(this.companyId, this.operationId, delivery.id),
        {
          method: "POST",
          body: { branch_id: this.branchId }
        }
      )
      toast({ type: "success", message: response.message || translate("Parcel marked as picked up.") })
      await this.reloadConsole()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to mark the parcel as picked up.") })
    }
  }

  toggleDeliveryForm() {
    const panel = document.getElementById("reception-delivery-form")
    if (!panel) return
    this.deliveryFormOpen = !this.deliveryFormOpen
    panel.classList.toggle("hidden", !this.deliveryFormOpen)
    if (this.deliveryFormOpen) {
      panel.scrollIntoView({ behavior: "smooth", block: "center" })
      setTimeout(() => panel.querySelector('input[name="parcel[carrier]"]')?.focus(), 250)
    }
  }

  async submitDelivery(event) {
    event.preventDefault()
    const form = event.target
    const data = new FormData(form)
    const carrier = String(data.get("parcel[carrier]") || "").trim()
    const employeeId = String(data.get("parcel[employee_id]") || "").trim()
    const item = String(data.get("parcel[item]") || "").trim()

    if (!carrier || !employeeId || !item) {
      toast({ type: "error", message: translate("Carrier, recipient and item summary are required.") })
      return
    }

    try {
      const response = await fetchJson(
        Helpers.reception_parcels_company_operation_path(this.companyId, this.operationId),
        {
          method: "POST",
          body: {
            branch_id: this.branchId,
            parcel: { carrier, employee_id: employeeId, item }
          }
        }
      )

      form.reset()
      this.deliveryFormOpen = false
      document.getElementById("reception-delivery-form")?.classList.add("hidden")
      toast({ type: "success", message: response.message || `${translate("Parcel logged for")} ${item}` })
      await this.reloadConsole()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to log the parcel.") })
    }
  }

  selectNav(event) {
    if (event.params.key === "console") return
    toast({ type: "info", message: `${event.params.label} ${translate("is coming soon.")}` })
  }

  issueBadge() {
    toast({ type: "info", message: translate("Temporary badge issuing is not connected yet.") })
  }

  broadcast() {
    toast({ type: "warning", message: translate("Emergency broadcast is not connected yet.") })
  }

  dialLine(event) {
    toast({ type: "info", message: `${translate("Calling")} ${event.params.label} · ${translate("Ext.")} #${event.params.ext}` })
  }

  chime() {
    toast({ type: "success", message: translate("Chime broadcast over the lobby PA.") })
  }

  // --- Helpers ---------------------------------------------------------------------

  findVisitor(id) {
    return this.visitors.find((visitor) => visitor.id === id)
  }

  visitorNote(visitor) {
    if (visitor.note_key === "checked_in") return `${translate("Checked in at")} ${visitor.note_time}`
    if (visitor.note_key === "checked_out") return `${translate("Checked out at")} ${visitor.note_time}`

    const notes = {
      waiting: "Waiting at reception",
      inside: "Inside the building",
      pre_registered: "Pre-registered",
      completed: "Completed"
    }
    return translate(notes[visitor.note_key] || visitor.note || "")
  }

  initialsFor(name) {
    const parts = String(name || "").trim().split(/\s+/).filter(Boolean)
    if (parts.length === 0) return "?"
    return parts.slice(0, 2).map((part) => part[0].toUpperCase()).join("")
  }

  get currentShift() {
    const hour = new Date().getHours()
    if (hour < 12) return translate("Morning (08:00 - 17:00)")
    if (hour < 17) return translate("Afternoon (12:00 - 21:00)")
    return translate("Evening (17:00 - 01:00)")
  }

  get branchName() {
    return this.appointment?.location?.name || this.appointment?.branch?.name || this.operation?.branch?.name || translate("Branch not resolved")
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
