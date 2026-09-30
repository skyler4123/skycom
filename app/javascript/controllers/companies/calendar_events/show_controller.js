import Companies_LayoutController from "controllers/companies/layout_controller"

// Appointment detail (Calendar/Schedule module — docs/CALENDAR.md).
//
// Read-only view of one booking: who it is for, which resources it holds, and
// the status actions available right now.
//
// Depends on BE: GET  /companies/:company_id/calendar_events/:id.json
//            POST /companies/:company_id/calendar_events/:id/confirm(.json)
//            POST /companies/:company_id/calendar_events/:id/cancel(.json)
//            POST /companies/:company_id/calendar_events/:id/complete(.json)
export default class Companies_CalendarEvents_ShowController extends Companies_LayoutController {
  /** @type {Object|null} */
  event = null

  /** @type {string} */
  eventId = ""

  async connect() {
    super.connect()
    this.eventId = window.location.pathname.split("/").filter(Boolean).pop()
    try {
      const response = await fetchJson(`${Helpers.company_calendar_event_path(currentCompany().id, this.eventId)}.json`)
      this.event = response.calendar_event
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load appointment")}${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
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
    return `<span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium ${colors[status] || colors.pending}">${Helpers.capitalize((status || "").replace("_", " "))}</span>`
  }

  formatDateTime(value) {
    if (!value) return "—"
    return new Date(value).toLocaleString(undefined, {
      year: "numeric", month: "long", day: "numeric", hour: "2-digit", minute: "2-digit"
    })
  }

  // One labelled row, omitted entirely when the list is empty.
  resourceRow(label, items, emptyLabel) {
    if (!items || items.length === 0) {
      return `<div class="py-3 flex justify-between gap-4 border-b border-slate-100 dark:border-slate-800">
        <span class="text-sm text-slate-500">${translate(label)}</span>
        <span class="text-sm text-slate-400">${translate(emptyLabel)}</span>
      </div>`
    }
    return `<div class="py-3 flex justify-between gap-4 border-b border-slate-100 dark:border-slate-800">
      <span class="text-sm text-slate-500">${translate(label)}</span>
      <span class="text-sm text-slate-900 dark:text-white text-right">${items.map((i) => i.name).join(", ")}</span>
    </div>`
  }

  async transition(event) {
    event.preventDefault()
    const action = event.currentTarget.dataset.transition
    const paths = {
      confirm: Helpers.confirm_company_calendar_event_path,
      cancel: Helpers.cancel_company_calendar_event_path,
      complete: Helpers.complete_company_calendar_event_path
    }
    try {
      const response = await fetchJson(paths[action](currentCompany().id, this.eventId), { method: "POST" })
      toast({ type: "success", message: response.message })
      this.event = response.calendar_event
      this.renderContent()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update appointment") })
    }
  }

  contentHTML() {
    const e = this.event
    if (!e) return `<div class="p-8 text-center text-slate-500">${translate("Not found")}</div>`

    const base = "px-4 py-2 text-sm font-medium rounded-lg cursor-pointer"
    const actions = []
    if (e.status === "pending") {
      actions.push(`<button data-action="companies--calendar-events--show#transition" data-transition="confirm"
        class="${base} bg-emerald-600 hover:bg-emerald-700 text-white">${translate("Confirm")}</button>`)
    }
    if (["pending", "confirmed", "in_progress"].includes(e.status)) {
      actions.push(`<button data-action="companies--calendar-events--show#transition" data-transition="cancel"
        class="${base} border border-red-300 text-red-600 hover:bg-red-50">${translate("Cancel Appointment")}</button>`)
    }
    if (["confirmed", "in_progress"].includes(e.status)) {
      actions.push(`<button data-action="companies--calendar-events--show#transition" data-transition="complete"
        class="${base} border border-slate-300 text-slate-600 hover:bg-slate-50 dark:text-slate-300 dark:border-slate-600 dark:hover:bg-slate-800">${translate("Complete")}</button>`)
    }

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6">
            <div>
              <h2 class="text-xl font-bold text-slate-900 dark:text-white">${e.display_title}</h2>
              <p class="text-sm text-slate-500">${e.calendar_procedure?.name || ""}</p>
            </div>
            <div class="flex items-center gap-2">${this.statusBadge(e.status)}</div>
          </div>

          <div class="mb-6">
            <div class="py-3 flex justify-between gap-4 border-b border-slate-100 dark:border-slate-800">
              <span class="text-sm text-slate-500">${translate("When")}</span>
              <span class="text-sm text-slate-900 dark:text-white text-right">
                ${this.formatDateTime(e.starts_at)}<br>
                <span class="text-slate-500">${translate("to")} ${this.formatDateTime(e.ends_at)}</span>
              </span>
            </div>
            ${this.resourceRow("Practitioners", e.practitioners, "Not assigned")}
            ${this.resourceRow("Room / Location", e.locations, "Not assigned")}
            ${this.resourceRow("Equipment", e.equipment, "Not assigned")}
            ${this.resourceRow("Patient / Participant", e.participants, "Not assigned")}
            ${e.notes ? `<div class="py-3 flex justify-between gap-4 border-b border-slate-100 dark:border-slate-800">
              <span class="text-sm text-slate-500">${translate("Notes")}</span>
              <span class="text-sm text-slate-900 dark:text-white text-right whitespace-pre-line">${e.notes}</span>
            </div>` : ""}
            ${e.cancellation_reason ? `<div class="py-3 flex justify-between gap-4 border-b border-slate-100 dark:border-slate-800">
              <span class="text-sm text-slate-500">${translate("Cancellation Reason")}</span>
              <span class="text-sm text-red-600 text-right">${e.cancellation_reason}</span>
            </div>` : ""}
          </div>

          <div class="flex flex-wrap justify-end gap-3">
            <a href="${Helpers.company_calendar_events_path(currentCompany().id)}"
              class="${base} text-slate-600 hover:bg-slate-100 dark:text-slate-300">${translate("Back")}</a>
            ${e.status !== "cancelled"
              ? `<a href="${Helpers.edit_company_calendar_event_path(currentCompany().id, e.id)}"
                  class="${base} border border-slate-300 text-slate-600 hover:bg-slate-50 dark:text-slate-300 dark:border-slate-600 dark:hover:bg-slate-800">${translate("Edit")}</a>`
              : ""}
            ${actions.join("")}
          </div>
        </div>
      </div>
    `
  }
}
