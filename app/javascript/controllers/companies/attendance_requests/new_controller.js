import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceRequests_NewController extends Companies_LayoutController {
  // New Attendance Request form — filed for self (employee forced server-side).
  // Depends on BE: Companies::AttendanceRequestsController#create
  // Endpoints: POST /companies/:company_id/attendance_requests
  // Docs: docs/superpowers/specs/2026-10-08-attendance-request-design.md
  connect() {
    super.connect()
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  contentHTML() {
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Attendance Request")}</h2>
        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Date")}</label>
            <input type="date" name="attendance_request[attendance_date]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Type")}</label>
            <select name="attendance_request[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="onsite_miss">${translate("Onsite Miss")}</option>
              <option value="remote_work">${translate("Remote Work")}</option>
              <option value="field_work">${translate("Field Work")}</option>
            </select>
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Check In")}</label>
            <input type="datetime-local" name="attendance_request[check_in]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Check Out")}</label>
            <input type="datetime-local" name="attendance_request[check_out]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Reason")}</label>
            <textarea name="attendance_request[reason]" rows="3" required placeholder="${translate("Why could you not check in onsite?")}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm"></textarea>
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_attendance_requests_path(currentCompany().id)}"
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
          action: Helpers.create_company_attendance_requests_path(currentCompany().id),
          method: "POST",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false"`,
          html: fields
        })}
      </div>
    `
  }
}
