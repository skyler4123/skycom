import Companies_LayoutController from "controllers/companies/layout_controller"
import ApexCharts from "apexcharts"

export default class Companies_Usage_ShowController extends Companies_LayoutController {
  static targets = ["usageChart"]

  /** @type {object | null} */ wallet = null
  /** @type {Array<{date: string, total_credits: number}>} */ dailyUsage = []
  /** @type {number} */ todayTotal = 0
  /** @type {number} */ liveDelta = 0
  /** @type {number} */ monthlyTotal = 0

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
      const response = await fetchJson(`${Helpers.company_usage_path(currentCompany().id)}.json`)
      this.wallet = response.wallet
      this.dailyUsage = response.daily_usage || []
      this.todayTotal = response.today_total || 0
      this.liveDelta = response.live_delta || 0
      this.monthlyTotal = response.monthly_total || 0
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load usage data") })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        this.renderCharts()
        return true
      }
      return false
    })
  }

  renderCharts() {
    const container = this.usageChartTarget
    if (!container) return

    const options = {
      series: [{ name: translate("Credits"), data: this.dailyUsage.map(d => d.total_credits) }],
      chart: { type: "bar", height: 300, toolbar: { show: false } },
      colors: ["#008FFB"],
      plotOptions: { bar: { columnWidth: "45%", borderRadius: 2 } },
      dataLabels: { enabled: false },
      xaxis: { categories: this.dailyUsage.map(d => d.date), labels: { style: { fontSize: "11px" } } },
      yaxis: { labels: { style: { fontSize: "11px" } } },
      grid: { borderColor: "#e2e8f0", strokeDashArray: 4 },
    }

    const chart = new ApexCharts(container, options)
    chart.render()
  }

  formatCredits(value) {
    return Number(value || 0).toLocaleString("en-US")
  }

  contentHTML() {
    const cards = [
      { label: translate("Credit Balance"), value: this.formatCredits(this.wallet?.main_credit_balance), icon: "account_balance_wallet", color: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400" },
      { label: translate("Today"), value: this.formatCredits(this.todayTotal), icon: "today", color: "bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400" },
      { label: translate("Live Delta"), value: this.formatCredits(this.liveDelta), icon: "bolt", color: "bg-amber-100 dark:bg-amber-900/30 text-amber-600 dark:text-amber-400" },
      { label: translate("Monthly Total"), value: this.formatCredits(this.monthlyTotal), icon: "calendar_month", color: "bg-purple-100 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400" },
    ]

    return `
      <div class="p-4 md:p-6 overflow-y-auto space-y-6">
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          ${cards.map(card => `
            <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-5">
              <div class="flex items-center gap-3">
                <div class="size-10 rounded-lg ${card.color} flex items-center justify-center">
                  <span class="material-symbols-outlined text-[22px]">${card.icon}</span>
                </div>
                <div class="min-w-0">
                  <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">${card.label}</p>
                  <p class="text-xl font-black text-slate-900 dark:text-white">${card.value}</p>
                </div>
              </div>
            </div>
          `).join("")}
        </div>

        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-5">
          <h3 class="text-sm font-bold text-slate-700 dark:text-slate-300 mb-4">${translate("Daily Usage")}</h3>
          <div data-${this.identifier}-target="usageChart"></div>
        </div>
      </div>
    `
  }
}
