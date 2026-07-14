import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceDays_IndexController extends Companies_LayoutController {
  static targets = ["attendanceDaysList"]

  /** @type {Array<{id: string, employee: {name: string}, attendance_date: string, check_in: string, check_out: string, total_seconds_worked: number, attendance_status: string}>} */
  attendanceDays = []

  async connect() {
    super.connect()
    try {
      const response = await fetchJson()
      this.attendanceDays = response.attendance_days || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load attendance records") }${__errDetail ? ": " + __errDetail : ""}` })
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
      present: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300',
      half_day: 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-300',
      late: 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300',
      absent: 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-300',
      missing_checkout: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300'
    }
    const color = colors[status] || 'bg-gray-100 text-gray-800'
    return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${color}">${Helpers.capitalize(status?.replace('_', ' ') || '')}</span>`
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <h2 class="text-xl font-bold text-slate-900 dark:text-white mb-6">${translate("Attendance Days")}</h2>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium">${translate("Employee")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Date")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Check In")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Check Out")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Worked")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Status")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="attendanceDaysList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.attendanceDays.map(d => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="py-4 px-6 text-sm font-medium">
                      <a href="${Helpers.company_attendance_day_path(currentCompany().id, d.id)}"
                        class="text-slate-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 cursor-pointer">
                        ${d.employee?.name || '—'}
                      </a>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600">${this.formatDate(d.attendance_date)}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${this.formatTime(d.check_in)}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${this.formatTime(d.check_out)}</td>
                    <td class="py-4 px-6 text-sm text-slate-900 font-medium">${Math.round((d.total_seconds_worked || 0) / 60)}min</td>
                    <td class="py-4 px-6 text-sm">${this.statusBadge(d.attendance_status)}</td>
                    <td class="py-4 px-6 text-sm text-right">
                      <a href="${Helpers.company_attendance_day_path(currentCompany().id, d.id)}"
                        class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
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
