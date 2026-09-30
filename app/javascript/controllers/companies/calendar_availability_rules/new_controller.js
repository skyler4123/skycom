import Companies_LayoutController from "controllers/companies/layout_controller"
import { submitViaJson, formBodyFromDom } from "controllers/companies/form_submit"
import { availabilityFieldsHTML } from "controllers/companies/calendar_availability_rules/availability_form"

// New Working hours (Calendar/Schedule module — docs/CALENDAR.md).
//
// Raw weekly windows per practitioner or per room, plus blackout blocks for
// leave. Skycom does NOT compute free slots from these yet — that is the
// Calendar::Adapter#available_slots seam (docs/CALENDAR.md §6).
//
// A rule is owned by EITHER a practitioner OR a location; #switchOwner toggles
// which select is enabled. Days are submitted as
// calendar_availability_rule[days_of_week][] (the array form strong params
// needs; a bare symbol would be silently dropped).
//
// Depends on BE: GET  /companies/:company_id/calendar_availability_rules/new(.json)
//            POST /companies/:company_id/calendar_availability_rules(.json)
export default class Companies_CalendarAvailabilityRules_NewController extends Companies_LayoutController {
  /** @type {{id: string, name: string}[]} */
  practitioners = []

  /** @type {{id: string, name: string}[]} */
  locations = []

  /** @type {"practitioner"|"location"} */
  owner = "practitioner"

  async connect() {
    super.connect()
    await this.loadOptions()
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  async loadOptions() {
    try {
      const [practitioners, locations] = await Promise.all([
        fetchJson(`${Helpers.company_calendar_practitioners_path(currentCompany().id)}.json`),
        fetchJson(`${Helpers.company_calendar_locations_path(currentCompany().id)}.json`)
      ])
      this.practitioners = practitioners.calendar_practitioners || []
      this.locations = locations.calendar_locations || []
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load working hours")}${__errDetail ? ": " + __errDetail : ""}` })
    }
  }

  switchOwner(event) {
    this.owner = event.currentTarget.dataset.owner || "practitioner"
    this.renderContent()
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
    window.location.href = Helpers.company_calendar_availability_rules_path(currentCompany().id)
  }

  contentHTML() {
    const fields = availabilityFieldsHTML({
      rule: null, practitioners: this.practitioners, locations: this.locations,
      owner: this.owner, isNew: true
    })

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.create_company_calendar_availability_rules_path(currentCompany().id),
          method: "POST",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" data-action="submit->companies--calendar-availability-rules--new#submit"`,
          html: `
            ${fields}
            <div class="flex justify-end gap-3 pt-4">
              <a href="${Helpers.company_calendar_availability_rules_path(currentCompany().id)}"
                class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
                ${translate("Cancel")}
              </a>
              <button type="submit"
                class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
                ${translate("Save")}
              </button>
            </div>
          `
        })}
      </div>
    `
  }
}
