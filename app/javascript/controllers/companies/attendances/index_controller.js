import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Attendances_IndexController extends Companies_LayoutController {
  static targets = ["attendanceList"]

  /** @type {Array<{id: string, employee: {name: string}, check_in_at: string, check_out_at: string, total_work_minutes: number, computed_status: string}>} */
  attendanceRecords = []

  async connect() {
    super.connect()
    try {
      const response = await fetchJson()
      this.attendanceRecords = response.attendance_records || []
    } catch (error) {
      toast({ type: "error", message: translate("Failed to load attendance records") })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  formatDateTime(dt) {
    if (!dt) return '—'
    return new Date(dt).toLocaleString()
  }

  statusBadge(status) {
    const colors = {
      pending: 'bg-yellow-100 text-yellow-800',
      present: 'bg-green-100 text-green-800',
      half_day: 'bg-orange-100 text-orange-800',
      late: 'bg-red-100 text-red-800',
      missing_checkout: 'bg-gray-100 text-gray-800'
    }
    const color = colors[status] || 'bg-gray-100 text-gray-800'
    return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${color}">${Helpers.capitalize(status?.replace('_', ' ') || '')}</span>`
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <h2 class="text-xl font-bold text-slate-900 dark:text-white mb-6">${translate("Attendance Records")}</h2>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium">${translate("Employee")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Check In")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Check Out")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Worked")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Late")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Overtime")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Status")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="attendanceList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.attendanceRecords.map(r => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="py-4 px-6 text-sm font-medium text-slate-900">${r.employee?.name || '—'}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${this.formatDateTime(r.check_in_at)}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${this.formatDateTime(r.check_out_at)}</td>
                    <td class="py-4 px-6 text-sm text-slate-900 font-medium">${r.total_work_minutes}min</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${r.late_minutes}min</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${r.overtime_minutes}min</td>
                    <td class="py-4 px-6 text-sm">${this.statusBadge(r.computed_status)}</td>
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
