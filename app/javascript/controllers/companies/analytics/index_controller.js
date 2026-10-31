import Companies_LayoutController from "controllers/companies/layout_controller"
import ApexCharts from "apexcharts"
import { chartGridColor, chartLabelColor, tokenColor } from "controllers/helpers/chart_colors"

// Depends on BE: Companies::AnalyticsController#index
// Endpoints: GET /companies/:company_id/analytics.json?period=this_month|last_month|last_6_months|this_year
export default class Companies_Analytics_IndexController extends Companies_LayoutController {
  /** @type {object | null} */ analyticsData = null
  /** @type {ApexCharts[]} */ charts = []
  loading = true
  /** @type {string | null} */ error = null
  period = "this_month"

  async connect() {
    super.connect()

    poll(() => {
      if (currentCompany()) {
        this.period = new URLSearchParams(window.location.search).get("period") || "this_month"
        this.loadData(this.period)
        return true
      }
      return false
    })
  }

  async loadData(period = this.period) {
    this.loading = true
    this.error = null

    try {
      const url = new URL(window.location.href)
      url.searchParams.set("period", period)
      const response = await fetchJson(url.pathname + url.search)
      this.analyticsData = response
      this.period = response.period?.key || period
    } catch (error) {
      this.error = error.errors?.join(", ") || error.message
    } finally {
      this.loading = false
      poll(() => {
        if (this.hasContentTarget) {
          this.destroyCharts()
          this.renderContent()
          this.renderCharts()
          return true
        }
        return false
      })
    }
  }

  async onPeriodChange(event) {
    const period = event.target.value
    this.period = period

    const url = new URL(window.location.href)
    url.searchParams.set("period", period)
    window.history.replaceState({}, "", url.pathname + url.search)

    await this.loadData(period)
  }

  reload() {
    this.loadData(this.period)
  }

  currency() {
    return this.analyticsData?.summary?.currency || currentCompany()?.currency || "usd"
  }

  contentHTML() {
    if (this.loading) return this.loadingHTML()
    if (this.error) return this.errorHTML()
    if (!this.analyticsData) return `<div class="p-6">${this.emptyInline(translate("No analytics data available"))}</div>`

    return `
      <div class="p-4 overflow-y-auto space-y-4">
        ${this.headerHTML()}
        ${this.pillarsHTML()}
        ${this.secondaryMetricsHTML()}
        ${this.marginChartHTML()}
        ${this.revenueMixHTML()}
        ${this.topItemsHTML()}
        ${this.cohortsHTML()}
        ${this.inventoryHTML()}
        ${this.workforceHTML()}
        ${this.clvHTML()}
      </div>
    `
  }

  headerHTML() {
    return `
      <div class="flex flex-col gap-3 xl:flex-row xl:items-center xl:justify-between">
        <div>
          <h1 class="text-2xl font-black text-foreground">${translate("Executive analysis")}</h1>
          <p class="text-sm text-muted-foreground mt-1">${translate("Period-based financial, customer, inventory, and workforce signals.")}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <label class="flex items-center gap-2 px-3 py-2 rounded-lg border border-line bg-card text-xs text-muted-foreground">
            <span class="font-semibold">${translate("Period")}</span>
            <select name="period" data-action="change->${this.identifier}#onPeriodChange"
              class="bg-transparent text-foreground text-xs font-semibold focus:outline-none cursor-pointer">
              ${this.periodOptionsHTML()}
            </select>
          </label>
          <span class="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-muted text-muted-foreground text-[11px]">
            <span class="material-symbols-outlined text-[15px]">compare_arrows</span>
            ${translate("vs previous period")}
          </span>
        </div>
      </div>
    `
  }

  periodOptionsHTML() {
    const options = [
      [ "this_month", translate("This Month") ],
      [ "last_month", translate("Last Month") ],
      [ "last_6_months", translate("Last 6 Months") ],
      [ "this_year", translate("This Year") ]
    ]

    return options.map(([ value, label ]) => `
      <option value="${value}" ${this.period === value ? "selected" : ""}>${label}</option>
    `).join("")
  }

  pillarsHTML() {
    const s = this.analyticsData.summary || {}
    const inventory = this.analyticsData.inventory_velocity || {}
    const topMover = inventory.by_product?.[0]
    const turnover = topMover?.turnover_rate
    const currency = this.currency()

    return `
      <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-3">
        ${this.pillarCard("revenue", translate("Net revenue"), Helpers.formatMoney(s.total_revenue_cents, currency), this.deltaBadge(s.revenue_delta_pct), translate("vs previous period"), "payments")}
        ${this.grossProfitCard(s, currency)}
        ${this.pillarCard("customer-economics", translate("Customer economics"), Helpers.formatMoney(s.avg_order_value_cents, currency), `${this.number(s.active_customers)} ${translate("active customers")}`, `${this.percent(s.repeat_customer_rate)} ${translate("returning")}`, "group")}
        ${this.pillarCard("inventory-velocity", translate("Inventory velocity"), turnover == null ? "—" : `${turnover}x`, `${topMover?.name || translate("Top mover")} · ${this.decimal(s.inventory_days_of_cover)} ${translate("days of cover")}`, `${this.number(s.low_stock_count)} ${translate("low stock")}`, "inventory")}
      </div>
    `
  }

  pillarCard(key, label, value, helper, subhelper, icon) {
    return `
      <div data-analytics-metric="${key}" class="bg-card border border-line rounded-xl p-4 flex flex-col justify-between min-h-[132px]">
        <div class="flex items-start justify-between gap-2">
          <div class="min-w-0">
            <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${label}</p>
            <p class="text-2xl font-black text-foreground mt-1 truncate">${value}</p>
          </div>
          <div class="size-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center shrink-0">
            <span class="material-symbols-outlined text-[20px]">${icon}</span>
          </div>
        </div>
        <div class="mt-2 pt-2 border-t border-line text-[11px] text-muted-foreground">
          <div class="flex items-center justify-between gap-2"><span>${helper}</span><span class="truncate">${subhelper}</span></div>
        </div>
      </div>
    `
  }

  grossProfitCard(summary, currency) {
    return `
      <div data-analytics-metric="gross-profit" class="bg-card border border-line rounded-xl p-4 flex flex-col justify-between min-h-[132px]">
        <div class="flex items-start justify-between gap-2">
          <div class="min-w-0">
            <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Gross profit")}</p>
            <p class="text-2xl font-black text-foreground mt-1 truncate">${Helpers.formatMoney(summary.gross_profit_cents, currency)}</p>
          </div>
          <div class="size-9 rounded-lg bg-success/10 text-success flex items-center justify-center shrink-0">
            <span class="material-symbols-outlined text-[20px]">trending_up</span>
          </div>
        </div>
        <div class="mt-2 pt-2 border-t border-line text-[11px] text-muted-foreground flex items-center justify-between gap-2">
          <span data-analytics-metric="gross-margin" class="font-semibold text-foreground">${this.percent(summary.gross_margin_pct)}</span>
          <span>${this.percent(summary.cost_coverage_pct)} ${translate("cost coverage")}</span>
        </div>
      </div>
    `
  }

  secondaryMetricsHTML() {
    const s = this.analyticsData.summary || {}
    const currency = this.currency()

    return `
      <div class="grid grid-cols-2 xl:grid-cols-4 gap-3">
        ${this.smallMetric("orders", translate("Orders"), this.number(s.total_orders), "receipt_long")}
        ${this.smallMetric("new-customers", translate("New customers"), this.number(s.new_customers), "person_add")}
        ${this.smallMetric("revenue-per-hour", translate("Revenue per worked hour"), s.revenue_per_worked_hour_cents == null ? "—" : Helpers.formatMoney(s.revenue_per_worked_hour_cents, currency), "schedule")}
        ${this.smallMetric("low-stock", translate("Low stock"), this.number(s.low_stock_count), "warning")}
      </div>
    `
  }

  smallMetric(key, label, value, icon) {
    return `
      <div data-analytics-metric="${key}" class="bg-card border border-line rounded-xl p-3.5 flex items-center justify-between gap-3">
        <div class="min-w-0">
          <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${label}</p>
          <p class="text-xl font-black text-foreground mt-0.5 truncate">${value}</p>
        </div>
        <span class="material-symbols-outlined text-[20px] text-muted-foreground shrink-0">${icon}</span>
      </div>
    `
  }

  marginChartHTML() {
    const margins = this.analyticsData.profit_margins || {}
    const rows = margins.by_month || []

    return `
      <div class="bg-card border border-line rounded-xl p-4">
        <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-2 mb-3">
          <div>
            <h2 class="text-base font-bold text-foreground">${translate("Revenue vs tracked cost")}</h2>
            <p class="text-xs text-muted-foreground">${translate("Gross billing, tracked product cost, and margin rate.")}</p>
          </div>
          <div class="flex flex-wrap items-center gap-3 text-[11px] text-muted-foreground">
            <span class="inline-flex items-center gap-1"><span class="size-2 rounded-full bg-primary"></span>${translate("Revenue")}</span>
            <span class="inline-flex items-center gap-1"><span class="size-2 rounded-full bg-muted-foreground"></span>${translate("Tracked cost")}</span>
            <span class="inline-flex items-center gap-1"><span class="size-2 rounded-full bg-success"></span>${translate("Margin %")}</span>
          </div>
        </div>
        ${rows.length ? `<div data-analytics-chart="margin" class="h-72"></div>` : this.emptyInline(translate("No revenue data for this period"))}
      </div>
    `
  }

  revenueMixHTML() {
    const mix = this.analyticsData.revenue_mix || {}
    const currency = this.currency()

    return `
      <div data-analytics-section="revenue-mix" class="bg-card border border-line rounded-xl p-4">
        <div class="mb-3">
          <h2 class="text-base font-bold text-foreground">${translate("Revenue mix")}</h2>
          <p class="text-xs text-muted-foreground">${translate("Where this period's revenue came from.")}</p>
        </div>
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
          ${this.mixList(translate("By order category"), mix.by_category, currency)}
          ${this.mixList(translate("By branch"), mix.by_branch, currency)}
        </div>
      </div>
    `
  }

  mixList(title, rows = [], currency) {
    const data = rows || []

    return `
      <div>
        <h3 class="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-2">${title}</h3>
        ${data.length ? data.map((row) => `
          <div class="mb-2 last:mb-0">
            <div class="flex items-center justify-between gap-2 text-xs">
              <span class="text-foreground truncate">${this.escape(row.name || translate("Unassigned"))}</span>
              <span class="text-muted-foreground shrink-0">${this.percent(row.pct)} · ${Helpers.formatMoney(row.revenue_cents, currency)}</span>
            </div>
            <div class="w-full h-1.5 rounded-full bg-muted overflow-hidden mt-1">
              <div class="h-full rounded-full bg-primary" style="width: ${Math.min(Number(row.pct || 0), 100)}%"></div>
            </div>
          </div>
        `).join("") : this.emptyInline(translate("No revenue yet"))}
      </div>
    `
  }

  topItemsHTML() {
    const items = this.analyticsData.top_items || {}
    const currency = this.currency()

    return `
      <div data-analytics-section="top-items" class="bg-card border border-line rounded-xl p-4">
        <div class="mb-3">
          <h2 class="text-base font-bold text-foreground">${translate("Top products & services")}</h2>
          <p class="text-xs text-muted-foreground">${translate("Ranked by revenue in the selected period.")}</p>
        </div>
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
          ${this.itemList(translate("Products"), items.products, currency, true)}
          ${this.itemList(translate("Services"), items.services, currency, false)}
        </div>
      </div>
    `
  }

  itemList(title, rows = [], currency, showMargin) {
    const data = rows || []

    return `
      <div>
        <h3 class="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-2">${title}</h3>
        ${data.length ? data.map((row, index) => `
          <div class="flex items-center justify-between gap-3 p-2.5 rounded-lg bg-muted mb-2 last:mb-0">
            <div class="flex items-center gap-2 min-w-0">
              <span class="size-6 rounded-full bg-primary/10 text-primary text-[10px] font-bold flex items-center justify-center shrink-0">${index + 1}</span>
              <div class="min-w-0">
                <p class="text-xs font-semibold text-foreground truncate">${this.escape(row.name || translate("Unknown item"))}</p>
                <p class="text-[11px] text-muted-foreground">${this.number(row.quantity)} ${translate("units")}</p>
              </div>
            </div>
            <div class="text-right shrink-0">
              <p class="text-xs font-bold text-foreground">${Helpers.formatMoney(row.revenue_cents, currency)}</p>
              ${showMargin ? `<p class="text-[10px] text-muted-foreground">${this.percent(row.margin_pct)} ${translate("margin")}</p>` : ""}
            </div>
          </div>
        `).join("") : this.emptyInline(translate("No sales yet"))}
      </div>
    `
  }

  cohortsHTML() {
    const cohorts = this.analyticsData.cohorts || []

    return `
      <div data-analytics-section="cohorts" class="bg-card border border-line rounded-xl p-4">
        <div class="mb-3">
          <h2 class="text-base font-bold text-foreground">${translate("Customer cohorts")}</h2>
          <p class="text-xs text-muted-foreground">${translate("Retention from each customer's first paid order month.")}</p>
        </div>
        ${cohorts.length ? `
          <div class="overflow-x-auto">
            <table class="w-full text-left text-xs">
              <thead>
                <tr class="text-[10px] uppercase tracking-wider text-muted-foreground">
                  <th class="py-2 pr-3">${translate("Cohort")}</th>
                  <th class="py-2 px-2 text-center">${translate("New")}</th>
                  ${Array.from({ length: 6 }, (_, index) => `<th class="py-2 px-2 text-center">M${index}</th>`).join("")}
                </tr>
              </thead>
              <tbody>
                ${cohorts.map((row) => `
                  <tr class="border-t border-line">
                    <td class="py-2 pr-3 font-semibold text-foreground whitespace-nowrap">${this.formatMonth(row.cohort)}</td>
                    <td class="py-2 px-2 text-center text-muted-foreground">${row.new_customers}</td>
                    ${(row.retention || []).map((value) => `
                      <td class="py-2 px-2 text-center">
                        <span class="inline-flex min-w-12 justify-center px-2 py-1 rounded ${this.cohortCellClass(value)}">${value == null ? "—" : `${value}%`}</span>
                      </td>
                    `).join("")}
                  </tr>
                `).join("")}
              </tbody>
            </table>
          </div>
        ` : this.emptyInline(translate("Not enough paid order history yet"))}
      </div>
    `
  }

  cohortCellClass(value) {
    if (value == null) return "bg-muted text-muted-foreground"
    if (value >= 90) return "bg-primary text-primary-foreground"
    if (value >= 70) return "bg-primary/70 text-primary-foreground"
    if (value >= 50) return "bg-primary/40 text-foreground"
    return "bg-muted text-muted-foreground"
  }

  inventoryHTML() {
    const inventory = this.analyticsData.inventory_velocity || {}
    const currency = this.currency()
    const rows = inventory.by_product || []
    const lowStock = inventory.low_stock_items || []

    return `
      <div data-analytics-section="inventory" class="bg-card border border-line rounded-xl p-4">
        <div class="mb-3">
          <h2 class="text-base font-bold text-foreground">${translate("Inventory velocity")}</h2>
          <p class="text-xs text-muted-foreground">${translate("Sell-through, days of cover, and low-stock risk.")}</p>
        </div>
        <div class="grid grid-cols-2 gap-2 mb-3">
          ${this.smallStat(translate("Days of cover"), `${this.decimal(inventory.days_of_cover)} ${translate("days")}`)}
          ${this.smallStat(translate("Stock value"), Helpers.formatMoney(inventory.stock_value_retail_cents, currency))}
          ${this.smallStat(translate("Tracked cost"), Helpers.formatMoney(inventory.stock_value_cost_cents, currency))}
          ${this.smallStat(translate("Low stock"), this.number(inventory.low_stock_count))}
        </div>
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <div>
            <h3 class="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-2">${translate("Fast movers")}</h3>
            ${rows.length ? rows.slice(0, 5).map((row) => `
              <div class="flex items-center justify-between gap-3 p-2.5 rounded-lg bg-muted mb-2 last:mb-0">
                <div class="min-w-0">
                  <p class="text-xs font-semibold text-foreground truncate">${this.escape(row.name || translate("Unknown product"))}</p>
                  <p class="text-[11px] text-muted-foreground">${this.number(row.units_sold)} ${translate("sold")} · ${this.decimal(row.days_of_cover)} ${translate("days of cover")}</p>
                </div>
                <span class="text-xs font-bold text-foreground shrink-0">${row.turnover_rate ?? "—"}x</span>
              </div>
            `).join("") : this.emptyInline(translate("No stock movement yet"))}
          </div>
          <div>
            <h3 class="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-2">${translate("Low stock items")}</h3>
            ${lowStock.length ? lowStock.map((row) => `
              <div class="flex items-center justify-between gap-3 p-2.5 rounded-lg bg-danger/5 border border-danger/20 mb-2 last:mb-0">
                <div class="min-w-0">
                  <p class="text-xs font-semibold text-foreground truncate">${this.escape(row.product_name || translate("Unknown product"))}</p>
                  <p class="text-[11px] text-muted-foreground truncate">${this.escape(row.warehouse_name || "—")}</p>
                </div>
                <span class="text-xs font-bold text-danger shrink-0">${this.number(row.available)} ${translate("left")}</span>
              </div>
            `).join("") : this.emptyInline(translate("Stock levels look healthy"))}
          </div>
        </div>
      </div>
    `
  }

  workforceHTML() {
    const performance = this.analyticsData.staff_performance || {}
    const totals = performance.totals || {}
    const rows = performance.by_employee || []

    return `
      <div data-analytics-section="workforce" class="bg-card border border-line rounded-xl p-4">
        <div class="mb-3">
          <h2 class="text-base font-bold text-foreground">${translate("Workforce")}</h2>
          <p class="text-xs text-muted-foreground">${translate("Attendance, hours, and overtime from monthly rollups.")}</p>
        </div>
        <div class="grid grid-cols-3 gap-2 mb-3">
          ${this.smallStat(translate("Attendance rate"), this.percent(totals.average_attendance_rate))}
          ${this.smallStat(translate("Hours"), `${this.number(totals.total_hours)}h`)}
          ${this.smallStat(translate("Overtime"), `${this.number(totals.overtime_hours)}h`)}
        </div>
        ${rows.length ? rows.slice(0, 5).map((row) => `
          <div class="flex items-center justify-between gap-3 p-2.5 rounded-lg bg-muted mb-2 last:mb-0">
            <div class="min-w-0">
              <p class="text-xs font-semibold text-foreground truncate">${this.escape(row.name || "—")}</p>
              <p class="text-[11px] text-muted-foreground">${this.number(row.absent_days)} ${translate("absent days")}</p>
            </div>
            <div class="text-right shrink-0">
              <p class="text-xs font-bold text-foreground">${this.percent(row.attendance_rate)}</p>
              <p class="text-[10px] text-muted-foreground">${this.number(row.total_hours)}h</p>
            </div>
          </div>
        `).join("") : this.emptyInline(translate("No attendance rollup yet"))}
      </div>
    `
  }

  clvHTML() {
    const clv = this.analyticsData.customer_clv || {}
    const rows = clv.by_customer || []
    const currency = this.currency()

    return `
      <div data-analytics-section="clv" class="bg-card border border-line rounded-xl p-4">
        <div class="mb-3">
          <h2 class="text-base font-bold text-foreground">${translate("Top customers by lifetime value")}</h2>
          <p class="text-xs text-muted-foreground">${translate("All-time paid order spend, not just the selected period.")}</p>
        </div>
        ${rows.length ? rows.map((row) => `
          <div class="flex items-center justify-between gap-3 p-2.5 rounded-lg bg-muted mb-2 last:mb-0">
            <div class="flex items-center gap-2 min-w-0">
              <span class="size-8 rounded-full bg-primary/10 text-primary text-[11px] font-bold flex items-center justify-center shrink-0">${this.initials(row.name)}</span>
              <div class="min-w-0">
                <p class="text-xs font-semibold text-foreground truncate">${this.escape(row.name || "—")}</p>
                <p class="text-[11px] text-muted-foreground">${this.number(row.order_count)} ${translate("orders")}</p>
              </div>
            </div>
            <span class="text-xs font-bold text-primary shrink-0">${Helpers.formatMoney(row.total_spent_cents, currency)}</span>
          </div>
        `).join("") : this.emptyInline(translate("No customer spend yet"))}
      </div>
    `
  }

  smallStat(label, value) {
    return `
      <div class="p-2.5 rounded-lg bg-muted">
        <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${label}</p>
        <p class="text-sm font-bold text-foreground mt-0.5">${value}</p>
      </div>
    `
  }

  renderCharts() {
    const container = this.contentTarget.querySelector('[data-analytics-chart="margin"]')
    const margins = this.analyticsData?.profit_margins?.by_month || []
    if (!container || margins.length === 0) return

    const currency = this.currency()
    const chart = new ApexCharts(container, {
      series: [
        { name: translate("Revenue"), type: "column", data: margins.map((row) => Helpers.chartAmount(row.revenue_cents, currency)) },
        { name: translate("Tracked cost"), type: "column", data: margins.map((row) => Helpers.chartAmount(row.cost_cents, currency)) },
        { name: translate("Margin %"), type: "line", data: margins.map((row) => row.margin_pct) }
      ],
      chart: { height: 288, type: "line", toolbar: { show: false }, zoom: { enabled: false } },
      colors: [ tokenColor("primary"), tokenColor("muted-foreground"), tokenColor("success") ],
      stroke: { width: [ 0, 0, 3 ], curve: "smooth" },
      plotOptions: { bar: { columnWidth: "45%", borderRadius: 3 } },
      dataLabels: { enabled: false },
      grid: { borderColor: chartGridColor(), strokeDashArray: 4, xaxis: { lines: { show: false } } },
      xaxis: {
        categories: margins.map((row) => this.formatMonth(row.month)),
        labels: { style: { colors: chartLabelColor(), fontSize: "10px" } },
        axisBorder: { show: false },
        axisTicks: { show: false }
      },
      yaxis: [
        { labels: { style: { colors: chartLabelColor(), fontSize: "10px" }, formatter: (value) => Helpers.formatCompactNumber(value, currency) } },
        { opposite: true, max: 100, labels: { style: { colors: chartLabelColor(), fontSize: "10px" }, formatter: (value) => `${Math.round(value)}%` } }
      ],
      legend: { show: false },
      tooltip: { shared: true, intersect: false }
    })
    chart.render()
    this.charts.push(chart)
  }

  destroyCharts() {
    this.charts.forEach((chart) => chart.destroy())
    this.charts = []
  }

  disconnect() {
    super.disconnect()
    this.destroyCharts()
  }

  loadingHTML() {
    return `
      <div class="p-4 space-y-4">
        <div class="h-16 rounded-xl bg-muted animate-pulse"></div>
        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-3">
          ${Array.from({ length: 4 }, () => '<div class="h-32 rounded-xl bg-muted animate-pulse"></div>').join("")}
        </div>
        <div class="h-80 rounded-xl bg-muted animate-pulse"></div>
      </div>
    `
  }

  errorHTML() {
    return `
      <div class="p-6">
        <div class="bg-card border border-line rounded-xl p-8 text-center">
          <span class="material-symbols-outlined text-4xl text-danger">error</span>
          <h2 class="text-lg font-bold text-foreground mt-2">${translate("Failed to load analytics")}</h2>
          <p class="text-sm text-muted-foreground mt-1">${this.escape(this.error)}</p>
          <button type="button" data-action="click->${this.identifier}#reload"
            class="mt-4 px-4 py-2 rounded-lg bg-primary text-primary-foreground text-sm font-semibold">
            ${translate("Try again")}
          </button>
        </div>
      </div>
    `
  }

  emptyInline(message) {
    return `<div class="flex flex-col items-center justify-center py-8 text-center text-muted-foreground"><span class="material-symbols-outlined text-3xl mb-1">inbox</span><p class="text-xs">${message}</p></div>`
  }

  deltaBadge(value) {
    if (value === null || value === undefined) return `<span class="text-muted-foreground">${translate("No baseline")}</span>`

    const numeric = Number(value)
    const positive = numeric > 0
    const negative = numeric < 0
    const icon = positive ? "trending_up" : negative ? "trending_down" : "trending_flat"
    const tone = positive ? "text-success" : negative ? "text-danger" : "text-muted-foreground"

    return `<span class="inline-flex items-center gap-0.5 font-semibold ${tone}"><span class="material-symbols-outlined text-[14px]">${icon}</span>${positive ? "+" : ""}${numeric}%</span>`
  }

  percent(value, digits = 1) {
    if (value === null || value === undefined || Number.isNaN(Number(value))) return "—"
    return `${Number(value).toFixed(digits)}%`
  }

  number(value) {
    return Number(value || 0).toLocaleString()
  }

  decimal(value, digits = 1) {
    if (value === null || value === undefined || Number.isNaN(Number(value))) return "—"
    return Number(value).toFixed(digits)
  }

  initials(name) {
    return (name || "?").split(/\s+/).filter(Boolean).slice(0, 2).map((part) => part[0]).join("").toUpperCase()
  }

  escape(value) {
    return Helpers.escapeHtml(value ?? "")
  }

  formatMonth(value) {
    if (!value) return "—"
    return Helpers.timeFormat(`${value}-01`, "MMM YYYY")
  }
}
