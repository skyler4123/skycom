import ApexCharts from "apexcharts"
import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Analytics_IndexController extends Companies_LayoutController {
  static targets = ["marginChart", "velocityChart", "clvChart", "staffChart"]

  summary = {
    total_revenue_cents: 0,
    total_orders: 0,
    active_customers: 0,
    active_employees: 0,
    avg_order_value_cents: 0,
    currency: "USD"
  }

  profitMargins = { overall_margin_pct: 0, by_month: [] }
  inventoryVelocity = { low_stock_count: 0, by_product: [] }
  staffPerformance = { by_employee: [] }
  customerCLV = { by_customer: [], new_customers_30d: 0 }
  /** @type {ApexCharts[]} */ charts = []

  async connect() {
    super.connect()

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
      const response = await fetchJson()
      this.summary = response.summary || this.summary
      this.profitMargins = response.profit_margins || this.profitMargins
      this.inventoryVelocity = response.inventory_velocity || this.inventoryVelocity
      this.staffPerformance = response.staff_performance || this.staffPerformance
      this.customerCLV = response.customer_clv || this.customerCLV
    } catch (error) {
      toast({ type: "error", message: translate("Failed to load analytics") })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        setTimeout(() => this.renderCharts(), 150)
        return true
      }
      return false
    })
  }

  async onPeriodChange(event) {
    const url = new URL(window.location.href)
    url.searchParams.set("period", event.target.value)
    try {
      const response = await fetchJson(url.pathname + url.search)
      this.summary = response.summary || this.summary
      this.profitMargins = response.profit_margins || this.profitMargins
      this.inventoryVelocity = response.inventory_velocity || this.inventoryVelocity
      this.staffPerformance = response.staff_performance || this.staffPerformance
      this.customerCLV = response.customer_clv || this.customerCLV
      this.renderContent()
      setTimeout(() => this.renderCharts(), 150)
    } catch (error) {
      toast({ type: "error", message: translate("Failed to load analytics") })
    }
  }

  formatCents(cents, currency) {
    const curr = currency || this.summary.currency || "USD"
    if (curr === "VND") {
      return `${Number(cents).toLocaleString("vi-VN")}₫`
    }
    return `$${Number(cents / 100).toLocaleString("en-US", { minimumFractionDigits: 2 })}`
  }

  contentHTML() {
    const s = this.summary
    const period = new URLSearchParams(window.location.search).get("period") || "this_month"

    return `
      <div class="p-4 overflow-y-auto">
        <div class="mb-6 flex items-center justify-between">
          <h1 class="text-2xl font-black text-slate-900 dark:text-white">${translate("Analytics")}</h1>
          <select data-action="change->${this.identifier}#onPeriodChange"
            class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 cursor-pointer">
            <option value="this_month" ${period === "this_month" ? "selected" : ""}>${translate("This Month")}</option>
            <option value="last_month" ${period === "last_month" ? "selected" : ""}>${translate("Last Month")}</option>
            <option value="last_6_months" ${period === "last_6_months" ? "selected" : ""}>${translate("Last 6 Months")}</option>
            <option value="this_year" ${period === "this_year" ? "selected" : ""}>${translate("This Year")}</option>
          </select>
        </div>

        <!-- Summary Cards -->
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          ${this.summaryCard("total_revenue_cents", this.formatCents(s.total_revenue_cents), "Revenue", "payments")}
          ${this.summaryCard("total_orders", s.total_orders, "Orders", "shopping_cart")}
          ${this.summaryCard("active_customers", s.active_customers, "Active Customers", "people")}
          ${this.summaryCard("active_employees", s.active_employees, "Active Employees", "badge")}
        </div>

        <!-- Profit Margins Chart -->
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6 mb-6">
          <div class="flex items-center justify-between mb-4">
            <div>
              <h2 class="text-lg font-bold text-slate-900 dark:text-white">${translate("Revenue & Profit Margins")}</h2>
              <p class="text-sm text-slate-500">${translate("Overall margin")}: <span class="font-semibold ${this.profitMargins.overall_margin_pct >= 0 ? 'text-emerald-600' : 'text-red-600'}">${this.profitMargins.overall_margin_pct}%</span></p>
            </div>
          </div>
          <div data-${this.identifier}-target="marginChart" class="h-72"></div>
        </div>

        <!-- Two-column section -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
          <!-- Inventory Velocity -->
          <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6">
            <h2 class="text-lg font-bold text-slate-900 dark:text-white mb-1">${translate("Inventory Velocity")}</h2>
            ${this.inventoryVelocity.low_stock_count > 0
              ? `<p class="text-sm text-amber-600 mb-4">${this.inventoryVelocity.low_stock_count} ${translate("low stock items")}</p>`
              : `<p class="text-sm text-emerald-600 mb-4">${translate("Stock levels healthy")}</p>`}
            <div data-${this.identifier}-target="velocityChart" class="h-72"></div>
          </div>

          <!-- Customer CLV -->
          <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6">
            <h2 class="text-lg font-bold text-slate-900 dark:text-white mb-1">${translate("Customer CLV")}</h2>
            <p class="text-sm text-slate-500 mb-4">${this.customerCLV.new_customers_30d} ${translate("new customers in 30 days")}</p>
            <div data-${this.identifier}-target="clvChart" class="h-72"></div>
          </div>
        </div>

        <!-- Staff Performance -->
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6">
          <h2 class="text-lg font-bold text-slate-900 dark:text-white mb-4">${translate("Staff Performance")}</h2>
          <div data-${this.identifier}-target="staffChart" class="h-72"></div>
        </div>
      </div>
    `
  }

  summaryCard(key, value, label, icon) {
    return `
      <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-4">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 rounded-lg bg-blue-50 dark:bg-blue-900/30 flex items-center justify-center shrink-0">
            <span class="material-symbols-outlined text-blue-600 dark:text-blue-400 text-[20px]">${icon}</span>
          </div>
          <div>
            <p class="text-2xl font-black text-slate-900 dark:text-white">${value}</p>
            <p class="text-xs font-medium text-slate-500">${translate(label)}</p>
          </div>
        </div>
      </div>
    `
  }

  disconnect() {
    super.disconnect()
    this.charts.forEach(chart => chart.destroy())
    this.charts = []
  }

  renderCharts() {
    this.renderMarginChart()
    this.renderVelocityChart()
    this.renderCLVChart()
    this.renderStaffChart()
  }

  renderMarginChart() {
    const container = this.marginChartTarget
    if (!container || !this.profitMargins.by_month.length) return

    const months = this.profitMargins.by_month.map(m => m.month)
    const revenue = this.profitMargins.by_month.map(m => Math.round(m.revenue_cents / 100))
    const cost = this.profitMargins.by_month.map(m => Math.round(m.cost_cents / 100))
    const margins = this.profitMargins.by_month.map(m => m.margin_pct)

    const chart = new ApexCharts(container, {
      series: [
        { name: translate("Revenue"), type: "column", data: revenue },
        { name: translate("Cost"), type: "column", data: cost },
        { name: translate("Margin %"), type: "line", data: margins }
      ],
      chart: { height: 280, type: "line", toolbar: { show: false } },
      colors: ["#3b82f6", "#94a3b8", "#10b981"],
      stroke: { width: [0, 0, 3] },
      xaxis: { categories: months, labels: { style: { colors: "#94a3b8" } } },
      yaxis: [
        { title: { text: "$" }, labels: { style: { colors: "#94a3b8" } } },
        { opposite: true, title: { text: "%" }, max: 100, labels: { style: { colors: "#10b981" } } }
      ],
      tooltip: { shared: true, intersect: false },
      legend: { position: "top", horizontalAlign: "right", labels: { colors: "#94a3b8" } }
    })
    chart.render()
    this.charts.push(chart)
  }

  renderVelocityChart() {
    const container = this.velocityChartTarget
    if (!container || !this.inventoryVelocity.by_product.length) return

    const top = this.inventoryVelocity.by_product
      .sort((a, b) => b.units_sold_30d - a.units_sold_30d).slice(0, 10)
    const chart = new ApexCharts(container, {
      series: [{ name: translate("Units Sold (30d)"), data: top.map(p => p.units_sold_30d) }],
      chart: { height: 280, type: "bar", toolbar: { show: false } },
      colors: ["#3b82f6"],
      plotOptions: { bar: { horizontal: true, borderRadius: 4 } },
      xaxis: { categories: top.map(p => p.name), labels: { style: { colors: "#94a3b8" } } },
      yaxis: { labels: { style: { colors: "#94a3b8" } } },
      legend: { show: false }
    })
    chart.render()
    this.charts.push(chart)
  }

  renderCLVChart() {
    const container = this.clvChartTarget
    if (!container || !this.customerCLV.by_customer.length) return

    const top = this.customerCLV.by_customer
      .sort((a, b) => b.total_spent_cents - a.total_spent_cents).slice(0, 10)
    const chart = new ApexCharts(container, {
      series: [{ name: translate("Total Spent"), data: top.map(c => Math.round(c.total_spent_cents / 100)) }],
      chart: { height: 280, type: "bar", toolbar: { show: false } },
      colors: ["#8b5cf6"],
      plotOptions: { bar: { horizontal: true, borderRadius: 4 } },
      xaxis: { categories: top.map(c => c.name), labels: { style: { colors: "#94a3b8" } } },
      yaxis: { labels: { style: { colors: "#94a3b8" } } },
      tooltip: { y: { formatter: (val) => `$${val.toLocaleString()}` } },
      legend: { show: false }
    })
    chart.render()
    this.charts.push(chart)
  }

  renderStaffChart() {
    const container = this.staffChartTarget
    if (!container || !this.staffPerformance.by_employee.length) return

    const employees = this.staffPerformance.by_employee.map(e => e.name)
    const hours = this.staffPerformance.by_employee.map(e => e.total_hours)
    const overtime = this.staffPerformance.by_employee.map(e => e.overtime_hours)

    const chart = new ApexCharts(container, {
      series: [
        { name: translate("Hours Worked"), data: hours },
        { name: translate("Overtime"), data: overtime }
      ],
      chart: { height: 280, type: "bar", toolbar: { show: false } },
      colors: ["#3b82f6", "#f59e0b"],
      plotOptions: { bar: { horizontal: false, borderRadius: 4 } },
      xaxis: { categories: employees, labels: { style: { colors: "#94a3b8" } } },
      yaxis: { title: { text: translate("Hours") }, labels: { style: { colors: "#94a3b8" } } },
      legend: { position: "top", horizontalAlign: "right", labels: { colors: "#94a3b8" } }
    })
    chart.render()
    this.charts.push(chart)
  }
}
