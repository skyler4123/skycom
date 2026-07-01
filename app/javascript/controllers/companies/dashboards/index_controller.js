import Companies_LayoutController from "controllers/companies/layout_controller"
import ApexCharts from "apexcharts"

export default class Companies_Dashboards_IndexController extends Companies_LayoutController {
  static targets = ["companyDetails", "chartsContainer"]

  /** @type {object | null} */ company = null
  /** @type {object | null} */ counts = null

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
      const companyId = currentCompany().id
      const response = await fetchJson(`/companies/${companyId}/dashboards.json`)
      this.company = response.company
      this.counts = response.counts
    } catch (error) {
      toast({ type: "error", message: translate("Failed to load dashboard data") })
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
    const resources = [
      { key: "products",  label: translate("Products"),  icon: "inventory_2" },
      { key: "stocks",    label: translate("Stocks"),    icon: "warehouse" },
      { key: "services",  label: translate("Services"),  icon: "concierge" },
      { key: "orders",    label: translate("Orders"),    icon: "receipt_long" },
      { key: "employees", label: translate("Employees"), icon: "badge" },
    ]

    const colors = ["#008FFB", "#00E396", "#FEB019", "#FF4560", "#775DD0", "#546E7A", "#26a69a", "#D10CE8"]

    resources.forEach(({ key, label }) => {
      const data = this.counts?.[key] || {}
      const categories = Object.keys(data)
      const values = Object.values(data)

      const container = this.chartsContainerTarget.querySelector(`[data-chart="${key}"]`)
      if (!container) return

      if (categories.length === 0) {
        container.innerHTML = `<div class="flex items-center justify-center h-[200px] text-slate-400 dark:text-slate-500 text-sm">${translate("No data")}</div>`
        return
      }

      const chartColors = categories.map((_, i) => colors[i % colors.length])

      const options = {
        series: [{ name: label, data: values }],
        chart: {
          height: 220,
          type: "bar",
          toolbar: { show: false },
          sparkline: { enabled: false },
        },
        colors: chartColors,
        plotOptions: {
          bar: { columnWidth: "50%", distributed: true, borderRadius: 2 },
        },
        dataLabels: { enabled: false },
        legend: { show: false },
        tooltip: {
          y: { formatter: (val) => `${val} ${label}` },
        },
        xaxis: {
          categories: categories,
          labels: {
            style: { colors: chartColors, fontSize: "10px", fontWeight: 600 },
            rotate: -45,
            trim: true,
            maxHeight: 60,
          },
          axisBorder: { show: false },
          axisTicks: { show: false },
        },
        yaxis: {
          labels: { style: { fontSize: "10px" } },
          tickAmount: 4,
        },
        grid: {
          borderColor: "#e2e8f0",
          strokeDashArray: 4,
          xaxis: { lines: { show: false } },
        },
      }

      const chart = new ApexCharts(container, options)
      chart.render()
    })
  }

  contentHTML() {
    const c = this.company
    const counts = this.counts || {}
    const resources = [
      { key: "products",  label: translate("Products"),  icon: "inventory_2" },
      { key: "stocks",    label: translate("Stocks"),    icon: "warehouse" },
      { key: "services",  label: translate("Services"),  icon: "concierge" },
      { key: "orders",    label: translate("Orders"),    icon: "receipt_long" },
      { key: "employees", label: translate("Employees"), icon: "badge" },
    ]

    const total = (key) => {
      const data = counts[key] || {}
      return Object.values(data).reduce((sum, v) => sum + v, 0)
    }

    const statusBadge = (status) => {
      const colors = {
        active: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
        inactive: "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400",
        suspended: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400",
        draft: "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400",
        pending: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400",
        confirmed: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
        completed: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
        paid: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
        cancelled: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
      }
      const s = status || "inactive"
      return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md ${colors[s] || colors.inactive}">${s.replace("_", " ").replace(/\b\w/g, (l) => l.toUpperCase())}</span>`
    }

    const businessTypeBadge = (type) => {
      const colors = {
        retail: "bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400",
        restaurant: "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400",
        hospital: "bg-rose-100 text-rose-700 dark:bg-rose-900/30 dark:text-rose-400",
        education: "bg-cyan-100 text-cyan-700 dark:bg-cyan-900/30 dark:text-cyan-400",
        hotel: "bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-400",
        fitness: "bg-lime-100 text-lime-700 dark:bg-lime-900/30 dark:text-lime-400",
      }
      const t = type || "retail"
      return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md ${colors[t] || colors.retail}">${t.replace(/_/g, " ").replace(/\b\w/g, (l) => l.toUpperCase())}</span>`
    }

    return `
      <div class="p-4 overflow-y-auto space-y-6">
        <!-- Company Profile Card -->
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div class="p-6">
            <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
              <div class="flex items-center gap-4">
                <div class="size-14 shrink-0 rounded-xl bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                  <span class="material-symbols-outlined text-3xl text-blue-600 dark:text-blue-400">business</span>
                </div>
                <div>
                  <h2 class="text-2xl font-black text-slate-900 dark:text-white">${c?.name || translate("Company")}</h2>
                  <div class="flex flex-wrap items-center gap-2 mt-1">
                    ${c?.code ? `<span class="font-mono text-xs bg-slate-100 dark:bg-slate-800 px-2 py-0.5 rounded text-slate-500 dark:text-slate-400">${c.code}</span>` : ""}
                    ${businessTypeBadge(c?.business_type)}
                    ${c?.workflow_status ? statusBadge(c.workflow_status) : ""}
                    ${c?.lifecycle_status ? statusBadge(c.lifecycle_status) : ""}
                  </div>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mt-6 pt-6 border-t border-slate-200 dark:border-slate-700">
              <div class="flex items-center gap-3">
                <div class="size-9 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500">
                  <span class="material-symbols-outlined text-[18px]">location_on</span>
                </div>
                <div class="min-w-0">
                  <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">${translate("Address")}</p>
                  <p class="text-sm text-slate-900 dark:text-white truncate">${[c?.address_line_1, c?.city, c?.postal_code].filter(Boolean).join(", ") || "—"}</p>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <div class="size-9 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500">
                  <span class="material-symbols-outlined text-[18px]">call</span>
                </div>
                <div class="min-w-0">
                  <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">${translate("Phone")}</p>
                  <p class="text-sm text-slate-900 dark:text-white">${c?.phone_number || "—"}</p>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <div class="size-9 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500">
                  <span class="material-symbols-outlined text-[18px]">mail</span>
                </div>
                <div class="min-w-0">
                  <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">${translate("Email")}</p>
                  <p class="text-sm text-slate-900 dark:text-white truncate">${c?.email || "—"}</p>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <div class="size-9 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500">
                  <span class="material-symbols-outlined text-[18px]">language</span>
                </div>
                <div class="min-w-0">
                  <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">${translate("Website")}</p>
                  <p class="text-sm text-slate-900 dark:text-white truncate">${c?.website || "—"}</p>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <div class="size-9 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500">
                  <span class="material-symbols-outlined text-[18px]">currency_exchange</span>
                </div>
                <div class="min-w-0">
                  <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">${translate("Currency")}</p>
                  <p class="text-sm text-slate-900 dark:text-white uppercase">${c?.currency_code || "—"}</p>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <div class="size-9 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500">
                  <span class="material-symbols-outlined text-[18px]">schedule</span>
                </div>
                <div class="min-w-0">
                  <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">${translate("Timezone")}</p>
                  <p class="text-sm text-slate-900 dark:text-white">${(() => { if (!c?.timezone) return "—"; const m = c.timezone.match(/minus_(\d+)/); if (m) return `UTC-${m[1]}`; const p = c.timezone.match(/plus_(\d+)/); if (p) return `UTC+${p[1]}`; return c.timezone === "utc" ? "UTC" : c.timezone; })()}</p>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <div class="size-9 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500">
                  <span class="material-symbols-outlined text-[18px]">person</span>
                </div>
                <div class="min-w-0">
                  <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">${translate("Owner")}</p>
                  <p class="text-sm text-slate-900 dark:text-white truncate">${c?.owner ? `${c.owner.first_name || ""} ${c.owner.last_name || ""}`.trim() || c.owner.email : "—"}</p>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <div class="size-9 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500">
                  <span class="material-symbols-outlined text-[18px]">calendar_today</span>
                </div>
                <div class="min-w-0">
                  <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">${translate("Created")}</p>
                  <p class="text-sm text-slate-900 dark:text-white">${c?.created_at ? new Date(c.created_at).toLocaleDateString() : "—"}</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Charts Grid -->
        <div data-${this.identifier}-target="chartsContainer" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          ${resources.map(({ key, label, icon }) => `
            <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-4">
              <div class="flex items-center justify-between mb-3">
                <div class="flex items-center gap-2">
                  <span class="material-symbols-outlined text-slate-500 dark:text-slate-400 text-[20px]">${icon}</span>
                  <h3 class="text-sm font-bold text-slate-700 dark:text-slate-300">${label}</h3>
                </div>
                <span class="text-xs font-bold text-slate-400 dark:text-slate-500 bg-slate-100 dark:bg-slate-800 px-2 py-0.5 rounded-md">${total(key)}</span>
              </div>
              <div data-chart="${key}"></div>
            </div>
          `).join("")}
        </div>
      </div>
    `
  }
}
