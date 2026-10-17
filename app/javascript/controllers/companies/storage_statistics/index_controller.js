import Companies_LayoutController from "controllers/companies/layout_controller"
import ApexCharts from "apexcharts"

// Storage Statistics overview — company-wide usage totals with two
// ApexCharts donuts (size and file count per type) plus a breakdown table.
// The backend caches the payload 1 hour in local_cache; uploads/deletes do
// not bust it (accepted staleness — see docs/STORAGE.md).
// Depends on BE: Companies::StorageStatisticsController#index
// Endpoints: GET <pathname>.json
// Docs: docs/STORAGE.md
export default class Companies_StorageStatistics_IndexController extends Companies_LayoutController {
  static targets = ["sizeChart", "countChart"]

  TYPE_LABELS = { image: "Image", pdf: "PDF", office: "Office", text: "Text", archive: "Archive" }
  CHART_COLORS = ["#4F46E5", "#22C55E", "#F59E0B", "#EF4444", "#06B6D4"]

  /** @type {StorageStatistics} */ stats = { total_size: 0, total_files: 0, total_folders: 0, by_type: [] }
  /** @type {ApexCharts[]} */ charts = []

  async connect() {
    super.connect()

    try {
      /** @type {StorageStatistics} */
      const response = await fetchJson(`${pathname()}.json`)
      this.stats = response
    } catch (error) {
      toast({ type: "error", message: `${translate("Failed to load storage statistics")}: ${error.errors?.join(", ") || error.message}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.contentTarget.classList.add("flex", "flex-col", "flex-1")
        this.renderContent()
        if (this.stats.total_files > 0) setTimeout(() => this.renderCharts(), 150)
        return true
      }
      return false
    })
  }

  typeLabel(type) {
    return translate(this.TYPE_LABELS[type] || type)
  }

  humanSize(bytes) {
    const n = Number(bytes) || 0
    if (n < 1024) return `${n} B`
    if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`
    if (n < 1024 ** 3) return `${(n / (1024 * 1024)).toFixed(1)} MB`
    if (n < 1024 ** 4) return `${(n / 1024 ** 3).toFixed(1)} GB`
    return `${(n / 1024 ** 4).toFixed(1)} TB`
  }

  contentHTML() {
    const s = this.stats

    return `
      <div class="p-4 md:p-6 flex-1">
        <h1 class="text-2xl font-black text-slate-900 dark:text-white mb-6">${translate("Storage Statistics")}</h1>

        <div class="grid grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
          ${this.statCard("total_size", translate("Total Used"), this.humanSize(s.total_size), "hard_drive")}
          ${this.statCard("total_files", translate("Total Files"), s.total_files, "description")}
          ${this.statCard("total_folders", translate("Total Folders"), s.total_folders, "folder")}
        </div>

        ${s.total_files > 0 ? this.chartsHTML() : this.emptyHTML()}

        ${this.breakdownHTML()}
      </div>
    `
  }

  statCard(key, label, value, icon) {
    return `
      <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-5">
        <div class="flex items-center gap-2 mb-2">
          <span class="material-symbols-outlined text-[18px] text-slate-400 dark:text-slate-500">${icon}</span>
          <span class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">${label}</span>
        </div>
        <p class="text-2xl font-black text-slate-900 dark:text-white" data-statistic="${key}">${value}</p>
      </div>
    `
  }

  chartsHTML() {
    return `
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-5">
          <h2 class="text-lg font-bold text-slate-900 dark:text-white mb-4">${translate("Storage by Type")}</h2>
          <div data-chart-container="size" data-${this.identifier}-target="sizeChart" class="h-72"></div>
        </div>
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-5">
          <h2 class="text-lg font-bold text-slate-900 dark:text-white mb-4">${translate("Files by Type")}</h2>
          <div data-chart-container="count" data-${this.identifier}-target="countChart" class="h-72"></div>
        </div>
      </div>
    `
  }

  emptyHTML() {
    return `
      <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-10 mb-6 flex flex-col items-center gap-2">
        <span class="material-symbols-outlined text-[40px] text-slate-300 dark:text-slate-600">folder_open</span>
        <p class="text-sm text-slate-400 dark:text-slate-500">${translate("No files yet")}</p>
      </div>
    `
  }

  breakdownHTML() {
    const s = this.stats

    return `
      <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-5">
        <h2 class="text-lg font-bold text-slate-900 dark:text-white mb-4">${translate("Breakdown by Type")}</h2>
        <table class="w-full text-sm">
          <thead>
            <tr class="text-left text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase border-b border-slate-200 dark:border-slate-700">
              <th class="py-2 font-bold">${translate("Type")}</th>
              <th class="py-2 font-bold">${translate("Files")}</th>
              <th class="py-2 font-bold">${translate("Size")}</th>
              <th class="py-2 font-bold">${translate("Share")}</th>
            </tr>
          </thead>
          <tbody>
            ${(s.by_type || []).map((bucket) => this.breakdownRow(bucket, s.total_size)).join("")}
          </tbody>
        </table>
      </div>
    `
  }

  breakdownRow(bucket, totalSize) {
    const share = totalSize > 0 ? ((bucket.size / totalSize) * 100).toFixed(1) : "0.0"

    return `
      <tr data-statistic-type="${bucket.type}" class="border-b border-slate-100 dark:border-slate-800 last:border-0">
        <td class="py-2.5 text-slate-700 dark:text-slate-300">${this.typeLabel(bucket.type)}</td>
        <td class="py-2.5 text-slate-700 dark:text-slate-300" data-statistic-count>${bucket.count}</td>
        <td class="py-2.5 text-slate-700 dark:text-slate-300" data-statistic-size>${this.humanSize(bucket.size)}</td>
        <td class="py-2.5 text-slate-500 dark:text-slate-400">${share}%</td>
      </tr>
    `
  }

  renderCharts() {
    if (!this.hasSizeChartTarget || !this.hasCountChartTarget) return

    const buckets = this.stats.by_type || []
    const labels = buckets.map((bucket) => this.typeLabel(bucket.type))

    this.buildChart(this.sizeChartTarget, labels, buckets.map((bucket) => bucket.size), {
      tooltip: { y: { formatter: (val) => this.humanSize(val) } }
    })
    this.buildChart(this.countChartTarget, labels, buckets.map((bucket) => bucket.count), {})
  }

  buildChart(container, labels, series, extraOptions) {
    const options = {
      chart: { type: "donut", height: 280, toolbar: { show: false } },
      series,
      labels,
      colors: this.CHART_COLORS,
      legend: { position: "bottom", fontSize: "12px" },
      dataLabels: { enabled: false },
      ...extraOptions
    }

    const chart = new ApexCharts(container, options)
    chart.render()
    container.dataset.chartSeries = JSON.stringify(series)
    this.charts.push(chart)
  }
}
