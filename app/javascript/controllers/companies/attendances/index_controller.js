import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Attendances_IndexController extends Companies_LayoutController {
  static targets = ["attendanceList"]

  /** @type {Array<{id: string, employee: {name: string}, attendance_date: string, check_in: string, check_out: string, total_seconds_worked: number, attendance_status: string}>} */
  attendanceDays = []

  async connect() {
    super.connect()
    try {
      const response = await fetchJson()
      this.attendanceDays = response.attendance_days || []
      this.pagination = response.pagination || {}
    } catch (error) {
      toast({ type: "error", message: translate("Failed to load attendance records") })
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
      present: 'bg-green-100 text-green-800',
      half_day: 'bg-orange-100 text-orange-800',
      late: 'bg-red-100 text-red-800',
      absent: 'bg-gray-100 text-gray-800'
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
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="attendanceList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.attendanceDays.map(d => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="py-4 px-6 text-sm font-medium text-slate-900">${d.employee?.name || '—'}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${this.formatDate(d.attendance_date)}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${this.formatTime(d.check_in)}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${this.formatTime(d.check_out)}</td>
                    <td class="py-4 px-6 text-sm text-slate-900 font-medium">${Math.round((d.total_seconds_worked || 0) / 60)}min</td>
                    <td class="py-4 px-6 text-sm">${this.statusBadge(d.attendance_status)}</td>
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
