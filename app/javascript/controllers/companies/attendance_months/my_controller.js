import Companies_LayoutController from "controllers/companies/layout_controller"

// Depends on BE: Companies::AttendanceMonthsController#my (JSON with employee, month, attendance_month, attendance_days, months)
export default class Companies_AttendanceMonths_MyController extends Companies_LayoutController {
  /** @type {Object|null} */
  employee = null

  /** @type {string|null} */
  month = null

  /** @type {Object|null} */
  attendanceMonth = null

  /** @type {Array} */
  attendanceDays = []

  /** @type {Array} */
  months = []

  async connect() {
    super.connect()
    const params = new URLSearchParams(window.location.search)
    const month = params.get("month")
    const base = Helpers.company_attendance_months_my_path(currentCompany().id)
    const query = month ? `?month=${month}` : ''
    try {
      const response = await fetchJson(`${base}.json${query}`)
      this.employee = response.employee
      this.month = response.month
      this.attendanceMonth = response.attendance_month
      this.attendanceDays = response.attendance_days || []
      this.months = response.months || []
      poll(() => {
        if (this.hasContentTarget) { this.renderContent(); return true }
        return false
      })
    } catch (error) {
      poll(() => {
        if (this.hasContentTarget) {
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load attendance month.")}</div>`
          return true
        }
        return false
      })
    }
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

  contentHTML() {
    const m = this.attendanceMonth
    const months = this.months || []
    const cid = currentCompany().id
    const options = months.map(x => {
      const selected = this.month && x.month && String(x.month).slice(0, 7) === String(this.month).slice(0, 7) ? 'selected' : ''
      return `<option value="${String(x.month).slice(0, 7)}" ${selected}>${this.formatDate(String(x.month).slice(0, 10))}</option>`
    }).join('')
    const dropdown = months.length > 0
      ? `<select onchange="window.location.href='/companies/${cid}/attendance_months/my?month='+this.value" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">${options}</select>`
      : ''

    if (!m) {
      return `
        <div class="p-4 overflow-y-auto">
          <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
            <h2 class="text-2xl font-black text-slate-900 dark:text-white mb-6">${translate("Attendance Month")}</h2>
            ${dropdown}
            <p class="text-sm text-slate-500 dark:text-slate-400 mt-4">${translate("No attendance data for this month.")}</p>
          </div>
        </div>
      `
    }

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <h2 class="text-2xl font-black text-slate-900 dark:text-white mb-6">${translate("Attendance Month")}</h2>
          ${dropdown}
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-6">
            <div class="p-3 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-900">
              <p class="text-xs font-medium text-slate-500 dark:text-slate-400">${translate("Employee")}</p>
              <p class="text-sm font-semibold text-slate-900 dark:text-white">${m.employee?.name || this.employee?.name || '—'}</p>
            </div>
            <div class="p-3 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-900">
              <p class="text-xs font-medium text-slate-500 dark:text-slate-400">${translate("Month")}</p>
              <p class="text-sm font-semibold text-slate-900 dark:text-white">${this.formatDate(m.month)}</p>
            </div>
            <div class="p-3 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-900">
              <p class="text-xs font-medium text-slate-500 dark:text-slate-400">${translate("Total Worked")}</p>
              <p class="text-sm font-semibold text-slate-900 dark:text-white">${m.total_work_minutes || 0} min</p>
            </div>
            <div class="p-3 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-900">
              <p class="text-xs font-medium text-slate-500 dark:text-slate-400">${translate("Days Present")}</p>
              <p class="text-sm font-semibold text-slate-900 dark:text-white">${m.total_present_days || 0}</p>
            </div>
            <div class="p-3 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-900">
              <p class="text-xs font-medium text-slate-500 dark:text-slate-400">${translate("Days Absent")}</p>
              <p class="text-sm font-semibold text-slate-900 dark:text-white">${m.total_absent_days || 0}</p>
            </div>
          </div>
          <div class="mt-8 border-t border-slate-200 dark:border-slate-700 pt-6">
            <h3 class="text-lg font-bold text-slate-900 dark:text-white mb-4">${translate("Daily Breakdown")}</h3>
            ${this.attendanceDays.length === 0 ? `<p class="text-sm text-slate-500 dark:text-slate-400">${translate("No daily records for this month yet.")}</p>` : `
              <div class="overflow-x-auto border border-slate-200 dark:border-slate-700 rounded-lg">
                <table class="w-full text-left border-collapse">
                  <thead>
                    <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                      <th class="py-4 px-6 font-medium">${translate("Date")}</th>
                      <th class="py-4 px-6 font-medium">${translate("Check In")}</th>
                      <th class="py-4 px-6 font-medium">${translate("Check Out")}</th>
                      <th class="py-4 px-6 font-medium">${translate("Worked")}</th>
                      <th class="py-4 px-6 font-medium">${translate("Status")}</th>
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
