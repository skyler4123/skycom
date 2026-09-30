import Companies_LayoutController from "controllers/companies/layout_controller"
import { submitViaJson, formBodyFromDom } from "controllers/companies/form_submit"

// Location form (Calendar/Schedule module — docs/CALENDAR.md).
//
// Plain form shell. The calendar module is deliberately isolated from the
// dynamic-property + TableConfig stack, so there is no table_config_id value and
// no form-engine field generation here.
//
// Depends on BE: POST /companies/:company_id/calendar_locations.json
//            GET /companies/:company_id/calendar_locations/new(.json)
export default class Companies_CalendarLocations_NewController extends Companies_LayoutController {
  connect() {
    super.connect()
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
    window.location.href = Helpers.company_calendar_locations_path(currentCompany().id)
  }

  contentHTML() {
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Location")}</h2>
        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Name")}</label>
            <input type="text" name="calendar_location[name]" value="" required placeholder="e.g. Surgery Room 1"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Code")}</label>
            <input type="text" name="calendar_location[code]" value=""
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Capacity")}</label>
            <input type="number" min="0" name="calendar_location[capacity]" value=""
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Description")}</label>
            <textarea name="calendar_location[description]" rows="3"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm"></textarea>
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Color")}</label>
            <div class="flex items-center gap-2">
            <span class="w-9 h-9 rounded-lg border border-slate-200 dark:border-slate-600 shrink-0"
              style="background: #6366f1"></span>
            <input type="text" name="calendar_location[color]" value="#6366f1" placeholder="#6366f1"
              class="flex-1 px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
</div>
          </div>
          <div class="col-span-2 flex items-center gap-2">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Bookable")}</label>
            <input type="hidden" name="calendar_location[bookable]" value="0">
            <input type="checkbox" name="calendar_location[bookable]" value="1" checked
              class="w-4 h-4 rounded border-slate-300 text-blue-600">
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_calendar_locations_path(currentCompany().id)}"
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
          action: Helpers.create_company_calendar_locations_path(currentCompany().id),
          method: "POST",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" data-action="submit->companies--calendar-locations--new#submit"`,
          html: fields
        })}
      </div>
    `
  }
}
