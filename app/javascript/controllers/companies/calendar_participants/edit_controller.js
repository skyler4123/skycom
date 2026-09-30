import Companies_LayoutController from "controllers/companies/layout_controller"
import { submitViaJson, formBodyFromDom } from "controllers/companies/form_submit"

// Participant form (Calendar/Schedule module — docs/CALENDAR.md).
//
// Plain form shell. The calendar module is deliberately isolated from the
// dynamic-property + TableConfig stack, so there is no table_config_id value and
// no form-engine field generation here.
//
// Depends on BE: GET /companies/:company_id/calendar_participants/:id(.json)
//            PATCH /companies/:company_id/calendar_participants/:id(.json)
export default class Companies_CalendarParticipants_EditController extends Companies_LayoutController {
  connect() {
    super.connect()
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  /** @type {Object|null} */
  record = null

  /** @type {string} */
  recordId = ""

  async connect() {
    super.connect()
    const pathParts = window.location.pathname.split("/")
    this.recordId = pathParts[pathParts.length - 2]
    try {
      const response = await fetchJson(`${Helpers.company_calendar_participant_path(currentCompany().id, this.recordId)}.json`)
      this.record = response.calendar_participant || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load participant")}${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
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
    window.location.href = Helpers.company_calendar_participants_path(currentCompany().id)
  }

  contentHTML() {
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Participant")}</h2>
        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Name")}</label>
            <input type="text" name="calendar_participant[name]" value="((this.record.name) || '')" required placeholder="e.g. Patient A"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Code")}</label>
            <input type="text" name="calendar_participant[code]" value="((this.record.code) || '')"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Email")}</label>
            <input type="email" name="calendar_participant[email]" value="{((this.record.email) || '')}"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Phone")}</label>
            <input type="text" name="calendar_participant[phone_number]" value="((this.record.phone_number) || '')"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Notes")}</label>
            <textarea name="calendar_participant[notes]" rows="3"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm"></textarea>
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_calendar_participants_path(currentCompany().id)}"
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
          action: Helpers.company_calendar_participant_path(currentCompany().id, this.recordId),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" data-action="submit->companies--calendar-participants--edit#submit"`,
          html: fields
        })}
      </div>
    `
  }
}
