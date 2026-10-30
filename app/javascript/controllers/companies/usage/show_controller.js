import Companies_LayoutController from "controllers/companies/layout_controller"
import ApexCharts from "apexcharts"
import { chartPalette, chartGridColor } from "controllers/helpers/chart_colors"

export default class Companies_Usage_ShowController extends Companies_LayoutController {
  static targets = ["usageChart"]

  /** @type {object | null} */ wallet = null
  /** @type {Array<{date: string, total_credits: number}>} */ dailyUsage = []
  /** @type {number} */ todayTotal = 0
  /** @type {number} */ liveDelta = 0
  /** @type {number} */ monthlyTotal = 0
  /** @type {{active: boolean, until: string | null, seconds_remaining: number} | null} */ usageLogging = null
  /** @type {Array<{id: string, action_type: string, change_amount: number, balance_after: number, description: string | null, created_at: string}>} */ usageLogs = []

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
      this.usageLogging = response.usage_logging || null
      this.usageLogs = response.usage_logs || []
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

  async enableLogging(event) {
    if (event) event.preventDefault()
    await this.toggleLogging(Helpers.company_usage_enable_logging_path(currentCompany().id))
  }

  async disableLogging(event) {
    if (event) event.preventDefault()
    await this.toggleLogging(Helpers.company_usage_disable_logging_path(currentCompany().id))
  }

  async refreshLogs(event) {
    if (event) event.preventDefault()
    await this.loadData()
  }

  async toggleLogging(url) {
    try {
      const response = await fetchJson(url, { method: "POST" })
      toast({ type: "success", message: response.message || "" })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update usage logging") })
    }
    await this.loadData()
  }

  renderCharts() {
    const container = this.usageChartTarget
    if (!container) return

    const options = {
      series: [{ name: translate("Credits"), data: this.dailyUsage.map(d => d.total_credits) }],
      chart: { type: "bar", height: 300, toolbar: { show: false } },
      colors: chartPalette(1),
      plotOptions: { bar: { columnWidth: "45%", borderRadius: 2 } },
      dataLabels: { enabled: false },
      xaxis: { categories: this.dailyUsage.map(d => d.date), labels: { style: { fontSize: "11px" } } },
      yaxis: { labels: { style: { fontSize: "11px" } } },
      grid: { borderColor: chartGridColor(), strokeDashArray: 4 },
    }

    const chart = new ApexCharts(container, options)
    chart.render()
  }

  formatCredits(value) {
    return Number(value || 0).toLocaleString("en-US")
  }

  loggingActive() {
    return this.usageLogging?.active === true
  }

  remainingLabel() {
    const total = Math.max(0, Math.floor(this.usageLogging?.seconds_remaining || 0))
    const minutes = String(Math.floor(total / 60)).padStart(2, "0")
    const seconds = String(total % 60).padStart(2, "0")
    return `${minutes}:${seconds}`
  }

  statusBadgeHTML() {
    if (this.loggingActive()) {
      return `<span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-success/10 text-success text-xs font-bold uppercase"><span class="size-1.5 rounded-full bg-success/100 animate-pulse"></span>${translate("Recording")} · ${this.remainingLabel()}</span>`
    }
    return `<span class="inline-flex items-center px-2.5 py-1 rounded-full bg-muted text-muted-foreground text-xs font-bold uppercase">${translate("Off")}</span>`
  }

  toggleButtonHTML() {
    if (this.loggingActive()) {
      return `<button
  type="button"
  data-action="click->${this.identifier}#disableLogging"
  class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-danger hover:bg-danger/90 text-danger-foreground rounded-lg font-medium text-xs whitespace-nowrap cursor-pointer "
>
  <span class="material-symbols-outlined text-[16px]">stop_circle</span>
  ${translate("Stop Logging")}
</button>`
    }
    return `<button
  type="button"
  data-action="click->${this.identifier}#enableLogging"
  class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-xs whitespace-nowrap cursor-pointer "
>
  <span class="material-symbols-outlined text-[16px]">play_circle</span>
  ${translate("Enable Logging")}
</button>`
  }

  formatLogTime(isoString) {
    return new Date(isoString).toLocaleTimeString("en-US", { hour12: false })
  }

  formatChange(value) {
    const sign = value > 0 ? "+" : ""
    return `${sign}${this.formatCredits(value)}`
  }

  usageLogRowsHTML() {
    return this.usageLogs.map(log => `
      <tr class="border-t border-line hover:bg-muted/50">
        <td class="py-2.5 px-4 text-xs text-muted-foreground whitespace-nowrap font-mono">${this.formatLogTime(log.created_at)}</td>
        <td class="py-2.5 px-4 text-sm text-foreground whitespace-nowrap capitalize">${(log.action_type || "").replace(/_/g, " ")}</td>
        <td class="py-2.5 px-4 text-sm font-bold whitespace-nowrap ${log.change_amount >= 0 ? "text-success " : "text-danger "}">${this.formatChange(log.change_amount)}</td>
        <td class="py-2.5 px-4 text-sm text-foreground whitespace-nowrap font-mono">${this.formatCredits(log.balance_after)}</td>
        <td class="py-2.5 px-4 text-sm text-muted-foreground">${log.description || "—"}</td>
      </tr>
    `).join("")
  }

  usageLogBodyHTML() {
    if (!this.loggingActive()) {
      return `
        <div class="py-10 flex flex-col items-center gap-2 text-center">
          <span class="material-symbols-outlined text-[32px] text-muted-foreground/60">monitor_heart</span>
          <p class="text-sm text-muted-foreground">${translate("Enable logging to capture credit movements")}</p>
        </div>
      `
    }
    if (this.usageLogs.length === 0) {
      return `
        <div class="py-10 flex flex-col items-center gap-2 text-center">
          <span class="material-symbols-outlined text-[32px] text-muted-foreground/60">hourglass_empty</span>
          <p class="text-sm text-muted-foreground">${translate("No activity captured yet")}</p>
        </div>
      `
    }
    return `
      <div class="overflow-x-auto">
        <table class="w-full text-left">
          <thead>
            <tr class="text-[10px] font-bold text-muted-foreground uppercase border-b border-line">
              <th class="py-2 px-4">${translate("Time")}</th>
              <th class="py-2 px-4">${translate("Action")}</th>
              <th class="py-2 px-4">${translate("Change")}</th>
              <th class="py-2 px-4">${translate("Credits Remaining")}</th>
              <th class="py-2 px-4">${translate("Description")}</th>
            </tr>
          </thead>
          <tbody>${this.usageLogRowsHTML()}</tbody>
        </table>
      </div>
    `
  }

  contentHTML() {
    const cards = [
      { label: translate("Main Credits"), value: this.formatCredits(this.wallet?.main_credit_balance), icon: "savings", color: "bg-success/10 text-success ", hint: translate("Credits purchased through top-ups. Used after promotional credits run out.") },
      { label: translate("Promo Credits"), value: this.formatCredits(this.wallet?.promo_credit_balance), icon: "redeem", color: "bg-danger/10 text-danger ", hint: translate("Free promotional credits. Spent first automatically.") },
      { label: translate("Used Today"), value: this.formatCredits(this.todayTotal), icon: "today", color: "bg-primary/10 text-primary", hint: translate("Credits consumed since midnight today — already includes the latest-hour amount shown beside it.") },
      { label: translate("Latest Hour Usage"), value: this.formatCredits(this.liveDelta), icon: "hourglass_top", color: "bg-warning/10 text-warning ", hint: translate("Credits used since the last hourly system update. Included in Used Today. Resets every hour.") },
      { label: translate("Used This Month"), value: this.formatCredits(this.monthlyTotal), icon: "calendar_month", color: "bg-primary/10 text-primary ", hint: translate("Total credits consumed this calendar month.") },
    ]

    return `
      <div class="p-4 md:p-6 overflow-y-auto space-y-6">
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-4">
          ${cards.map(card => `
            <div class="bg-card rounded-xl border border-line p-5">
              <div class="flex items-center gap-3">
                <div class="size-10 rounded-lg ${card.color} flex items-center justify-center shrink-0">
                  <span class="material-symbols-outlined text-[22px]">${card.icon}</span>
                </div>
                <div class="min-w-0">
                  <div class="flex items-center gap-1">
                    <p class="text-[10px] font-bold text-muted-foreground uppercase truncate">${card.label}</p>
                    <span
                      ${tooltip(card.hint)}
                      class="material-symbols-outlined text-[14px]! text-muted-foreground/60 hover:text-muted-foreground cursor-pointer shrink-0"
                    >info</span>
                  </div>
                  <p class="text-xl font-black text-foreground">${card.value}</p>
                </div>
              </div>
            </div>
          `).join("")}
        </div>

        <div class="bg-card rounded-xl border border-line p-5">
          <div class="flex items-center gap-1.5 mb-4">
            <h3 class="text-sm font-bold text-foreground">${translate("Daily Usage")}</h3>
            <span
              ${tooltip(translate("Credits used per day over the last 7 days."))}
              class="material-symbols-outlined text-[16px] text-muted-foreground/60 hover:text-muted-foreground cursor-pointer"
            >info</span>
          </div>
          <div data-${this.identifier}-target="usageChart"></div>
        </div>

        <div class="bg-card rounded-xl border border-line p-5">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4">
            <div class="flex items-center gap-3">
              <div class="flex items-center gap-1.5">
                <h3 class="text-sm font-bold text-foreground">${translate("Usage Logs")}</h3>
                <span
                  ${tooltip(translate("Per-action record of credit movements. Enable logging to capture them live."))}
                  class="material-symbols-outlined text-[16px] text-muted-foreground/60 hover:text-muted-foreground cursor-pointer"
                >info</span>
              </div>
              ${this.statusBadgeHTML()}
            </div>
            <div class="flex items-center gap-2">
              <button
                type="button"
                data-action="click->${this.identifier}#refreshLogs"
                aria-label="${translate("Refresh")}"
                ${tooltip(translate("Refresh"))}
                class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer "
              >
                <span class="material-symbols-outlined text-[18px]!">refresh</span>
              </button>
              ${this.toggleButtonHTML()}
            </div>
          </div>
          ${this.usageLogBodyHTML()}
        </div>
      </div>
    `
  }
}
