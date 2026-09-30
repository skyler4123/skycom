import Companies_LayoutController from "controllers/companies/layout_controller"
import { submitViaJson, formBodyFromDom } from "controllers/companies/form_submit"

// Edit Procedure (Calendar/Schedule module — docs/CALENDAR.md).
//
// A procedure is the bookable appointment type ("Removal teeth"). It always
// names the position that performs it, and declares which extra resources a
// booking must be given (room / machine / how many practitioners).
//
// The calendar module is isolated from the dynamic-property + TableConfig stack,
// so there is no table_config_id value and no form-engine field generation.
//
// Depends on BE: GET   /companies/:company_id/calendar_procedures/:id/edit(.json)
//            PATCH /companies/:company_id/calendar_procedures/:id(.json)
export default class Companies_CalendarProcedures_EditController extends Companies_LayoutController {
  /** @type {Object|null} */
  procedure = null

  /** @type {{id: string, name: string, color: string}[]} */
  positions = []

  /** @type {string} */
  procedureId = ""

  async connect() {
    super.connect()
    const pathParts = window.location.pathname.split("/")
    this.procedureId = pathParts[pathParts.length - 2]
    await this.loadProcedure()
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  async loadProcedure() {
    try {
      const response = await fetchJson(`${Helpers.edit_company_calendar_procedure_path(currentCompany().id, this.procedureId)}.json`)
      this.procedure = response.calendar_procedure || {}
      this.positions = response.options?.positions || []
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load procedure")}${__errDetail ? ": " + __errDetail : ""}` })
    }
  }

  positionOptionsHTML() {
    if (this.positions.length === 0) return `<option value="">${translate("Create a position first")}</option>`
    return this.positions.map((p) =>
      `<option value="${p.id}" ${String(p.id) === String(this.procedure.calendar_position_id) ? "selected" : ""}>${p.name}</option>`
    ).join("")
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
    window.location.href = Helpers.company_calendar_procedures_path(currentCompany().id)
  }

  contentHTML() {
    if (!this.procedure) return `<div class="p-8 text-center text-slate-500">${translate("Not found")}</div>`

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Procedure")}</h2>
        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Name")}</label>
            <input type="text" name="calendar_procedure[name]" required value="${(this.procedure.name || "").replace(/"/g, "&quot;")}" placeholder="e.g. Tooth Extraction"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Slug")}</label>
            <input type="text" name="calendar_procedure[slug]" required value="${(this.procedure.slug || "").replace(/"/g, "&quot;")}" placeholder="e.g. tooth-extraction"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
            <p class="text-[10px] text-slate-400">${translate("Lowercase and hyphen-separated")}</p>
          </div>
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Position")}</label>
            <select name="calendar_procedure[calendar_position_id]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="">${translate("Select a position")}</option>
              ${this.positionOptionsHTML()}
            </select>
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Code")}</label>
            <input type="text" name="calendar_procedure[code]" value="${(this.procedure.code || "").replace(/"/g, "&quot;")}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Duration (minutes)")}</label>
            <input type="number" min="1" name="calendar_procedure[duration_minutes]" value="${this.procedure.duration_minutes || 30}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Buffer Before (minutes)")}</label>
            <input type="number" min="0" name="calendar_procedure[buffer_before_minutes]" value="${this.procedure.buffer_before_minutes || 0}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Buffer After (minutes)")}</label>
            <input type="number" min="0" name="calendar_procedure[buffer_after_minutes]" value="${this.procedure.buffer_after_minutes || 0}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Min Lead Time (minutes)")}</label>
            <input type="number" min="0" name="calendar_procedure[min_lead_minutes]" value="${this.procedure.min_lead_minutes || 0}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Practitioners Required")}</label>
            <input type="number" min="1" name="calendar_procedure[requires_practitioners]" value="${this.procedure.requires_practitioners || 1}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Color")}</label>
            <div class="flex items-center gap-2">
              <span class="w-9 h-9 rounded-lg border border-slate-200 dark:border-slate-600 shrink-0" style="background:${this.procedure.color || "#6366f1"}"></span>
              <input type="text" name="calendar_procedure[color]" value="${this.procedure.color || "#6366f1"}" placeholder="#6366f1"
                class="flex-1 px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
            </div>
          </div>
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Description")}</label>
            <textarea name="calendar_procedure[description]" rows="3"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${this.procedure.description || ""}</textarea>
          </div>
          <div class="col-span-2 flex flex-wrap items-center gap-6">
            <div class="flex items-center gap-2">
              <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Requires a room")}</label>
              <input type="hidden" name="calendar_procedure[requires_location]" value="0">
              <input type="checkbox" name="calendar_procedure[requires_location]" value="1" ${this.procedure.requires_location ? "checked" : ""}
                class="w-4 h-4 rounded border-slate-300 text-blue-600">
            </div>
            <div class="flex items-center gap-2">
              <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Requires a machine")}</label>
              <input type="hidden" name="calendar_procedure[requires_equipment]" value="0">
              <input type="checkbox" name="calendar_procedure[requires_equipment]" value="1" ${this.procedure.requires_equipment ? "checked" : ""}
                class="w-4 h-4 rounded border-slate-300 text-blue-600">
            </div>
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_calendar_procedures_path(currentCompany().id)}"
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
          action: Helpers.company_calendar_procedure_path(currentCompany().id, this.procedureId),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" data-action="submit->companies--calendar-procedures--edit#submit"`,
          html: fields
        })}
      </div>
    `
  }
}
