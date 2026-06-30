import Companies_LayoutController from "controllers/companies/layout_controller"
import ApexCharts from "apexcharts"

export default class Companies_Billing_ShowController extends Companies_LayoutController {
  static targets = ["usageChart", "costChart"]

  /** @type {string} */ currency = "USD"
  /** @type {object|null} */ company = null
  /** @type {object|null} */ billingContract = null
  /** @type {object|null} */ wallet = null
  /** @type {Array} */ invoices = []
  /** @type {object} */ dailyMetricTotals = {}
  /** @type {Array} */ catalogAddonFeatures = []
  /** @type {object} */ estimate = {}

  async connect() {
    super.connect()

    try {
      const response = await fetchJson()
      this.currency = response.currency || "USD"
      this.company = response.company
      this.billingContract = response.billing_contract
      this.wallet = response.wallet
      this.invoices = response.invoices || []
      this.dailyMetricTotals = response.daily_metric_totals || {}
      this.catalogAddonFeatures = Helpers.sortObjectArray(response.catalog_addon_features || [])
      this.estimate = response.estimate || {}
    } catch (error) {
      toast({ type: "error", message: "Failed to load billing data" })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        setTimeout(() => this.renderCharts(), 100)
        return true
      }
      return false
    })
  }

  displayValue(value, unit) {
    if (unit === "x1000") return Math.round(value / 1000)
    return value
  }

  displayLabel(key, unit) {
    const label = key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
    return unit === "x1000" ? `${label} (x1000)` : label
  }

  renderCharts() {
    this.renderUsageChart()
    this.renderCostChart()
  }

  renderUsageChart() {
    const container = this.usageChartTarget
    if (!container) return

    const metrics = Object.keys(this.dailyMetricTotals)
    if (metrics.length === 0) {
      container.innerHTML = '<div class="flex items-center justify-center h-[200px] text-slate-400 text-sm">No usage data yet</div>'
      return
    }

    const labels = metrics.map(k => this.displayLabel(k, this.dailyMetricTotals[k].display_unit))
    const currentData = metrics.map(k => this.displayValue(this.dailyMetricTotals[k].current, this.dailyMetricTotals[k].display_unit))
    const allowanceData = metrics.map(k => this.displayValue(this.dailyMetricTotals[k].allowance, this.dailyMetricTotals[k].display_unit))

    const options = {
      series: [
        { name: "Current Usage", data: currentData },
        { name: "Allowance", data: allowanceData }
      ],
      chart: {
        height: 230,
        type: "bar",
        toolbar: { show: false }
      },
      colors: ["#3B82F6", "#94A3B8"],
      plotOptions: {
        bar: {
          columnWidth: "60%",
          borderRadius: 4,
          dataLabels: { position: "top" }
        }
      },
      dataLabels: {
        enabled: true,
        offsetY: -20,
        style: { fontSize: "11px", colors: ["#64748B"] }
      },
      legend: {
        position: "top",
        horizontalAlign: "right",
        fontSize: "12px"
      },
      xaxis: {
        categories: labels,
        labels: { style: { fontSize: "11px", fontWeight: 500 } }
      },
      yaxis: {
        title: { text: "Count" }
      },
      tooltip: {
        y: { formatter: (val) => `${val}` }
      }
    }

    new ApexCharts(container, options).render()
  }

  renderCostChart() {
    const container = this.costChartTarget
    if (!container) return

    const breakdown = this.estimate?.breakdown
    if (!breakdown || (breakdown.features_cents === 0 && breakdown.overage_cents === 0 && breakdown.base_cents === 0)) {
      container.innerHTML = '<div class="flex items-center justify-center h-[200px] text-slate-400 text-sm">No costs yet</div>'
      return
    }

    const currency = this.currency
    const fmt = (cents) => this.formatCents(cents)

    const series = []
    const labels = []

    if (breakdown.base_cents > 0) {
      series.push(breakdown.base_cents)
      labels.push(`Base Plan (${fmt(breakdown.base_cents)})`)
    }
    if (breakdown.features_cents > 0) {
      series.push(breakdown.features_cents)
      labels.push(`Add-ons (${fmt(breakdown.features_cents)})`)
    }
    if (breakdown.overage_cents > 0) {
      series.push(breakdown.overage_cents)
      labels.push(`Overage (${fmt(breakdown.overage_cents)})`)
    }

    if (series.length === 0) {
      container.innerHTML = '<div class="flex items-center justify-center h-[200px] text-slate-400 text-sm">No costs yet</div>'
      return
    }

    const options = {
      series: series,
      chart: {
        height: 230,
        type: "donut",
        toolbar: { show: false }
      },
      labels: labels,
      colors: ["#8B5CF6", "#3B82F6", "#F59E0B"],
      legend: {
        position: "bottom",
        fontSize: "12px",
        itemMargin: { horizontal: 12 }
      },
      dataLabels: {
        enabled: true,
        formatter: function (val) {
          return val.toFixed(1) + "%"
        }
      },
      tooltip: {
        y: { formatter: (val) => fmt(val) }
      },
      plotOptions: {
        pie: {
          donut: {
            labels: {
              show: true,
              total: {
                show: true,
                label: "Total",
                formatter: () => fmt(series.reduce((a, b) => a + b, 0))
              }
            }
          }
        }
      }
    }

    new ApexCharts(container, options).render()
  }

  formatCents(cents) {
    if (cents == null) cents = 0
    const currency = this.currency || "USD"
    if (currency === "VND") {
      return `${Number(cents).toLocaleString("vi-VN")}₫`
    }
    return `$${(Number(cents) / 100).toFixed(2)}`
  }

  lifecycleBadge(status) {
    const colors = {
      active: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
      suspended: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
      disabled: "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400"
    }
    const cls = colors[status] || "bg-slate-100 text-slate-600"
    return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold ${cls}">${status?.replace(/_/g, ' ') || "Unknown"}</span>`
  }

  statusBadge(active) {
    if (active) {
      return '<span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-xs font-bold bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400"><span class="material-symbols-outlined text-[12px]">check_circle</span>Enabled</span>'
    }
    return '<span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-xs font-medium bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400"><span class="material-symbols-outlined text-[12px]">remove_circle</span>Disabled</span>'
  }

  usageBar(pct) {
    const color = pct >= 100 ? "bg-red-500" : pct >= 80 ? "bg-amber-500" : "bg-emerald-500"
    const barWidth = Math.min(pct, 100)
    return `
      <div class="w-full bg-slate-200 dark:bg-slate-700 rounded-full h-2">
        <div class="${color} h-2 rounded-full" style="width: ${barWidth}%"></div>
      </div>
    `
  }

  async payAll(event) {
    event.preventDefault()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`/companies/${companyId}/billing/pay_all`, { method: "POST" })
      toast({ type: "success", message: response.message || "Payment processed" })

      const fresh = await fetchJson()
      this.company = fresh.company
      this.wallet = fresh.wallet
      this.invoices = fresh.invoices || []
      this.estimate = fresh.estimate || {}
      this.renderContent()
      setTimeout(() => this.renderCharts(), 100)
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Payment failed" })
    }
  }

  contentHTML() {
    return `
      <div class="p-4 md:p-6 overflow-y-auto space-y-6">

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="p-5 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
            <div class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider mb-2">Billing Status</div>
            <div class="flex items-center gap-3">
              <div class="flex items-center justify-center w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400">
                <span class="material-symbols-outlined text-[22px]">account_balance</span>
              </div>
              <div>
                <div>${this.lifecycleBadge(this.company?.lifecycle_status)}</div>
                <div class="text-xs text-slate-500 mt-1">${this.billingContract?.contract_type?.replace(/_/g, ' ') || "No contract"}</div>
              </div>
            </div>
            ${this.company && !this.company.is_accessible
              ? `<div class="mt-3 text-xs font-medium text-red-600 bg-red-50 dark:bg-red-900/20 dark:text-red-400 px-3 py-2 rounded-lg">Account suspended — top up to resume</div>`
              : ""}
          </div>

          <div class="p-5 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
            <div class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider mb-2">Wallet Balance</div>
            <div class="flex items-center gap-3">
              <div class="flex items-center justify-center w-10 h-10 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400">
                <span class="material-symbols-outlined text-[22px]">account_balance_wallet</span>
              </div>
              <div>
                <div class="text-2xl font-black text-slate-900 dark:text-white">${this.formatCents(this.wallet?.total_cents)}</div>
                <div class="text-xs text-slate-500">Main: ${this.formatCents(this.wallet?.main_balance_cents)} · Promo: ${this.formatCents(this.wallet?.promo_balance_cents)}</div>
              </div>
            </div>
          </div>

          <div class="p-5 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
            <div class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider mb-2">This Month Estimate</div>
            <div class="flex items-center gap-3">
              <div class="flex items-center justify-center w-10 h-10 rounded-lg bg-purple-100 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400">
                <span class="material-symbols-outlined text-[22px]">trending_up</span>
              </div>
              <div>
                <div class="text-2xl font-black text-slate-900 dark:text-white">${this.formatCents(this.estimate?.total_cents)}</div>
                <div class="text-xs text-slate-500">${this.estimate?.days_remaining || 0} days remaining</div>
              </div>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <div class="lg:col-span-2 p-5 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
            <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">Usage vs Allowance</h3>
            <div data-${this.identifier}-target="usageChart"></div>
          </div>
          <div class="p-5 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
            <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">Cost Breakdown</h3>
            <div data-${this.identifier}-target="costChart"></div>
          </div>
        </div>

        <div class="p-5 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">Usage Metrics</h3>
          <div class="overflow-x-auto">
            <table class="w-full text-left">
              <thead>
                <tr class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider border-b border-slate-200 dark:border-slate-700">
                  <th class="pb-3 pr-4">Metric</th>
                  <th class="pb-3 pr-4 text-right">Current</th>
                  <th class="pb-3 pr-4 text-right">Allowance</th>
                  <th class="pb-3 pr-4 text-right">Unit Price</th>
                  <th class="pb-3 pr-4 text-right">Current Cost</th>
                  <th class="pb-3 pr-4">Usage</th>
                  <th class="pb-3 text-right">Projected EOM</th>
                </tr>
              </thead>
              <tbody>
                ${Object.entries(this.dailyMetricTotals).map(([key, metric]) => {
                  const label = this.displayLabel(key, metric.display_unit)
                  const displayCurrent = this.displayValue(metric.current, metric.display_unit)
                  const displayAllowance = this.displayValue(metric.allowance, metric.display_unit)
                  const displayProjected = this.displayValue(metric.projected, metric.display_unit)
                  return `
                    <tr class="border-b border-slate-100 dark:border-slate-800 text-sm">
                      <td class="py-3 pr-4 font-medium text-slate-900 dark:text-white">${label}</td>
                      <td class="py-3 pr-4 text-right text-slate-700 dark:text-slate-300">${displayCurrent}</td>
                      <td class="py-3 pr-4 text-right text-slate-500">${displayAllowance}</td>
                      <td class="py-3 pr-4 text-right text-slate-500">${this.formatCents(metric.unit_price_cents)}</td>
                      <td class="py-3 pr-4 text-right ${metric.overage_cents > 0 ? "text-amber-600 font-bold" : "text-slate-400"}">${this.formatCents(metric.overage_cents)}</td>
                      <td class="py-3 pr-4">
                        <div class="flex items-center gap-2">
                          <div class="flex-1 max-w-[100px]">${this.usageBar(metric.usage_pct)}</div>
                          <span class="text-xs ${metric.usage_pct >= 100 ? "text-red-600 font-bold" : metric.usage_pct >= 80 ? "text-amber-600 font-bold" : "text-slate-500"}">${metric.usage_pct}%</span>
                        </div>
                      </td>
                      <td class="py-3 text-right text-slate-700 dark:text-slate-300">${displayProjected}</td>
                    </tr>
                  `
                }).join("")}
                ${Object.keys(this.dailyMetricTotals).length === 0
                  ? '<tr><td colspan="7" class="py-6 text-center text-sm text-slate-400">No usage data yet</td></tr>'
                  : ""}
              </tbody>
            </table>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <div class="p-5 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
            <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">Add-on Features Catalog</h3>
            <div class="overflow-x-auto">
              <table class="w-full text-left">
                <thead>
                  <tr class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider border-b border-slate-200 dark:border-slate-700">
                    <th class="pb-3 pr-4">Add-on Feature</th>
                    <th class="pb-3 pr-4 text-right">Price/mo</th>
                    <th class="pb-3 pr-4">Status</th>
                    <th class="pb-3 text-right">Active Days</th>
                  </tr>
                </thead>
                <tbody>
                  ${this.catalogAddonFeatures.length > 0
                    ? this.catalogAddonFeatures.map(f => `
                      <tr class="border-b border-slate-100 dark:border-slate-800 text-sm">
                        <td class="py-3 pr-4 font-medium text-slate-900 dark:text-white">${f.name}</td>
                        <td class="py-3 pr-4 text-right text-slate-700 dark:text-slate-300">${this.formatCents(f.monthly_price_cents)}/mo</td>
                        <td class="py-3 pr-4">${this.statusBadge(f.active)}</td>
                        <td class="py-3 text-right ${f.active_days > 0 ? "text-slate-700 dark:text-slate-300" : "text-slate-400"}">${f.active_days}</td>
                      </tr>
                    `).join("")
                    : '<tr><td colspan="4" class="py-6 text-center text-sm text-slate-400">No add-on features available.</td></tr>'
                  }
                </tbody>
              </table>
            </div>
          </div>
          <div class="p-5 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col justify-center">
            <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-3">Outstanding Invoices</h3>
            ${this.invoices.length > 0
              ? `<div class="space-y-2 mb-4">
                  ${this.invoices.slice(0, 5).map(inv => `
                    <div class="flex items-center justify-between text-sm">
                      <span class="text-slate-700 dark:text-slate-300">${inv.invoice_number}</span>
                      <span class="font-medium text-slate-900 dark:text-white">${this.formatCents(inv.price_cents)}</span>
                      <span class="text-xs ${inv.payment_status === "overdue" ? "text-red-600" : "text-amber-600"}">${inv.payment_status}</span>
                    </div>
                  `).join("")}
                </div>
                <button
                  type="button"
                  data-action="click->${this.identifier}#payAll"
                  class="w-full px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer transition-colors"
                >
                  Pay All Outstanding (${this.formatCents(this.invoices.reduce((s, i) => s + i.price_cents, 0))})
                </button>`
              : `<div class="text-center py-4">
                  <span class="material-symbols-outlined text-3xl text-emerald-500 block mb-2">check_circle</span>
                  <p class="text-sm text-slate-500 font-medium">All invoices paid</p>
                  <p class="text-xs text-slate-400 mt-1">No outstanding balances</p>
                </div>`
            }
          </div>
        </div>

      </div>
    `
  }
}
