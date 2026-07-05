import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceMonths_IndexController extends Companies_LayoutController {
  static targets = ["attendanceMonthsList"]

  /** @type {Array} */
  attendanceMonths = []

  async connect() {
    super.connect()
    try {
      const response = await fetchJson()
      this.attendanceMonths = response.attendance_months || []
      this.pagination = response.pagination || {}
    } catch (error) {
      toast({ type: "error", message: translate("Failed to load attendance months") })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  formatDate(dateStr) {
    if (!dateStr) return '—'
    const d = new Date(dateStr + 'T00:00:00')
    return d.toLocaleDateString('en-GB', { month: 'long', year: 'numeric' })
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <h2 class="text-xl font-bold text-slate-900 dark:text-white mb-6">${translate("Attendance Months")}</h2>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium">${translate("Employee")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Month")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Worked")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Late")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Overtime")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Absent")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Present")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="attendanceMonthsList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.attendanceMonths.map(m => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="py-4 px-6 text-sm font-medium">
                      <a href="${Helpers.company_attendance_month_path(currentCompany().id, m.id)}"
                        class="text-slate-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 cursor-pointer">
                        ${m.employee?.name || '—'}
                      </a>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600">${this.formatDate(m.month)}</td>
                    <td class="py-4 px-6 text-sm text-slate-900 font-medium">${m.total_work_minutes || 0}min</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${m.total_late_minutes || 0}min</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${m.total_overtime_minutes || 0}min</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${m.total_absent_days || 0}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${m.total_present_days || 0}</td>
                    <td class="py-4 px-6 text-sm text-right">
                      <a href="${Helpers.company_attendance_month_path(currentCompany().id, m.id)}"
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
