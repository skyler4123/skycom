import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_ShiftTemplates_ShowController extends Companies_LayoutController {
  /** @type {Object|null} */
  shiftTemplate = null

  async connect() {
    super.connect()
    const id = window.location.pathname.split("/").pop()
    try {
      const response = await fetchJson(`${Helpers.company_shift_template_path(currentCompany().id, id)}.json`)
      this.shiftTemplate = response.shift_template
    } catch (error) {
      toast({ type: "error", message: translate("Failed to load shift template") })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  contentHTML() {
    const st = this.shiftTemplate
    if (!st) return '<div class="p-8 text-center">Not found.</div>'

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_shift_templates_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]">arrow_back</span>
            ${translate("Back")}
          </a>
          <h2 class="text-2xl font-black text-slate-900 dark:text-white mb-6">${st.name}</h2>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Start Time")}</p>
              <p class="text-sm font-semibold text-slate-900">${this.formatTime(st.start_time)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("End Time")}</p>
              <p class="text-sm font-semibold text-slate-900">${this.formatTime(st.end_time)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Grace Period")}</p>
              <p class="text-sm font-semibold text-slate-900">${st.grace_period_minutes}min</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Unpaid Break")}</p>
              <p class="text-sm font-semibold text-slate-900">${st.unpaid_break_minutes}min</p>
            </div>
            <div class="col-span-2">
              <p class="text-xs font-medium text-slate-500">${translate("Description")}</p>
              <p class="text-sm font-semibold text-slate-900">${st.description || '—'}</p>
            </div>
          </div>
          <div class="mt-8 flex justify-end">
            <a href="${Helpers.edit_company_shift_template_path(currentCompany().id, st.id)}"
              class="inline-flex items-center px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer">
              ${translate("Edit")}
            </a>
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
