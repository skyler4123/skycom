import Companies_LayoutController from "controllers/companies/layout_controller"
import { periodSelectorHTML, periodQueryParams, compositeTone } from "controllers/companies/performance/period_helpers"

export default class Companies_Performance_IndexController extends Companies_LayoutController {
  // Company KPI leaderboard. Read-only; computed on demand for the selected period.
  // Depends on BE: Companies::PerformanceController#index
  // Endpoints: GET /companies/:company_id/performance.json?period&from&to
  // Docs: docs/KPI.md

  period = "this_month"
  from = null
  to = null

  /** @type {any[]} */
  rows = []

  /** @type {{ orders_count: number, revenue_cents: number }} */
  unattributed = { orders_count: 0, revenue_cents: 0 }

  canManage = false

  connect() {
    super.connect()

    const params = new URLSearchParams(window.location.search)
    this.period = params.get("period") || "this_month"
    this.from = params.get("from")
    this.to = params.get("to")

    poll(() => {
      if (currentCompany()) {
        this.loadData()
        return true
      }
      return false
    })
  }

  async loadData() {
    try {
      const response = await fetchJson(`${Helpers.company_performance_index_path(currentCompany().id)}.json`, {
        params: periodQueryParams(this)
      })
      this.rows = response.rows || []
      this.unattributed = response.unattributed || this.unattributed
      this.canManage = response.can_manage === true
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load performance.") })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    }, { maxAttempts: 500 })
  }

  onPeriodChange(event) {
    this.period = event.target.value

    if (this.period === "custom") {
      this.renderContent()
      return
    }

    this.from = null
    this.to = null
    this.refresh()
  }

  async applyCustom() {
    this.from = this.element.querySelector("[data-period-from]")?.value || null
    this.to = this.element.querySelector("[data-period-to]")?.value || null

    if (!this.from || !this.to) {
      toast({ type: "warning", message: translate("Choose both dates.") })
      return
    }

    await this.refresh()
  }

  async refresh() {
    await this.loadData()
    this.renderContent()

    const query = new URLSearchParams(periodQueryParams(this)).toString()
    history.replaceState(null, "", `${Helpers.company_performance_index_path(currentCompany().id)}?${query}`)
  }

  contentHTML() {
    const scoredRows = this.rows.filter((row) => (row.rows || []).length > 0)
    const currency = currentCompany()?.currency || "usd"

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between mb-6">
            <div>
              <h2 class="text-xl font-bold text-foreground">${translate("Performance")}</h2>
              <p class="text-sm text-muted-foreground mt-1">${translate("Employee KPI scores for the selected period.")}</p>
            </div>
            ${this.canManage ? `
              <a href="${Helpers.company_kpi_configs_path(currentCompany().id)}"
                class="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-muted-foreground border border-line rounded-lg hover:bg-muted">
                <span class="material-symbols-outlined text-[18px]!">tune</span>
                ${translate("KPI Settings")}
              </a>
            ` : ""}
          </div>

          <div class="mb-6">
            ${periodSelectorHTML({
              identifierName: this.identifier,
              period: this.period,
              from: this.from,
              to: this.to
            })}
          </div>

          <div class="grid grid-cols-1 gap-3 sm:grid-cols-3 mb-6">
            <div class="border border-line rounded-xl p-4">
              <p class="text-xs font-medium text-muted-foreground">${translate("Employees scored")}</p>
              <p class="text-2xl font-bold text-foreground mt-1">${scoredRows.length}</p>
            </div>
            <div class="border border-line rounded-xl p-4">
              <p class="text-xs font-medium text-muted-foreground">${translate("Unattributed orders")}</p>
              <p class="text-2xl font-bold ${this.unattributed.orders_count > 0 ? "text-warning" : "text-foreground"} mt-1">
                ${this.unattributed.orders_count}
              </p>
            </div>
            <div class="border border-line rounded-xl p-4">
              <p class="text-xs font-medium text-muted-foreground">${translate("Unattributed revenue")}</p>
              <p class="text-2xl font-bold ${this.unattributed.revenue_cents > 0 ? "text-warning" : "text-foreground"} mt-1">
                ${Helpers.formatMoney(this.unattributed.revenue_cents, currency)}
              </p>
            </div>
          </div>

          ${this.unattributed.orders_count > 0 ? `
            <div class="mb-6 flex items-start gap-3 rounded-xl border border-warning/40 bg-warning/10 p-4" data-unattributed-banner>
              <span class="material-symbols-outlined text-warning text-[20px]!">warning</span>
              <p class="text-sm text-foreground">
                ${translate("Some paid orders have no salesperson. Their revenue is excluded from employee scores.")}
              </p>
            </div>
          ` : ""}

          ${scoredRows.length ? this.tableHTML(scoredRows) : this.emptyHTML()}
        </div>
      </div>
    `
  }

  tableHTML(scoredRows) {
    return `
      <div class="overflow-x-auto border border-line rounded-xl">
        <table class="w-full text-sm">
          <thead class="bg-muted/50 text-muted-foreground">
            <tr>
              <th class="text-left font-semibold px-4 py-3 w-16">#</th>
              <th class="text-left font-semibold px-4 py-3">${translate("Employee")}</th>
              <th class="text-left font-semibold px-4 py-3">${translate("Metrics")}</th>
              <th class="text-right font-semibold px-4 py-3">${translate("Composite score")}</th>
              <th class="text-right font-semibold px-4 py-3"></th>
            </tr>
          </thead>
          <tbody class="divide-y divide-line">
            ${scoredRows.map((row, index) => `
              <tr data-performance-row data-performance-employee="${row.employee_id}">
                <td class="px-4 py-3 text-muted-foreground font-mono">${index + 1}</td>
                <td class="px-4 py-3">
                  <a href="${Helpers.company_performance_path(currentCompany().id, row.employee_id)}"
                    class="font-medium text-foreground hover:text-primary">
                    ${escapeHtml(row.name || "")}
                  </a>
                </td>
                <td class="px-4 py-3 text-muted-foreground">${(row.rows || []).length}</td>
                <td class="px-4 py-3 text-right font-mono font-semibold ${compositeTone(row.composite_pct)}"
                  data-performance-composite>
                  ${row.composite_pct === null || row.composite_pct === undefined ? "—" : `${Number(row.composite_pct).toFixed(1)}%`}
                </td>
                <td class="px-4 py-3 text-right">
                  <a href="${Helpers.company_performance_path(currentCompany().id, row.employee_id)}"
                    ${tooltip("Open scorecard")}
                    class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg">
                    <span class="material-symbols-outlined text-[20px]">chevron_right</span>
                  </a>
                </td>
              </tr>
            `).join("")}
          </tbody>
        </table>
      </div>
    `
  }

  emptyHTML() {
    return `
      <div class="text-center py-12 border border-line rounded-xl">
        <span class="material-symbols-outlined text-[40px] text-muted-foreground/60">leaderboard</span>
        <p class="text-sm font-medium text-foreground mt-3">${translate("No KPI configured yet.")}</p>
        <p class="text-sm text-muted-foreground mt-1">${translate("Create the first KPI to start measuring employee performance.")}</p>
        ${this.canManage ? `
          <a href="${Helpers.company_kpi_configs_path(currentCompany().id)}"
            class="mt-4 inline-flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm">
            <span class="material-symbols-outlined text-[20px]">add</span>
            ${translate("Add KPI")}
          </a>
        ` : ""}
      </div>
    `
  }
}
