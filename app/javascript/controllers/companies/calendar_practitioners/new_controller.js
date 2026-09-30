import Companies_LayoutController from "controllers/companies/layout_controller"
import { submitViaJson, formBodyFromDom } from "controllers/companies/form_submit"

// Practitioner form (Calendar/Schedule module — docs/CALENDAR.md).
//
// A practitioner is a BRIDGE: it points at a real Employee (or User) through
// calendar_practitioner[source_type] + calendar_practitioner[source_id]. The
// employee is picked from the company roster served in `options`, so the source
// id is never typed by hand and always resolves to a live record.
//
// The calendar module is isolated from the dynamic-property + TableConfig stack,
// so there is no table_config_id value and no form-engine field generation.
//
// Depends on BE: POST /companies/:company_id/calendar_practitioners.json
//            GET /companies/:company_id/calendar_practitioners/new(.json)
//            GET /companies/:company_id/calendar_practitioners/:id(.json)
//            PATCH /companies/:company_id/calendar_practitioners/:id(.json)
export default class Companies_CalendarPractitioners_NewController extends Companies_LayoutController {
  /** @type {{id: string, name: string, color: string}[]} */
  positions = []

  /** @type {{id: string, name: string}[]} */
  employees = []

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
      const response = await fetchJson(`${Helpers.new_company_calendar_practitioner_path(currentCompany().id)}.json`)
      const options = response.options || {}
      this.positions = options.positions || []
      this.employees = options.employees || []
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load practitioners")}${__errDetail ? ": " + __errDetail : ""}` })
    }
  }

  positionOptionsHTML() {
    if (this.positions.length === 0) {
      return `<option value="">${translate("Create a position first")}</option>`
    }
    return this.positions.map((p) => `<option value="${p.id}">${p.name}</option>`).join("")
  }

  employeeOptionsHTML() {
    if (this.employees.length === 0) {
      return `<option value="">${translate("Create an employee first")}</option>`
    }
    return this.employees.map((e) => `<option value="${e.id}">${e.name}</option>`).join("")
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
    window.location.href = Helpers.company_calendar_practitioners_path(currentCompany().id)
  }

  contentHTML() {
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Practitioner")}</h2>
        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Display Name")}</label>
            <input type="text" name="calendar_practitioner[name]" required placeholder="e.g. Dr. D"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Position")}</label>
            <select name="calendar_practitioner[calendar_position_id]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="">${translate("Select a position")}</option>
              ${this.positionOptionsHTML()}
            </select>
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Employee")}</label>
            <select name="calendar_practitioner[source_id]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="">${translate("Select an employee")}</option>
              ${this.employeeOptionsHTML()}
            </select>
          </div>
          <input type="hidden" name="calendar_practitioner[source_type]" value="Employee">
          <div class="col-span-2 flex items-center gap-2">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Bookable")}</label>
            <input type="hidden" name="calendar_practitioner[bookable]" value="0">
            <input type="checkbox" name="calendar_practitioner[bookable]" value="1" checked
              class="w-4 h-4 rounded border-slate-300 text-blue-600">
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_calendar_practitioners_path(currentCompany().id)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.create_company_calendar_practitioners_path(currentCompany().id),
          method: "POST",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" data-action="submit->companies--calendar-practitioners--new#submit"`,
          html: fields
        })}
      </div>
    `
  }
}
