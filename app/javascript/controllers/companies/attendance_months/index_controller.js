import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceMonths_IndexController extends Companies_LayoutController {
  // Attendance months dashboard with employee-name search, month range + absence/deficit thresholds.
  // Depends on BE: Companies::AttendanceMonthsController#index (JSON), #collect
  // Endpoints: GET <pathname>.json?employee_name&from&to&min_absent_days&min_deficit_minutes — traditional GET form, full-page submit
  // Docs: docs/HR.md
  static targets = ["attendanceMonthsList"]

  /** @type {Array} */
  attendanceMonths = []

  async connect() {
    super.connect()
    try {
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson(`${pathname()}.json?${urlParams.toString()}`)
      this.attendanceMonths = response.attendance_months || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load attendance months") }${__errDetail ? ": " + __errDetail : ""}` })
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
    const urlParams = new URLSearchParams(window.location.search)
    const employeeNameValue = urlParams.get('employee_name') || ''
    const fromValue = urlParams.get('from') || ''
    const toValue = urlParams.get('to') || ''
    const minAbsentValue = urlParams.get('min_absent_days') || ''
    const minDeficitValue = urlParams.get('min_deficit_minutes') || ''

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <h2 class="text-xl font-bold text-slate-900 dark:text-white mb-6">${translate("Attendance Months")}</h2>
          <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end gap-4 mb-6 w-full">
            <div class="flex flex-wrap items-end gap-3 w-full lg:w-auto">
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("Employee Name")}</label>
                <input type="text" name="employee_name" value="${employeeNameValue.replace(/"/g, '&quot;')}" placeholder="${translate("e.g. John Doe")}" class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300" />
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("From")}</label>
                <input type="date" name="from" value="${fromValue}" class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300" />
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("To")}</label>
                <input type="date" name="to" value="${toValue}" class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300" />
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("Min Absent Days")}</label>
                <input type="number" name="min_absent_days" min="0" step="1" value="${minAbsentValue.replace(/"/g, '&quot;')}" placeholder="0" class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300" />
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("Min Deficit Minutes")}</label>
                <input type="number" name="min_deficit_minutes" min="0" step="1" value="${minDeficitValue.replace(/"/g, '&quot;')}" placeholder="0" class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300" />
              </div>
              <div class="flex gap-2 mt-auto">
                <button type="submit" class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm flex items-center gap-2 cursor-pointer">
                  <span class="material-symbols-outlined text-[18px]!">search</span>
                  ${translate("Search")}
                </button>
              </div>
            </div>
          </form>
          <div class="flex justify-end mb-4">
            <button type="button" data-action="click->${this.identifier}#collect" class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg transition-colors font-medium text-sm flex items-center gap-2 cursor-pointer">
              <span class="material-symbols-outlined text-[18px]!">sync</span>
              ${translate("Collect Data")}
            </button>
          </div>
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
