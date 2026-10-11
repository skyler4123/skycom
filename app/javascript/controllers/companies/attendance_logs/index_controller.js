import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceLogs_IndexController extends Companies_LayoutController {
  // Attendance logs dashboard with employee-name search, type + date-range filters.
  // Depends on BE: Companies::AttendanceLogsController#index (JSON)
  // Endpoints: GET <pathname>.json?employee_name&log_type&from&to — traditional GET form, full-page submit
  // Docs: docs/HR.md
  static targets = ["attendanceLogsList"]

  /** @type {Array} */
  attendanceLogs = []

  async connect() {
    super.connect()
    try {
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson(`${pathname()}.json?${urlParams.toString()}`)
      this.attendanceLogs = response.attendance_logs || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load attendance logs") }${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  formatDate(dt) {
    if (!dt) return '—'
    return new Date(dt).toLocaleDateString()
  }

  formatTime(dt) {
    if (!dt) return '—'
    return new Date(dt).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', hour12: false })
  }

  logTypeBadge(type) {
    const colors = {
      check_in: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300',
      check_out: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300'
    }
    const color = colors[type] || 'bg-gray-100 text-gray-800'
    return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${color}">${Helpers.capitalize(type || '')}</span>`
  }

  contentHTML() {
    const urlParams = new URLSearchParams(window.location.search)
    const employeeNameValue = urlParams.get('employee_name') || ''
    const logTypeValue = urlParams.get('log_type') || ''
    const fromValue = urlParams.get('from') || ''
    const toValue = urlParams.get('to') || ''
    const logTypeOptions = [ 'check_in', 'check_out' ]
      .map(t => `<option value="${t}" ${t === logTypeValue ? 'selected' : ''}>${Helpers.capitalize(t.replace('_', ' '))}</option>`).join('')

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <h2 class="text-xl font-bold text-slate-900 dark:text-white mb-6">${translate("Attendance Logs")}</h2>
          <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end gap-4 mb-6 w-full">
            <div class="flex flex-wrap items-end gap-3 w-full lg:w-auto">
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("Employee Name")}</label>
                <input type="text" name="employee_name" value="${employeeNameValue.replace(/"/g, '&quot;')}" placeholder="${translate("e.g. John Doe")}" class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300" />
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("Log Type")}</label>
                <select name="log_type" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                  <option value="">${translate("All")}</option>
                  ${logTypeOptions}
                </select>
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("From")}</label>
                <input type="date" name="from" value="${fromValue}" class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300" />
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("To")}</label>
                <input type="date" name="to" value="${toValue}" class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300" />
              </div>
              <div class="flex gap-2 mt-auto">
                <button type="submit" class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm flex items-center gap-2 cursor-pointer">
                  <span class="material-symbols-outlined text-[18px]!">search</span>
                  ${translate("Search")}
                </button>
              </div>
            </div>
          </form>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium">${translate("Employee")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Type")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Time")}</th>
                  <th class="py-4 px-6 font-medium">${translate("WiFi")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="attendanceLogsList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.attendanceLogs.map(l => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="py-4 px-6 text-sm font-medium">
                      <a href="${Helpers.company_attendance_log_path(currentCompany().id, l.id)}"
                        class="text-slate-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 cursor-pointer">
                        ${l.employee?.name || '—'}
                      </a>
                    </td>
                    <td class="py-4 px-6 text-sm">${this.logTypeBadge(l.log_type)}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${this.formatDate(l.logged_at)} ${this.formatTime(l.logged_at)}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${l.wifi_ssid || '—'}</td>
                    <td class="py-4 px-6 text-sm text-right">
                      <a href="${Helpers.company_attendance_log_path(currentCompany().id, l.id)}"
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
