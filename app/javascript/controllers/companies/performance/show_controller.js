import Companies_LayoutController from "controllers/companies/layout_controller"
import { periodSelectorHTML, periodQueryParams, formatAchievement, compositeTone } from "controllers/companies/performance/period_helpers"

export default class Companies_Performance_ShowController extends Companies_LayoutController {
  // One employee's KPI scorecard. Read-only; computed on demand.
  // Depends on BE: Companies::PerformanceController#show
  // Endpoints: GET /companies/:company_id/performance/:id.json?period&from&to
  // Docs: docs/KPI.md

  employeeId = null
  period = "this_month"
  from = null
  to = null

  /** @type {any | null} */
  scorecard = null

  connect() {
    super.connect()

    this.employeeId = window.location.pathname.split("/")[4]

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
      this.scorecard = await fetchJson(
        `${Helpers.company_performance_path(currentCompany().id, this.employeeId)}.json`,
        { params: periodQueryParams(this) }
      )
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load performance.") })
      this.scorecard = null
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
    history.replaceState(
      null,
      "",
      `${Helpers.company_performance_path(currentCompany().id, this.employeeId)}?${query}`
    )
  }

  contentHTML() {
    if (!this.scorecard) {
      return `<div class="p-8 text-center text-muted-foreground">${translate("Employee not found.")}</div>`
    }

    const rows = this.scorecard.rows || []

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_performance_index_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Performance")}
          </a>

          <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between mb-6">
            <div>
              <h2 class="text-2xl font-black text-foreground">${escapeHtml(this.scorecard.employee?.name || "")}</h2>
              <p class="text-sm text-muted-foreground mt-1">${translate("Employee KPI scorecard for the selected period.")}</p>
            </div>
            <div class="border border-line rounded-xl px-5 py-3 text-right">
              <p class="text-xs font-medium text-muted-foreground">${translate("Composite score")}</p>
              <p class="text-3xl font-black ${compositeTone(this.scorecard.composite_pct)}" data-scorecard-composite>
                ${this.scorecard.composite_pct === null || this.scorecard.composite_pct === undefined
                  ? "—"
                  : `${Number(this.scorecard.composite_pct).toFixed(1)}%`}
              </p>
            </div>
          </div>

          <div class="mb-6">
            ${periodSelectorHTML({
              identifierName: this.identifier,
              period: this.period,
              from: this.from,
              to: this.to
            })}
          </div>

          ${rows.length ? this.tableHTML(rows) : this.emptyHTML()}
        </div>
      </div>
    `
  }

  tableHTML(rows) {
    return `
      <div class="overflow-x-auto border border-line rounded-xl">
        <table class="w-full text-sm">
          <thead class="bg-muted/50 text-muted-foreground">
            <tr>
              <th class="text-left font-semibold px-4 py-3">${translate("KPI")}</th>
              <th class="text-right font-semibold px-4 py-3">${translate("Actual")}</th>
              <th class="text-right font-semibold px-4 py-3">${translate("Target")}</th>
              <th class="text-right font-semibold px-4 py-3">${translate("Achievement")}</th>
              <th class="text-right font-semibold px-4 py-3">${translate("Weight")}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-line">
            ${rows.map((row) => `
              <tr data-scorecard-row data-kpi-config-id="${row.kpi_config_id}">
                <td class="px-4 py-3">
                  <p class="font-medium text-foreground">${escapeHtml(row.name || "")}</p>
                  <p class="text-xs text-muted-foreground mt-0.5">${translate(this.metricLabel(row))}</p>
                </td>
                <td class="px-4 py-3 text-right font-mono text-foreground">${this.formatValue(row, row.actual_value)}</td>
                <td class="px-4 py-3 text-right font-mono text-muted-foreground">${this.formatValue(row, row.target_value)}</td>
                <td class="px-4 py-3 text-right font-mono font-semibold ${compositeTone(row.achievement_pct)}">
                  ${formatAchievement(row.achievement_pct)}
                </td>
                <td class="px-4 py-3 text-right font-mono text-muted-foreground">${row.weight}</td>
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
        <p class="text-sm font-medium text-foreground mt-3">${translate("No KPI applies to this employee yet.")}</p>
      </div>
    `
  }

  metricLabel(row) {
    return { orders_count: "Orders sold", orders_revenue_cents: "Sales revenue" }[row.metric_key] || row.metric_key
  }

  formatValue(row, value) {
    if (value === null || value === undefined) return "—"
    if (row.unit === "currency_cents") {
      return Helpers.formatMoney(value, currentCompany()?.currency || "usd")
    }

    return Number(value).toLocaleString()
  }
}
