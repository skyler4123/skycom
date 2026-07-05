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
      toast({ type: "error", message: translate("Failed to load scheduled shift") })
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
      scheduled: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300',
      active: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300',
      completed: 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-300',
      absent: 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300',
      cancelled: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300'
    }
    const color = colors[status] || 'bg-gray-100 text-gray-800'
    return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${color}">${Helpers.capitalize(status || '')}</span>`
  }

  contentHTML() {
    const s = this.scheduledShift
    if (!s) return '<div class="p-8 text-center">Not found.</div>'

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_scheduled_shifts_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]">arrow_back</span>
            ${translate("Back")}
          </a>
          <h2 class="text-2xl font-black text-slate-900 dark:text-white mb-6">${translate("Scheduled Shift")}</h2>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Employee")}</p>
              <p class="text-sm font-semibold text-slate-900">${s.employee?.name || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Date")}</p>
              <p class="text-sm font-semibold text-slate-900">${this.formatDate(s.work_date)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Shift Template")}</p>
              <p class="text-sm font-semibold text-slate-900">${s.shift_template?.name || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Start")}</p>
              <p class="text-sm font-semibold text-slate-900">${this.formatTime(s.expected_start_at)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("End")}</p>
              <p class="text-sm font-semibold text-slate-900">${this.formatTime(s.expected_end_at)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Status")}</p>
              <p class="text-sm font-semibold">${this.statusBadge(s.status)}</p>
            </div>
          </div>
          <div class="mt-8 flex justify-end">
            <a href="${Helpers.edit_company_scheduled_shift_path(currentCompany().id, s.id)}"
              class="inline-flex items-center px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer">
              ${translate("Edit")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}
