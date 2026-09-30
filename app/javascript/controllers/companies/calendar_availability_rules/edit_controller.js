import Companies_LayoutController from "controllers/companies/layout_controller"
import { submitViaJson, formBodyFromDom } from "controllers/companies/form_submit"
import { availabilityFieldsHTML } from "controllers/companies/calendar_availability_rules/availability_form"

// Edit Working hours (Calendar/Schedule module — docs/CALENDAR.md).
//
// The owner toggle opens on whichever owner the rule already has, so a
// practitioner-owned rule never starts with the location select enabled.
//
// Depends on BE: GET   /companies/:company_id/calendar_availability_rules/:id/edit(.json)
//            PATCH /companies/:company_id/calendar_availability_rules/:id(.json)
export default class Companies_CalendarAvailabilityRules_EditController extends Companies_LayoutController {
  /** @type {Object|null} */
  rule = null

  /** @type {{id: string, name: string}[]} */
  practitioners = []

  /** @type {{id: string, name: string}[]} */
  locations = []

  /** @type {"practitioner"|"location"} */
  owner = "practitioner"

  /** @type {string} */
  ruleId = ""

  async connect() {
    super.connect()
    const pathParts = window.location.pathname.split("/")
    this.ruleId = pathParts[pathParts.length - 2]
    try {
      const [rule, practitioners, locations] = await Promise.all([
        fetchJson(`${Helpers.edit_company_calendar_availability_rule_path(currentCompany().id, this.ruleId)}.json`),
        fetchJson(`${Helpers.company_calendar_practitioners_path(currentCompany().id)}.json`),
        fetchJson(`${Helpers.company_calendar_locations_path(currentCompany().id)}.json`)
      ])
      this.rule = rule.calendar_availability_rule || {}
      this.practitioners = practitioners.calendar_practitioners || []
      this.locations = locations.calendar_locations || []
      if (this.rule.calendar_location_id) this.owner = "location"
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load working hours")}${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
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
    if (!this.rule) return `<div class="p-8 text-center text-slate-500">${translate("Not found")}</div>`

    const fields = availabilityFieldsHTML({
      rule: this.rule, practitioners: this.practitioners, locations: this.locations,
      owner: this.owner, isNew: false
    })

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_calendar_availability_rule_path(currentCompany().id, this.ruleId),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" data-action="submit->companies--calendar-availability-rules--edit#submit"`,
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
