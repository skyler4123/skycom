import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_ScheduledShifts_ShowController extends Companies_LayoutController {
  /** @type {Object|null} */
  scheduledShift = null

  async connect() {
    super.connect()
    const id = window.location.pathname.split("/").pop()
    try {
      const response = await fetchJson(`${Helpers.company_scheduled_shift_path(currentCompany().id, id)}.json`)
      this.scheduledShift = response.scheduled_shift
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load scheduled shift") }${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  formatDate(dateStr) {
    if (!dateStr) return '—'
    return new Date(dateStr + 'T00:00:00').toLocaleDateString()
  }

  formatTime(dt) {
    if (!dt) return '—'
    return new Date(dt).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', hour12: false })
  }

  statusBadge(status) {
    const colors = {
      scheduled: 'bg-primary/10 text-primary ',
      active: 'bg-success/10 text-success ',
      completed: 'bg-muted text-foreground ',
      absent: 'bg-danger/10 text-danger ',
      cancelled: 'bg-warning/10 text-warning '
    }
    const color = colors[status] || 'bg-muted text-foreground'
    return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${color}">${Helpers.capitalize(status || '')}</span>`
  }

  contentHTML() {
    const s = this.scheduledShift
    if (!s) return '<div class="p-8 text-center">Not found.</div>'

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_scheduled_shifts_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back")}
          </a>
          <h2 class="text-2xl font-black text-foreground mb-6">${translate("Scheduled Shift")}</h2>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Employee")}</p>
              <p class="text-sm font-semibold text-foreground">${s.employee?.name || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Date")}</p>
              <p class="text-sm font-semibold text-foreground">${this.formatDate(s.work_date)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Shift Template")}</p>
              <p class="text-sm font-semibold text-foreground">${s.shift_template?.name || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Start")}</p>
              <p class="text-sm font-semibold text-foreground">${this.formatTime(s.expected_start_at)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("End")}</p>
              <p class="text-sm font-semibold text-foreground">${this.formatTime(s.expected_end_at)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Status")}</p>
              <p class="text-sm font-semibold">${this.statusBadge(s.status)}</p>
            </div>
          </div>
          <div class="mt-8 flex justify-end">
            <a href="${Helpers.edit_company_scheduled_shift_path(currentCompany().id, s.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm cursor-pointer">
              ${translate("Edit")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}
