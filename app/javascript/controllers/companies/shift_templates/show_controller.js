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
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load shift template") }${__errDetail ? ": " + __errDetail : ""}` })
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
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_shift_templates_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back")}
          </a>
          <h2 class="text-2xl font-black text-foreground mb-6">${st.name}</h2>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Start Time")}</p>
              <p class="text-sm font-semibold text-foreground">${this.formatTime(st.start_time)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("End Time")}</p>
              <p class="text-sm font-semibold text-foreground">${this.formatTime(st.end_time)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Grace Period")}</p>
              <p class="text-sm font-semibold text-foreground">${st.grace_period_minutes}min</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Unpaid Break")}</p>
              <p class="text-sm font-semibold text-foreground">${st.unpaid_break_minutes}min</p>
            </div>
            <div class="col-span-2">
              <p class="text-xs font-medium text-muted-foreground">${translate("Description")}</p>
              <p class="text-sm font-semibold text-foreground">${st.description || '—'}</p>
            </div>
          </div>
          <div class="mt-8 flex justify-end">
            <a href="${Helpers.edit_company_shift_template_path(currentCompany().id, st.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm cursor-pointer">
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
