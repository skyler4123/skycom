import Companies_LayoutController from "controllers/companies/layout_controller"

// Appointments list (Calendar/Schedule module — docs/CALENDAR.md).
//
// Server-side filters: ?q= (title / procedure / participant / practitioner /
// room) plus ?status= and ?calendar_procedure_id=. Plain SQL — the calendar
// module is isolated from the dynamic-property + Meilisearch stack.
//
// The status buttons call the member transition endpoints (confirm / cancel /
// complete). Those are writes, not list reloads, so each one toasts the server's
// own message and then reloads.
//
// Depends on BE: GET   /companies/:company_id/calendar_events.json
//            POST  /companies/:company_id/calendar_events/:id/confirm(.json)
//            POST  /companies/:company_id/calendar_events/:id/cancel(.json)
//            POST  /companies/:company_id/calendar_events/:id/complete(.json)
//            DELETE /companies/:company_id/calendar_events/:id(.json)
export default class Companies_CalendarEvents_IndexController extends Companies_LayoutController {
  static targets = ["list"]

  /** @type {Object[]} */
  calendarEvents = []

  /** @type {{page: number, pages: number}} */
  pagination = {}

  /** @type {{procedures: Object[], practitioners: Object[], locations: Object[], equipment: Object[], participants: Object[]}} */
  options = {}

  /** @type {string} */
  searchTerm = ""

  /** @type {string} */
  statusFilter = ""

  async connect() {
    super.connect()
    await this.load()
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  async load() {
    try {
      const response = await fetchJson(`${Helpers.company_calendar_events_path(currentCompany().id)}.json`, {
        params: {
          q: this.searchTerm || undefined,
          status: this.statusFilter || undefined
        }
      })
      this.calendarEvents = response.calendar_events || []
      this.pagination = response.pagination || {}
      this.options = response.options || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load appointments")}${__errDetail ? ": " + __errDetail : ""}` })
    }
  }

  async search(event) {
    this.searchTerm = event.target.value.trim()
    await this.load()
    this.renderContent()
  }

  async filterByStatus(event) {
    this.statusFilter = event.currentTarget.dataset.status || ""
    await this.load()
    this.renderContent()
  }

  // Status transition: one POST, then a reload.
  async transition(event) {
    event.preventDefault()
    event.stopPropagation()
    const { id, transition: action } = event.currentTarget.dataset
    const paths = {
      confirm: Helpers.confirm_company_calendar_event_path,
      cancel: Helpers.cancel_company_calendar_event_path,
      complete: Helpers.complete_company_calendar_event_path
    }
    try {
      const response = await fetchJson(paths[action](currentCompany().id, id), { method: "POST" })
      toast({ type: "success", message: response.message })
      await this.load()
      this.renderContent()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update appointment") })
    }
  }

  async destroy(event) {
    event.preventDefault()
    event.stopPropagation()
    const id = event.currentTarget.dataset.id
    try {
      const response = await fetchJson(Helpers.company_calendar_event_path(currentCompany().id, id), { method: "DELETE" })
      toast({ type: "success", message: response.message })
      await this.load()
      this.renderContent()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to delete") })
    }
  }

  statusBadge(status) {
    const colors = {
      pending: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300",
      confirmed: "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300",
      in_progress: "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300",
      completed: "bg-slate-100 text-slate-800 dark:bg-slate-800 dark:text-slate-300",
      cancelled: "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300",
      no_show: "bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-300"
    }
    return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${colors[status] || colors.pending}">${Helpers.capitalize((status || "").replace("_", " "))}</span>`
  }

  formatDateTime(value) {
    if (!value) return "—"
    return new Date(value).toLocaleString(undefined, {
      year: "numeric", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit"
    })
  }

  // "Dr. D, Nurse F" / "Surgery Room 1" / "Patient A" — omitted when empty.
  assignmentSummary(event) {
    const parts = []
    if (event.practitioners?.length) parts.push(event.practitioners.map((p) => p.name).join(", "))
    if (event.locations?.length) parts.push(event.locations.map((l) => l.name).join(", "))
    if (event.equipment?.length) parts.push(event.equipment.map((e) => e.name).join(", "))
    if (event.participants?.length) parts.push(event.participants.map((p) => p.name).join(", "))
    return parts.length ? parts.join(" · ") : "—"
  }

  statusButtons(event) {
    const base = "px-2 py-1 text-[11px] font-medium rounded-lg cursor-pointer"
    const buttons = []
    if (event.status === "pending") {
      buttons.push(`<a href="${Helpers.edit_company_calendar_event_path(currentCompany().id, event.id)}"
        class="${base} text-slate-600 hover:text-blue-600 hover:bg-blue-50">${translate("Edit")}</a>`)
      buttons.push(`<button data-action="click->companies--calendar-events--index#transition"
        data-id="${event.id}" data-transition="confirm"
        class="${base} text-emerald-600 hover:bg-emerald-50">${translate("Confirm")}</button>`)
    }
    if (["pending", "confirmed", "in_progress"].includes(event.status)) {
      buttons.push(`<button data-action="click->companies--calendar-events--index#transition"
        data-id="${event.id}" data-transition="cancel"
        class="${base} text-red-600 hover:bg-red-50">${translate("Cancel")}</button>`)
    }
    if (["confirmed", "in_progress"].includes(event.status)) {
      buttons.push(`<button data-action="click->companies--calendar-events--index#transition"
        data-id="${event.id}" data-transition="complete"
        class="${base} text-slate-600 hover:bg-slate-100">${translate("Complete")}</button>`)
    }
    return buttons.join("")
  }

  contentHTML() {
    const statuses = ["", "pending", "confirmed", "in_progress", "completed", "cancelled", "no_show"]
    const filterChip = (value) => {
      const active = this.statusFilter === value
      return `<button data-action="click->companies--calendar-events--index#filterByStatus" data-status="${value}"
        class="px-3 py-1 text-xs rounded-full border cursor-pointer ${active
          ? "bg-blue-600 text-white border-blue-600"
          : "bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-700"}">
        ${value ? Helpers.capitalize(value.replace("_", " ")) : translate("All")}
      </button>`
    }

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 mb-4">
            <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Appointments")}</h2>
            <div class="flex items-center gap-2">
              <input type="text" value="${this.searchTerm}" placeholder="${translate("Search appointments")}"
                data-action="input->companies--calendar-events--index#search"
                class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800">
              <a href="${Helpers.new_company_calendar_event_path(currentCompany().id)}"
                class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer whitespace-nowrap">
                <span class="material-symbols-outlined text-[20px]">add</span>
                ${translate("Add Appointment")}
              </a>
            </div>
          </div>
          <div class="flex flex-wrap gap-2 mb-4">
            ${statuses.map(filterChip).join("")}
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium">${translate("Appointment")}</th>
                  <th class="py-4 px-6 font-medium">${translate("When")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Assigned")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Status")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="list" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.calendarEvents.length === 0 ? `
                  <tr><td colspan="5" class="py-10 text-center text-sm text-slate-500">${translate("No appointments yet")}</td></tr>
                ` : this.calendarEvents.map(e => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="py-4 px-6 text-sm">
                      <a href="${Helpers.company_calendar_event_path(currentCompany().id, e.id)}"
                        class="font-medium text-slate-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 cursor-pointer">
                        ${e.display_title}
                      </a>
                      <div class="text-xs text-slate-500">${e.calendar_procedure?.name || ""}</div>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${this.formatDateTime(e.starts_at)}</td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${this.assignmentSummary(e)}</td>
                    <td class="py-4 px-6 text-sm">${this.statusBadge(e.status)}</td>
                    <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                      ${this.statusButtons(e)}
                      <button data-action="click->companies--calendar-events--index#destroy" data-id="${e.id}"
                        class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg cursor-pointer">
                        <span class="material-symbols-outlined text-[20px]">delete</span>
                      </button>
                    </td>
                  </tr>
                `).join("")}
              </tbody>
            </table>
          </div>
          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}
