import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_ScheduledShifts_NewController extends Companies_LayoutController {
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
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Scheduled Shift")}</h2>
        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Employee ID")}</label>
            <input type="text" name="scheduled_shift[employee_id]" required placeholder="e.g. uuid"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Work Date")}</label>
            <input type="date" name="scheduled_shift[work_date]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Shift Template ID")}</label>
            <input type="text" name="scheduled_shift[shift_template_id]" placeholder="e.g. uuid"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Start")}</label>
            <input type="datetime-local" name="scheduled_shift[expected_start_at]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("End")}</label>
            <input type="datetime-local" name="scheduled_shift[expected_end_at]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Branch ID")}</label>
            <input type="text" name="scheduled_shift[branch_id]" placeholder="e.g. uuid"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Status")}</label>
            <select name="scheduled_shift[status]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="scheduled">Scheduled</option>
              <option value="active">Active</option>
              <option value="completed">Completed</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_scheduled_shifts_path(currentCompany().id)}"
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
          action: Helpers.create_company_scheduled_shifts_path(currentCompany().id),
          method: "POST",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false"`,
          html: fields
        })}
      </div>
    `
  }
}
