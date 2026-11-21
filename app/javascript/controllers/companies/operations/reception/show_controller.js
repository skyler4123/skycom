import { Controller } from "@hotwired/stimulus"

// Skycom Reception — one front-desk page for the branch-scoped Reception
// operation. The page renders only guest-linked visit Events, held parcels,
// room-like Facilities, today's non-visit facility appointments, the signed-in
// employee's scheduled shift, and the write actions the desk performs.
//
// Serves Stimulus: Companies_Operations_Reception_ShowController
// Depends on BE: Companies::Operations::ReceptionController#show
//               (hydrates company + appointment + reception payload)
// Endpoints: Helpers.reception_company_operation_path
//            Helpers.reception_check_in_company_operation_path
//            Helpers.reception_pre_register_company_operation_path
//            Helpers.reception_advance_company_operation_path
//            Helpers.reception_parcels_company_operation_path
//            Helpers.reception_parcel_notify_company_operation_path
//            Helpers.reception_parcel_pick_up_company_operation_path
//            Helpers.reception_notify_host_company_operation_path
// Docs: docs/OPERATIONS.md, docs/TIME_DISPLAY.md
export default class Companies_Operations_Reception_ShowController extends Controller {
  /** @type {any | null} */ operation = null
  /** @type {any | null} */ appointment = null
  /** @type {any[]} */ visitors = []
  /** @type {any[]} */ deliveries = []
  /** @type {any[]} */ rooms = []
  /** @type {any[]} */ appointments = []
  /** @type {any} */ referenceData = {}
  /** @type {any} */ counts = {}
  /** @type {any | null} */ shift = null
  /** @type {string | null} */ generatedAt = null
  /** @type {string | null} */ companyId = null
  /** @type {string | null} */ operationId = null
  /** @type {string | null} */ branchId = null
  /** @type {string} */ companyName = ""
  /** @type {string} */ searchQuery = ""
  /** @type {string} */ queueQuery = ""
  /** @type {string} */ activeTab = "lobby"
  /** @type {boolean} */ walkinOpen = false
  /** @type {boolean} */ preRegisterOpen = false
  /** @type {boolean} */ deliveryFormOpen = false
  /** @type {boolean} */ roomsExpanded = false
  /** @type {boolean} */ appointmentsExpanded = false
  /** @type {boolean} */ pollError = false
  /** @type {boolean} */ polling = false
  /** @type {number} */ pollInterval = 20000

  static PREVIEW_ROOMS = 8
  static PREVIEW_APPOINTMENTS = 5

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
    this.boundPoll = () => this.pollNow()
    window.addEventListener("keydown", this.boundShortcut)
    window.addEventListener("reception:poll", this.boundPoll)

    try {
      await this.loadConsole()
      this.renderContent()
      this.startPolling()
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      this.element.innerHTML = `<div class="flex items-center justify-center h-screen text-danger text-lg font-semibold">${translate("Failed to load the reception console.")}${detail ? ": " + this.escape(detail) : ""}</div>`
    }
  }

  disconnect() {
    if (this.boundShortcut) window.removeEventListener("keydown", this.boundShortcut)
    if (this.boundPoll) window.removeEventListener("reception:poll", this.boundPoll)
    if (this.pollTimer) window.clearInterval(this.pollTimer)
  }

  // --- Data -----------------------------------------------------------------------

  async loadConsole() {
    const params = this.branchId ? { branch_id: this.branchId } : {}
    const response = await fetchJson(Helpers.reception_company_operation_path(this.companyId, this.operationId, params))
    this.operation = response.operation
    this.appointment = response.appointment
    this.companyName = response.company?.name || Helpers.currentCompany()?.name || ""
    this.referenceData = response.reference || {}
    this.hydrateReception(response.reception || {})
    return response
  }

  hydrateReception(reception) {
    this.visitors = reception.visits || []
    this.deliveries = reception.parcels || []
    this.rooms = reception.rooms || []
    this.appointments = reception.appointments || []
    this.counts = reception.counts || {}
    this.shift = reception.shift || null
    this.generatedAt = reception.generated_at || null
    this.pollError = false
  }

  startPolling() {
    if (this.pollTimer) window.clearInterval(this.pollTimer)
    this.pollTimer = window.setInterval(() => this.pollNow(), this.pollInterval)
  }

  async pollNow() {
    if (this.polling || document.hidden) return
    this.polling = true
    try {
      await this.loadConsole()
      this.renderLiveRegions()
    } catch {
      this.pollError = true
      this.renderUpdated()
    } finally {
      this.polling = false
    }
  }

  async reloadConsole() {
    const scrollY = window.scrollY
    await this.loadConsole()
    this.renderContent()
    window.scrollTo(0, scrollY)
  }

  // --- Counts ---------------------------------------------------------------------

  get lobbyVisitors() { return this.visitors.filter((visitor) => visitor.status === "lobby") }
  get activeVisitors() { return this.visitors.filter((visitor) => visitor.status === "active") }
  get upcomingVisitors() { return this.visitors.filter((visitor) => visitor.status === "upcoming") }
  get departedVisitors() { return this.visitors.filter((visitor) => visitor.status === "departed") }
  get insideCount() { return this.counts.inside ?? this.activeVisitors.length }
  get lobbyCount() { return this.counts.lobby ?? this.lobbyVisitors.length }
  get expectedCount() { return this.counts.expected ?? this.upcomingVisitors.length }
  get departedCount() { return this.counts.departed ?? this.departedVisitors.length }
  get scheduledToday() { return this.counts.scheduled_today ?? this.visitors.length }
  get parcelsHeld() { return this.counts.parcels ?? this.deliveries.length }
  get roomsReady() { return this.counts.rooms_ready ?? this.rooms.filter((room) => room.status === "available").length }
  get roomsTotal() { return this.counts.rooms_total ?? this.rooms.length }
  get roomsBusy() { return Math.max(0, this.roomsTotal - this.roomsReady) }
  get averageWait() { return this.counts.average_wait_minutes }
  get appointmentsCount() { return this.counts.appointments ?? this.appointments.length }
  get vipCount() { return this.visitors.filter((visitor) => visitor.vip && visitor.status !== "departed").length }
  get visitsCapped() { return this.counts.visits_capped === true }
  get parcelsCapped() { return this.counts.parcels_capped === true }
  get appointmentsCapped() { return this.counts.appointments_capped === true }

  get filteredVisitors() {
    const query = this.queueQuery.trim().toLowerCase()
    return this.visitors.filter((visitor) => {
      const matchesTab = visitor.status === this.activeTab
      const matchesQuery = !query || String(visitor.search || "").includes(query)
      return matchesTab && matchesQuery
    })
  }

  get searchMatches() {
    const query = this.searchQuery.trim().toLowerCase()
    if (!query) return { visits: [], parcels: [] }
    return {
      visits: this.visitors.filter((visitor) => String(visitor.search || "").includes(query)).slice(0, 6),
      parcels: this.deliveries.filter((parcel) => String(parcel.search || "").includes(query)).slice(0, 4)
    }
  }

  get activeTabLabel() {
    const labels = {
      lobby: translate("In lobby"),
      active: translate("Inside"),
      upcoming: translate("Expected"),
      departed: translate("Departed")
    }
    return labels[this.activeTab] || labels.lobby
  }

  // --- Rendering ------------------------------------------------------------------

  renderContent() {
    this.element.innerHTML = `
      <div class="print:hidden bg-background text-foreground min-h-screen flex flex-col">
        ${this.renderHeader()}
        <main class="flex-1 pt-20 pb-6 w-full px-4 lg:px-6">
          ${this.renderHeadline()}
          <div id="reception-kpi-ribbon">${this.renderKpis()}</div>
          <div class="flex justify-end mb-3">
            <span id="reception-updated-at" class="text-[11px] text-muted-foreground"></span>
          </div>
          <div class="grid grid-cols-1 xl:grid-cols-12 gap-4 items-start">
            <section class="xl:col-span-8 flex flex-col gap-3 min-w-0" aria-label="${translate("Reception queue")}">
              ${this.renderQueueToolbar()}
              <div id="reception-visitor-list" class="flex flex-col gap-2.5">${this.renderVisitorCards()}</div>
              ${this.renderWalkinStation()}
              ${this.renderPreRegisterStation()}
            </section>
            <aside class="xl:col-span-4 flex flex-col gap-4 min-w-0">
              ${this.renderRoomsPanel()}
              ${this.renderAppointmentsPanel()}
              ${this.renderDeliveriesPanel()}
            </aside>
          </div>
        </main>
        ${this.renderFooter()}
      </div>
      <div id="reception-badge-print" class="hidden print:block"></div>
    `
    this.renderUpdated()
  }

  renderLiveRegions() {
    this.replaceHTML("reception-kpi-ribbon", this.renderKpis())
    this.replaceHTML("reception-queue-tabs", this.renderQueueTabs())
    this.replaceHTML("reception-queue-meta", this.renderQueueMeta())
    this.replaceHTML("reception-visitor-list", this.renderVisitorCards())
    this.replaceHTML("reception-rooms-body", this.renderRoomsBody())
    this.replaceHTML("reception-appointments-body", this.renderAppointmentsBody())
    this.replaceHTML("reception-deliveries-body", this.renderDeliveryItems())
    this.replaceHTML("reception-shift-pill", this.renderShiftPill())
    this.replaceHTML("reception-bell-badge", this.renderBellBadge())
    this.replaceHTML("reception-search-results", this.renderSearchResultsBody())
    this.renderUpdated()
  }

  replaceHTML(id, html) {
    const element = document.getElementById(id)
    if (element) element.innerHTML = html
  }

  renderUpdated() {
    const element = document.getElementById("reception-updated-at")
    if (!element) return
    if (this.pollError) {
      element.textContent = translate("Update failed · retrying")
      element.classList.add("text-danger")
    } else {
      element.textContent = this.generatedAt ? `${translate("Updated")} ${this.time(this.generatedAt)}` : ""
      element.classList.remove("text-danger")
    }
  }

  renderHeader() {
    const userName = this.element.dataset.userName || (typeof window.currentUser === "function" ? window.currentUser()?.name : window.currentUser?.name) || ""
    const userRole = this.element.dataset.userRole || (typeof window.currentUser === "function" ? window.currentUser()?.roles?.[0]?.name : "") || ""
    return `
      <header class="fixed top-0 left-0 right-0 z-40 bg-card/95 backdrop-blur border-b border-line shadow-sm">
        <div class="h-16 w-full px-4 lg:px-6 flex items-center justify-between gap-3">
          <div class="flex items-center gap-3 min-w-0">
            <div class="w-9 h-9 rounded-lg bg-primary flex items-center justify-center text-primary-foreground shadow-sm shrink-0">
              <span class="material-symbols-outlined text-[20px]">concierge</span>
            </div>
            <div class="flex flex-col leading-none min-w-0">
              <span class="font-bold tracking-tight truncate">${translate("Skycom Reception")}</span>
              <span class="text-[11px] text-muted-foreground truncate">${this.escape(this.companyLabel)}</span>
            </div>
            <div class="hidden md:flex items-center gap-2 px-3 py-1.5 rounded-lg bg-muted ml-2">
              <span class="material-symbols-outlined text-[18px] text-primary">domain</span>
              <span class="text-[12px] font-semibold text-foreground">${this.escape(this.branchName)}</span>
            </div>
          </div>
          <div class="flex-1 max-w-lg hidden lg:block">
            <div class="relative flex items-center w-full">
              <span class="material-symbols-outlined absolute left-3 text-[20px] text-muted-foreground pointer-events-none">search</span>
              <input id="reception-quick-search" type="search" value="${this.escape(this.searchQuery)}"
                data-reception-header-search
                data-action="input->${this.identifier}#updateHeaderSearch keydown.enter->${this.identifier}#jumpFirstSearchResult keydown.esc->${this.identifier}#clearHeaderSearch"
                placeholder="${translate("Search visits and waiting parcels (Press '/' to focus)...")}"
                class="w-full h-10 pl-10 pr-3 rounded-lg bg-muted text-foreground placeholder:text-muted-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary transition-all" />
              <div id="reception-search-results" class="absolute top-12 left-0 right-0 z-50"></div>
            </div>
          </div>
          <div class="flex items-center gap-2 shrink-0">
            <span id="reception-shift-pill">${this.renderShiftPill()}</span>
            <button type="button" data-action="click->${this.identifier}#focusLobby"
              class="relative h-10 w-10 flex items-center justify-center rounded-lg text-muted-foreground hover:bg-muted hover:text-foreground transition-colors touch-manipulation"
              title="${translate("Waiting guests in lobby")}">
              <span class="material-symbols-outlined text-[22px]">notifications</span>
              <span id="reception-bell-badge">${this.renderBellBadge()}</span>
            </button>
            <div class="h-7 w-px bg-line hidden sm:block"></div>
            <div class="hidden sm:flex items-center gap-2">
              <div class="flex flex-col text-right leading-tight">
                <span class="text-[12px] font-semibold text-foreground">${this.escape(userName)}</span>
                ${userRole ? `<span class="text-[10px] text-muted-foreground">${this.escape(userRole)}</span>` : ""}
              </div>
              <div class="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-primary-foreground">
                <span class="material-symbols-outlined text-[18px]">person</span>
              </div>
            </div>
            <button type="button" class="w-10 h-10 rounded-lg bg-muted hover:bg-line text-foreground flex items-center justify-center transition-colors touch-manipulation" ${Helpers.darkmodeTrigger()} title="${translate("Toggle dark mode")}"></button>
          </div>
        </div>
      </header>
    `
  }

  renderShiftPill() {
    if (!this.shift) return ""
    return `
      <span class="hidden xl:flex items-center gap-2 px-3 py-1.5 rounded-full bg-muted">
        <span class="w-2 h-2 rounded-full bg-success"></span>
        <span class="text-[11px] font-semibold text-foreground">${translate("Shift:")} ${this.escape(translate(this.shift.name))} (${this.time(this.shift.start_at, "h:mm A")}–${this.time(this.shift.end_at, "h:mm A")})</span>
      </span>
    `
  }

  renderBellBadge() {
    if (this.lobbyCount <= 0) return ""
    return `<span class="absolute top-1 right-1 flex items-center justify-center min-w-[18px] h-[18px] px-1 rounded-full bg-danger text-danger-foreground text-[10px] font-bold">${this.lobbyCount}</span>`
  }

  renderHeadline() {
    return `
      <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-3 py-2 mb-3">
        <div class="flex flex-col">
          <span class="text-[11px] uppercase tracking-wider text-muted-foreground">${translate("Skycom Reception")}</span>
          <h1 class="text-2xl font-bold text-foreground tracking-tight mt-1">${this.escape(this.branchName)} · ${translate("Reception")}</h1>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button type="button" data-action="click->${this.identifier}#toggleWalkin"
            class="flex items-center gap-1.5 px-3 py-2 min-h-[40px] rounded-lg bg-primary text-primary-foreground text-[13px] font-semibold shadow-sm hover:brightness-110 active:scale-95 transition-all touch-manipulation">
            <span class="material-symbols-outlined text-[18px]">person_add</span>
            <span>${translate("Walk-in check-in")}</span>
          </button>
          <button type="button" data-action="click->${this.identifier}#togglePreRegister"
            class="flex items-center gap-1.5 px-3 py-2 min-h-[40px] rounded-lg bg-muted text-foreground text-[13px] font-semibold hover:bg-line active:scale-95 transition-all touch-manipulation">
            <span class="material-symbols-outlined text-[18px] text-primary">event_upcoming</span>
            <span>${translate("Pre-register")}</span>
          </button>
          <button type="button" data-reception-open-parcel data-action="click->${this.identifier}#toggleDeliveryForm"
            class="flex items-center gap-1.5 px-3 py-2 min-h-[40px] rounded-lg bg-muted text-foreground text-[13px] font-semibold hover:bg-line active:scale-95 transition-all touch-manipulation">
            <span class="material-symbols-outlined text-[18px] text-warning">local_shipping</span>
            <span>${translate("Log delivery")}</span>
          </button>
        </div>
      </div>
    `
  }

  renderKpis() {
    return `
      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3 mb-1">
        ${this.renderKpiCard({
          key: "inside",
          label: translate("Inside"),
          value: this.insideCount,
          unit: translate("Visitors"),
          icon: "groups",
          tone: "primary",
          footer: `${this.departedCount} ${translate("checked out")}`
        })}
        ${this.renderKpiCard({
          key: "lobby",
          label: translate("Lobby"),
          value: this.lobbyCount,
          unit: translate("Guests"),
          icon: "chair",
          tone: this.lobbyCount > 0 ? "warning" : "success",
          footer: this.averageWait === null || this.averageWait === undefined
            ? translate("No guests waiting")
            : this.averageWait < 1
              ? translate("Just arrived")
              : `${translate("Avg wait:")} ${this.averageWait} ${translate("mins")}`
        })}
        ${this.renderKpiCard({
          key: "expected",
          label: translate("Expected"),
          value: this.expectedCount,
          unit: translate("still to arrive"),
          icon: "event_upcoming",
          tone: "primary",
          progress: this.scheduledToday > 0
            ? Math.max(0, Math.min(100, Math.round(((this.scheduledToday - this.expectedCount) / this.scheduledToday) * 100)))
            : null,
          footer: `${this.scheduledToday} ${translate("scheduled today")}`
        })}
        ${this.renderKpiCard({
          key: "parcels",
          label: translate("Parcels held"),
          value: this.parcelsHeld,
          unit: translate("Held at desk"),
          icon: "inventory_2",
          tone: "warning",
          footer: `${this.parcelsHeld} ${translate("awaiting pickup")}`
        })}
        ${this.renderKpiCard({
          key: "rooms",
          label: translate("Rooms"),
          value: this.roomsReady,
          unit: `/ ${this.roomsTotal} ${translate("Ready")}`,
          icon: "meeting_room",
          tone: "success",
          footer: `${this.roomsBusy} ${translate("in use")}`
        })}
      </div>
    `
  }

  renderKpiCard({ key, label, value, unit, icon, tone, footer, progress = null }) {
    const tones = {
      primary: "text-primary",
      success: "text-success",
      warning: "text-warning",
      danger: "text-danger",
      info: "text-info"
    }
    const toneClass = tones[tone] || tones.primary
    return `
      <div data-reception-kpi="${key}" class="relative overflow-hidden rounded-xl bg-card border border-line shadow-sm p-3 flex flex-col justify-between">
        <div class="absolute right-2 top-2 opacity-10">
          <span class="material-symbols-outlined text-[48px] ${toneClass}">${icon}</span>
        </div>
        <div class="flex items-center justify-between gap-2">
          <span class="text-[11px] font-semibold text-muted-foreground">${label}</span>
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
            <span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-[18px] text-muted-foreground pointer-events-none">filter_list</span>
            <input id="reception-filter-input" type="text" value="${this.escape(this.queueQuery)}"
              data-action="input->${this.identifier}#updateQueueFilter keydown.esc->${this.identifier}#clearQueueFilter"
              placeholder="${translate("Filter the open queue...")}"
              class="w-full h-10 pl-9 pr-3 rounded-lg bg-muted text-foreground placeholder:text-muted-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary transition-all" />
          </div>
          <div id="reception-queue-tabs" class="flex items-center gap-1 p-1 rounded-lg bg-muted overflow-x-auto">
            ${this.renderQueueTabs()}
          </div>
        </div>
        <div id="reception-queue-meta">${this.renderQueueMeta()}</div>
      </div>
    `
  }

  renderQueueMeta() {
    return `
      <div class="flex flex-wrap items-center justify-between gap-2 text-[11px] text-muted-foreground">
        <div class="flex items-center gap-2">
          <span>${translate("Showing:")} <strong class="text-foreground">${this.escape(this.activeTabLabel)}</strong></span>
          <span class="w-1 h-1 rounded-full bg-line"></span>
          <span class="text-warning font-semibold flex items-center gap-1">
            <span class="w-1.5 h-1.5 rounded-full bg-warning"></span> ${this.vipCount} ${translate("VIP flagged")}
          </span>
        </div>
        ${this.visitsCapped ? `<span>${translate("Showing the first 200")}</span>` : ""}
      </div>
    `
  }

  renderQueueTabs() {
    const tabs = [
      { key: "lobby", label: translate("In lobby"), count: this.lobbyVisitors.length },
      { key: "active", label: translate("Inside"), count: this.activeVisitors.length },
      { key: "upcoming", label: translate("Expected"), count: this.upcomingVisitors.length },
      { key: "departed", label: translate("Departed"), count: this.departedVisitors.length }
    ]

    return tabs.map((tab) => {
      const active = tab.key === this.activeTab
      return `
        <button type="button" data-reception-tab="${tab.key}" data-action="click->${this.identifier}#setTab" data-${this.identifier}-tab-param="${tab.key}"
          class="px-2 py-1 min-h-[32px] rounded-md text-[11px] font-semibold whitespace-nowrap transition-all touch-manipulation ${active ? "bg-card text-foreground shadow-sm border border-line" : "text-muted-foreground hover:text-foreground"}">
          ${tab.label} (${tab.count})
        </button>
      `
    }).join("")
  }

  renderVisitorCards() {
    const visible = this.filteredVisitors
    if (visible.length === 0) {
      return `<div class="rounded-xl border border-line bg-card p-8 text-center text-sm text-muted-foreground">${translate("No visitors match this view.")}</div>`
    }
    return visible.map((visitor) => this.renderVisitorCard(visitor)).join("")
  }

  renderVisitorCard(visitor) {
    const borderTone = visitor.vip ? "border-l-warning" : {
      lobby: "border-l-warning",
      active: "border-l-success",
      upcoming: "border-l-info",
      departed: "border-l-line"
    }[visitor.status] || "border-l-line"

    const statusChip = {
      lobby: `<span class="flex items-center gap-1 text-warning font-semibold"><span class="material-symbols-outlined text-[15px]">timer</span> ${translate("Waiting")} ${this.waitLabel(visitor.wait_minutes)}</span>`,
      active: `<span class="flex items-center gap-1 text-success font-medium"><span class="material-symbols-outlined text-[15px]">check_circle</span> ${translate("Inside")} ${this.durationLabel(visitor.inside_minutes)}</span>`,
      upcoming: `<span class="flex items-center gap-1 text-info font-medium"><span class="material-symbols-outlined text-[15px]">event</span> ${translate("Expected")} ${this.time(visitor.arrival_at)}</span>`,
      departed: `<span class="flex items-center gap-1 text-muted-foreground"><span class="material-symbols-outlined text-[15px]">logout</span> ${translate("Departed")} ${visitor.checked_out_at ? this.time(visitor.checked_out_at) : ""}</span>`
    }[visitor.status] || ""

    return `
      <div id="reception-visitor-${visitor.id}" data-reception-visitor="${visitor.id}" data-status="${visitor.status}" data-search="${this.escape(visitor.search)}"
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
              <span class="px-2 py-0.5 rounded text-[10px] bg-muted text-muted-foreground font-mono border border-line">${translate("Code:")} ${this.escape(visitor.badge)}</span>
            </div>
            <div class="flex flex-wrap items-center gap-x-2 gap-y-1 mt-1 text-[12px] text-muted-foreground">
              <span class="font-medium text-foreground">${this.escape(visitor.company || translate("No company"))}</span>
              <span>·</span>
              <span class="flex items-center gap-1">
                <span class="material-symbols-outlined text-[15px] text-primary">person</span>
                ${translate("Host:")} <strong class="text-foreground">${this.escape(visitor.host || translate("No host"))}</strong>${visitor.hostRole ? ` (${this.escape(translate(visitor.hostRole))})` : ""}
              </span>
              <span>·</span>
              ${statusChip}
            </div>
            <div class="flex flex-wrap items-center gap-x-3 gap-y-1 mt-1.5 text-[11px] text-muted-foreground">
              <span>${translate("Arrival:")} <strong class="text-foreground">${this.time(visitor.arrival_at)}</strong></span>
              <span>·</span>
              <span>${this.escape(this.visitorNote(visitor))}</span>
              <span>·</span>
              <span>${translate("Room:")} <strong class="text-foreground">${this.escape(visitor.room || translate("No room"))}</strong></span>
            </div>
          </div>
        </div>
        <div class="flex flex-wrap items-center gap-1.5 shrink-0 pt-2 md:pt-0 border-t md:border-t-0 border-line">
          ${this.renderVisitorActions(visitor)}
        </div>
      </div>
    `
  }

  renderVisitorActions(visitor) {
    const button = (action, icon, label, extraClass = "", transition = null) => `
      <button type="button" data-action="click->${this.identifier}#${action}" data-${this.identifier}-id-param="${visitor.id}"${transition ? ` data-${this.identifier}-transition-param="${transition}"` : ""}
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

    const notify = this.renderNotifyControl(visitor)

    if (visitor.status === "lobby") {
      return `
        ${button("advanceVisitor", "login", translate("Mark inside"), "bg-primary text-primary-foreground hover:brightness-110 active:scale-95 shadow-sm", "mark_inside")}
        ${notify}
        ${visitor.can_print ? iconButton("printBadge", "print", translate("Print visitor badge")) : ""}
      `
    }

    if (visitor.status === "active") {
      return `
        ${button("advanceVisitor", "logout", translate("Check out"), "bg-muted text-foreground hover:bg-line active:scale-95", "check_out")}
        ${visitor.can_print ? iconButton("printBadge", "print", translate("Print visitor badge")) : ""}
      `
    }

    if (visitor.status === "upcoming") {
      return `
        ${button("advanceVisitor", "how_to_reg", translate("They've arrived"), "bg-primary text-primary-foreground hover:brightness-110 active:scale-95 shadow-sm", "arrive")}
        ${notify}
      `
    }

    return button("advanceVisitor", "undo", translate("Reopen"), "bg-muted text-foreground hover:bg-line active:scale-95", "reopen")
  }

  renderNotifyControl(visitor) {
    if (!visitor.host) {
      return `<button type="button" disabled class="px-3 py-1.5 min-h-[36px] rounded-lg bg-muted text-muted-foreground text-[11px] font-semibold cursor-not-allowed touch-manipulation">${translate("No host to notify")}</button>`
    }
    if (visitor.notified_at) {
      return `
        <span class="px-2 py-1 rounded-lg bg-success/10 text-success text-[10px] font-semibold">${translate("Notified")} ${this.time(visitor.notified_at)}</span>
        <button type="button" data-action="click->${this.identifier}#notifyHost" data-${this.identifier}-id-param="${visitor.id}"
          class="px-2.5 py-1.5 min-h-[36px] rounded-lg bg-card text-primary text-[11px] font-semibold border border-line hover:bg-line transition-colors touch-manipulation">
          ${translate("Notify again")}
        </button>
      `
    }
    return `
      <button type="button" data-action="click->${this.identifier}#notifyHost" data-${this.identifier}-id-param="${visitor.id}"
        class="px-3 py-1.5 min-h-[36px] rounded-lg bg-card text-primary text-[11px] font-semibold border border-line hover:bg-line transition-colors touch-manipulation">
        ${translate("Notify host")}
      </button>
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
    const fields = `
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-2">
        <div>
          <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("Guest name")}</label>
          <input name="visitor[name]" type="text" required
            class="w-full h-10 px-2.5 rounded-lg bg-card text-foreground placeholder:text-muted-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary"
            placeholder="${translate("e.g. Jessica Tan")}" />
        </div>
        <div>
          <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("Guest company")}</label>
          <input name="visitor[company]" type="text" required
            class="w-full h-10 px-2.5 rounded-lg bg-card text-foreground placeholder:text-muted-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary"
            placeholder="${translate("e.g. Deloitte Consulting")}" />
        </div>
        <div>
          <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("Host (optional)")}</label>
          <select name="visitor[host_id]"
            class="w-full h-10 px-2.5 rounded-lg bg-card text-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary">
            <option value="">${translate("No host")}</option>
            ${(this.reference.hosts || []).map((host) => `
              <option value="${this.escape(host.id)}">${this.escape(host.name)}${host.role ? ` (${this.escape(translate(host.role))})` : ""}</option>
            `).join("")}
          </select>
        </div>
        <div>
          <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("Room (optional)")}</label>
          <select name="visitor[facility_id]"
            class="w-full h-10 px-2.5 rounded-lg bg-card text-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary">
            <option value="">${translate("No room")}</option>
            ${(this.reference.facilities || []).map((facility) => `
              <option value="${this.escape(facility.id)}">${this.escape(facility.name)}${facility.category ? ` · ${this.escape(translate(facility.category))}` : ""}</option>
            `).join("")}
          </select>
        </div>
      </div>
      <div class="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-2 pt-2">
        <label class="flex items-center gap-2 text-[11px] text-foreground">
          <input name="visitor[vip]" type="checkbox" class="w-4 h-4 rounded accent-primary" />
          ${translate("VIP guest")}
        </label>
        <button type="submit"
          class="px-4 py-2 min-h-[42px] rounded-lg bg-primary text-primary-foreground text-[13px] font-semibold hover:brightness-110 active:scale-95 transition-all flex items-center justify-center gap-2 shadow-sm touch-manipulation">
          <span class="material-symbols-outlined text-[18px]">verified</span>
          <span>${translate("Check in to lobby")}</span>
        </button>
      </div>
    `
    return `
      <div id="reception-walkin-station" class="${this.walkinOpen ? "" : "hidden"} rounded-xl bg-muted border border-line p-4 flex flex-col gap-3">
        <div class="flex items-center justify-between gap-3">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-primary text-primary-foreground flex items-center justify-center">
              <span class="material-symbols-outlined text-[20px]">person_add</span>
            </div>
            <div>
              <h2 class="text-[15px] font-bold text-foreground leading-tight">${translate("Walk-in check-in")}</h2>
              <span class="text-[11px] text-muted-foreground">${translate("Creates a lobby visit. Nothing is sent or printed automatically.")}</span>
            </div>
          </div>
          <button type="button" data-action="click->${this.identifier}#toggleWalkin"
            class="h-10 w-10 flex items-center justify-center rounded-lg bg-card text-muted-foreground hover:text-foreground border border-line touch-manipulation"
            title="${translate("Close")}">
            <span class="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>
        ${form({
          action: Helpers.reception_check_in_company_operation_path(this.companyId, this.operationId),
          method: "POST",
          attributes: `class="flex flex-col gap-2" novalidate data-action="submit->${this.identifier}#submitWalkin"`,
          html: fields
        })}
      </div>
    `
  }

  renderPreRegisterStation() {
    const date = Helpers.localToday(this.location)
    const start = Helpers.locationNow(this.location).add(1, "hour").format("HH:mm")
    const fields = `
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-2">
        <div>
          <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("Guest name")}</label>
          <input name="pre_registration[name]" type="text" required
            class="w-full h-10 px-2.5 rounded-lg bg-card text-foreground placeholder:text-muted-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary"
            placeholder="${translate("e.g. Jessica Tan")}" />
        </div>
        <div>
          <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("Guest company")}</label>
          <input name="pre_registration[company]" type="text" required
            class="w-full h-10 px-2.5 rounded-lg bg-card text-foreground placeholder:text-muted-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary"
            placeholder="${translate("e.g. Deloitte Consulting")}" />
        </div>
        <div>
          <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("Host (optional)")}</label>
          <select name="pre_registration[host_id]"
            class="w-full h-10 px-2.5 rounded-lg bg-card text-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary">
            <option value="">${translate("No host")}</option>
            ${(this.reference.hosts || []).map((host) => `
              <option value="${this.escape(host.id)}">${this.escape(host.name)}${host.role ? ` (${this.escape(translate(host.role))})` : ""}</option>
            `).join("")}
          </select>
        </div>
        <div>
          <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("Room (optional)")}</label>
          <select name="pre_registration[facility_id]"
            class="w-full h-10 px-2.5 rounded-lg bg-card text-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary">
            <option value="">${translate("No room")}</option>
            ${(this.reference.facilities || []).map((facility) => `
              <option value="${this.escape(facility.id)}">${this.escape(facility.name)}${facility.category ? ` · ${this.escape(translate(facility.category))}` : ""}</option>
            `).join("")}
          </select>
        </div>
        <div>
          <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("Date")}</label>
          <input name="pre_registration[date]" type="date" required value="${date}"
            class="w-full h-10 px-2.5 rounded-lg bg-card text-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary" />
        </div>
        <div>
          <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("Start time")}</label>
          <input name="pre_registration[start_time]" type="time" required value="${start}"
            class="w-full h-10 px-2.5 rounded-lg bg-card text-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary" />
        </div>
        <div>
          <label class="block text-[10px] font-semibold text-muted-foreground mb-1">${translate("End time (optional)")}</label>
          <input name="pre_registration[end_time]" type="time"
            class="w-full h-10 px-2.5 rounded-lg bg-card text-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary" />
        </div>
        <div class="flex items-end pb-2">
          <label class="flex items-center gap-2 text-[11px] text-foreground">
            <input name="pre_registration[vip]" type="checkbox" class="w-4 h-4 rounded accent-primary" />
            ${translate("VIP guest")}
          </label>
        </div>
      </div>
      <div class="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-2 pt-2">
        <span class="text-[11px] text-muted-foreground">${translate("Nothing is saved until Save pre-registration. Room conflicts are allowed.")}</span>
        <button type="submit"
          class="px-4 py-2 min-h-[42px] rounded-lg bg-primary text-primary-foreground text-[13px] font-semibold hover:brightness-110 active:scale-95 transition-all flex items-center justify-center gap-2 shadow-sm touch-manipulation">
          <span class="material-symbols-outlined text-[18px]">event_available</span>
          <span>${translate("Save pre-registration")}</span>
        </button>
      </div>
    `
    return `
      <div id="reception-preregister-station" class="${this.preRegisterOpen ? "" : "hidden"} rounded-xl bg-muted border border-line p-4 flex flex-col gap-3">
        <div class="flex items-center justify-between gap-3">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-primary text-primary-foreground flex items-center justify-center">
              <span class="material-symbols-outlined text-[20px]">event_upcoming</span>
            </div>
            <div>
              <h2 class="text-[15px] font-bold text-foreground leading-tight">${translate("Pre-register a visitor")}</h2>
              <span class="text-[11px] text-muted-foreground">${translate("Saves an expected visit for the date you choose.")}</span>
            </div>
          </div>
          <button type="button" data-action="click->${this.identifier}#togglePreRegister"
            class="h-10 w-10 flex items-center justify-center rounded-lg bg-card text-muted-foreground hover:text-foreground border border-line touch-manipulation"
            title="${translate("Close")}">
            <span class="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>
        ${form({
          action: Helpers.reception_pre_register_company_operation_path(this.companyId, this.operationId),
          method: "POST",
          attributes: `class="flex flex-col gap-2" novalidate data-action="submit->${this.identifier}#submitPreRegister"`,
          html: fields
        })}
      </div>
    `
  }

  renderRoomsPanel() {
    return `
      <div class="rounded-xl bg-card border border-line shadow-sm p-3 flex flex-col gap-2">
        <div class="flex items-center justify-between pb-2 border-b border-line">
          <div class="flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[20px] text-primary">meeting_room</span>
            <h2 class="text-[15px] font-bold text-foreground">${translate("Rooms")}</h2>
          </div>
          <span class="text-[11px] text-success font-bold">${this.roomsReady} / ${this.roomsTotal} ${translate("Ready")}</span>
        </div>
        <div id="reception-rooms-body">${this.renderRoomsBody()}</div>
      </div>
    `
  }

  renderRoomsBody() {
    if (this.rooms.length === 0) {
      return `<div class="text-center text-[12px] text-muted-foreground py-3">${translate("No rooms configured for this branch.")}</div>`
    }
    const visible = this.roomsExpanded ? this.rooms : this.rooms.slice(0, Companies_Operations_Reception_ShowController.PREVIEW_ROOMS)
    return `
      <div class="grid grid-cols-3 gap-1.5">
        ${visible.map((room) => this.renderRoom(room)).join("")}
      </div>
      ${this.rooms.length > Companies_Operations_Reception_ShowController.PREVIEW_ROOMS ? `
        <div class="flex items-center justify-between gap-2 mt-2">
          <span class="text-[10px] text-muted-foreground">${translate("Showing")} ${visible.length} ${translate("of")} ${this.rooms.length}</span>
          <button type="button" data-reception-show-rooms data-action="click->${this.identifier}#toggleRooms"
            class="min-h-[32px] px-2.5 rounded-lg bg-muted text-foreground text-[11px] font-semibold hover:bg-line transition-colors touch-manipulation">
            ${this.roomsExpanded ? translate("Show less") : translate("Show all")}
          </button>
        </div>
      ` : ""}
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
        ? `${translate("Busy until")} ${this.time(room.time_at)}`
        : `${translate("Reserved")} ${this.time(room.time_at)}`

    return `
      <div data-reception-room="${room.id}" class="p-2 rounded-lg bg-muted border border-line flex flex-col items-center text-center">
        <span class="text-[10px] font-bold text-foreground truncate w-full">${this.escape(room.name)}</span>
        <span class="text-[10px] font-semibold ${tone} mt-0.5">${this.escape(label)}</span>
      </div>
    `
  }

  renderAppointmentsPanel() {
    return `
      <div class="rounded-xl bg-card border border-line shadow-sm p-3 flex flex-col gap-2">
        <div class="flex items-center justify-between pb-2 border-b border-line">
          <div class="flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[20px] text-primary">calendar_month</span>
            <h2 class="text-[15px] font-bold text-foreground">${translate("Appointments today")}</h2>
          </div>
          <span class="text-[11px] text-muted-foreground font-bold">${this.appointmentsCount}</span>
        </div>
        <div id="reception-appointments-body">${this.renderAppointmentsBody()}</div>
      </div>
    `
  }

  renderAppointmentsBody() {
    if (this.appointments.length === 0) {
      return `<div class="text-center text-[12px] text-muted-foreground py-3">${translate("No appointments today.")}</div>`
    }
    const visible = this.appointmentsExpanded ? this.appointments : this.appointments.slice(0, Companies_Operations_Reception_ShowController.PREVIEW_APPOINTMENTS)
    return `
      <div class="flex flex-col gap-2">
        ${visible.map((appointment) => this.renderAppointment(appointment)).join("")}
      </div>
      ${this.appointmentsCapped ? `<p class="text-[10px] text-muted-foreground mt-2">${translate("Showing the first 200")}</p>` : ""}
      ${this.appointments.length > Companies_Operations_Reception_ShowController.PREVIEW_APPOINTMENTS ? `
        <button type="button" data-reception-show-appointments data-action="click->${this.identifier}#toggleAppointments"
          class="w-full mt-2 py-1.5 min-h-[34px] rounded-lg bg-muted text-foreground text-[11px] font-semibold hover:bg-line transition-colors touch-manipulation">
          ${this.appointmentsExpanded ? translate("Show less") : `${translate("Show all")} ${this.appointments.length} ${translate("appointments")}`}
        </button>
      ` : ""}
    `
  }

  renderAppointment(appointment) {
    return `
      <div data-reception-appointment="${appointment.id}" class="p-2 rounded-lg bg-muted border border-line flex items-start gap-2">
        <div class="w-12 text-center shrink-0 pt-0.5">
          <span class="text-[12px] font-bold text-foreground block leading-tight">${this.time(appointment.start_at, "h:mm A")}</span>
        </div>
        <div class="flex-1 min-w-0">
          <div class="flex items-center justify-between gap-2">
            <span class="text-[12px] font-bold text-foreground truncate">${this.escape(translate(appointment.title))}</span>
            <span class="px-1.5 py-0.5 rounded text-[9px] bg-primary/10 text-primary font-semibold whitespace-nowrap">${this.escape(translate(appointment.status))}</span>
          </div>
          <p class="text-[11px] text-muted-foreground truncate mt-0.5">${appointment.host ? `${translate("Host:")} ${this.escape(appointment.host)}` : translate("No host")} · ${this.escape(appointment.room || translate("No room"))}</p>
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
            <h2 class="text-[15px] font-bold text-foreground">${translate("Parcels held")}</h2>
          </div>
          <span class="text-[11px] text-warning font-bold">${this.parcelsHeld} ${translate("awaiting pickup")}</span>
        </div>
        <div id="reception-deliveries-body" class="flex flex-col gap-2">
          ${this.renderDeliveryItems()}
        </div>
        <div id="reception-delivery-form" class="${this.deliveryFormOpen ? "" : "hidden"} rounded-lg bg-muted border border-line p-2.5">
          ${this.renderParcelForm()}
        </div>
        <div class="flex items-center justify-between pt-1">
          <button type="button" data-reception-open-parcel-panel data-action="click->${this.identifier}#toggleDeliveryForm"
            class="min-h-[32px] text-[11px] text-primary font-bold hover:underline flex items-center gap-1 touch-manipulation">
            <span class="material-symbols-outlined text-[16px]">add_box</span>
            ${translate("Log delivery")}
          </button>
          ${this.parcelsCapped ? `<span class="text-[10px] text-muted-foreground">${translate("Showing the first 200")}</span>` : ""}
        </div>
      </div>
    `
  }

  renderParcelForm() {
    const fields = `
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
        <input name="parcel[item]" type="text" required placeholder="${translate("e.g. Legal documents")}"
          class="w-full h-9 px-2 rounded-lg bg-card text-foreground text-[12px] border border-line focus:outline-none focus:ring-2 focus:ring-primary" />
      </div>
      <div class="flex items-center justify-between gap-1.5">
        <span class="text-[10px] text-muted-foreground">${translate("Nothing is saved until Save delivery.")}</span>
        <div class="flex items-center gap-1.5">
          <button type="button" data-reception-cancel-parcel data-action="click->${this.identifier}#toggleDeliveryForm"
            class="px-2.5 py-1.5 min-h-[34px] rounded-lg bg-card text-foreground text-[11px] font-semibold border border-line hover:bg-line touch-manipulation">
            ${translate("Cancel")}
          </button>
          <button type="submit" data-reception-save-parcel
            class="px-2.5 py-1.5 min-h-[34px] rounded-lg bg-primary text-primary-foreground text-[11px] font-semibold hover:brightness-110 flex items-center gap-1 touch-manipulation">
            <span class="material-symbols-outlined text-[15px]">save</span>
            ${translate("Save delivery")}
          </button>
        </div>
      </div>
    `
    return form({
      action: Helpers.reception_parcels_company_operation_path(this.companyId, this.operationId),
      method: "POST",
      attributes: `class="flex flex-col gap-2" novalidate data-action="submit->${this.identifier}#submitDelivery"`,
      html: fields
    })
  }

  renderDeliveryItems() {
    if (this.deliveries.length === 0) {
      return `<div class="text-center text-[12px] text-muted-foreground py-3">${translate("No parcels waiting at the desk.")}</div>`
    }

    return this.deliveries.map((delivery) => `
      <div id="reception-parcel-${delivery.id}" data-reception-parcel="${delivery.id}" class="p-2 rounded-lg bg-muted border border-line flex items-center justify-between gap-2">
        <div class="flex items-center gap-2 min-w-0">
          <div class="w-8 h-8 rounded-lg bg-warning/10 text-warning flex items-center justify-center shrink-0 font-bold text-[10px]">
            ${this.escape(delivery.carrier)}
          </div>
          <div class="flex flex-col min-w-0">
            <span class="text-[12px] font-bold text-foreground truncate">${this.escape(translate(delivery.title))}</span>
            <span class="text-[11px] text-muted-foreground truncate">${translate("For:")} <strong class="text-foreground">${this.escape(delivery.recipient || translate("Unknown recipient"))}</strong></span>
            <span class="text-[10px] text-muted-foreground truncate">${this.escape(translate(delivery.location))}${delivery.received_at ? ` · ${this.escape(this.time(delivery.received_at))}` : ""}</span>
          </div>
        </div>
        <div class="flex items-center gap-1 shrink-0">
          ${this.renderParcelNotifyControl(delivery)}
          <button type="button" data-action="click->${this.identifier}#pickUpParcel" data-${this.identifier}-id-param="${delivery.id}"
            class="h-9 w-9 flex items-center justify-center rounded-md bg-card text-success border border-line hover:bg-line transition-colors touch-manipulation"
            title="${translate("Mark picked up")}">
            <span class="material-symbols-outlined text-[16px]">inventory_2</span>
          </button>
        </div>
      </div>
    `).join("")
  }

  renderParcelNotifyControl(delivery) {
    if (delivery.notified_at) {
      return `
        <span class="px-1.5 py-1 rounded bg-success/10 text-success text-[9px] font-semibold whitespace-nowrap">${translate("Notified")} ${this.time(delivery.notified_at, "h:mm A")}</span>
        <button type="button" data-action="click->${this.identifier}#deliveryAction" data-${this.identifier}-id-param="${delivery.id}"
          class="px-1.5 py-1 rounded-md bg-card text-primary text-[9px] font-semibold border border-line hover:bg-line transition-colors whitespace-nowrap">
          ${translate("Notify again")}
        </button>
      `
    }
    return `
      <button type="button" data-action="click->${this.identifier}#deliveryAction" data-${this.identifier}-id-param="${delivery.id}"
        class="px-2 py-1 rounded-md bg-card text-primary text-[10px] font-semibold border border-line hover:bg-line transition-colors">
        ${translate("Notify")}
      </button>
    `
  }

  renderFooter() {
    return `
      <footer class="w-full bg-muted border-t border-line py-2 px-4 lg:px-6">
        <div class="flex items-center justify-center text-[11px] text-muted-foreground">
          Skycom · ${translate("Reception")} · ${this.escape(this.companyLabel)}
        </div>
      </footer>
    `
  }

  renderSearchResultsBody() {
    if (!this.searchQuery.trim()) return ""
    const matches = this.searchMatches
    const total = matches.visits.length + matches.parcels.length
    return `
      <div class="rounded-xl border border-line bg-card shadow-lg p-2 flex flex-col gap-1 max-h-80 overflow-y-auto">
        ${total === 0 ? `<span class="text-[12px] text-muted-foreground px-2 py-1">${translate("No matches.")}</span>` : ""}
        ${matches.visits.length > 0 ? `<span class="text-[10px] uppercase tracking-wider text-muted-foreground px-2 pt-1">${translate("Visits")}</span>` : ""}
        ${matches.visits.map((visitor) => `
          <button type="button" data-reception-search-result="visit" data-action="click->${this.identifier}#jumpToSearchResult" data-${this.identifier}-type-param="visit" data-${this.identifier}-id-param="${visitor.id}"
            class="text-left px-2 py-1.5 rounded-lg hover:bg-muted transition-colors">
            <span class="block text-[12px] font-semibold text-foreground truncate">${this.escape(visitor.name)}</span>
            <span class="block text-[10px] text-muted-foreground truncate">${this.escape(visitor.company || "")} · ${this.escape(this.activeTabLabelFor(visitor.status))}</span>
          </button>
        `).join("")}
        ${matches.parcels.length > 0 ? `<span class="text-[10px] uppercase tracking-wider text-muted-foreground px-2 pt-1">${translate("Parcels")}</span>` : ""}
        ${matches.parcels.map((parcel) => `
          <button type="button" data-reception-search-result="parcel" data-action="click->${this.identifier}#jumpToSearchResult" data-${this.identifier}-type-param="parcel" data-${this.identifier}-id-param="${parcel.id}"
            class="text-left px-2 py-1.5 rounded-lg hover:bg-muted transition-colors">
            <span class="block text-[12px] font-semibold text-foreground truncate">${this.escape(parcel.title)}</span>
            <span class="block text-[10px] text-muted-foreground truncate">${this.escape(parcel.carrier)} · ${translate("For:")} ${this.escape(parcel.recipient || "")}</span>
          </button>
        `).join("")}
      </div>
    `
  }

  activeTabLabelFor(status) {
    return {
      lobby: translate("In lobby"),
      active: translate("Inside"),
      upcoming: translate("Expected"),
      departed: translate("Departed")
    }[status] || ""
  }

  // --- Interactions ---------------------------------------------------------------

  updateHeaderSearch(event) {
    this.searchQuery = event.target.value || ""
    this.replaceHTML("reception-search-results", this.renderSearchResultsBody())
  }

  clearHeaderSearch(event) {
    if (event) event.preventDefault()
    this.searchQuery = ""
    const input = document.getElementById("reception-quick-search")
    if (input) input.value = ""
    this.replaceHTML("reception-search-results", "")
  }

  jumpFirstSearchResult(event) {
    if (event) event.preventDefault()
    const matches = this.searchMatches
    const first = matches.visits[0] || matches.parcels[0]
    if (!first) return
    this.jumpToSearchResult({
      params: {
        type: matches.visits[0] ? "visit" : "parcel",
        id: first.id
      }
    })
  }

  jumpToSearchResult(event) {
    const { type, id } = event.params
    this.searchQuery = ""
    const searchInput = document.getElementById("reception-quick-search")
    if (searchInput) searchInput.value = ""
    this.replaceHTML("reception-search-results", "")
    if (type === "visit") {
      const visitor = this.findVisitor(id)
      if (!visitor) return
      this.activeTab = visitor.status
      this.queueQuery = ""
      const filter = document.getElementById("reception-filter-input")
      if (filter) filter.value = ""
      this.replaceHTML("reception-queue-tabs", this.renderQueueTabs())
      this.replaceHTML("reception-queue-meta", this.renderQueueMeta())
      this.replaceHTML("reception-visitor-list", this.renderVisitorCards())
      this.scrollAndHighlight(`reception-visitor-${visitor.id}`)
      return
    }
    this.scrollAndHighlight(`reception-parcel-${id}`)
  }

  scrollAndHighlight(id) {
    const element = document.getElementById(id)
    if (!element) return
    element.scrollIntoView({ behavior: "smooth", block: "center" })
    element.classList.add("ring-2", "ring-primary")
    window.setTimeout(() => element.classList.remove("ring-2", "ring-primary"), 1800)
  }

  updateQueueFilter(event) {
    this.queueQuery = event.target.value || ""
    this.replaceHTML("reception-visitor-list", this.renderVisitorCards())
    this.replaceHTML("reception-queue-meta", this.renderQueueMeta())
  }

  clearQueueFilter(event) {
    if (event) event.preventDefault()
    this.queueQuery = ""
    const input = document.getElementById("reception-filter-input")
    if (input) input.value = ""
    this.replaceHTML("reception-visitor-list", this.renderVisitorCards())
    this.replaceHTML("reception-queue-meta", this.renderQueueMeta())
  }

  setTab(event) {
    this.activeTab = event.params.tab
    this.replaceHTML("reception-queue-tabs", this.renderQueueTabs())
    this.replaceHTML("reception-queue-meta", this.renderQueueMeta())
    this.replaceHTML("reception-visitor-list", this.renderVisitorCards())
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
      window.setTimeout(() => station.querySelector('input[name="visitor[name]"]')?.focus(), 250)
    }
  }

  togglePreRegister() {
    const station = document.getElementById("reception-preregister-station")
    if (!station) return
    this.preRegisterOpen = !this.preRegisterOpen
    station.classList.toggle("hidden", !this.preRegisterOpen)
    if (this.preRegisterOpen) {
      station.scrollIntoView({ behavior: "smooth", block: "center" })
      window.setTimeout(() => station.querySelector('input[name="pre_registration[name]"]')?.focus(), 250)
    }
  }

  toggleDeliveryForm() {
    const panel = document.getElementById("reception-delivery-form")
    if (!panel) return
    this.deliveryFormOpen = !this.deliveryFormOpen
    panel.classList.toggle("hidden", !this.deliveryFormOpen)
    if (this.deliveryFormOpen) {
      panel.scrollIntoView({ behavior: "smooth", block: "center" })
      window.setTimeout(() => panel.querySelector('input[name="parcel[carrier]"]')?.focus(), 250)
    }
  }

  toggleRooms() {
    this.roomsExpanded = !this.roomsExpanded
    this.replaceHTML("reception-rooms-body", this.renderRoomsBody())
  }

  toggleAppointments() {
    this.appointmentsExpanded = !this.appointmentsExpanded
    this.replaceHTML("reception-appointments-body", this.renderAppointmentsBody())
  }

  async submitWalkin(event) {
    event.preventDefault()
    const formElement = event.target
    const data = new FormData(formElement)
    const name = String(data.get("visitor[name]") || "").trim()
    const company = String(data.get("visitor[company]") || "").trim()
    const hostId = String(data.get("visitor[host_id]") || "").trim()
    const facilityId = String(data.get("visitor[facility_id]") || "").trim()
    const vip = data.get("visitor[vip]") === "on"

    if (!name) {
      this.errorToast(translate("Guest name is required."), 'input[name="visitor[name]"]')
      return
    }
    if (!company) {
      this.errorToast(translate("Company or organization is required."), 'input[name="visitor[company]"]')
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
              vip
            }
          }
        }
      )

      formElement.reset()
      this.walkinOpen = false
      document.getElementById("reception-walkin-station")?.classList.add("hidden")
      toast({ type: "success", message: response.message })
      await this.reloadConsole()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to check in the guest.") })
    }
  }

  async submitPreRegister(event) {
    event.preventDefault()
    const formElement = event.target
    const data = new FormData(formElement)
    const name = String(data.get("pre_registration[name]") || "").trim()
    const company = String(data.get("pre_registration[company]") || "").trim()
    const hostId = String(data.get("pre_registration[host_id]") || "").trim()
    const facilityId = String(data.get("pre_registration[facility_id]") || "").trim()
    const date = String(data.get("pre_registration[date]") || "").trim()
    const startTime = String(data.get("pre_registration[start_time]") || "").trim()
    const endTime = String(data.get("pre_registration[end_time]") || "").trim()
    const vip = data.get("pre_registration[vip]") === "on"

    if (!name) {
      this.errorToast(translate("Guest name is required."), 'input[name="pre_registration[name]"]')
      return
    }
    if (!company) {
      this.errorToast(translate("Company or organization is required."), 'input[name="pre_registration[company]"]')
      return
    }
    if (!date) {
      this.errorToast(translate("Date is required."), 'input[name="pre_registration[date]"]')
      return
    }
    if (!startTime) {
      this.errorToast(translate("Start time is required."), 'input[name="pre_registration[start_time]"]')
      return
    }

    try {
      const response = await fetchJson(
        Helpers.reception_pre_register_company_operation_path(this.companyId, this.operationId),
        {
          method: "POST",
          body: {
            branch_id: this.branchId,
            pre_registration: {
              name,
              company,
              host_id: hostId || null,
              facility_id: facilityId || null,
              date,
              start_time: startTime,
              end_time: endTime || null,
              vip
            }
          }
        }
      )

      formElement.reset()
      this.preRegisterOpen = false
      document.getElementById("reception-preregister-station")?.classList.add("hidden")
      toast({ type: "success", message: response.message })
      await this.reloadConsole()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to save the pre-registration.") })
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
      toast({ type: "success", message: response.message })
      await this.reloadConsole()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to notify the host.") })
    }
  }

  async advanceVisitor(event) {
    const visitor = this.findVisitor(event.params.id)
    if (!visitor) return

    try {
      const response = await fetchJson(
        Helpers.reception_advance_company_operation_path(this.companyId, this.operationId),
        {
          method: "POST",
          body: { branch_id: this.branchId, event_id: visitor.event_id, transition: event.params.transition }
        }
      )
      toast({ type: "success", message: response.message })
      await this.reloadConsole()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to update the visit.") })
    }
  }

  printBadge(event) {
    const visitor = this.findVisitor(event.params.id)
    if (!visitor || !visitor.can_print) return
    const root = document.getElementById("reception-badge-print")
    if (!root) return
    root.innerHTML = this.renderBadgePrint(visitor)
    window.print()
  }

  renderBadgePrint(visitor) {
    return `
      <div class="p-6 text-foreground">
        <div class="text-[11px] uppercase tracking-[0.2em]">${this.escape(this.companyLabel)}</div>
        <div class="mt-3 text-2xl font-black uppercase tracking-widest">${translate("Visitor")}</div>
        <div class="mt-2 text-xl font-bold">${this.escape(visitor.name)}</div>
        <div class="text-[13px]">${this.escape(visitor.company || translate("No company"))}</div>
        <dl class="mt-4 grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 text-[12px]">
          <dt class="font-semibold">${translate("Host:")}</dt><dd>${this.escape(visitor.host || translate("No host"))}</dd>
          <dt class="font-semibold">${translate("Room:")}</dt><dd>${this.escape(visitor.room || translate("No room"))}</dd>
          <dt class="font-semibold">${translate("Branch:")}</dt><dd>${this.escape(this.branchName)}</dd>
          <dt class="font-semibold">${translate("Time:")}</dt><dd>${this.time(visitor.lobby_entered_at || visitor.arrival_at)}</dd>
          <dt class="font-semibold">${translate("Code:")}</dt><dd class="font-mono">${this.escape(visitor.badge)}</dd>
        </dl>
      </div>
    `
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
      toast({ type: "success", message: response.message })
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
      toast({ type: "success", message: response.message })
      await this.reloadConsole()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to mark the parcel as picked up.") })
    }
  }

  async submitDelivery(event) {
    event.preventDefault()
    const formElement = event.target
    const data = new FormData(formElement)
    const carrier = String(data.get("parcel[carrier]") || "").trim()
    const employeeId = String(data.get("parcel[employee_id]") || "").trim()
    const item = String(data.get("parcel[item]") || "").trim()

    if (!carrier) {
      this.errorToast(translate("Carrier is required."), 'input[name="parcel[carrier]"]')
      return
    }
    if (!employeeId) {
      this.errorToast(translate("Recipient is required."), 'select[name="parcel[employee_id]"]')
      return
    }
    if (!item) {
      this.errorToast(translate("Item summary is required."), 'input[name="parcel[item]"]')
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

      formElement.reset()
      this.deliveryFormOpen = false
      document.getElementById("reception-delivery-form")?.classList.add("hidden")
      toast({ type: "success", message: response.message })
      await this.reloadConsole()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to log the parcel.") })
    }
  }

  errorToast(message, selector) {
    toast({ type: "error", message })
    const element = this.element.querySelector(selector)
    if (element) {
      element.focus()
      element.scrollIntoView({ behavior: "smooth", block: "center" })
    }
  }

  // --- Helpers --------------------------------------------------------------------

  get location() {
    return this.appointment?.location || {}
  }

  get branchName() {
    return this.appointment?.location?.name || this.appointment?.branch?.name || this.operation?.branch?.name || translate("Branch not available")
  }

  get companyLabel() {
    return this.companyName || Helpers.currentCompany()?.name || translate("Company")
  }

  get reference() {
    return this.referenceData || {}
  }

  time(value, format = "h:mm A") {
    return Helpers.locationTime(value, format, this.location)
  }

  waitLabel(minutes) {
    if (minutes === null || minutes === undefined || minutes < 1) return translate("Just arrived")
    return `${minutes} ${translate("mins")}`
  }

  durationLabel(minutes) {
    if (minutes === null || minutes === undefined || minutes < 1) return translate("Just arrived")
    return `${minutes} ${translate("mins")}`
  }

  findVisitor(id) {
    return this.visitors.find((visitor) => String(visitor.id) === String(id))
  }

  visitorNote(visitor) {
    if (visitor.status === "lobby") return `${translate("Entered lobby:")} ${this.time(visitor.lobby_entered_at)}`
    if (visitor.status === "active") return `${translate("Marked inside:")} ${this.time(visitor.inside_at)}`
    if (visitor.status === "departed") return `${translate("Checked out:")} ${this.time(visitor.checked_out_at)}`
    return `${translate("Pre-registered for:")} ${this.time(visitor.arrival_at)}`
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
