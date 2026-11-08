import { Controller } from "@hotwired/stimulus"

// Booking — full-screen resource reservation console for the branch-scoped
// Booking operation. The timeline rows are real Facilities (rooms, pods,
// studios, equipment) and the blocks are real Events for the selected day,
// linked through EventFacilityAppointment.
//
// Serves Stimulus: Companies_Operations_Booking_ShowController
// Depends on BE: Companies::Operations::BookingController#show/create_reservation
// Endpoints: Helpers.booking_company_operation_path
//            Helpers.booking_reservations_company_operation_path
// Docs: docs/OPERATIONS.md, docs/EVENTS.md
export default class Companies_Operations_Booking_ShowController extends Controller {
  /** @type {any | null} */ operation = null
  /** @type {any | null} */ appointment = null
  /** @type {any[]} */ resources = []
  /** @type {any[]} */ bookings = []
  /** @type {any[]} */ upcoming = []
  /** @type {any} */ counts = {}
  /** @type {any} */ reference = {}
  /** @type {any} */ timeline = { start_hour: 8, end_hour: 18 }
  /** @type {string | null} */ companyId = null
  /** @type {string | null} */ operationId = null
  /** @type {string | null} */ branchId = null
  /** @type {string | null} */ selectedDate = null
  /** @type {string} */ activeFilter = "all"
  /** @type {number | null} */ needleTimer = null

  async connect() {
    const pathParts = window.location.pathname.split("/")
    this.companyId = this.element.dataset.companyId || pathParts[2]
    this.operationId = this.element.dataset.operationId || pathParts[5]
    this.branchId = new URLSearchParams(window.location.search).get("branch_id")

    try {
      await this.loadConsole()
      this.renderContent()
      this.startNeedleTimer()
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      this.element.innerHTML = `<div class="flex items-center justify-center h-screen text-danger text-lg font-semibold">${translate("Failed to load the booking console.")}${detail ? ": " + this.escape(detail) : ""}</div>`
    }
  }

  disconnect() {
    if (this.needleTimer) window.clearInterval(this.needleTimer)
  }

  // --- Data -----------------------------------------------------------------------

  async loadConsole() {
    const params = {}
    if (this.branchId) params.branch_id = this.branchId
    if (this.selectedDate) params.date = this.selectedDate

    const response = await fetchJson(Helpers.booking_company_operation_path(this.companyId, this.operationId, params))
    this.operation = response.operation
    this.appointment = response.appointment
    this.reference = response.reference || {}
    this.hydrateBooking(response.booking || {})
    return response
  }

  hydrateBooking(booking) {
    this.resources = booking.resources || []
    this.bookings = booking.bookings || []
    this.upcoming = booking.upcoming || []
    this.counts = booking.counts || {}
    this.timeline = booking.timeline || { start_hour: 8, end_hour: 18 }
    this.selectedDate = booking.date || this.selectedDate
  }

  // --- Time helpers ---------------------------------------------------------------

  get timelineStartHour() { return this.timeline.start_hour ?? 8 }
  get timelineEndHour() { return this.timeline.end_hour ?? 18 }
  get timelineSpan() { return Math.max(1, this.timelineEndHour - this.timelineStartHour) }

  percentForTime(value) {
    if (!value) return 0
    const date = new Date(value)
    if (Number.isNaN(date.getTime())) return 0
    const minutes = date.getHours() * 60 + date.getMinutes()
    const start = this.timelineStartHour * 60
    return this.clampPercent(((minutes - start) / (this.timelineSpan * 60)) * 100)
  }

  durationPercent(booking) {
    if (!booking.start_at || !booking.end_at) return 0
    const start = new Date(booking.start_at)
    const end = new Date(booking.end_at)
    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) return 0
    const minutes = (end - start) / 60000
    return this.clampPercent((minutes / (this.timelineSpan * 60)) * 100)
  }

  nowPercent() {
    const now = new Date()
    const minutes = now.getHours() * 60 + now.getMinutes()
    const start = this.timelineStartHour * 60
    return this.clampPercent(((minutes - start) / (this.timelineSpan * 60)) * 100)
  }

  clampPercent(value) {
    return Math.max(0, Math.min(100, value))
  }

  get isToday() {
    if (!this.selectedDate) return true
    return this.selectedDate === this.todayIso()
  }

  todayIso() {
    return this.isoDate(new Date())
  }

  isoDate(date) {
    const month = String(date.getMonth() + 1).padStart(2, "0")
    const day = String(date.getDate()).padStart(2, "0")
    return `${date.getFullYear()}-${month}-${day}`
  }

  get dateLabel() {
    const date = this.selectedDate ? new Date(`${this.selectedDate}T12:00:00`) : new Date()
    return date.toLocaleDateString("en-US", { weekday: "long", month: "short", day: "numeric", year: "numeric" })
  }

  get nowLabel() {
    return new Date().toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" })
  }

  startNeedleTimer() {
    if (this.needleTimer) window.clearInterval(this.needleTimer)
    this.needleTimer = window.setInterval(() => {
      const needle = this.element.querySelector("[data-booking-now-needle]")
      if (needle) needle.style.left = `calc(14rem + ((100% - 14rem) * ${this.nowPercent() / 100}))`
      const label = this.element.querySelector("[data-booking-now-label]")
      if (label) label.textContent = this.nowLabel
    }, 60000)
  }

  // --- Derived data ---------------------------------------------------------------

  get branchName() {
    return this.appointment?.location?.name || this.appointment?.branch?.name || this.operation?.branch?.name || translate("Branch not resolved")
  }

  get userName() {
    return this.element.dataset.userName || (typeof window.currentUser === "function" ? window.currentUser()?.name : window.currentUser?.name) || translate("Front Desk")
  }

  get userRole() {
    return this.element.dataset.userRole || translate("Front Office & Operations")
  }

  get totalBookings() { return this.counts.total_bookings_today ?? this.bookings.length }
  get pendingCheckins() { return this.counts.pending_checkin ?? this.upcoming.length }
  get resourcesTotal() { return this.counts.resources_total ?? this.resources.length }
  get resourcesInUse() { return this.counts.resources_in_use ?? this.resources.filter((resource) => resource.status === "busy").length }
  get roomUtilization() { return this.counts.room_utilization ?? (this.resourcesTotal === 0 ? 0 : Math.round((this.resourcesInUse / this.resourcesTotal) * 100)) }
  get equipmentDeployed() { return this.counts.equipment_deployed ?? 0 }
  get equipmentTotal() { return this.counts.equipment_total ?? 0 }
  get hotDeskOccupied() { return this.counts.hot_desk_occupied ?? 0 }
  get hotDeskTotal() { return this.counts.hot_desk_total ?? 0 }
  get hotDeskPercent() { return this.hotDeskTotal === 0 ? 0 : Math.round((this.hotDeskOccupied / this.hotDeskTotal) * 100) }

  resourceGroup(resource) {
    const category = String(resource.category || "").trim()
    if (category && category !== "Facilities") return category

    const name = String(resource.name || "").toLowerCase()
    if (/pod|booth|focus/.test(name)) return translate("Focus Pods")
    if (/studio|lab\b|hall|event|theatre|theater|auditorium/.test(name)) return translate("Event Spaces")
    if (/equipment|camera|microphone|mic\b|projector|screen|beamer|vr\b|polycom|av\b/.test(name)) return translate("Equipment Units")
    return translate("Meeting Rooms")
  }

  get categories() {
    const seen = new Map()
    this.resources.forEach((resource) => {
      const group = this.resourceGroup(resource)
      seen.set(group, (seen.get(group) || 0) + 1)
    })
    return Array.from(seen.entries()).map(([name, count]) => ({ name, count }))
  }

  get filteredResources() {
    if (this.activeFilter === "all") return this.resources
    return this.resources.filter((resource) => this.resourceGroup(resource) === this.activeFilter)
  }

  get featuredBooking() {
    return this.bookings.find((booking) => booking.status === "active") || this.bookings[0] || null
  }

  get featuredResource() {
    const booking = this.featuredBooking
    if (!booking) return null
    return this.resources.find((resource) => booking.resource_ids.includes(resource.id)) || null
  }

  get unassignedBookings() {
    return this.bookings.filter((booking) => !booking.resource_ids || booking.resource_ids.length === 0)
  }

  bookingsFor(resourceId) {
    if (resourceId === "unassigned") return this.unassignedBookings
    return this.bookings.filter((booking) => booking.resource_ids.includes(resourceId))
  }

  // --- Rendering ------------------------------------------------------------------

  renderContent() {
    this.element.innerHTML = this.contentHTML()
  }

  contentHTML() {
    return `
      <div class="bg-background text-foreground min-h-screen flex flex-col">
        ${this.renderHeader()}
        <main class="flex-1 pt-20 w-full">
          <div class="w-full px-4 lg:px-6 py-4 flex flex-col gap-4">
            ${this.renderHeadline()}
            ${this.renderKpis()}
            ${this.renderActionBar()}
            <div class="grid grid-cols-1 lg:grid-cols-12 gap-4 items-start">
              <section class="lg:col-span-8 flex flex-col gap-4 min-w-0">
                ${this.renderControls()}
                ${this.renderTimeline()}
                ${this.renderFloorMap()}
              </section>
              <aside class="lg:col-span-4 flex flex-col gap-4 min-w-0">
                ${this.renderInspector()}
                ${this.renderReservationForm()}
                ${this.renderUpcoming()}
              </aside>
            </div>
          </div>
        </main>
        ${this.renderFooter()}
      </div>
    `
  }

  renderHeader() {
    return `
      <header class="fixed top-0 left-0 right-0 z-40 bg-card/95 backdrop-blur border-b border-line shadow-sm">
        <div class="h-20 w-full px-4 lg:px-6 flex items-center justify-between gap-4">
          <div class="flex items-center gap-3 min-w-0">
            <div class="flex items-center gap-2 shrink-0">
              <div class="w-9 h-9 rounded-lg bg-primary flex items-center justify-center text-primary-foreground shadow-sm">
                <span class="material-symbols-outlined text-[20px]">hub</span>
              </div>
              <div class="flex flex-col leading-none">
                <span class="text-[16px] font-bold tracking-tight truncate">${translate("Skycom")}</span>
                <span class="text-[10px] uppercase tracking-wider text-muted-foreground mt-1">${translate("ERP Platform")}</span>
              </div>
            </div>
            <div class="h-6 w-px bg-line hidden xl:block"></div>
            <div class="hidden xl:flex items-center gap-2 px-3 py-1.5 rounded-lg bg-muted">
              <span class="material-symbols-outlined text-[16px] text-primary">business</span>
              <span class="text-[13px] font-semibold text-foreground">${this.escape(this.branchName)}</span>
              <span class="material-symbols-outlined text-[16px] text-muted-foreground">expand_more</span>
            </div>
            <div class="hidden 2xl:flex items-center gap-2 px-3 py-1.5 rounded-lg bg-muted text-muted-foreground">
              <span class="material-symbols-outlined text-[16px]">calendar_today</span>
              <span class="text-[13px] font-semibold text-foreground">${translate("Today")}, ${this.escape(this.dateLabel)}</span>
            </div>
          </div>
          <nav class="hidden lg:flex items-center gap-1 px-1 py-1 rounded-xl bg-muted">
            <a class="px-3 py-2 rounded-lg bg-primary text-primary-foreground text-[13px] font-semibold" href="#">${translate("Bookings & Calendar")}</a>
            <a class="px-3 py-2 rounded-lg text-muted-foreground text-[13px] font-semibold hover:text-foreground" href="#">${translate("Resource Directory")}</a>
            <a class="px-3 py-2 rounded-lg text-muted-foreground text-[13px] font-semibold hover:text-foreground" href="#">${translate("Room Management")}</a>
            <a class="px-3 py-2 rounded-lg text-muted-foreground text-[13px] font-semibold hover:text-foreground" href="#">${translate("Analytics & Usage")}</a>
          </nav>
          <div class="flex items-center gap-3">
            <div class="hidden md:inline-flex items-center gap-1.5 px-2 py-1 rounded-full bg-success/10 text-success">
              <span class="w-1.5 h-1.5 rounded-full bg-success animate-pulse"></span>
              <span class="text-[10px] font-semibold uppercase tracking-wide">${translate("Live Scheduling Engine")}</span>
            </div>
            <div class="h-6 w-px bg-line hidden sm:block"></div>
            <div class="hidden sm:flex items-center gap-2">
              <div class="flex flex-col items-end text-right">
                <span class="text-[12px] font-semibold text-foreground leading-none">${this.escape(this.userName)}</span>
                <span class="text-[10px] text-muted-foreground leading-none mt-1">${this.escape(this.userRole)}</span>
              </div>
              <div class="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-primary-foreground">
                <span class="material-symbols-outlined text-[18px]">person</span>
              </div>
            </div>
          </div>
        </div>
      </header>
    `
  }

  renderHeadline() {
    return `
      <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-3">
        <div class="flex flex-col">
          <div class="flex items-center gap-2">
            <span class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-success/10 text-success border border-success/20 text-[11px] font-semibold">
              <span class="w-1.5 h-1.5 rounded-full bg-success animate-pulse"></span>
              ${translate("Live Scheduling Engine")}
            </span>
            <span class="text-[11px] text-muted-foreground truncate">· ${this.escape(this.branchName)} · ${this.escape(this.dateLabel)}</span>
          </div>
          <h1 class="text-2xl font-bold text-foreground tracking-tight mt-1">${translate("Booking Operations Console")}</h1>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-muted text-muted-foreground text-[12px] font-semibold">
            <span class="material-symbols-outlined text-[17px] text-primary">event_available</span>
            ${this.totalBookings} ${translate("bookings")} · ${this.resourcesInUse} ${translate("spaces in use")}
          </span>
        </div>
      </div>
    `
  }

  renderKpis() {
    return `
      <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
        ${this.renderKpiCard({
          label: translate("Total Bookings Today"),
          value: this.totalBookings,
          unit: translate("Confirmed"),
          footer: `<span class="w-2 h-2 rounded-full bg-warning inline-block"></span> ${this.pendingCheckins} ${translate("pending check-in")}`,
          icon: "calendar_month",
          tone: "primary"
        })}
        ${this.renderKpiCard({
          label: translate("Room Utilization"),
          value: `${this.roomUtilization}%`,
          unit: translate("Active"),
          footer: `${this.resourcesInUse} ${translate("of")} ${this.resourcesTotal} ${translate("spaces in use")}`,
          icon: "meeting_room",
          tone: "success"
        })}
        ${this.renderKpiCard({
          label: translate("Equipment Deployed"),
          value: this.equipmentDeployed,
          unit: translate("Devices"),
          footer: `${this.equipmentTotal} ${translate("equipment resources tracked")}`,
          icon: "devices_other",
          tone: "warning"
        })}
        ${this.renderKpiCard({
          label: translate("Hot Desk Occupancy"),
          value: `${this.hotDeskOccupied}<span class="text-2xl text-muted-foreground">/${this.hotDeskTotal}</span>`,
          unit: `${this.hotDeskPercent}% ${translate("full")}`,
          footer: `${Math.max(0, this.hotDeskTotal - this.hotDeskOccupied)} ${translate("open agile bays available")}`,
          icon: "desk",
          tone: "info"
        })}
      </div>
    `
  }

  renderKpiCard({ label, value, unit, footer, icon, tone }) {
    const tones = {
      primary: { bar: "bg-primary", icon: "text-primary" },
      success: { bar: "bg-success", icon: "text-success" },
      warning: { bar: "bg-warning", icon: "text-warning" },
      info: { bar: "bg-info", icon: "text-info" }
    }
    const palette = tones[tone] || tones.primary

    return `
      <div class="relative overflow-hidden rounded-xl bg-card border border-line shadow-sm p-4 flex items-center justify-between gap-3 group hover:shadow-md transition-all">
        <div class="absolute left-0 top-0 bottom-0 w-1 ${palette.bar}"></div>
        <div class="flex flex-col pl-1 min-w-0">
          <span class="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">${label}</span>
          <div class="flex items-baseline gap-1.5 mt-1">
            <span class="text-3xl font-extrabold tracking-tight text-foreground">${value}</span>
            <span class="text-[12px] font-semibold text-muted-foreground">${unit}</span>
          </div>
          <span class="text-[12px] text-muted-foreground mt-1 flex items-center gap-1">${footer}</span>
        </div>
        <div class="w-12 h-12 rounded-xl bg-muted flex items-center justify-center ${palette.icon} shrink-0">
          <span class="material-symbols-outlined text-[26px]">${icon}</span>
        </div>
      </div>
    `
  }

  renderActionBar() {
    return `
      <div class="flex flex-wrap items-center justify-between gap-3 bg-card border border-line px-4 py-3 rounded-xl shadow-sm">
        <div class="flex items-center gap-3 flex-wrap">
          <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg bg-muted text-muted-foreground text-[13px] font-semibold">
            <span class="material-symbols-outlined text-[18px] text-primary">corporate_fare</span>
            <span>${this.escape(this.branchName)}</span>
          </div>
          <div class="h-4 w-px bg-line/60"></div>
          <div class="flex items-center gap-1.5 text-[11px] font-semibold text-muted-foreground">
            <span class="w-2 h-2 rounded-full bg-success"></span>
            <span>${translate("Synced with live Event reservations")}</span>
          </div>
        </div>
        <div class="flex items-center gap-2 flex-wrap">
          <button type="button" data-action="click->${this.identifier}#quickRoom"
            class="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-muted hover:bg-line text-foreground text-[13px] font-semibold transition-colors">
            <span class="material-symbols-outlined text-[18px]">bolt</span>
            <span>${translate("15-Min Quick Room")}</span>
          </button>
          <button type="button" data-action="click->${this.identifier}#scrollToReservation"
            class="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-muted hover:bg-line text-foreground text-[13px] font-semibold transition-colors">
            <span class="material-symbols-outlined text-[18px]">no_meeting_room</span>
            <span>${translate("Release Unused")}</span>
          </button>
          <button type="button" data-action="click->${this.identifier}#scrollToReservation"
            class="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-muted hover:bg-line text-foreground text-[13px] font-semibold transition-colors">
            <span class="material-symbols-outlined text-[18px]">picture_as_pdf</span>
            <span>${translate("Daily Run Sheet")}</span>
          </button>
          <button id="btnOpenNewReservation" type="button" data-action="click->${this.identifier}#scrollToReservation"
            class="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-primary text-primary-foreground text-[13px] font-semibold shadow-sm hover:brightness-110 transition-all">
            <span class="material-symbols-outlined text-[18px]">add_circle</span>
            <span>${translate("New Reservation")}</span>
          </button>
        </div>
      </div>
    `
  }

  renderControls() {
    return `
      <div class="bg-card rounded-xl border border-line p-4 shadow-sm flex flex-col gap-4">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div class="inline-flex p-1 bg-muted rounded-xl" role="tablist">
            <button type="button" class="px-3.5 py-1.5 rounded-lg bg-card text-primary text-[13px] font-semibold shadow-sm flex items-center gap-1.5">
              <span class="material-symbols-outlined text-[16px]">view_timeline</span>
              <span>${translate("Day Timeline Grid")}</span>
            </button>
            <button type="button" class="px-3.5 py-1.5 rounded-lg text-muted-foreground hover:text-foreground text-[13px] font-semibold flex items-center gap-1.5">
              <span class="material-symbols-outlined text-[16px]">meeting_room</span>
              <span>${translate("Room List")}</span>
            </button>
            <button type="button" class="px-3.5 py-1.5 rounded-lg text-muted-foreground hover:text-foreground text-[13px] font-semibold flex items-center gap-1.5">
              <span class="material-symbols-outlined text-[16px]">grid_view</span>
              <span>${translate("Desk Zones")}</span>
            </button>
          </div>
          <div class="flex items-center gap-1">
            <button type="button" data-action="click->${this.identifier}#previousDay"
              class="p-1.5 rounded-lg hover:bg-muted text-muted-foreground" title="${translate("Previous day")}">
              <span class="material-symbols-outlined text-[18px]">chevron_left</span>
            </button>
            <div class="flex items-center gap-1 px-2.5 py-1 rounded-lg bg-muted text-foreground text-[13px] font-semibold">
              <span class="material-symbols-outlined text-[16px] text-primary">event</span>
              <span>${this.escape(this.dateLabel)}</span>
            </div>
            <button type="button" data-action="click->${this.identifier}#nextDay"
              class="p-1.5 rounded-lg hover:bg-muted text-muted-foreground" title="${translate("Next day")}">
              <span class="material-symbols-outlined text-[18px]">chevron_right</span>
            </button>
            <button type="button" data-action="click->${this.identifier}#today"
              class="ml-1 px-2.5 py-1 rounded-lg bg-muted hover:bg-line text-muted-foreground text-[11px] font-semibold">
              ${translate("Today")}
            </button>
          </div>
        </div>
        <div class="flex items-center gap-2 overflow-x-auto pb-0.5">
          ${this.renderFilterChip("all", `${translate("All Resources")} (${this.resources.length})`)}
          ${this.categories.map((category) => this.renderFilterChip(category.name, `${this.escape(category.name)} (${category.count})`)).join("")}
        </div>
      </div>
    `
  }

  renderFilterChip(key, label) {
    const active = this.activeFilter === key
    const classes = active
      ? "bg-primary text-primary-foreground shadow-sm"
      : "bg-muted text-muted-foreground hover:text-foreground"
    return `
      <button type="button" data-action="click->${this.identifier}#setFilter" data-${this.identifier}-filter-param="${this.escape(key)}"
        class="px-3 py-1 rounded-full text-[11px] font-semibold whitespace-nowrap transition-colors ${classes}">
        ${label}
      </button>
    `
  }

  renderTimeline() {
    return `
      <div class="bg-card rounded-xl border border-line shadow-sm overflow-hidden flex flex-col">
        <div class="border-b border-line bg-muted/70 flex items-stretch">
          <div class="w-56 shrink-0 p-2 px-4 border-r border-line flex items-center justify-between">
            <span class="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">${translate("Resource / Space")}</span>
            <span class="material-symbols-outlined text-[16px] text-muted-foreground">tune</span>
          </div>
          <div class="flex-1 grid text-center py-2 text-[11px] font-semibold text-muted-foreground select-none" style="grid-template-columns: repeat(${this.timelineSpan}, minmax(0, 1fr));">
            ${this.renderHourMarkers()}
          </div>
        </div>
        <div class="relative divide-y divide-line bg-card">
          ${this.isToday ? this.renderNowNeedle() : ""}
          ${this.filteredResources.length === 0 ? this.renderEmptyResources() : this.filteredResources.map((resource) => this.renderTimelineRow(resource)).join("")}
          ${this.renderUnassignedRow()}
        </div>
      </div>
    `
  }

  renderHourMarkers() {
    return Array.from({ length: this.timelineSpan }, (_, index) => {
      const hour = this.timelineStartHour + index
      return `<div>${String(hour).padStart(2, "0")}:00</div>`
    }).join("")
  }

  renderNowNeedle() {
    return `
      <div data-booking-now-needle class="absolute top-0 bottom-0 pointer-events-none z-30" style="left: calc(14rem + ((100% - 14rem) * ${this.nowPercent() / 100}));">
        <div class="relative h-full flex flex-col items-center">
          <div data-booking-now-label class="bg-danger text-danger-foreground text-[10px] font-semibold px-1.5 py-0.5 rounded-full shadow-sm whitespace-nowrap -mt-2">
            ${this.escape(this.nowLabel)}
          </div>
          <div class="w-0.5 flex-1 bg-danger"></div>
        </div>
      </div>
    `
  }

  renderUnassignedRow() {
    if (this.activeFilter !== "all" || this.unassignedBookings.length === 0) return ""
    return this.renderTimelineRow({
      id: "unassigned",
      name: translate("Unassigned bookings"),
      category: translate("Unassigned"),
      capacity: null,
      status: "available"
    })
  }

  renderEmptyResources() {
    return `
      <div class="p-8 text-center text-sm text-muted-foreground">
        ${translate("No facilities are configured for this branch yet. Add a Facility to start using the booking timeline.")}
      </div>
    `
  }

  renderTimelineRow(resource) {
    const resourceBookings = this.bookingsFor(resource.id)
    const statusDot = resource.status === "busy" ? "bg-success" : "bg-line"
    const capacity = resource.capacity ? `${resource.capacity} ${translate("Pax")}` : null
    const detail = [capacity, this.resourceGroup(resource)].filter(Boolean).join(" • ")

    return `
      <div class="flex items-stretch hover:bg-muted/40 transition-colors group">
        <div class="w-56 shrink-0 p-3 px-4 border-r border-line flex flex-col justify-center">
          <div class="flex items-center gap-1.5 min-w-0">
            <span class="text-[15px] font-semibold text-foreground tracking-tight truncate">${this.escape(resource.name)}</span>
            <span class="w-2 h-2 rounded-full ${statusDot} shrink-0"></span>
          </div>
          <div class="flex items-center gap-2 mt-0.5 text-muted-foreground text-[11px] font-semibold truncate">
            ${detail ? `<span>${this.escape(detail)}</span>` : `<span>${translate("Resource")}</span>`}
          </div>
        </div>
        <div class="flex-1 relative h-24 p-1">
          <div class="absolute inset-0 grid pointer-events-none opacity-40" style="grid-template-columns: repeat(${this.timelineSpan}, minmax(0, 1fr));">
            ${Array.from({ length: this.timelineSpan }, () => `<div class="border-r border-dashed border-line"></div>`).join("")}
          </div>
          ${resourceBookings.length === 0 ? this.renderAvailableBand() : resourceBookings.map((booking) => this.renderBookingBlock(booking)).join("")}
        </div>
      </div>
    `
  }

  renderAvailableBand() {
    return `
      <div class="absolute top-1.5 bottom-1.5 left-0 right-0 rounded-lg border border-dashed border-line flex items-center justify-center">
        <span class="text-[11px] font-semibold text-muted-foreground flex items-center gap-1">
          <span class="material-symbols-outlined text-[15px]">add</span>
          ${translate("Available all day")}
        </span>
      </div>
    `
  }

  renderBookingBlock(booking) {
    const left = this.percentForTime(booking.start_at)
    const width = Math.max(2, this.durationPercent(booking))
    const tone = this.bookingTone(booking.status)
    const statusLabel = this.bookingStatusLabel(booking.status)

    return `
      <div data-booking-block data-booking-id="${this.escape(booking.id)}"
        class="absolute top-1.5 bottom-1.5 z-10 cursor-pointer rounded-lg p-2 border ${tone} transition-all hover:shadow-md overflow-hidden"
        style="left: ${left}%; width: ${width}%;"
        title="${this.escape(booking.title)} · ${this.escape(booking.start_label)} - ${this.escape(booking.end_label)}">
        <div class="flex items-center justify-between gap-1 leading-none">
          <span class="text-[11px] font-bold tracking-wide truncate">${this.escape(booking.title)}</span>
          ${statusLabel ? `<span class="px-1.5 py-0.5 rounded-full text-[9px] uppercase font-bold shrink-0 ${this.bookingBadgeTone(booking.status)}">${statusLabel}</span>` : ""}
        </div>
        <div class="text-[11px] truncate mt-1 opacity-90">${this.escape(booking.organizer)} • ${booking.attendees} ${translate("Att.")}</div>
        <div class="text-[10px] truncate mt-1 opacity-75">${this.escape(booking.start_label)} - ${this.escape(booking.end_label)}</div>
      </div>
    `
  }

  bookingTone(status) {
    const tones = {
      active: "bg-primary text-primary-foreground border-primary",
      completed: "bg-muted text-muted-foreground border-line opacity-80",
      upcoming: "bg-card text-foreground border-line",
      cancelled: "bg-muted text-muted-foreground border-line opacity-60"
    }
    return tones[status] || tones.upcoming
  }

  bookingBadgeTone(status) {
    const tones = {
      active: "bg-success text-success-foreground",
      completed: "bg-line text-muted-foreground",
      upcoming: "bg-primary/10 text-primary",
      cancelled: "bg-danger/10 text-danger"
    }
    return tones[status] || tones.upcoming
  }

  bookingStatusLabel(status) {
    const labels = {
      active: translate("Active"),
      completed: translate("Done"),
      upcoming: translate("Confirmed"),
      cancelled: translate("Cancelled")
    }
    return labels[status] || ""
  }

  renderFloorMap() {
    return `
      <div class="bg-card rounded-xl border border-line p-4 shadow-sm flex flex-col gap-4">
        <div class="flex items-center justify-between gap-3">
          <div class="flex items-center gap-3">
            <span class="material-symbols-outlined text-[24px] text-primary">map</span>
            <div>
              <span class="text-[16px] font-bold text-foreground tracking-tight">${translate("Floor 4 Agile Zoning & Hot Desking")}</span>
              <p class="text-[12px] text-muted-foreground mt-0.5">${translate("Live occupancy derived from today's facility bookings")}</p>
            </div>
          </div>
          <span class="text-[11px] font-semibold px-2.5 py-1 rounded-full bg-success/10 text-success">${translate("Zone Live Map")}</span>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          ${this.renderZoneCard(translate("Zone A (East Wing)"), translate("Open collaborative benching and shared desks."), this.hotDeskOccupied, this.hotDeskTotal, "primary")}
          ${this.renderZoneCard(translate("Zone B (Quiet Hub)"), translate("Individual focus desks with privacy screens."), Math.max(0, this.hotDeskTotal - this.hotDeskOccupied), this.hotDeskTotal, "success")}
          <div class="p-4 rounded-xl bg-muted flex flex-col justify-between">
            <span class="text-[13px] font-bold text-foreground">${translate("Micro-Pods & Booths")}</span>
            <div class="grid grid-cols-4 gap-2 my-2">
              ${this.resources.slice(0, 8).map((resource, index) => `
                <div class="h-8 rounded ${resource.status === "busy" ? "bg-primary text-primary-foreground" : "bg-success/15 text-success"} text-[10px] flex items-center justify-center font-bold truncate px-1" title="${this.escape(resource.name)}">
                  ${this.escape(resource.code || `P-${String(index + 1).padStart(2, "0")}`)}
                </div>
              `).join("") || `<span class="col-span-4 text-[11px] text-muted-foreground">${translate("No pods configured")}</span>`}
            </div>
            <div class="flex items-center justify-between text-[11px] font-semibold text-muted-foreground">
              <span class="flex items-center gap-1"><span class="w-2 h-2 rounded bg-primary inline-block"></span> ${translate("Occupied")}</span>
              <span class="flex items-center gap-1"><span class="w-2 h-2 rounded bg-success/40 inline-block"></span> ${translate("Free")}</span>
            </div>
          </div>
        </div>
      </div>
    `
  }

  renderZoneCard(title, description, occupied, total, tone) {
    const percent = total === 0 ? 0 : Math.round((occupied / total) * 100)
    const bar = tone === "primary" ? "bg-primary" : "bg-success"
    return `
      <div class="p-4 rounded-xl bg-muted flex flex-col justify-between">
        <div class="flex items-center justify-between gap-2">
          <span class="text-[13px] font-bold text-foreground">${title}</span>
          <span class="px-2 py-0.5 rounded-full ${percent >= 80 ? "bg-danger/10 text-danger" : "bg-success/10 text-success"} text-[11px] font-bold">${percent}% ${translate("Full")}</span>
        </div>
        <p class="text-[12px] text-muted-foreground mt-2">${description}</p>
        <div class="w-full bg-line h-2 rounded-full overflow-hidden mt-3">
          <div class="${bar} h-full rounded-full" style="width: ${percent}%"></div>
        </div>
        <div class="flex items-center justify-between mt-3 text-[11px] font-semibold">
          <span class="text-muted-foreground">${Math.max(0, total - occupied)} ${translate("Open")}</span>
          <button type="button" data-action="click->${this.identifier}#scrollToReservation" class="text-primary hover:underline">${translate("Claim Seat")} →</button>
        </div>
      </div>
    `
  }

  renderInspector() {
    const booking = this.featuredBooking
    const resource = this.featuredResource
    if (!booking) {
      return `
        <div class="bg-card rounded-xl border border-line p-4 shadow-sm">
          <div class="flex items-center justify-between">
            <span class="text-[11px] font-bold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
              <span class="material-symbols-outlined text-[16px] text-primary">visibility</span>
              ${translate("Selected Room Inspector")}
            </span>
            <span class="px-2.5 py-0.5 rounded-full bg-muted text-muted-foreground text-[11px] font-bold">${translate("Idle")}</span>
          </div>
          <p class="text-[13px] text-muted-foreground mt-3">${translate("Select a booking block to inspect the reservation.")}</p>
        </div>
      `
    }

    const statusLabel = booking.status === "active" ? translate("In Session") : this.bookingStatusLabel(booking.status)
    return `
      <div class="bg-card rounded-xl border border-line p-4 shadow-sm flex flex-col gap-4">
        <div class="flex items-center justify-between">
          <span class="text-[11px] font-bold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[16px] text-primary">visibility</span>
            ${translate("Selected Room Inspector")}
          </span>
          <span class="px-2.5 py-0.5 rounded-full bg-success/10 text-success text-[11px] font-bold">${statusLabel}</span>
        </div>
        <div class="flex flex-col gap-2">
          <div class="relative w-full h-36 rounded-lg overflow-hidden bg-muted flex items-center justify-center">
            <span class="material-symbols-outlined text-[64px] text-muted-foreground/40">meeting_room</span>
            <div class="absolute inset-0 bg-gradient-to-t from-foreground/70 via-foreground/10 to-transparent"></div>
            <div class="absolute bottom-2 left-3 text-primary-foreground">
              <span class="text-[20px] font-bold leading-tight block">${this.escape(resource?.name || translate("Unassigned room"))}</span>
              <span class="text-[11px] opacity-90">${this.escape(this.branchName)}</span>
            </div>
          </div>
          <div class="pt-1">
            <span class="text-[16px] font-bold text-foreground block">${this.escape(booking.title)}</span>
            <span class="text-[12px] text-muted-foreground">${translate("Scheduled:")} ${this.escape(booking.start_label)} – ${this.escape(booking.end_label)}</span>
          </div>
        </div>
        <div class="bg-muted rounded-lg p-2 flex flex-col gap-2">
          <div class="flex items-center gap-2">
            <div class="w-10 h-10 rounded-full bg-primary text-primary-foreground flex items-center justify-center font-bold text-[16px]">
              ${this.escape(this.initialsFor(booking.organizer))}
            </div>
            <div class="flex flex-col">
              <span class="text-[13px] font-semibold text-foreground leading-tight">${this.escape(booking.organizer)}</span>
              <span class="text-[12px] text-muted-foreground leading-tight">${translate("Organiser")}</span>
            </div>
          </div>
          ${booking.customer ? `
            <div class="flex items-center gap-1.5 text-[11px] font-semibold text-muted-foreground">
              <span class="material-symbols-outlined text-[14px]">apartment</span>
              ${translate("Client:")} <strong class="text-foreground">${this.escape(booking.customer)}</strong>
            </div>
          ` : ""}
          <div class="grid grid-cols-2 gap-2 pt-2 border-t border-line text-[11px] font-semibold">
            <div>
              <span class="text-muted-foreground block">${translate("Attendees")}</span>
              <span class="text-foreground">${booking.attendees}</span>
            </div>
            <div>
              <span class="text-muted-foreground block">${translate("Reference")}</span>
              <span class="text-primary truncate block">${this.escape(booking.code || booking.id)}</span>
            </div>
          </div>
        </div>
        <div class="grid grid-cols-2 gap-2">
          <button type="button" data-action="click->${this.identifier}#extendBooking"
            class="px-3 py-2 rounded-lg bg-muted hover:bg-line text-foreground text-[11px] font-semibold flex items-center justify-center gap-1.5 transition-colors">
            <span class="material-symbols-outlined text-[16px] text-primary">more_time</span>
            ${translate("Extend +30m")}
          </button>
          <button type="button" data-action="click->${this.identifier}#endBooking"
            class="px-3 py-2 rounded-lg bg-danger/10 hover:bg-danger hover:text-danger-foreground text-danger text-[11px] font-semibold flex items-center justify-center gap-1.5 transition-colors">
            <span class="material-symbols-outlined text-[16px]">stop_circle</span>
            ${translate("End & Release")}
          </button>
        </div>
        <div class="grid grid-cols-2 gap-2">
          <button type="button" data-action="click->${this.identifier}#checkInBooking"
            class="px-3 py-2 rounded-lg bg-success text-success-foreground text-[11px] font-semibold flex items-center justify-center gap-1.5 transition-colors shadow-sm">
            <span class="material-symbols-outlined text-[16px]">how_to_reg</span>
            ${translate("Check-In Room")}
          </button>
          <button type="button" data-action="click->${this.identifier}#ringOrganizer"
            class="px-3 py-2 rounded-lg bg-muted hover:bg-line text-muted-foreground text-[11px] font-semibold flex items-center justify-center gap-1.5 transition-colors">
            <span class="material-symbols-outlined text-[16px]">call</span>
            ${translate("Ring Organizer")}
          </button>
        </div>
      </div>
    `
  }

  renderReservationForm() {
    const facilities = this.reference.facilities?.length ? this.reference.facilities : this.resources
    const options = facilities.map((facility) => {
      const capacity = facility.capacity ? ` (${facility.capacity}p)` : ""
      return `<option value="${this.escape(facility.id)}">${this.escape(facility.name)}${capacity}</option>`
    }).join("")

    return `
      <div id="quickReservationDrawer" class="bg-card rounded-xl border border-line p-4 shadow-sm flex flex-col gap-4">
        <div class="flex items-center justify-between border-b border-line pb-2">
          <span class="text-[16px] font-bold text-foreground flex items-center gap-2">
            <span class="material-symbols-outlined text-primary text-[22px]">add_alarm</span>
            ${translate("Instant Reservation")}
          </span>
          <span class="text-[11px] font-semibold text-muted-foreground">${translate("Instant Lock")}</span>
        </div>
        <form class="flex flex-col gap-3" data-action="submit->${this.identifier}#handleReservationSubmit">
          <div>
            <label class="text-[11px] font-semibold text-muted-foreground block mb-1">${translate("Meeting / Event Name")}</label>
            <input name="booking[title]" class="w-full px-3 py-2 rounded-lg bg-muted text-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary" placeholder="${translate("e.g. Q4 Regional Strategy Workshop")}" required type="text" />
          </div>
          <div class="grid grid-cols-2 gap-2">
            <div>
              <label class="text-[11px] font-semibold text-muted-foreground block mb-1">${translate("Select Space")}</label>
              <select name="booking[facility_id]" class="w-full px-3 py-2 rounded-lg bg-muted text-foreground text-[11px] font-semibold border border-line focus:outline-none focus:ring-2 focus:ring-primary">
                ${options || `<option value="">${translate("No facilities")}</option>`}
              </select>
            </div>
            <div>
              <label class="text-[11px] font-semibold text-muted-foreground block mb-1">${translate("Host / Dept")}</label>
              <input name="booking[host]" class="w-full px-3 py-2 rounded-lg bg-muted text-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary" type="text" value="${this.escape(this.userName)}" />
            </div>
          </div>
          <div class="grid grid-cols-2 gap-2">
            <div>
              <label class="text-[11px] font-semibold text-muted-foreground block mb-1">${translate("Start Time")}</label>
              <input name="booking[start_time]" class="w-full px-3 py-2 rounded-lg bg-muted text-foreground text-[11px] font-semibold border border-line focus:outline-none focus:ring-2 focus:ring-primary" type="time" value="10:30" />
            </div>
            <div>
              <label class="text-[11px] font-semibold text-muted-foreground block mb-1">${translate("End Time")}</label>
              <input name="booking[end_time]" class="w-full px-3 py-2 rounded-lg bg-muted text-foreground text-[11px] font-semibold border border-line focus:outline-none focus:ring-2 focus:ring-primary" type="time" value="11:30" />
            </div>
          </div>
          <div class="flex items-center justify-between p-2 rounded-lg bg-muted mt-1">
            <div class="flex flex-col">
              <span class="text-[11px] font-semibold text-foreground">${translate("10-Min No-Show Release")}</span>
              <span class="text-[11px] text-muted-foreground">${translate("Auto-releases room if not checked in")}</span>
            </div>
            <input checked class="w-4 h-4 text-primary rounded focus:ring-primary" type="checkbox" />
          </div>
          <button class="w-full py-2.5 rounded-lg bg-primary hover:brightness-110 text-primary-foreground text-[13px] font-semibold transition-all shadow-sm mt-1 flex items-center justify-center gap-1.5" type="submit">
            <span class="material-symbols-outlined text-[18px]">verified</span>
            <span>${translate("Confirm & Lock Booking")}</span>
          </button>
        </form>
      </div>
    `
  }

  renderUpcoming() {
    return `
      <div class="bg-card rounded-xl border border-line p-4 shadow-sm flex flex-col gap-4">
        <div class="flex items-center justify-between">
          <span class="text-[16px] font-bold text-foreground">${translate("Upcoming Check-Ins")}</span>
          <span class="text-[11px] font-semibold text-success">${this.pendingCheckins} ${translate("Pending")}</span>
        </div>
        <div class="flex flex-col gap-2">
          ${this.upcoming.length === 0 ? `<p class="text-[12px] text-muted-foreground">${translate("No pending check-ins for this day.")}</p>` : this.upcoming.map((booking) => this.renderUpcomingItem(booking)).join("")}
        </div>
      </div>
    `
  }

  renderUpcomingItem(booking) {
    return `
      <div class="p-2.5 rounded-lg bg-muted flex items-center justify-between gap-2">
        <div class="flex flex-col min-w-0 pr-2">
          <span class="text-[13px] font-semibold text-foreground truncate">${this.escape(booking.title)}</span>
          <span class="text-[11px] text-muted-foreground truncate">${this.escape(booking.resource_name || translate("Unassigned room"))} • ${translate("Starts")} ${this.escape(booking.start_label)}</span>
        </div>
        <div class="flex items-center gap-1 shrink-0">
          <button type="button" data-action="click->${this.identifier}#checkInBooking" class="p-1 rounded bg-success text-success-foreground hover:brightness-110 transition-colors" title="${translate("Check In Now")}">
            <span class="material-symbols-outlined text-[16px]">check</span>
          </button>
          <button type="button" data-action="click->${this.identifier}#endBooking" class="p-1 rounded bg-danger/10 text-danger hover:bg-danger hover:text-danger-foreground transition-colors" title="${translate("Release Room")}">
            <span class="material-symbols-outlined text-[16px]">close</span>
          </button>
        </div>
      </div>
    `
  }

  renderFooter() {
    return `
      <footer class="w-full bg-muted border-t border-line mt-4">
        <div class="w-full px-4 lg:px-6 py-4 flex flex-col md:flex-row items-center justify-between gap-3">
          <div class="flex items-center gap-2 text-muted-foreground text-[13px] font-semibold">
            <span>${translate("Skycom ERP Booking & Reservations")}</span>
            <span class="text-line">•</span>
            <span>${translate("Reception Console")} v4.8</span>
          </div>
          <div class="flex items-center gap-4 text-muted-foreground text-[11px] font-semibold">
            <span>${translate("Tenant:")} ${this.escape(this.operation?.company?.name || translate("Skycom Enterprise Corp"))}</span>
            <span class="text-muted-foreground/80">© 2026 ${translate("Skycom Systems. All rights reserved.")}</span>
          </div>
        </div>
      </footer>
    `
  }

  // --- Interactions ---------------------------------------------------------------

  setFilter(event) {
    this.activeFilter = event.params.filter || "all"
    this.renderContent()
  }

  async previousDay() {
    await this.shiftDay(-1)
  }

  async nextDay() {
    await this.shiftDay(1)
  }

  async today() {
    this.selectedDate = null
    await this.reloadConsole()
  }

  async shiftDay(offset) {
    const base = this.selectedDate ? new Date(`${this.selectedDate}T12:00:00`) : new Date()
    base.setDate(base.getDate() + offset)
    this.selectedDate = this.isoDate(base)
    await this.reloadConsole()
  }

  async reloadConsole() {
    try {
      await this.loadConsole()
      this.renderContent()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    }
  }

  scrollToReservation() {
    document.getElementById("quickReservationDrawer")?.scrollIntoView({ behavior: "smooth", block: "center" })
    document.getElementById("quickReservationDrawer")?.querySelector("input")?.focus()
  }

  async handleReservationSubmit(event) {
    event.preventDefault()
    const form = event.target
    const data = new FormData(form)
    const payload = {
      booking: {
        title: data.get("booking[title]"),
        facility_id: data.get("booking[facility_id]"),
        host: data.get("booking[host]"),
        start_time: data.get("booking[start_time]"),
        end_time: data.get("booking[end_time]"),
        date: this.selectedDate
      }
    }

    try {
      const params = this.branchId ? { branch_id: this.branchId } : {}
      const response = await fetchJson(Helpers.booking_reservations_company_operation_path(this.companyId, this.operationId, params), {
        method: "POST",
        body: payload
      })
      toast({ type: "success", message: response.message || translate("Reservation confirmed.") })
      form.reset()
      await this.reloadConsole()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to create the reservation.") })
    }
  }

  quickRoom() {
    this.scrollToReservation()
  }

  extendBooking() {
    toast({ type: "info", message: translate("Extend the booking from the Events module.") })
  }

  endBooking() {
    toast({ type: "info", message: translate("Release the booking from the Events module.") })
  }

  checkInBooking() {
    toast({ type: "info", message: translate("Check-in is managed from the Reception console.") })
  }

  ringOrganizer() {
    toast({ type: "info", message: translate("Call the organiser from the employee directory.") })
  }

  // --- Utilities ------------------------------------------------------------------

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
