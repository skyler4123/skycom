import { Controller } from "@hotwired/stimulus"

// Booking — full-screen resource reservation console for the branch-scoped
// Booking operation. The timeline rows are real Facilities and the blocks are
// real Events for the selected day, linked through EventFacilityAppointment.
//
// Serves Stimulus: Companies_Operations_Booking_ShowController
// Depends on BE: Companies::Operations::BookingController
//   #show #customers #create_reservation
//   #extend_reservation #finish_reservation #cancel_reservation
// Endpoints: Helpers.booking_company_operation_path
//            Helpers.booking_customers_company_operation_path
//            Helpers.booking_reservations_company_operation_path
//            Helpers.booking_reservation_extend_company_operation_path
//            Helpers.booking_reservation_end_company_operation_path
//            Helpers.booking_reservation_cancel_company_operation_path
// Docs: docs/OPERATIONS.md, docs/EVENTS.md
export default class Companies_Operations_Booking_ShowController extends Controller {
  /** @type {any | null} */ operation = null
  /** @type {any | null} */ appointment = null
  /** @type {any | null} */ company = null
  /** @type {any} */ reference = {}
  /** @type {any[]} */ resources = []
  /** @type {any[]} */ bookings = []
  /** @type {any[]} */ upcoming = []
  /** @type {any} */ counts = {}
  /** @type {any} */ caps = {}
  /** @type {any} */ timeline = { start_hour: 8, end_hour: 18 }
  /** @type {string | null} */ companyId = null
  /** @type {string | null} */ operationId = null
  /** @type {string | null} */ branchId = null
  /** @type {string | null} */ selectedDate = null
  /** @type {string} */ activeFilter = "all"
  /** @type {string | null} */ selectedBookingId = null
  /** @type {string | null} */ selectedResourceId = null
  /** @type {number | null} */ needleTimer = null
  /** @type {number | null} */ customerSearchTimer = null
  /** @type {number} */ customerSearchToken = 0
  /** @type {string} */ reservationError = ""
  /** @type {string} */ extendNotice = ""
  /** @type {string} */ quickRoomNotice = ""
  /** @type {any | null} */ cancelState = null
  /** @type {boolean} */ actionPending = false
  /** @type {boolean} */ formSubmitting = false
  /** @type {string | null} */ serverNow = null
  /** @type {number} */ loadedAt = Date.now()
  /** @type {any[]} */ customerResults = []
  /** @type {string} */ customerSearchError = ""
  /** @type {boolean} */ customerSearching = false
  /** @type {any} */ formState = {
    title: "",
    facilityId: "",
    hostId: "",
    customerId: "",
    customerName: "",
    customerQuery: "",
    start: "",
    end: ""
  }

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
    if (this.customerSearchTimer) window.clearTimeout(this.customerSearchTimer)
  }

  // --- Data -----------------------------------------------------------------------

  async loadConsole() {
    const params = {}
    if (this.branchId) params.branch_id = this.branchId
    if (this.selectedDate) params.date = this.selectedDate

    const response = await fetchJson(Helpers.booking_company_operation_path(this.companyId, this.operationId, params))
    this.operation = response.operation
    this.appointment = response.appointment
    this.company = response.company || null
    this.reference = response.reference || {}
    this.hydrateBooking(response.booking || {})
    this.caps = { ...(response.booking?.caps || {}), ...(response.reference?.caps || {}) }
    return response
  }

  hydrateBooking(booking) {
    this.resources = booking.resources || []
    this.bookings = booking.bookings || []
    this.upcoming = booking.upcoming || []
    this.counts = booking.counts || {}
    this.timeline = booking.timeline || { start_hour: 8, end_hour: 18 }
    this.selectedDate = booking.date || this.selectedDate
    this.serverNow = booking.now || null
    this.loadedAt = Date.now()
  }

  // --- Time helpers ---------------------------------------------------------------

  get location() {
    return this.appointment?.location || {}
  }

  get timelineStartHour() { return this.timeline.start_hour ?? 8 }
  get timelineEndHour() { return this.timeline.end_hour ?? 18 }

  currentNow() {
    const base = this.serverNow ? new Date(this.serverNow).getTime() : Date.now()
    return new Date(base + (Date.now() - this.loadedAt))
  }

  time(value, format = "h:mm A") {
    return Helpers.locationTime(value, format, this.location)
  }

  dateLabelFor(value) {
    return Helpers.dateOnly(value, "dddd, MMM D, YYYY", this.location)
  }

  get dateLabel() {
    return this.dateLabelFor(this.selectedDate || this.todayIso())
  }

  todayIso() {
    if (this.serverNow) return Helpers.locationTime(this.serverNow, "YYYY-MM-DD", this.location)
    return Helpers.localToday(this.location)
  }

  get isToday() {
    return (this.selectedDate || this.todayIso()) === this.todayIso()
  }

  windowBounds() {
    const date = this.selectedDate || this.todayIso()
    const [year, month, day] = String(date).split("-").map(Number)
    const offsetHours = Helpers.timezoneOffsetHours(this.location) ?? 0
    const start = Date.UTC(year, month - 1, day, this.timelineStartHour, 0, 0) - (offsetHours * 3600 * 1000)
    const end = Date.UTC(year, month - 1, day, this.timelineEndHour, 0, 0) - (offsetHours * 3600 * 1000)
    return { start, end }
  }

  windowSegment(booking) {
    if (!booking.start_at || !booking.end_at) return null
    const start = new Date(booking.start_at).getTime()
    const end = new Date(booking.end_at).getTime()
    if (Number.isNaN(start) || Number.isNaN(end)) return null

    const bounds = this.windowBounds()
    const clippedStart = Math.max(start, bounds.start)
    const clippedEnd = Math.min(end, bounds.end)
    if (clippedEnd <= clippedStart) return null

    return {
      left: ((clippedStart - bounds.start) / (bounds.end - bounds.start)) * 100,
      width: ((clippedEnd - clippedStart) / (bounds.end - bounds.start)) * 100
    }
  }

  get showNowNeedle() {
    if (!this.isToday) return false
    const now = this.currentNow().getTime()
    const bounds = this.windowBounds()
    return now >= bounds.start && now < bounds.end
  }

  nowPercent() {
    const bounds = this.windowBounds()
    return this.clampPercent(((this.currentNow().getTime() - bounds.start) / (bounds.end - bounds.start)) * 100)
  }

  get nowLabel() {
    return this.time(this.currentNow().toISOString())
  }

  get windowLabel() {
    return `${String(this.timelineStartHour).padStart(2, "0")}:00–${String(this.timelineEndHour).padStart(2, "0")}:00`
  }

  startNeedleTimer() {
    if (this.needleTimer) window.clearInterval(this.needleTimer)
    this.needleTimer = window.setInterval(() => {
      if (!this.isToday) return
      const needle = this.element.querySelector("[data-booking-now-needle]")
      if (this.showNowNeedle && needle) {
        needle.style.left = `calc(14rem + ((100% - 14rem) * ${this.nowPercent() / 100}))`
        const label = this.element.querySelector("[data-booking-now-label]")
        if (label) label.textContent = this.nowLabel
      } else if (this.showNowNeedle !== Boolean(needle)) {
        this.refreshTimeline()
      }
    }, 60000)
  }

  // --- Derived data ---------------------------------------------------------------

  get branchName() {
    return this.appointment?.location?.name || ""
  }

  get companyName() {
    return this.company?.name || ""
  }

  get userName() {
    const user = typeof window.currentUser === "function" ? window.currentUser() : window.currentUser
    return this.element.dataset.userName || Helpers.currentEmployee()?.name || user?.name || ""
  }

  get userRole() {
    return this.element.dataset.userRole || Helpers.currentEmployee()?.category?.name || ""
  }

  get totalBookings() { return this.counts.total_bookings ?? this.bookings.length }
  get upcomingCount() { return this.counts.upcoming ?? 0 }
  get inProgressCount() { return this.counts.in_progress ?? 0 }
  get doneCount() { return this.counts.done ?? 0 }
  get spacesTotal() { return this.counts.spaces_total ?? this.resources.length }
  get spacesInUse() { return this.counts.spaces_in_use ?? this.resources.filter((resource) => resource.in_use).length }
  get utilization() { return this.counts.utilization ?? (this.spacesTotal === 0 ? 0 : Math.round((this.spacesInUse / this.spacesTotal) * 100)) }

  get categories() {
    const fromCounts = this.counts.categories || []
    if (fromCounts.length > 0) return fromCounts
    const seen = new Map()
    this.resources.forEach((resource) => {
      const name = resource.category || translate("Other spaces")
      seen.set(name, (seen.get(name) || 0) + 1)
    })
    return Array.from(seen.entries()).map(([name, total]) => ({ name, total, in_use: 0, free: total }))
  }

  get filteredResources() {
    if (this.activeFilter === "all") return this.resources
    return this.resources.filter((resource) => (resource.category || translate("Other spaces")) === this.activeFilter)
  }

  get bookingsKpiLabel() {
    return this.isToday ? translate("Bookings today") : translate("Bookings on this day")
  }

  get selectedBooking() {
    return this.bookings.find((booking) => String(booking.id) === String(this.selectedBookingId)) || null
  }

  get selectedFacility() {
    const booking = this.selectedBooking
    if (!booking) return null
    return (booking.facilities || []).find((facility) => String(facility.id) === String(this.selectedResourceId)) ||
      (booking.facilities || [])[0] ||
      null
  }

  bookingsFor(resourceId) {
    if (resourceId === "unassigned") {
      return this.bookings.filter((booking) => !booking.resource_ids || booking.resource_ids.length === 0)
    }
    return this.bookings.filter((booking) => (booking.resource_ids || []).includes(resourceId))
  }

  visibleOnTimeline(booking) {
    if (booking.status === "cancelled") return false
    if (booking.status !== "done") return true
    const start = new Date(booking.start_at).getTime()
    return !Number.isNaN(start) && start <= this.currentNow().getTime()
  }

  visibleBookingsFor(resourceId) {
    return this.bookingsFor(resourceId).filter((booking) => this.visibleOnTimeline(booking))
  }

  // --- Rendering ------------------------------------------------------------------

  renderContent() {
    this.element.innerHTML = this.contentHTML()
  }

  contentHTML() {
    return `
      <div class="bg-background text-foreground min-h-screen flex flex-col">
        <div class="print:hidden flex flex-col min-h-screen">
          ${this.renderHeader()}
          <main class="flex-1 pt-20 w-full">
            <div class="w-full px-4 lg:px-6 py-4 flex flex-col gap-4">
              ${this.renderHeadline()}
              ${this.renderKpis()}
              ${this.renderActionBar()}
              <div class="grid grid-cols-1 lg:grid-cols-12 gap-4 items-start">
                <section class="lg:col-span-8 flex flex-col gap-4 min-w-0">
                  ${this.renderControls()}
                  <div data-booking-timeline>${this.renderTimeline()}</div>
                  ${this.renderSpacesByType()}
                </section>
                <aside class="lg:col-span-4 flex flex-col gap-4 min-w-0">
                  <div data-booking-inspector>${this.renderInspector()}</div>
                  <div id="quickReservationDrawer" data-booking-reservation-card>${this.renderReservationForm()}</div>
                  <div data-booking-upcoming>${this.renderUpcoming()}</div>
                </aside>
              </div>
            </div>
          </main>
          ${this.renderFooter()}
        </div>
        ${this.renderRunSheet()}
      </div>
    `
  }

  renderHeader() {
    const currentHref = `${window.location.pathname}${window.location.search}`
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
            ${this.branchName ? `
              <div class="hidden xl:flex items-center gap-2 px-3 py-1.5 rounded-lg bg-muted">
                <span class="material-symbols-outlined text-[16px] text-primary">business</span>
                <span class="text-[13px] font-semibold text-foreground">${this.escape(this.branchName)}</span>
              </div>
            ` : ""}
            <div class="hidden 2xl:flex items-center gap-2 px-3 py-1.5 rounded-lg bg-muted text-muted-foreground">
              <span class="material-symbols-outlined text-[16px]">calendar_today</span>
              <span class="text-[13px] font-semibold text-foreground">${this.escape(this.dateLabel)}</span>
            </div>
          </div>
          <nav class="hidden lg:flex items-center gap-1 px-1 py-1 rounded-xl bg-muted">
            <a class="px-3 py-2 rounded-lg bg-primary text-primary-foreground text-[13px] font-semibold" href="${this.escape(currentHref)}">${translate("Bookings")}</a>
          </nav>
          ${this.userName ? `
            <div class="flex items-center gap-3">
              <div class="h-6 w-px bg-line hidden sm:block"></div>
              <div class="hidden sm:flex items-center gap-2">
                <div class="flex flex-col items-end text-right">
                  <span class="text-[12px] font-semibold text-foreground leading-none">${this.escape(this.userName)}</span>
                  ${this.userRole ? `<span class="text-[10px] text-muted-foreground leading-none mt-1">${this.escape(this.userRole)}</span>` : ""}
                </div>
                <div class="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-primary-foreground">
                  <span class="material-symbols-outlined text-[18px]">person</span>
                </div>
              </div>
            </div>
          ` : ""}
        </div>
      </header>
    `
  }

  renderHeadline() {
    return `
      <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-3">
        <div class="flex flex-col">
          <div class="flex flex-wrap items-center gap-2 text-[11px] text-muted-foreground">
            ${this.branchName ? `<span>${this.escape(this.branchName)}</span><span>·</span>` : ""}
            <span>${this.escape(this.dateLabel)}</span>
          </div>
          <h1 class="text-2xl font-bold text-foreground tracking-tight mt-1">${translate("Booking Operations Console")}</h1>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-muted text-muted-foreground text-[12px] font-semibold">
            <span class="material-symbols-outlined text-[17px] text-primary">event_available</span>
            ${this.totalBookings} ${translate("bookings")} · ${this.spacesInUse} ${translate("spaces in use now")}
          </span>
        </div>
      </div>
    `
  }

  renderKpis() {
    return `
      <div class="grid gap-4" style="grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));">
        <div data-booking-kpi="bookings">${this.renderKpiCard({
          label: this.bookingsKpiLabel,
          value: this.totalBookings,
          unit: translate("bookings"),
          footer: `<span class="w-2 h-2 rounded-full bg-warning inline-block"></span> ${this.upcomingCount} ${translate("upcoming")} · ${this.inProgressCount} ${translate("in progress")} · ${this.doneCount} ${translate("done")}`,
          icon: "calendar_month",
          tone: "primary"
        })}</div>
        <div data-booking-kpi="spaces">${this.renderKpiCard({
          label: translate("Spaces in use"),
          value: `${this.spacesInUse}<span class="text-2xl text-muted-foreground">/${this.spacesTotal}</span>`,
          unit: `${this.utilization}%`,
          footer: `${this.spacesInUse} ${translate("of")} ${this.spacesTotal} ${translate("spaces in use")}`,
          icon: "meeting_room",
          tone: "success"
        })}</div>
        ${this.categories.map((category) => `
          <div data-booking-category-kpi="${this.escape(category.name)}">${this.renderKpiCard({
            label: category.name,
            value: `${category.in_use}<span class="text-2xl text-muted-foreground">/${category.total}</span>`,
            unit: `${category.total === 0 ? 0 : Math.round((category.in_use / category.total) * 100)}%`,
            footer: `${category.free} ${translate("free")}`,
            icon: "space_dashboard",
            tone: "info"
          })}</div>
        `).join("")}
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
          <span class="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider truncate">${this.escape(label)}</span>
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
      <div data-booking-action-bar class="flex flex-wrap items-center justify-between gap-3 bg-card border border-line px-4 py-3 rounded-xl shadow-sm">
        <div class="flex items-center gap-3 flex-wrap">
          ${this.branchName ? `
            <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg bg-muted text-muted-foreground text-[13px] font-semibold">
              <span class="material-symbols-outlined text-[18px] text-primary">corporate_fare</span>
              <span>${this.escape(this.branchName)}</span>
            </div>
            <div class="h-4 w-px bg-line/60"></div>
          ` : ""}
          <div class="flex flex-col">
            <button type="button" data-action="click->${this.identifier}#quickRoom"
              class="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-muted hover:bg-line text-foreground text-[13px] font-semibold transition-colors">
              <span class="material-symbols-outlined text-[18px]">bolt</span>
              <span>${translate("15-Min Quick Room")}</span>
            </button>
            ${this.quickRoomNotice ? `<span class="text-[10px] font-semibold text-warning mt-1">${this.escape(this.quickRoomNotice)}</span>` : ""}
          </div>
        </div>
        <div class="flex items-center gap-2 flex-wrap">
          <button type="button" data-action="click->${this.identifier}#printRunSheet"
            class="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-muted hover:bg-line text-foreground text-[13px] font-semibold transition-colors">
            <span class="material-symbols-outlined text-[18px]">picture_as_pdf</span>
            <span>${translate("Daily run sheet")}</span>
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
          <div class="flex items-center gap-3">
            <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-primary text-primary-foreground text-[13px] font-semibold">
              <span class="material-symbols-outlined text-[16px]">view_timeline</span>
              <span>${translate("Day")}</span>
            </span>
            <span class="text-[11px] font-semibold text-muted-foreground" ${tooltip(translate("Branch opening hours are not configured yet. The grid shows a fixed day window."))}>
              ${translate("Day window")} ${this.windowLabel}
            </span>
          </div>
          <div class="flex items-center gap-1">
            <button type="button" data-action="click->${this.identifier}#previousDay"
              class="p-1.5 rounded-lg hover:bg-muted text-muted-foreground" title="${translate("Previous day")}" aria-label="${translate("Previous day")}">
              <span class="material-symbols-outlined text-[18px]">chevron_left</span>
            </button>
            <div class="flex items-center gap-1 px-2.5 py-1 rounded-lg bg-muted text-foreground text-[13px] font-semibold">
              <span class="material-symbols-outlined text-[16px] text-primary">event</span>
              <span>${this.escape(this.dateLabel)}</span>
            </div>
            <button type="button" data-action="click->${this.identifier}#nextDay"
              class="p-1.5 rounded-lg hover:bg-muted text-muted-foreground" title="${translate("Next day")}" aria-label="${translate("Next day")}">
              <span class="material-symbols-outlined text-[18px]">chevron_right</span>
            </button>
            <button type="button" data-action="click->${this.identifier}#today"
              class="ml-1 px-2.5 py-1 rounded-lg bg-muted hover:bg-line text-muted-foreground text-[11px] font-semibold">
              ${translate("Today")}
            </button>
          </div>
        </div>
        <div class="flex items-center gap-2 overflow-x-auto pb-0.5">
          ${this.renderFilterChip("all", `${translate("All spaces")} (${this.spacesTotal})`)}
          ${this.categories.map((category) => this.renderFilterChip(category.name, `${this.escape(category.name)} (${category.total})`)).join("")}
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
            <span class="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">${translate("Space")}</span>
            <span class="material-symbols-outlined text-[16px] text-muted-foreground">tune</span>
          </div>
          <div class="flex-1 grid text-center py-2 text-[11px] font-semibold text-muted-foreground select-none" style="grid-template-columns: repeat(${this.timelineEndHour - this.timelineStartHour}, minmax(0, 1fr));">
            ${this.renderHourMarkers()}
          </div>
        </div>
        <div class="relative divide-y divide-line bg-card">
          ${this.showNowNeedle ? this.renderNowNeedle() : ""}
          ${this.filteredResources.length === 0 ? this.renderEmptyResources() : this.filteredResources.map((resource) => this.renderTimelineRow(resource)).join("")}
          ${this.renderUnassignedRow()}
        </div>
      </div>
      ${this.renderCapsNotice()}
    `
  }

  renderHourMarkers() {
    const span = this.timelineEndHour - this.timelineStartHour
    return Array.from({ length: span }, (_, index) => {
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
    if (this.activeFilter !== "all") return ""
    const bookings = this.visibleBookingsFor("unassigned")
    if (bookings.length === 0) return ""
    return this.renderTimelineRow({
      id: "unassigned",
      name: translate("Unassigned bookings"),
      category: translate("Unassigned"),
      capacity: null,
      in_use: false
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
    const bookings = this.visibleBookingsFor(resource.id)
    const blocks = bookings.map((booking) => this.renderBookingBlock(booking, resource.id)).join("")
    const outside = bookings.filter((booking) => !this.windowSegment(booking))
    const statusDot = resource.in_use ? "bg-success" : "bg-line"
    const capacity = resource.capacity ? `${resource.capacity} ${translate("Pax")}` : null
    const detail = [capacity, resource.category].filter(Boolean).join(" • ")

    return `
      <div data-booking-row="${this.escape(resource.id)}" class="flex items-stretch hover:bg-muted/40 transition-colors group">
        <div class="w-56 shrink-0 p-3 px-4 border-r border-line flex flex-col justify-center">
          <div class="flex items-center gap-1.5 min-w-0">
            <span class="text-[15px] font-semibold text-foreground tracking-tight truncate">${this.escape(resource.name)}</span>
            <span class="w-2 h-2 rounded-full ${statusDot} shrink-0"></span>
          </div>
          <div class="flex items-center gap-2 mt-0.5 text-muted-foreground text-[11px] font-semibold truncate">
            ${detail ? `<span class="truncate">${this.escape(detail)}</span>` : `<span>${translate("Space")}</span>`}
          </div>
          ${outside.length > 0 ? this.renderOutsideTags(outside, resource.id) : ""}
        </div>
        <div class="flex-1 relative h-24 p-1">
          <div class="absolute inset-0 grid pointer-events-none opacity-40" style="grid-template-columns: repeat(${this.timelineEndHour - this.timelineStartHour}, minmax(0, 1fr));">
            ${Array.from({ length: this.timelineEndHour - this.timelineStartHour }, () => `<div class="border-r border-dashed border-line"></div>`).join("")}
          </div>
          ${blocks || (outside.length === 0 ? this.renderAvailableBand() : "")}
        </div>
      </div>
    `
  }

  renderOutsideTags(bookings, resourceId) {
    const sorted = [...bookings].sort((a, b) => new Date(a.start_at) - new Date(b.start_at))
    const label = sorted.length === 1
      ? `${sorted.length} ${translate("booking outside this window")}`
      : `${sorted.length} ${translate("bookings outside this window")}`

    return `
      <div class="mt-1 flex flex-wrap items-center gap-1 text-[10px] font-semibold text-warning">
        <span>${label}</span>
        ${sorted.map((booking) => `
          <button type="button" data-booking-outside-tag data-booking-id="${this.escape(booking.id)}" data-resource-id="${this.escape(resourceId)}"
            data-action="click->${this.identifier}#selectBooking"
            data-selected="${String(this.selectedBookingId) === String(booking.id) && String(this.selectedResourceId) === String(resourceId)}"
            class="rounded-full border border-warning/40 bg-warning/10 px-1.5 py-0.5 hover:bg-warning/20 transition-colors ${String(this.selectedBookingId) === String(booking.id) && String(this.selectedResourceId) === String(resourceId) ? "ring-2 ring-primary" : ""}">
            ${this.escape(this.time(booking.start_at))}
          </button>
        `).join("")}
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

  renderBookingBlock(booking, resourceId) {
    const segment = this.windowSegment(booking)
    if (!segment) return ""
    const tone = this.bookingTone(booking.status)
    const statusLabel = this.bookingStatusLabel(booking.status)
    const selected = String(this.selectedBookingId) === String(booking.id) && String(this.selectedResourceId) === String(resourceId)
    const narrow = segment.width < 18

    return `
      <div data-booking-block data-booking-id="${this.escape(booking.id)}" data-resource-id="${this.escape(resourceId)}"
        data-selected="${selected}"
        data-action="click->${this.identifier}#selectBooking"
        class="absolute top-1.5 bottom-1.5 z-10 cursor-pointer rounded-lg p-2 border ${tone} ${selected ? "ring-2 ring-primary" : ""} transition-all hover:shadow-md overflow-hidden"
        style="left: ${segment.left}%; width: ${Math.max(1.5, segment.width)}%;"
        title="${this.escape(booking.title)} · ${this.escape(this.time(booking.start_at))} - ${this.escape(this.time(booking.end_at))}">
        <div class="flex items-center justify-between gap-1 leading-none">
          <span class="text-[11px] font-bold tracking-wide truncate">${this.escape(booking.title)}</span>
          ${!narrow && statusLabel ? `<span class="px-1.5 py-0.5 rounded-full text-[9px] uppercase font-bold shrink-0 ${this.bookingBadgeTone(booking.status)}">${statusLabel}</span>` : ""}
        </div>
        ${narrow ? "" : `<div class="text-[11px] truncate mt-1 opacity-90">${this.escape(booking.host?.name || translate("No host"))} • ${booking.attendees} ${translate("Att.")}</div>`}
        <div class="text-[10px] truncate mt-1 opacity-75">${this.escape(this.time(booking.start_at))} - ${this.escape(this.time(booking.end_at))}</div>
      </div>
    `
  }

  bookingTone(status) {
    const tones = {
      in_progress: "bg-primary text-primary-foreground border-primary",
      done: "bg-muted text-muted-foreground border-line opacity-80",
      upcoming: "bg-card text-foreground border-line"
    }
    return tones[status] || tones.upcoming
  }

  bookingBadgeTone(status) {
    const tones = {
      in_progress: "bg-success text-success-foreground",
      done: "bg-line text-muted-foreground",
      upcoming: "bg-primary/10 text-primary",
      cancelled: "bg-danger/10 text-danger"
    }
    return tones[status] || tones.upcoming
  }

  bookingStatusLabel(status) {
    const labels = {
      upcoming: translate("Upcoming"),
      in_progress: translate("In progress"),
      done: translate("Done"),
      cancelled: translate("Cancelled")
    }
    return labels[status] || ""
  }

  renderCapsNotice() {
    const lines = []
    if (this.caps?.bookings?.capped) {
      lines.push(`${translate("Showing the first")} ${this.caps.bookings.limit} ${translate("bookings for this day.")}`)
    }
    if (this.caps?.resources?.capped) {
      lines.push(`${translate("Showing the first")} ${this.caps.resources.limit} ${translate("spaces for this branch.")}`)
    }
    if (lines.length === 0) return ""
    return `<p class="text-[11px] font-semibold text-muted-foreground mt-1">${lines.map((line) => this.escape(line)).join(" ")}</p>`
  }

  renderSpacesByType() {
    return `
      <div class="bg-card rounded-xl border border-line p-4 shadow-sm flex flex-col gap-3">
        <div class="flex items-center justify-between gap-3">
          <span class="text-[16px] font-bold text-foreground tracking-tight">${translate("Spaces by type")}</span>
        </div>
        ${this.categories.length === 0 ? `
          <p class="text-[12px] text-muted-foreground">${translate("No facilities are configured for this branch yet.")}</p>
        ` : this.categories.map((category) => this.renderSpacesByTypeRow(category)).join("")}
      </div>
    `
  }

  renderSpacesByTypeRow(category) {
    const percent = category.total === 0 ? 0 : Math.round((category.in_use / category.total) * 100)
    return `
      <div data-booking-spaces-by-type="${this.escape(category.name)}" class="flex flex-col gap-1.5">
        <div class="flex items-center justify-between gap-3 text-[12px]">
          <span class="font-semibold text-foreground truncate">${this.escape(category.name)}</span>
          <span class="font-semibold text-muted-foreground whitespace-nowrap">${category.in_use} ${translate("in use")} · ${category.free} ${translate("free")}</span>
        </div>
        <div class="w-full bg-line h-1.5 rounded-full overflow-hidden">
          <div class="bg-primary h-full rounded-full" style="width: ${percent}%"></div>
        </div>
      </div>
    `
  }

  renderInspector() {
    const booking = this.selectedBooking
    if (!booking) {
      return `
        <div class="bg-card rounded-xl border border-line p-4 shadow-sm">
          <div class="flex items-center justify-between">
            <span class="text-[11px] font-bold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
              <span class="material-symbols-outlined text-[16px] text-primary">visibility</span>
              ${translate("Selected booking")}
            </span>
          </div>
          <p class="text-[13px] font-semibold text-foreground mt-3">${translate("Select a booking")}</p>
          <p class="text-[12px] text-muted-foreground mt-1">${translate("or lock a room with the form.")}</p>
        </div>
      `
    }

    const facility = this.selectedFacility
    const status = booking.status
    const active = status === "upcoming" || status === "in_progress"
    const confirm = this.cancelState && String(this.cancelState.id) === String(booking.id) && this.cancelState.context === "inspector"

    return `
      <div class="bg-card rounded-xl border border-line p-4 shadow-sm flex flex-col gap-4">
        <div class="flex items-center justify-between">
          <span class="text-[11px] font-bold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[16px] text-primary">visibility</span>
            ${translate("Selected booking")}
          </span>
          <span class="px-2.5 py-0.5 rounded-full text-[11px] font-bold ${this.bookingBadgeTone(status)}">${this.bookingStatusLabel(status)}</span>
        </div>

        <div class="flex items-center gap-3 rounded-lg bg-muted p-3">
          <div class="w-10 h-10 rounded-lg bg-card border border-line flex items-center justify-center text-primary shrink-0">
            <span class="material-symbols-outlined text-[22px]">meeting_room</span>
          </div>
          <div class="min-w-0">
            <span class="text-[15px] font-bold text-foreground truncate block">${this.escape(facility?.name || translate("No space linked"))}</span>
            <span class="text-[11px] font-semibold text-muted-foreground truncate block">
              ${this.escape(facility?.category || "—")}${facility?.capacity ? ` · ${this.escape(facility.capacity)} ${translate("Pax")}` : ""}
            </span>
          </div>
        </div>

        <div class="flex flex-col gap-1">
          <span class="text-[16px] font-bold text-foreground block">${this.escape(booking.title)}</span>
          <span class="text-[12px] text-muted-foreground">${this.escape(this.time(booking.start_at))} – ${this.escape(this.time(booking.end_at))}</span>
        </div>

        <div class="bg-muted rounded-lg p-3 flex flex-col gap-2 text-[12px]">
          <div class="flex items-center justify-between gap-3">
            <span class="font-semibold text-muted-foreground">${translate("Host")}</span>
            <span class="font-semibold text-foreground truncate">${this.escape(booking.host?.name || translate("No host"))}</span>
          </div>
          <div class="flex items-center justify-between gap-3">
            <span class="font-semibold text-muted-foreground">${translate("Customer")}</span>
            <span class="font-semibold text-foreground truncate">${this.escape(booking.customer?.name || translate("No customer"))}</span>
          </div>
          <div class="grid grid-cols-2 gap-2 pt-2 border-t border-line">
            <div>
              <span class="text-muted-foreground block">${translate("Attendees")}</span>
              <span class="text-foreground font-semibold">${booking.attendees}</span>
            </div>
            <div>
              <span class="text-muted-foreground block">${translate("Reference")}</span>
              <span class="text-primary font-semibold truncate block">${this.escape(booking.code || "—")}</span>
            </div>
          </div>
        </div>

        ${confirm ? `
          <div data-booking-cancel-confirm class="rounded-lg border border-danger/30 bg-danger/10 p-3 flex flex-col gap-2">
            <span class="text-[12px] font-semibold text-danger">${translate("Cancel this booking?")}</span>
            <div class="flex items-center gap-2">
              <button type="button" data-action="click->${this.identifier}#keepBooking"
                class="px-3 py-1.5 rounded-lg bg-muted text-foreground text-[11px] font-semibold">${translate("Keep")}</button>
              <button type="button" data-action="click->${this.identifier}#confirmCancel"
                class="px-3 py-1.5 rounded-lg bg-danger text-danger-foreground text-[11px] font-semibold">${translate("Cancel booking")}</button>
            </div>
          </div>
        ` : ""}

        ${active && !confirm ? `
          <div class="flex flex-col gap-2">
            <div class="grid grid-cols-2 gap-2">
              <div class="flex flex-col">
                <button type="button" data-action="click->${this.identifier}#extendBooking"
                  class="px-3 py-2 rounded-lg bg-muted hover:bg-line text-foreground text-[11px] font-semibold flex items-center justify-center gap-1.5 transition-colors">
                  <span class="material-symbols-outlined text-[16px] text-primary">more_time</span>
                  ${translate("Extend +30m")}
                </button>
                ${this.extendNotice ? `<span class="text-[10px] font-semibold text-danger mt-1 text-center">${this.escape(this.extendNotice)}</span>` : ""}
              </div>
              <button type="button" data-action="click->${this.identifier}#endBooking"
                class="px-3 py-2 rounded-lg bg-danger/10 hover:bg-danger hover:text-danger-foreground text-danger text-[11px] font-semibold flex items-center justify-center gap-1.5 transition-colors">
                <span class="material-symbols-outlined text-[16px]">stop_circle</span>
                ${translate("End & release")}
              </button>
            </div>
            <button type="button" data-action="click->${this.identifier}#requestCancel" data-booking-id="${this.escape(booking.id)}" data-context="inspector"
              class="text-[11px] font-semibold text-muted-foreground hover:text-danger text-left">
              ${translate("Cancel booking")}
            </button>
          </div>
          <p class="text-[11px] font-semibold text-muted-foreground">${translate("Guest check-in is in Reception.")}</p>
        ` : ""}
      </div>
    `
  }

  renderReservationForm() {
    const facilities = this.reference.facilities || []
    const hosts = this.reference.hosts || []
    const disabled = facilities.length === 0
    const action = Helpers.booking_reservations_company_operation_path(
      this.companyId,
      this.operationId,
      this.branchId ? { branch_id: this.branchId } : {}
    )

    const html = `
      ${facilities.length === 0 ? `<p class="text-[12px] text-danger font-semibold">${translate("No spaces are configured for this branch. Add a Facility to start booking.")}</p>` : ""}
      <div>
        <label class="text-[11px] font-semibold text-muted-foreground block mb-1">${translate("Meeting / event name")}</label>
        <input name="booking[title]" value="${this.escape(this.formState.title)}" class="w-full px-3 py-2 rounded-lg bg-muted text-foreground text-[13px] border border-line focus:outline-none focus:ring-2 focus:ring-primary" placeholder="${translate("e.g. Q4 Regional Strategy Workshop")}" required type="text" />
      </div>
      <div class="grid grid-cols-2 gap-2">
        <div>
          <label class="text-[11px] font-semibold text-muted-foreground block mb-1">${translate("Space")}</label>
          <select name="booking[facility_id]" ${disabled ? "disabled" : ""} class="w-full px-3 py-2 rounded-lg bg-muted text-foreground text-[11px] font-semibold border border-line focus:outline-none focus:ring-2 focus:ring-primary" required>
            <option value="">${translate("Select a space")}</option>
            ${facilities.map((facility) => `
              <option value="${this.escape(facility.id)}" ${String(this.formState.facilityId) === String(facility.id) ? "selected" : ""}>
                ${this.escape(facility.name)}${facility.category ? ` — ${this.escape(facility.category)}` : ""}
              </option>
            `).join("")}
          </select>
          ${this.caps?.facilities?.capped ? `<p class="text-[10px] font-semibold text-muted-foreground mt-1">${translate("Showing the first")} ${this.caps.facilities.limit}.</p>` : ""}
        </div>
        <div>
          <label class="text-[11px] font-semibold text-muted-foreground block mb-1">${translate("Host")}</label>
          <select name="booking[host_id]" class="w-full px-3 py-2 rounded-lg bg-muted text-foreground text-[11px] font-semibold border border-line focus:outline-none focus:ring-2 focus:ring-primary">
            <option value="">${translate("No host")}</option>
            ${hosts.map((host) => `
              <option value="${this.escape(host.id)}" ${String(this.formState.hostId) === String(host.id) ? "selected" : ""}>
                ${this.escape(host.name)}${host.role ? ` — ${this.escape(host.role)}` : ""}
              </option>
            `).join("")}
          </select>
          ${this.caps?.hosts?.capped ? `<p class="text-[10px] font-semibold text-muted-foreground mt-1">${translate("Showing the first")} ${this.caps.hosts.limit}.</p>` : ""}
        </div>
      </div>
      <div>
        <label class="text-[11px] font-semibold text-muted-foreground block mb-1">${translate("Customer")}</label>
        <div data-booking-customer-field>${this.renderCustomerField()}</div>
      </div>
      <div class="grid grid-cols-2 gap-2">
        <div>
          <label class="text-[11px] font-semibold text-muted-foreground block mb-1">${translate("Start")}</label>
          <input name="booking[start_time]" value="${this.escape(this.formState.start)}" class="w-full px-3 py-2 rounded-lg bg-muted text-foreground text-[11px] font-semibold border border-line focus:outline-none focus:ring-2 focus:ring-primary" required type="time" />
        </div>
        <div>
          <label class="text-[11px] font-semibold text-muted-foreground block mb-1">${translate("End")}</label>
          <input name="booking[end_time]" value="${this.escape(this.formState.end)}" class="w-full px-3 py-2 rounded-lg bg-muted text-foreground text-[11px] font-semibold border border-line focus:outline-none focus:ring-2 focus:ring-primary" required type="time" />
        </div>
      </div>
      <p data-booking-form-error class="text-[11px] font-semibold text-danger min-h-[1rem]">${this.escape(this.reservationError)}</p>
      <button class="w-full py-2.5 rounded-lg bg-primary hover:brightness-110 text-primary-foreground text-[13px] font-semibold transition-all shadow-sm mt-1 flex items-center justify-center gap-1.5 disabled:opacity-50" type="submit" ${disabled ? "disabled" : ""}>
        <span class="material-symbols-outlined text-[18px]">verified</span>
        <span>${translate("Confirm & Lock Booking")}</span>
      </button>
    `

    return `
      <div class="bg-card rounded-xl border border-line p-4 shadow-sm flex flex-col gap-4">
        <div class="flex items-center justify-between border-b border-line pb-2">
          <span class="text-[16px] font-bold text-foreground flex items-center gap-2">
            <span class="material-symbols-outlined text-primary text-[22px]">add_alarm</span>
            ${translate("Instant reservation")}
          </span>
        </div>
        ${Helpers.form({
          action: action,
          method: "POST",
          attributes: `novalidate data-booking-reservation-form data-action="submit->${this.identifier}#handleReservationSubmit input->${this.identifier}#syncReservationForm input->${this.identifier}#scheduleCustomerSearch change->${this.identifier}#syncReservationForm"`,
          html: html
        })}
      </div>
    `
  }

  renderCustomerField() {
    if (this.formState.customerId) {
      return `
        <input type="hidden" name="booking[customer_id]" value="${this.escape(this.formState.customerId)}" />
        <div class="flex items-center justify-between gap-2 px-3 py-2 rounded-lg bg-muted border border-line">
          <span class="text-[12px] font-semibold text-foreground truncate">${this.escape(this.formState.customerName || translate("No customer"))}</span>
          <button type="button" data-action="click->${this.identifier}#clearCustomer" class="text-muted-foreground hover:text-danger" title="${translate("Clear customer")}" aria-label="${translate("Clear customer")}">
            <span class="material-symbols-outlined text-[16px]">close</span>
          </button>
        </div>
      `
    }

    return `
      <input type="hidden" name="booking[customer_id]" value="" />
      <input name="booking[customer_query]" value="${this.escape(this.formState.customerQuery)}" data-action="keydown.enter->${this.identifier}#handleCustomerKeydown"
        class="w-full px-3 py-2 rounded-lg bg-muted text-foreground text-[12px] border border-line focus:outline-none focus:ring-2 focus:ring-primary"
        placeholder="${translate("No customer")}" autocomplete="off" type="text" />
      <div data-booking-customer-results class="mt-1 flex flex-col gap-1">${this.renderCustomerResults()}</div>
    `
  }

  renderCustomerResults() {
    const showEmpty = this.formState.customerQuery.length >= 2 && !this.customerSearching && this.customerResults.length === 0 && !this.customerSearchError
    return `
      ${this.formState.customerQuery.length === 0 ? `<span class="text-[10px] font-semibold text-muted-foreground">${translate("Type to search customers.")}</span>` : ""}
      ${this.customerSearchError ? `<span class="text-[10px] font-semibold text-danger">${this.escape(this.customerSearchError)}</span>` : ""}
      ${this.customerSearching ? `<span class="text-[10px] font-semibold text-muted-foreground">${translate("Searching customers…")}</span>` : ""}
      ${this.formState.customerQuery.length > 0 && this.formState.customerQuery.length < 2 ? `<span class="text-[10px] font-semibold text-muted-foreground">${translate("Type at least 2 characters.")}</span>` : ""}
      ${showEmpty ? `<span class="text-[10px] font-semibold text-muted-foreground">${translate("No customers found.")}</span>` : ""}
      ${this.customerResults.map((customer) => `
        <button type="button" data-booking-customer-result data-customer-id="${this.escape(customer.id)}" data-customer-name="${this.escape(customer.name)}"
          data-action="click->${this.identifier}#selectCustomer"
          class="text-left px-2 py-1.5 rounded-lg bg-card border border-line hover:bg-muted">
          <span class="block text-[12px] font-semibold text-foreground truncate">${this.escape(customer.name)}</span>
          <span class="block text-[10px] text-muted-foreground truncate">${this.escape([ customer.code, customer.email ].filter(Boolean).join(" · "))}</span>
        </button>
      `).join("")}
    `
  }

  renderUpcoming() {
    return `
      <div class="bg-card rounded-xl border border-line p-4 shadow-sm flex flex-col gap-4">
        <div class="flex items-center justify-between">
          <span class="text-[16px] font-bold text-foreground">${translate("Upcoming check-ins")}</span>
          <span class="text-[11px] font-semibold text-muted-foreground">${this.upcomingCount} ${translate("upcoming")}</span>
        </div>
        <div class="flex flex-col gap-2">
          ${this.upcoming.length === 0 ? `<p class="text-[12px] text-muted-foreground">${translate("No upcoming bookings for this day.")}</p>` : this.upcoming.map((booking) => this.renderUpcomingItem(booking)).join("")}
        </div>
      </div>
    `
  }

  renderUpcomingItem(booking) {
    const confirm = this.cancelState && String(this.cancelState.id) === String(booking.id) && this.cancelState.context === "upcoming"
    return `
      <div data-booking-upcoming-item="${this.escape(booking.id)}" class="p-2.5 rounded-lg bg-muted flex flex-col gap-2">
        <div class="flex items-center justify-between gap-2">
          <div class="flex flex-col min-w-0 pr-2">
            <span class="text-[13px] font-semibold text-foreground truncate">${this.escape(booking.title)}</span>
            <span class="text-[11px] text-muted-foreground truncate">${this.escape(booking.facility_name || translate("No space linked"))} • ${translate("Starts")} ${this.escape(this.time(booking.start_at))}</span>
          </div>
          <button type="button" data-action="click->${this.identifier}#requestCancel" data-booking-id="${this.escape(booking.id)}" data-context="upcoming"
            class="text-[11px] font-semibold text-danger hover:underline shrink-0">${translate("Cancel")}</button>
        </div>
        ${confirm ? `
          <div data-booking-cancel-confirm class="flex items-center justify-between gap-2 border-t border-line pt-2">
            <span class="text-[11px] font-semibold text-danger">${translate("Cancel this booking?")}</span>
            <div class="flex items-center gap-1">
              <button type="button" data-action="click->${this.identifier}#keepBooking" class="px-2 py-1 rounded bg-muted text-foreground text-[10px] font-semibold">${translate("Keep")}</button>
              <button type="button" data-action="click->${this.identifier}#confirmCancel" class="px-2 py-1 rounded bg-danger text-danger-foreground text-[10px] font-semibold">${translate("Cancel booking")}</button>
            </div>
          </div>
        ` : ""}
      </div>
    `
  }

  renderFooter() {
    return `
      <footer class="w-full bg-muted border-t border-line mt-4">
        <div class="w-full px-4 lg:px-6 py-4 flex flex-col md:flex-row items-center justify-between gap-3">
          <span class="text-muted-foreground text-[13px] font-semibold">${translate("Skycom ERP · Booking")}</span>
          ${this.companyName ? `<span class="text-muted-foreground text-[12px] font-semibold">${this.escape(this.companyName)}</span>` : ""}
        </div>
      </footer>
    `
  }

  renderRunSheet() {
    const bookings = [...this.bookings].sort((a, b) => new Date(a.start_at) - new Date(b.start_at))
    return `
      <div id="booking-run-sheet" data-booking-run-sheet class="hidden print:block text-foreground p-6">
        <div class="mb-4">
          <h1 class="text-xl font-bold">${this.escape(this.branchName)}</h1>
          <p class="text-sm">${this.escape(this.dateLabel)}</p>
        </div>
        ${bookings.length === 0 ? `<p class="text-sm font-semibold">${translate("No bookings")}</p>` : `
          <table class="w-full text-left text-[11px] border-collapse">
            <thead>
              <tr class="border-b border-line">
                <th class="py-1 pr-2 font-bold">${translate("Time")}</th>
                <th class="py-1 pr-2 font-bold">${translate("Space")}</th>
                <th class="py-1 pr-2 font-bold">${translate("Meeting / event name")}</th>
                <th class="py-1 pr-2 font-bold">${translate("Host")}</th>
                <th class="py-1 pr-2 font-bold">${translate("Customer")}</th>
                <th class="py-1 font-bold">${translate("Status")}</th>
              </tr>
            </thead>
            <tbody>
              ${bookings.map((booking) => `
                <tr class="border-b border-line align-top">
                  <td class="py-1 pr-2 whitespace-nowrap">${this.escape(this.time(booking.start_at))} – ${this.escape(this.time(booking.end_at))}</td>
                  <td class="py-1 pr-2">${this.escape((booking.facilities || []).map((facility) => facility.name).join(", ") || translate("No space linked"))}</td>
                  <td class="py-1 pr-2 font-semibold">${this.escape(booking.title)}</td>
                  <td class="py-1 pr-2">${this.escape(booking.host?.name || translate("No host"))}</td>
                  <td class="py-1 pr-2">${this.escape(booking.customer?.name || translate("No customer"))}</td>
                  <td class="py-1">${this.escape(this.bookingStatusLabel(booking.status))}</td>
                </tr>
              `).join("")}
            </tbody>
          </table>
          ${this.caps?.bookings?.capped ? `<p class="text-[11px] mt-3">${translate("Showing the first")} ${this.caps.bookings.limit} ${translate("bookings for this day.")}</p>` : ""}
        `}
      </div>
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
    this.clearSelection()
    await this.reloadConsole()
  }

  async shiftDay(offset) {
    const base = new Date(`${this.selectedDate || this.todayIso()}T12:00:00`)
    base.setDate(base.getDate() + offset)
    this.selectedDate = this.localIsoDate(base)
    this.clearSelection()
    await this.reloadConsole()
  }

  localIsoDate(date) {
    const month = String(date.getMonth() + 1).padStart(2, "0")
    const day = String(date.getDate()).padStart(2, "0")
    return `${date.getFullYear()}-${month}-${day}`
  }

  async reloadConsole() {
    try {
      await this.loadConsole()
      if (this.selectedBookingId && !this.bookings.some((booking) => String(booking.id) === String(this.selectedBookingId))) {
        this.clearSelection()
      }
      this.renderContent()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    }
  }

  clearSelection() {
    this.selectedBookingId = null
    this.selectedResourceId = null
    this.extendNotice = ""
    this.cancelState = null
  }

  selectBooking(event) {
    this.selectedBookingId = event.currentTarget.dataset.bookingId
    this.selectedResourceId = event.currentTarget.dataset.resourceId
    this.extendNotice = ""
    this.cancelState = null
    this.refreshTimeline()
    this.refreshInspector()
    this.refreshUpcoming()
  }

  refreshTimeline() {
    const target = this.element.querySelector("[data-booking-timeline]")
    if (target) target.innerHTML = this.renderTimeline()
  }

  refreshInspector() {
    const target = this.element.querySelector("[data-booking-inspector]")
    if (target) target.innerHTML = this.renderInspector()
  }

  refreshUpcoming() {
    const target = this.element.querySelector("[data-booking-upcoming]")
    if (target) target.innerHTML = this.renderUpcoming()
  }

  refreshReservationForm() {
    const target = this.element.querySelector("[data-booking-reservation-card]")
    if (target) target.innerHTML = this.renderReservationForm()
  }

  refreshActionBar() {
    const target = this.element.querySelector("[data-booking-action-bar]")
    if (target) target.innerHTML = this.renderActionBar()
  }

  scrollToReservation() {
    const drawer = document.getElementById("quickReservationDrawer")
    drawer?.scrollIntoView({ behavior: "smooth", block: "center" })
    drawer?.querySelector('input[name="booking[title]"]')?.focus()
  }

  syncReservationForm(event) {
    const form = this.element.querySelector("[data-booking-reservation-form]")
    if (!form) return
    const data = new FormData(form)
    this.formState.title = data.get("booking[title]") || ""
    this.formState.facilityId = data.get("booking[facility_id]") || ""
    this.formState.hostId = data.get("booking[host_id]") || ""
    this.formState.customerId = data.get("booking[customer_id]") || ""
    this.formState.customerQuery = data.get("booking[customer_query]") || ""
    this.formState.start = data.get("booking[start_time]") || ""
    this.formState.end = data.get("booking[end_time]") || ""

    const name = event?.target?.name
    if (["booking[facility_id]", "booking[start_time]", "booking[end_time]"].includes(name) && this.reservationError) {
      this.setReservationError("")
    }
  }

  handleCustomerKeydown(event) {
    if (event.key !== "Enter") return
    event.preventDefault()
    this.searchCustomers()
  }

  scheduleCustomerSearch(event) {
    if (event?.target?.name !== "booking[customer_query]") return
    const query = event.target.value || ""
    this.formState.customerQuery = query
    if (this.customerSearchTimer) window.clearTimeout(this.customerSearchTimer)
    if (query.trim().length < 2) {
      this.customerResults = []
      this.customerSearchError = ""
      this.customerSearching = false
      this.refreshCustomerResults()
      return
    }

    this.customerSearchTimer = window.setTimeout(() => this.searchCustomers(), 250)
  }

  async searchCustomers() {
    const query = this.formState.customerQuery.trim()
    if (query.length < 2) return
    const token = ++this.customerSearchToken
    this.customerSearching = true
    this.customerSearchError = ""
    this.refreshCustomerResults()

    try {
      const params = { q: query }
      if (this.branchId) params.branch_id = this.branchId
      const response = await fetchJson(Helpers.booking_customers_company_operation_path(this.companyId, this.operationId, params))
      if (token !== this.customerSearchToken) return
      this.customerResults = response.customers || []
    } catch (error) {
      if (token !== this.customerSearchToken) return
      this.customerResults = []
      this.customerSearchError = error.errors?.join(", ") || error.message || translate("Failed to search customers.")
    } finally {
      if (token === this.customerSearchToken) {
        this.customerSearching = false
        this.refreshCustomerResults()
      }
    }
  }

  refreshCustomerResults() {
    const target = this.element.querySelector("[data-booking-customer-results]")
    if (target) target.innerHTML = this.renderCustomerResults()
  }

  refreshCustomerField() {
    const target = this.element.querySelector("[data-booking-customer-field]")
    if (target) target.innerHTML = this.renderCustomerField()
  }

  selectCustomer(event) {
    this.formState.customerId = event.currentTarget.dataset.customerId
    this.formState.customerName = event.currentTarget.dataset.customerName
    this.formState.customerQuery = ""
    this.customerResults = []
    this.customerSearchError = ""
    this.refreshCustomerField()
  }

  clearCustomer() {
    this.formState.customerId = ""
    this.formState.customerName = ""
    this.formState.customerQuery = ""
    this.customerResults = []
    this.customerSearchError = ""
    this.refreshCustomerField()
  }

  setReservationError(message) {
    this.reservationError = message || ""
    const target = this.element.querySelector("[data-booking-form-error]")
    if (target) target.textContent = this.reservationError
  }

  async handleReservationSubmit(event) {
    event.preventDefault()
    if (this.formSubmitting) return

    const form = event.target
    const data = new FormData(form)
    const title = (data.get("booking[title]") || "").trim()
    const facilityId = data.get("booking[facility_id]") || ""
    const start = data.get("booking[start_time]") || ""
    const end = data.get("booking[end_time]") || ""

    if (!title) {
      toast({ type: "error", message: translate("Meeting / event name is required.") })
      form.querySelector('input[name="booking[title]"]')?.focus()
      return
    }
    if (!facilityId) {
      toast({ type: "error", message: translate("Select a space for this reservation.") })
      form.querySelector('select[name="booking[facility_id]"]')?.focus()
      return
    }
    if (!start || !end) {
      this.setReservationError(translate("Start and end times are required."))
      form.querySelector('input[name="booking[start_time]"]')?.focus()
      return
    }
    if (end <= start) {
      this.setReservationError(translate("End time must be after start time."))
      form.querySelector('input[name="booking[end_time]"]')?.focus()
      return
    }

    this.formSubmitting = true
    this.setReservationError("")
    try {
      const params = this.branchId ? { branch_id: this.branchId } : {}
      const response = await fetchJson(
        Helpers.booking_reservations_company_operation_path(this.companyId, this.operationId, params),
        {
          method: "POST",
          body: {
            booking: {
              title,
              facility_id: facilityId,
              host_id: data.get("booking[host_id]") || null,
              customer_id: data.get("booking[customer_id]") || null,
              start_time: start,
              end_time: end,
              date: this.selectedDate
            }
          }
        }
      )
      this.selectedBookingId = response.event?.id || null
      this.selectedResourceId = facilityId
      this.resetReservationForm()
      await this.reloadConsole()
      toast({ type: "success", message: response.message })
    } catch (error) {
      this.setReservationError(error.errors?.join(", ") || error.message || translate("Failed to create the reservation."))
    } finally {
      this.formSubmitting = false
    }
  }

  resetReservationForm() {
    this.formState = {
      title: "",
      facilityId: "",
      hostId: "",
      customerId: "",
      customerName: "",
      customerQuery: "",
      start: "",
      end: ""
    }
    this.customerResults = []
    this.customerSearchError = ""
    this.customerSearching = false
    this.reservationError = ""
    this.extendNotice = ""
    this.quickRoomNotice = ""
    this.cancelState = null
  }

  async quickRoom() {
    if (!this.isToday) {
      this.selectedDate = null
      this.clearSelection()
      await this.reloadConsole()
    }

    const now = this.currentNow()
    const label = Helpers.locationTime(now, "HH:mm", this.location)
    const [hours, minutes] = label.split(":").map(Number)
    const nowMinutes = (hours * 60) + minutes
    const windowStart = this.timelineStartHour * 60
    const windowEnd = this.timelineEndHour * 60
    const outside = nowMinutes < windowStart || nowMinutes >= windowEnd
    const startMinutes = outside ? windowStart : (Math.floor(nowMinutes / 15) * 15) + 15
    const endMinutes = startMinutes + 15

    this.formState.start = this.clockValue(startMinutes)
    this.formState.end = this.clockValue(endMinutes)
    this.formState.facilityId = ""
    this.formState.hostId = ""
    this.formState.customerId = ""
    this.formState.customerName = ""
    this.formState.customerQuery = ""
    this.customerResults = []
    this.customerSearchError = ""
    this.reservationError = ""
    this.quickRoomNotice = outside
      ? `${translate("Starts at")} ${this.clockValue(windowStart)} — ${translate("outside the day window the grid shows")}`
      : ""

    this.renderContent()
    this.scrollToReservation()
  }

  clockValue(minutes) {
    const normalized = ((minutes % (24 * 60)) + (24 * 60)) % (24 * 60)
    return `${String(Math.floor(normalized / 60)).padStart(2, "0")}:${String(normalized % 60).padStart(2, "0")}`
  }

  async extendBooking() {
    if (!this.selectedBookingId || this.actionPending) return
    this.actionPending = true
    this.extendNotice = ""
    try {
      const response = await fetchJson(
        Helpers.booking_reservation_extend_company_operation_path(
          this.companyId, this.operationId, this.selectedBookingId, this.branchId ? { branch_id: this.branchId } : {}
        ),
        { method: "POST", body: {} }
      )
      await this.reloadConsole()
      toast({ type: "success", message: response.message })
    } catch (error) {
      this.extendNotice = error.errors?.[0] || error.message || translate("Failed to extend the booking.")
      this.refreshInspector()
    } finally {
      this.actionPending = false
    }
  }

  async endBooking() {
    if (!this.selectedBookingId || this.actionPending) return
    this.actionPending = true
    try {
      const response = await fetchJson(
        Helpers.booking_reservation_end_company_operation_path(
          this.companyId, this.operationId, this.selectedBookingId, this.branchId ? { branch_id: this.branchId } : {}
        ),
        { method: "POST", body: {} }
      )
      this.extendNotice = ""
      await this.reloadConsole()
      toast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    } finally {
      this.actionPending = false
    }
  }

  requestCancel(event) {
    this.cancelState = {
      id: event.currentTarget.dataset.bookingId,
      context: event.currentTarget.dataset.context || "inspector"
    }
    this.refreshInspector()
    this.refreshUpcoming()
  }

  keepBooking() {
    this.cancelState = null
    this.refreshInspector()
    this.refreshUpcoming()
  }

  async confirmCancel() {
    if (!this.cancelState || this.actionPending) return
    this.actionPending = true
    const id = this.cancelState.id
    try {
      const response = await fetchJson(
        Helpers.booking_reservation_cancel_company_operation_path(
          this.companyId, this.operationId, id, this.branchId ? { branch_id: this.branchId } : {}
        ),
        { method: "POST", body: {} }
      )
      if (String(this.selectedBookingId) === String(id)) this.clearSelection()
      this.cancelState = null
      await this.reloadConsole()
      toast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    } finally {
      this.actionPending = false
    }
  }

  printRunSheet() {
    if (!this.element.querySelector("[data-booking-run-sheet]")) return
    const style = document.createElement("style")
    style.textContent = "@page { size: letter portrait; margin: 12mm; }"
    document.head.appendChild(style)
    const cleanup = () => style.remove()
    window.addEventListener("afterprint", cleanup, { once: true })
    window.print()
    window.setTimeout(cleanup, 2000)
  }

  // --- Utilities ------------------------------------------------------------------

  clampPercent(value) {
    return Math.max(0, Math.min(100, value))
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
