import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_ScheduledShifts_EditController extends Companies_LayoutController {
  /** @type {Object|null} */
  scheduledShift = null

  /** @type {string} */
  shiftId = ""

  async connect() {
    super.connect()
    const pathParts = window.location.pathname.split("/")
    this.shiftId = pathParts[pathParts.length - 2]
    try {
      const response = await fetchJson(`${Helpers.company_scheduled_shift_path(currentCompany().id, this.shiftId)}.json`)
      this.scheduledShift = response.scheduled_shift
    } catch (error) {
      toast({ type: "error", message: translate("Failed to load scheduled shift") })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  contentHTML() {
    const s = this.scheduledShift
    if (!s) return '<div class="p-8 text-center">Not found.</div>'

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Scheduled Shift")}</h2>
        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Employee ID")}</label>
            <input type="text" name="scheduled_shift[employee_id]" value="${s.employee_id || ''}" required class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Work Date")}</label>
            <input type="date" name="scheduled_shift[work_date]" value="${s.work_date || ''}" required class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Shift Template ID")}</label>
            <input type="text" name="scheduled_shift[shift_template_id]" value="${s.shift_template_id || ''}" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Start")}</label>
            <input type="datetime-local" name="scheduled_shift[expected_start_at]" value="${s.expected_start_at ? s.expected_start_at.substring(0, 16) : ''}" required class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("End")}</label>
            <input type="datetime-local" name="scheduled_shift[expected_end_at]" value="${s.expected_end_at ? s.expected_end_at.substring(0, 16) : ''}" required class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Status")}</label>
            <select name="scheduled_shift[status]" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="scheduled" ${s.status === 'scheduled' ? 'selected' : ''}>Scheduled</option>
              <option value="active" ${s.status === 'active' ? 'selected' : ''}>Active</option>
              <option value="completed" ${s.status === 'completed' ? 'selected' : ''}>Completed</option>
              <option value="cancelled" ${s.status === 'cancelled' ? 'selected' : ''}>Cancelled</option>
            </select>
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_scheduled_shift_path(currentCompany().id, this.shiftId)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Changes")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_scheduled_shift_path(currentCompany().id, this.shiftId),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
