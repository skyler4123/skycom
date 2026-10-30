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
        <h2 class="text-xl font-bold text-foreground">${translate("New Scheduled Shift")}</h2>
        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Employee ID")}</label>
            <input type="text" name="scheduled_shift[employee_id]" required placeholder="e.g. uuid"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Work Date")}</label>
            <input type="date" name="scheduled_shift[work_date]" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Shift Template ID")}</label>
            <input type="text" name="scheduled_shift[shift_template_id]" placeholder="e.g. uuid"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Start")}</label>
            <input type="datetime-local" name="scheduled_shift[expected_start_at]" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("End")}</label>
            <input type="datetime-local" name="scheduled_shift[expected_end_at]" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Branch ID")}</label>
            <input type="text" name="scheduled_shift[branch_id]" placeholder="e.g. uuid"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Status")}</label>
            <select name="scheduled_shift[status]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
              <option value="scheduled">Scheduled</option>
              <option value="active">Active</option>
              <option value="completed">Completed</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_scheduled_shifts_path(currentCompany().id)}"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer">
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
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false"`,
          html: fields
        })}
      </div>
    `
  }
}
