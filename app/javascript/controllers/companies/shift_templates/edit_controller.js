import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_ShiftTemplates_EditController extends Companies_LayoutController {
  /** @type {Object|null} */
  shiftTemplate = null

  /** @type {string} */
  templateId = ""

  async connect() {
    super.connect()
    const pathParts = window.location.pathname.split("/")
    this.templateId = pathParts[pathParts.length - 2]
    try {
      const response = await fetchJson(`${Helpers.company_shift_template_path(currentCompany().id, this.templateId)}.json`)
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

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Shift Template")}</h2>
        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Name")}</label>
            <input type="text" name="shift_template[name]" value="${st.name || ''}" required class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Start Time")}</label>
            <input type="time" name="shift_template[start_time]" value="${this.formatTime(st.start_time)}" required class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("End Time")}</label>
            <input type="time" name="shift_template[end_time]" value="${this.formatTime(st.end_time)}" required class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Grace Period (min)")}</label>
            <input type="number" name="shift_template[grace_period_minutes]" value="${st.grace_period_minutes || 15}" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Unpaid Break (min)")}</label>
            <input type="number" name="shift_template[unpaid_break_minutes]" value="${st.unpaid_break_minutes || 60}" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Description")}</label>
            <textarea name="shift_template[description]" rows="2" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${st.description || ''}</textarea>
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_shift_template_path(currentCompany().id, this.templateId)}"
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
          action: Helpers.company_shift_template_path(currentCompany().id, this.templateId),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }

  formatTime(timeStr) {
    if (!timeStr) return ''
    return new Date(timeStr).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', hour12: false })
  }
}
