import Companies_LayoutController from "controllers/companies/layout_controller"
import { submitViaJson, formBodyFromDom } from "controllers/companies/form_submit"
import { bookingFieldsHTML } from "controllers/companies/calendar_events/booking_form"

// New Appointment (Calendar/Schedule module — docs/CALENDAR.md).
//
// A booking names a procedure, a time window, and the practitioners / room /
// equipment / participants it consumes. The server HARD-BLOCKS a double-booked
// resource (CalendarEvent validation) and answers with `errors: [...]` + 422.
//
// #checkConflicts calls the read-only pre-flight endpoint on blur of the time
// window so the clash is visible before submitting; the same server rules run
// again on save, so this is a convenience, never the source of truth.
//
// Depends on BE: GET   /companies/:company_id/calendar_events/new(.json)
//            POST  /companies/:company_id/calendar_events/conflicts(.json)
//            POST  /companies/:company_id/calendar_events(.json)
export default class Companies_CalendarEvents_NewController extends Companies_LayoutController {
  static targets = ["conflicts"]

  /** @type {Object|null} */
  event = null

  /** @type {Object} */
  options = {}

  async connect() {
    super.connect()
    try {
      const response = await fetchJson(`${Helpers.new_company_calendar_event_path(currentCompany().id)}.json`)
      this.event = response.calendar_event || {}
      this.options = response.options || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load appointments")}${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  // Read-only pre-flight. Never blocks the save — the server decides.
  async checkConflicts() {
    const payload = this.collectPayload()
    if (!payload.calendar_event.starts_at || !payload.calendar_event.ends_at) return

    try {
      const response = await fetchJson(
        Helpers.conflicts_company_calendar_events_path(currentCompany().id),
        { method: "POST", body: payload }
      )
      this.renderConflicts(response.conflicts || [])
    } catch (error) {
      // A pre-flight failure is not worth interrupting the user for.
      this.renderConflicts([])
    }
  }

  collectPayload() {
    const read = (selector) => this.contentTarget?.querySelector(selector)?.value || ""
    const readMulti = (selector) =>
      Array.from(this.contentTarget?.querySelectorAll(`${selector} option:checked`) || []).map((o) => o.value)

    return {
      calendar_event: {
        calendar_procedure_id: read('[name="calendar_event[calendar_procedure_id]"]'),
        title: read('[name="calendar_event[title]"]'),
        starts_at: read('[name="calendar_event[starts_at]"]'),
        ends_at: read('[name="calendar_event[ends_at]"]'),
        status: read('[name="calendar_event[status]"]')
      },
      practitioner_ids: readMulti('[name="practitioner_ids[]"]'),
      location_ids: readMulti('[name="location_ids[]"]'),
      equipment_ids: readMulti('[name="equipment_ids[]"]'),
      participant_ids: readMulti('[name="participant_ids[]"]')
    }
  }

  renderConflicts(conflicts) {
    if (!this.hasConflictsTarget) return

    if (conflicts.length === 0) {
      this.conflictsTarget.classList.add("hidden")
      this.conflictsTarget.innerHTML = ""
      return
    }

    this.conflictsTarget.classList.remove("hidden")
    this.conflictsTarget.innerHTML = `
      <div class="mt-4 p-3 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
        <div class="flex items-start gap-2">
          <span class="material-symbols-outlined text-amber-600 text-[20px]">warning</span>
          <div>
            <p class="text-sm font-semibold text-amber-900 dark:text-amber-200">${translate("Scheduling conflict")}</p>
            <ul class="mt-1 space-y-1">
              ${conflicts.map((c) => `<li class="text-xs text-amber-800 dark:text-amber-300">${c.message}</li>`).join("")}
            </ul>
          </div>
        </div>
      </div>
    `
  }

  // Helpers.form() dispatches form:success on a 2xx and form:error otherwise.
  // Without this the page would sit on the form after a successful save.
  // Intercepts the native submit so the JSON response is not rendered as a page.
  // form() has no global interceptor, so each calendar form provides its own.
  async submit(event) {
    event.preventDefault()
    const response = await submitViaJson(event.currentTarget, formBodyFromDom, (error) => {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to save") })
    })
    if (response) this.onFormSuccess(response)
  }

  onFormSuccess() {
    window.location.href = Helpers.company_calendar_events_path(currentCompany().id)
  }

  contentHTML() {
    const fields = bookingFieldsHTML({ event: this.event, options: this.options, isNew: true })

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.create_company_calendar_events_path(currentCompany().id),
          method: "POST",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" data-action="submit->companies--calendar-events--new#submit"`,
          html: `
            ${fields}
            <div class="flex justify-end gap-3 pt-4">
              <a href="${Helpers.company_calendar_events_path(currentCompany().id)}"
                class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
                ${translate("Cancel")}
              </a>
              <button type="button" data-action="companies--calendar-events--new#checkConflicts"
                class="px-4 py-2 text-sm font-medium border border-slate-300 dark:border-slate-600 rounded-lg text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 cursor-pointer">
                ${translate("Check availability")}
              </button>
              <button type="submit"
                class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
                ${translate("Book Appointment")}
              </button>
            </div>
          `
        })}
      </div>
    `
  }
}
