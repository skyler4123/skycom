import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_ScheduledShifts_IndexController extends Companies_LayoutController {
  static targets = ["scheduledShiftsList"]

  /** @type {Array<{id: string, employee_name: string, shift_template_name: string, work_date: string, expected_start_at: string, expected_end_at: string, status: string}>} */
  scheduledShifts = []

  async connect() {
    super.connect()
    try {
      const response = await fetchJson()
      this.scheduledShifts = response.scheduled_shifts || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load scheduled shifts") }${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
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

  formatDate(dateStr) {
    if (!dateStr) return '—'
    return new Date(dateStr + 'T00:00:00').toLocaleDateString()
  }

  formatTime(dt) {
    if (!dt) return '—'
    return new Date(dt).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', hour12: false })
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <div class="flex justify-between items-center mb-6">
            <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Scheduled Shifts")}</h2>
            <a href="${Helpers.new_company_scheduled_shift_path(currentCompany().id)}"
              class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("Add Shift")}
            </a>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium">${translate("Employee")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Date")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Shift")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Start")}</th>
                  <th class="py-4 px-6 font-medium">${translate("End")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Status")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="scheduledShiftsList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.scheduledShifts.map(s => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="py-4 px-6 text-sm font-medium">
                      <a href="${Helpers.company_scheduled_shift_path(currentCompany().id, s.id)}"
                        class="text-slate-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 cursor-pointer">
                        ${s.employee_name || '—'}
                      </a>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600">${this.formatDate(s.work_date)}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${s.shift_template_name || '—'}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${this.formatTime(s.expected_start_at)}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${this.formatTime(s.expected_end_at)}</td>
                    <td class="py-4 px-6 text-sm">${this.statusBadge(s.status)}</td>
                    <td class="py-4 px-6 text-sm text-right">
                      <a href="${Helpers.edit_company_scheduled_shift_path(currentCompany().id, s.id)}"
                        class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer">
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
}
