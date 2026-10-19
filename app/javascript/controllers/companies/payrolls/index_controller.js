// Depends on BE: Companies::PayrollsController#index/summary/payrolls/generate + Companies::PayrollConfigsController#show/update
import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Payrolls_IndexController extends Companies_LayoutController {
  /** @type {any | null} */
  payrollConfig = null

  /** @type {any | null} */
  summary = null

  /** @type {string} */
  month = ""

  /** @type {any[]} */
  payrolls = []

  /** @type {any | null} */
  pagination = null

  async connect() {
    super.connect()

    const params = new URLSearchParams(window.location.search)
    this.month = params.get("month") || new Date().toISOString().slice(0, 7)

    const companyId = window.location.pathname.split("/")[2]

    try {
      const summaryResponse = await fetchJson(`${Helpers.company_payroll_summary_path(companyId)}?month=${this.month}`)
      this.summary = summaryResponse.summary
      await this.loadPayrolls(companyId)
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Failed to load payroll data" })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  async loadPayrolls(companyId) {
    const response = await fetchJson(`${Helpers.company_payroll_payrolls_path(companyId)}?month=${this.month}`)
    this.payrolls = response.payrolls || []
    this.pagination = response.pagination || null
  }

  async applyMonth(event) {
    event.preventDefault()
    const form = event.target
    const data = new FormData(form)
    this.month = data.get("month")
    const params = new URLSearchParams(window.location.search)
    params.set("month", this.month)
    window.location.href = `${pathname()}?${params.toString()}`
  }

  async generate() {
    const companyId = window.location.pathname.split("/")[2]
    try {
      await fetchJson(`${Helpers.company_payroll_generate_path(companyId)}`, {
        method: "POST",
        body: { month: this.month }
      })
      toast({ type: "success", message: "Payroll generated" })
      window.location.reload()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Failed to generate payroll" })
    }
  }

  viewDetail(event) {
    const id = event?.target?.dataset?.id || event?.params?.id
    const companyId = window.location.pathname.split("/")[2]
    window.location.href = `${Helpers.company_payroll_payroll_path(companyId, id)}`
  }

  exportCsv() {
    const records = this.payrolls
    if (!records || records.length === 0) {
      toast({ type: "error", message: "No records to export" })
      return
    }
    const cols = [
      { key: "employee", label: "Employee" },
      { key: "status", label: "Status" },
      { key: "month", label: "Month" }
    ]
    const flat = records.map(r => ({ ...r, employee: r.employee?.name }))
    downloadCSV(flat, cols, `payroll-${this.month}.csv`)
  }

  contentHTML() {
    const s = this.summary || {}
    const rowsHtml = this.payrolls.map(r => `
      <tr class="border-b border-slate-200 dark:border-slate-800 cursor-pointer" data-action="click->${this.identifier}#viewDetail" data-id="${r.id}">
        <td class="py-2 px-4 text-sm">${r.employee?.name || "—"}</td>
        <td class="py-2 px-4 text-sm">${r.month || "—"}</td>
        <td class="py-2 px-4 text-sm">${r.status || "—"}</td>
        <td class="py-2 px-4 text-sm">${r.metadata?.total_work_minutes ?? "—"}</td>
      </tr>
    `).join("")

    return `
      <div class="p-4 overflow-y-auto space-y-6">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
            <p class="text-xs text-slate-500 uppercase">Total</p>
            <p class="text-lg font-bold">${s.total ?? 0}</p>
          </div>
          <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
            <p class="text-xs text-slate-500 uppercase">Draft</p>
            <p class="text-lg font-bold">${s.draft ?? 0}</p>
          </div>
          <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
            <p class="text-xs text-slate-500 uppercase">Approved</p>
            <p class="text-lg font-bold">${s.approved ?? 0}</p>
          </div>
          <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
            <p class="text-xs text-slate-500 uppercase">Paid</p>
            <p class="text-lg font-bold">${s.paid ?? 0}</p>
          </div>
        </div>

        <form data-action="submit->${this.identifier}#applyMonth" class="flex flex-wrap items-end gap-3">
          <div>
            <label class="text-xs text-slate-500 uppercase">Month</label>
            <input type="month" name="month" value="${this.month}" class="px-3 py-2 border rounded-lg text-sm" />
          </div>
          <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm">Apply</button>
          <button type="button" data-action="click->${this.identifier}#generate" class="px-4 py-2 bg-emerald-600 text-white rounded-lg text-sm">Generate</button>
          <button type="button" data-action="click->${this.identifier}#exportCsv" class="px-4 py-2 bg-slate-100 dark:bg-slate-800 rounded-lg text-sm">Export CSV</button>
        </form>

        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-x-auto">
          <table class="w-full text-left">
            <thead>
              <tr class="border-b border-slate-200 dark:border-slate-800">
                <th class="py-2 px-4 text-xs text-slate-500 uppercase">Employee</th>
                <th class="py-2 px-4 text-xs text-slate-500 uppercase">Month</th>
                <th class="py-2 px-4 text-xs text-slate-500 uppercase">Status</th>
                <th class="py-2 px-4 text-xs text-slate-500 uppercase">Work Minutes</th>
              </tr>
            </thead>
            <tbody>
              ${rowsHtml || `<tr><td class="py-8 text-center text-slate-400" colspan="4">No records. Click Generate.</td></tr>`}
            </tbody>
          </table>
        </div>
      </div>
    `
  }
}
