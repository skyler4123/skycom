import Companies_LayoutController from "controllers/companies/layout_controller"

// Calendar/Schedule board — the month / week / day grid.
//
// Wraps the reusable `calendar` Stimulus controller and points it at the board's
// own range endpoint, so the grid is the SAME widget the /demo page uses (the
// api-url is a value with no default — see calendar_controller.js).
//
// The widget owns the grid and emits `calendar:change` when the user clicks or
// drag-selects a range. This controller listens for that and surfaces a
// "book this window" link, so a click on the grid leads straight to a booking.
//
// Depends on BE: GET /companies/:company_id/calendars.json          — board shell + counts
//            GET /companies/:company_id/calendars/events.json?start=&end= — grid data
//            (the grid's own fetch, issued by the `calendar` controller)
export default class Companies_Calendars_IndexController extends Companies_LayoutController {
  /** @type {{events: number, today: string, timezone: string}} */
  stats = { events: 0, today: "", timezone: "" }

  /** @type {{start: string, end: string}|null} */
  selectedRange = null

  async connect() {
    super.connect()
    try {
      const response = await fetchJson(`${Helpers.company_calendars_path(currentCompany().id)}.json`)
      this.stats = response.calendar || this.stats
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load calendar")}${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  // Fired by the `calendar` controller whenever the user picks a range.
  onRangeChange(event) {
    const detail = event.detail || {}
    this.selectedRange = detail.start ? { start: detail.start, end: detail.end || detail.start } : null
    this.renderContent()
  }

  // Pre-fills the booking form with the range the user selected on the grid.
  bookingPath() {
    if (!this.selectedRange) return Helpers.new_company_calendar_event_path(currentCompany().id)
    const query = new URLSearchParams({
      starts_at: this.selectedRange.start,
      ends_at: this.selectedRange.end
    })
    return `${Helpers.new_company_calendar_event_path(currentCompany().id)}?${query.toString()}`
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="mb-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Calendar Board")}</h2>
            <p class="text-sm text-slate-500">
              ${translate("Appointments in the next 3 months")}: ${this.stats.events || 0}
            </p>
          </div>
          <div class="flex items-center gap-2">
            ${this.selectedRange ? `
              <span class="text-xs text-slate-500">${this.selectedRange.start}${this.selectedRange.end && this.selectedRange.end !== this.selectedRange.start ? ` → ${this.selectedRange.end}` : ""}</span>` : ""}
            <a href="${this.bookingPath()}"
              class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer whitespace-nowrap">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("Book Appointment")}
            </a>
          </div>
        </div>

        <!--
          The grid is the shared calendar Stimulus controller. api-url has no
          default, so it must be supplied here; the range query it issues is
          served by Companies::CalendarsController#events.
          NB: no backticks in this comment - it lives inside a template literal.
        -->
        <div data-controller="calendar"
             data-calendar-api-url-value="${Helpers.events_company_calendars_path(currentCompany().id)}"
             data-action="calendar:change->companies--calendars--index#onRangeChange"
             class="bg-white dark:bg-gray-800 rounded-2xl border border-slate-200 dark:border-slate-700"></div>
      </div>
    `
  }
}
