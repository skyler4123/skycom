import Admin_LayoutController from "controllers/admin/layout_controller"

export default class Admin_PromoCampaigns_ShowController extends Admin_LayoutController {
  /** @type {Object | null} */ promoCampaign = null
  /** @type {Array} */ promoGrants = []

  async connect() {
    super.connect()

    const campaignId = window.location.pathname.split("/")[3]

    try {
      const response = await fetchJson(`${Helpers.admin_promo_campaign_path(campaignId)}.json`)
      this.promoCampaign = response.promo_campaign
      this.promoGrants = response.promo_grants || []
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `Failed to load campaign${__errDetail ? ": " + __errDetail : ""}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  async runNow() {
    try {
      const response = await fetchJson(Helpers.run_now_admin_promo_campaign_path(this.promoCampaign.id), { method: "POST" })
      this.promoCampaign = response.promo_campaign
      this.renderContent()
      toast({ type: "success", message: response.message || "Campaign executed" })
      const fresh = await fetchJson(`${Helpers.admin_promo_campaign_path(this.promoCampaign.id)}.json`)
      this.promoCampaign = fresh.promo_campaign
      this.promoGrants = fresh.promo_grants || []
      this.renderContent()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Failed to run campaign" })
    }
  }

  async cancelCampaign() {
    try {
      const response = await fetchJson(Helpers.cancel_admin_promo_campaign_path(this.promoCampaign.id), { method: "POST" })
      this.promoCampaign = response.promo_campaign
      this.renderContent()
      toast({ type: "success", message: response.message || "Campaign cancelled" })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Failed to cancel campaign" })
    }
  }

  contentHTML() {
    const c = this.promoCampaign
    if (!c) return '<div class="p-8 text-center">Campaign not found.</div>'

    const fmtLocalWithOffset = (v) => {
      const d = new Date(v)
      if (isNaN(d)) return "—"
      const pad = (n) => String(n).padStart(2, "0")
      const off = -d.getTimezoneOffset()
      const sign = off >= 0 ? "+" : "-"
      return `${d.toLocaleString()} (${sign}${pad(Math.floor(Math.abs(off) / 60))}:${pad(Math.abs(off) % 60)})`
    }

    const stats = c.stats || {}
    const canAct = c.status === "draft" || c.status === "scheduled"
    const grantColumns = [
      { key: "company_name", name: translate("Company") },
      { key: "granted_amount", name: translate("Amount") },
      { key: "promo_before", name: "Before" },
      { key: "promo_after", name: "After" }
    ]

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.admin_promo_campaigns_path()}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-300 mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            Back to ${translate("Promotions")}
          </a>

          <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-4 mb-6">
            <div>
              <h2 class="text-2xl font-black text-slate-900 dark:text-white">${c.name || "Unnamed"}</h2>
              <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">${c.description || ""}</p>
              <div class="mt-2">${Helpers.statusBadge(c.status)}</div>
            </div>
            <div class="flex gap-2">
              ${canAct ? `
                <button
                  type="button"
                  data-action="click->${this.identifier}#runNow"
                  class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-medium text-sm cursor-pointer">
                  ${translate("Run Now")}
                </button>
                <a href="${Helpers.edit_admin_promo_campaign_path(c.id)}"
                  class="inline-flex items-center px-4 py-2 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300 rounded-lg font-medium text-sm cursor-pointer">
                  Edit
                </a>
                <button
                  type="button"
                  data-action="click->${this.identifier}#cancelCampaign"
                  class="px-4 py-2 bg-red-50 hover:bg-red-100 text-red-600 rounded-lg font-medium text-sm cursor-pointer">
                  Cancel
                </button>` : ""}
            </div>
          </div>

          <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 border-t border-slate-200 dark:border-slate-800 pt-6">
            <div>
              <p class="text-xs font-medium text-slate-500 dark:text-slate-400">Amount</p>
              <p class="text-lg font-bold font-mono text-emerald-600 dark:text-emerald-400">${Number(c.amount || 0).toLocaleString()}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500 dark:text-slate-400">Max Cap</p>
              <p class="text-lg font-bold font-mono text-slate-900 dark:text-white">${Number(c.max_cap || 0).toLocaleString()}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500 dark:text-slate-400">${translate("Scheduled At")} (local)</p>
              <p class="text-sm font-semibold text-slate-900 dark:text-white">${c.scheduled_at ? fmtLocalWithOffset(c.scheduled_at) : "—"}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500 dark:text-slate-400">Matched / Granted / Skipped</p>
              <p class="text-sm font-semibold text-slate-900 dark:text-white">${stats.matched ?? "—"} / ${stats.granted ?? "—"} / ${stats.skipped ?? "—"}</p>
            </div>
          </div>

          <div class="border-t border-slate-200 dark:border-slate-800 pt-6 mt-6">
            <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase mb-4">Grants (${this.promoGrants.length})</h3>
            <div class="overflow-x-auto">
              ${table({
                rows: this.promoGrants,
                columns: grantColumns,
                identifier: this.identifier,
                target: "promoGrantsList",
                mappingLookup: {},
                renderers: {
                  granted_amount: (value) => `<span class="font-mono text-sm font-medium text-emerald-600 dark:text-emerald-400">+${Number(value || 0).toLocaleString()}</span>`,
                  promo_before: (value) => `<span class="font-mono text-sm text-slate-500 dark:text-slate-400">${Number(value || 0).toLocaleString()}</span>`,
                  promo_after: (value) => `<span class="font-mono text-sm text-slate-900 dark:text-white">${Number(value || 0).toLocaleString()}</span>`
                }
              })}
            </div>
          </div>
        </div>
      </div>
    `
  }
}
