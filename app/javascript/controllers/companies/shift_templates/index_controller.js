import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_ShiftTemplates_IndexController extends Companies_LayoutController {
  static targets = ["shiftTemplatesList"]

  /** @type {Array<{id: string, name: string, start_time: string, end_time: string, grace_period_minutes: number, unpaid_break_minutes: number}>} */
  shiftTemplates = []

  async connect() {
    super.connect()
    try {
      const response = await fetchJson()
      this.shiftTemplates = response.shift_templates || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load shift templates") }${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col">
          <div class="flex justify-between items-center mb-6">
            <h2 class="text-xl font-bold text-foreground">${translate("Shift Templates")}</h2>
            <a href="${Helpers.new_company_shift_template_path(currentCompany().id)}"
              class="flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg text-sm cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("Add")}
            </a>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-muted-foreground border-b border-line">
                  <th class="py-4 px-6 font-medium">${translate("Name")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Start")}</th>
                  <th class="py-4 px-6 font-medium">${translate("End")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Grace")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Break")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="shiftTemplatesList" class="divide-y divide-line">
                ${this.shiftTemplates.map(st => `
                  <tr class="hover:bg-muted/50">
                    <td class="py-4 px-6 text-sm font-medium">
                      <a href="${Helpers.company_shift_template_path(currentCompany().id, st.id)}"
                        class="text-foreground hover:text-primary cursor-pointer">
                        ${st.name}
                      </a>
                    </td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${this.formatTime(st.start_time)}</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${this.formatTime(st.end_time)}</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${st.grace_period_minutes}min</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${st.unpaid_break_minutes}min</td>
                    <td class="py-4 px-6 text-sm text-right">
                      <a href="${Helpers.edit_company_shift_template_path(currentCompany().id, st.id)}"
                        class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </a>
                    </td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }

  formatTime(timeStr) {
    if (!timeStr) return ''
    return new Date(timeStr).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', hour12: false })
  }
}
