import Companies_LayoutController from "controllers/companies/layout_controller"

// Depends on BE: Companies::AttendanceMonthsController#show (JSON with attendance_month + attendance_days), #collect
// Docs: docs/HR.md
export default class Companies_AttendanceMonths_ShowController extends Companies_LayoutController {
  /** @type {Object|null} */
  attendanceMonth = null

  /** @type {Array} */
  attendanceDays = []

  async connect() {
    super.connect()
    const id = window.location.pathname.split("/").pop()
    try {
      const response = await fetchJson(`${Helpers.company_attendance_month_path(currentCompany().id, id)}.json`)
      this.attendanceMonth = response.attendance_month
      this.attendanceDays = response.attendance_days || []
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load attendance month") }${__errDetail ? ": " + __errDetail : ""}` })
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

  formatDayDate(dateStr) {
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

  async collect() {
    const companyId = currentCompany().id
    try {
      const response = await fetchJson(`${Helpers.company_attendance_months_collect_path(companyId)}`, {
        method: "POST"
      })
      toast({ type: "success", message: response.message || "Attendance data collected" })
      window.location.reload()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Failed to collect attendance data" })
    }
  }

  contentHTML() {
    const m = this.attendanceMonth
    if (!m) return '<div class="p-8 text-center">Not found.</div>'

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <div class="flex items-center justify-between mb-6">
            <a href="${Helpers.company_attendance_months_path(currentCompany().id)}"
              class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 cursor-pointer">
              <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
              ${translate("Back")}
            </a>
            <button type="button" data-action="click->${this.identifier}#collect" class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg transition-colors font-medium text-sm flex items-center gap-2 cursor-pointer">
              <span class="material-symbols-outlined text-[18px]!">sync</span>
              ${translate("Collect Data")}
            </button>
          </div>
          <h2 class="text-2xl font-black text-slate-900 dark:text-white mb-6">${translate("Attendance Month")}</h2>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Employee")}</p>
              <p class="text-sm font-semibold text-slate-900">${m.employee?.name || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Month")}</p>
              <p class="text-sm font-semibold text-slate-900">${this.formatDate(m.month)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Total Worked")}</p>
              <p class="text-sm font-semibold text-slate-900">${m.total_work_minutes || 0} min</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Late")}</p>
              <p class="text-sm font-semibold text-slate-900">${m.total_late_minutes || 0} min</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Early Leave")}</p>
              <p class="text-sm font-semibold text-slate-900">${m.total_early_leave_minutes || 0} min</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Overtime")}</p>
              <p class="text-sm font-semibold text-slate-900">${m.total_overtime_minutes || 0} min</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Days Present")}</p>
              <p class="text-sm font-semibold text-slate-900">${m.total_present_days || 0}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Days Absent")}</p>
              <p class="text-sm font-semibold text-slate-900">${m.total_absent_days || 0}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Deficit")}</p>
              <p class="text-sm font-semibold text-slate-900">${m.total_deficit_minutes || 0} min</p>
            </div>
          </div>
          <div class="mt-8 border-t border-slate-200 dark:border-slate-700 pt-6">
            <h3 class="text-lg font-bold text-slate-900 dark:text-white mb-4">${translate("Daily Breakdown")}</h3>
            ${this.attendanceDays.length === 0 ? `<p class="text-sm text-slate-500 dark:text-slate-400">${translate("No daily records for this month yet.")}</p>` : `
              <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                  <thead>
                    <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                      <th class="py-4 px-6 font-medium">${translate("Date")}</th>
                      <th class="py-4 px-6 font-medium">${translate("Check In")}</th>
                      <th class="py-4 px-6 font-medium">${translate("Check Out")}</th>
                      <th class="py-4 px-6 font-medium">${translate("Worked")}</th>
                      <th class="py-4 px-6 font-medium">${translate("Status")}</th>
                      <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-slate-200 dark:divide-slate-800">
                    ${this.attendanceDays.map(d => `
                      <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                        <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${this.formatDayDate(d.attendance_date)}</td>
                        <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${this.formatTime(d.check_in)}</td>
                        <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${this.formatTime(d.check_out)}</td>
                        <td class="py-4 px-6 text-sm text-slate-900 dark:text-white font-medium">${Math.round((d.total_seconds_worked || 0) / 60)}min</td>
                        <td class="py-4 px-6 text-sm">${this.statusBadge(d.attendance_status)}</td>
                        <td class="py-4 px-6 text-sm text-right">
                          <a href="${Helpers.company_attendance_day_path(currentCompany().id, d.id)}" class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer">
                            <span class="material-symbols-outlined text-[20px]">visibility</span>
                          </a>
                        </td>
                      </tr>
                    `).join('')}
                  </tbody>
                </table>
              </div>
            `}
          </div>
        </div>
      </div>
    `
  }
}
