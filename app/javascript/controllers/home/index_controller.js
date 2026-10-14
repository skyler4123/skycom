import { Controller } from "@hotwired/stimulus"
import ApexCharts from "apexcharts"

const TICK_MS = 2000
const POOL_CAP = 10000

export default class Home_IndexController extends Controller {
  static targets = ["velocityChart"]

  /** @type {ApexCharts | null} */ chart = null
  /** @type {number | null} */ tickerId = null
  /** @type {{ sales: number, txns: number, credits: number, pool: number }} */
  live = { sales: 18450, txns: 248, credits: 34.2, pool: 9420 }
  /** @type {number[]} */ hourly = [920, 1680, 2840, 3920, 2650, 3420, 1890]

  connect() {
    this.renderSignedInHeader()
    if (this.hasVelocityChartTarget) this.renderChart()
    this.paintNumbers()
    this.startTicker()
  }

  disconnect() {
    this.stopTicker()
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  // Static HTML ships the signed-out header for SEO/cacheability. When the
  // browser holds a session (is_signed_in cookie), swap to the signed-in
  // header without a server round-trip. Cookie-only and synchronous, so the
  // swap is deterministic; the avatar paints a placeholder until the client
  // cache arrives, matching every other page.
  renderSignedInHeader() {
    if (!Helpers.isSignedIn()) return
    const guest = this.element.querySelector("#header-guest")
    const signedin = this.element.querySelector("#header-signedin")
    if (guest) guest.classList.add("hidden")
    if (signedin) {
      signedin.classList.remove("hidden")
      signedin.classList.add("flex")
    }
    this.revealAdminLink()
  }

  // Role needs the client cache, which arrives after connect — poll for it.
  // Admins see only Admin Dashboard; Go to Dashboard + New Company are
  // owner flows and stay visible for non-admins (shipped visible in ERB).
  revealAdminLink() {
    poll(() => {
      const role = currentUser()?.system_role
      if (!role) return false
      if (role === "super_admin" || role === "admin") {
        const adminLink = this.element.querySelector("#header-admin-link")
        if (adminLink) {
          adminLink.classList.remove("hidden")
          adminLink.classList.add("inline-flex")
        }
        for (const id of ["#header-dashboard-link", "#header-new-company-link"]) {
          const el = this.element.querySelector(id)
          if (el) {
            el.classList.add("hidden")
            el.classList.remove("inline-flex")
          }
        }
      }
      return true
    })
  }

  switchTenant(event) {
    event.preventDefault()
    const buttons = this.element.querySelectorAll('[data-tenant-tab="true"]')
    buttons.forEach((btn) => btn.setAttribute("aria-pressed", "false"))
    event.currentTarget.setAttribute("aria-pressed", "true")
    const title = this.element.querySelector("#tenant-title")
    if (title && event.params?.tenantName) title.textContent = event.params.tenantName
    if (event.params?.baseSales) this.live.sales = Number(event.params.baseSales)
    if (event.params?.baseTxns) this.live.txns = Number(event.params.baseTxns)
    if (event.params?.baseCredits) this.live.credits = Number(event.params.baseCredits)
    this.paintNumbers()
  }

  renderChart() {
    const categories = ["08:00", "10:00", "12:00", "14:00", "16:00", "18:00", "20:00"]
    const colors = categories.map((_, i) => (i === 3 ? "#4F46E5" : "#C7D2FE"))
    const options = {
      series: [{ name: "Sales", data: this.hourly }],
      chart: { height: 176, type: "bar", toolbar: { show: false }, animations: { enabled: true, dynamicAnimation: { speed: 500 } } },
      colors,
      plotOptions: { bar: { columnWidth: "55%", distributed: true, borderRadius: 4 } },
      dataLabels: { enabled: false },
      legend: { show: false },
      tooltip: { y: { formatter: (val) => `$${Math.round(Number(val)).toLocaleString("en-US")} sales` } },
      xaxis: {
        categories,
        labels: { style: { fontSize: "11px" } },
        axisBorder: { show: false },
        axisTicks: { show: false }
      },
      yaxis: { labels: { style: { fontSize: "10px" }, formatter: (val) => Math.round(val).toLocaleString("en-US") }, tickAmount: 4 },
      grid: { borderColor: "#e2e8f0", strokeDashArray: 4, xaxis: { lines: { show: false } } }
    }
    this.chart = new ApexCharts(this.velocityChartTarget, options)
    this.chart.render()
  }

  startTicker() {
    this.stopTicker()
    if (window.matchMedia?.("(prefers-reduced-motion: reduce)").matches) return
    this.tickerId = window.setInterval(() => this.tick(), TICK_MS)
  }

  stopTicker() {
    if (this.tickerId !== null) {
      window.clearInterval(this.tickerId)
      this.tickerId = null
    }
  }

  tick() {
    if (document.hidden) return
    const newTxns = 1 + Math.floor(Math.random() * 3)
    const delta = Math.round(newTxns * (45 + Math.random() * 60) * 100) / 100
    this.live.txns += newTxns
    this.live.sales = Math.round((this.live.sales + delta) * 100) / 100
    this.live.credits = Math.round((this.live.credits + 0.1) * 10) / 10
    this.live.pool = Math.max(0, Math.round((this.live.pool - 0.1) * 10) / 10)
    this.hourly[this.hourly.length - 1] = Math.round(this.hourly[this.hourly.length - 1] + delta)
    if (this.chart) this.chart.updateSeries([{ data: this.hourly }])
    this.paintNumbers()
    this.setLive("latency", `${100 + Math.floor(Math.random() * 25)}ms`)
  }

  paintNumbers() {
    this.setLive("sales", `$${this.live.sales.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`)
    this.setLive("txns", `${this.live.txns.toLocaleString("en-US")} transactions`)
    this.setLive("credits", this.live.credits.toFixed(1))
    this.setLive("pool", Math.floor(this.live.pool).toLocaleString("en-US"))
    this.setLive("burn", `${this.live.credits.toFixed(1)} cr today`)
    this.setLive("pool2", `Master Balance: ${Math.floor(this.live.pool).toLocaleString("en-US")} / ${POOL_CAP.toLocaleString("en-US")} cr remaining`)
  }

  setLive(name, text) {
    this.element.querySelectorAll(`[data-live="${name}"]`).forEach((el) => { el.textContent = text })
  }
}
