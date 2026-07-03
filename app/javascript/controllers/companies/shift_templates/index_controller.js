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
    } catch (error) {
      toast({ type: "error", message: translate("Failed to load shift templates") })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <div class="flex justify-between items-center mb-6">
            <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Shift Templates")}</h2>
            <a href="${Helpers.new_company_shift_template_path(currentCompany().id)}"
              class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("Add")}
            </a>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium">${translate("Name")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Start")}</th>
                  <th class="py-4 px-6 font-medium">${translate("End")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Grace")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Break")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="shiftTemplatesList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.shiftTemplates.map(st => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="py-4 px-6 text-sm font-medium">
                      <a href="${Helpers.company_shift_template_path(currentCompany().id, st.id)}"
                        class="text-slate-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 cursor-pointer">
                        ${st.name}
                      </a>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600">${st.start_time}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${st.end_time}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${st.grace_period_minutes}min</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${st.unpaid_break_minutes}min</td>
                    <td class="py-4 px-6 text-sm text-right">
                      <a href="${Helpers.edit_company_shift_template_path(currentCompany().id, st.id)}"
                        class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </a>
                    </td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    `
  }
}
