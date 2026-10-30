import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_ShiftTemplates_NewController extends Companies_LayoutController {
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
        <h2 class="text-xl font-bold text-foreground">${translate("New Shift Template")}</h2>
        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Name")}</label>
            <input type="text" name="shift_template[name]" required placeholder="e.g. Morning"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Start Time")}</label>
            <input type="time" name="shift_template[start_time]" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("End Time")}</label>
            <input type="time" name="shift_template[end_time]" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Grace Period (min)")}</label>
            <input type="number" name="shift_template[grace_period_minutes]" value="15"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Unpaid Break (min)")}</label>
            <input type="number" name="shift_template[unpaid_break_minutes]" value="60"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Description")}</label>
            <textarea name="shift_template[description]" rows="2"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm"></textarea>
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_shift_templates_path(currentCompany().id)}"
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
          action: Helpers.create_company_shift_templates_path(currentCompany().id),
          method: "POST",
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false"`,
          html: fields
        })}
      </div>
    `
  }
}
