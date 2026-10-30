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
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.admin_promo_campaigns_path()}"
            class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            Back to ${translate("Promotions")}
          </a>

          <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-4 mb-6">
            <div>
              <h2 class="text-2xl font-black text-foreground">${c.name || "Unnamed"}</h2>
              <p class="text-sm text-muted-foreground mt-1">${c.description || ""}</p>
              <div class="mt-2">${Helpers.statusBadge(c.status)}</div>
            </div>
            <div class="flex gap-2">
              ${canAct ? `
                <button
                  type="button"
                  data-action="click->${this.identifier}#runNow"
                  class="px-4 py-2 bg-success hover:bg-success/90 text-success-foreground rounded-lg font-medium text-sm cursor-pointer">
                  ${translate("Run Now")}
                </button>
                <a href="${Helpers.edit_admin_promo_campaign_path(c.id)}"
                  class="inline-flex items-center px-4 py-2 bg-muted hover:bg-muted text-foreground rounded-lg font-medium text-sm cursor-pointer">
                  Edit
                </a>
                <button
                  type="button"
                  data-action="click->${this.identifier}#cancelCampaign"
                  class="px-4 py-2 bg-danger/10 hover:bg-danger/10 text-danger rounded-lg font-medium text-sm cursor-pointer">
                  Cancel
                </button>` : ""}
            </div>
          </div>

          <div class="border-t border-line pt-6 mt-6">
            <h3 class="text-sm font-bold text-muted-foreground uppercase mb-4">${translate("Notification Preview")}</h3>
            <div class="p-4 bg-muted rounded-lg border border-line">
              <p class="text-sm font-bold text-foreground">${c.title || "—"}</p>
              <p class="text-sm text-muted-foreground mt-1">${c.body || "—"}</p>
            </div>
          </div>

          <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 border-t border-line pt-6 mt-6">
            <div>
              <p class="text-xs font-medium text-muted-foreground">Amount</p>
              <p class="text-lg font-bold font-mono text-success ">${Number(c.amount || 0).toLocaleString()}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">Max Cap</p>
              <p class="text-lg font-bold font-mono text-foreground">${Number(c.max_cap || 0).toLocaleString()}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Scheduled At")} (UTC)</p>
              <p class="text-sm font-semibold text-foreground">${c.scheduled_at ? Helpers.timeFormat(c.scheduled_at) : "—"}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">Matched / Granted / Skipped</p>
              <p class="text-sm font-semibold text-foreground">${stats.matched ?? "—"} / ${stats.granted ?? "—"} / ${stats.skipped ?? "—"}</p>
            </div>
          </div>

          <div class="border-t border-line pt-6 mt-6">
            <h3 class="text-sm font-bold text-muted-foreground uppercase mb-4">Grants (${this.promoGrants.length})</h3>
            <div class="overflow-x-auto">
              ${table({
                rows: this.promoGrants,
                columns: grantColumns,
                identifier: this.identifier,
                target: "promoGrantsList",
                mappingLookup: {},
                renderers: {
                  granted_amount: (value) => `<span class="font-mono text-sm font-medium text-success ">+${Number(value || 0).toLocaleString()}</span>`,
                  promo_before: (value) => `<span class="font-mono text-sm text-muted-foreground">${Number(value || 0).toLocaleString()}</span>`,
                  promo_after: (value) => `<span class="font-mono text-sm text-foreground">${Number(value || 0).toLocaleString()}</span>`
                }
              })}
            </div>
          </div>
        </div>
      </div>
    `
  }
}
