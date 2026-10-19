import Companies_LayoutController from "controllers/companies/layout_controller"

// Depends on BE: Companies::PayrollsController#my (JSON with employee, month, payroll, attendance_month, attendance_days, months)
export default class Companies_Payrolls_MyController extends Companies_LayoutController {
  /** @type {Object|null} */
  employee = null

  /** @type {string|null} */
  month = null

  /** @type {Object|null} */
  payroll = null

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
    const base = Helpers.company_payroll_my_path(currentCompany().id)
    const query = month ? `?month=${month}` : ''
    try {
      const response = await fetchJson(`${base}.json${query}`)
      this.employee = response.employee
      this.month = response.month
      this.payroll = response.payroll
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load payroll.")}</div>`
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

  contentHTML() {
    const payroll = this.payroll
    const months = this.months || []
    const cid = currentCompany().id
    const options = months.map(x => {
      const selected = this.month && x.month && String(x.month).slice(0, 7) === String(this.month).slice(0, 7) ? 'selected' : ''
      return `<option value="${String(x.month).slice(0, 7)}" ${selected}>${this.formatDate(String(x.month).slice(0, 10))}</option>`
    }).join('')
    const dropdown = months.length > 0
      ? `<select onchange="window.location.href='/companies/${cid}/payroll/my?month='+this.value" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">${options}</select>`
      : ''

    if (!payroll) {
      return `
        <div class="p-4 overflow-y-auto">
          <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
            <h2 class="text-2xl font-black text-slate-900 dark:text-white mb-6">${translate("Payroll")}</h2>
            ${dropdown}
            <p class="text-sm text-slate-500 dark:text-slate-400 mt-4">${translate("No payroll data for this month.")}</p>
          </div>
        </div>
      `
    }

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <h2 class="text-2xl font-black text-slate-900 dark:text-white mb-6">${translate("Payroll")}</h2>
          ${dropdown}
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-6">
            <div class="p-3 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-900">
              <p class="text-xs font-medium text-slate-500 dark:text-slate-400">${translate("Employee")}</p>
              <p class="text-sm font-semibold text-slate-900 dark:text-white">${payroll.employee?.name || this.employee?.name || '—'}</p>
            </div>
            <div class="p-3 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-900">
              <p class="text-xs font-medium text-slate-500 dark:text-slate-400">${translate("Month")}</p>
              <p class="text-sm font-semibold text-slate-900 dark:text-white">${this.formatDate(payroll.month)}</p>
            </div>
            <div class="p-3 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-900">
              <p class="text-xs font-medium text-slate-500 dark:text-slate-400">${translate("Status")}</p>
              <p class="text-sm font-semibold text-slate-900 dark:text-white">${payroll.status || '—'}</p>
            </div>
          </div>
        </div>
      </div>
    `
  }
}
