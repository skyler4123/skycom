import Admin_LayoutController from "controllers/admin/layout_controller"

export default class Admin_PromoCampaigns_IndexController extends Admin_LayoutController {
  static targets = ["promoCampaignsList"]

  /** @type {Array} */ promoCampaigns = []
  /** @type {Object} */ pagination = {}

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(Helpers.admin_promo_campaigns_path())
      this.promoCampaigns = response.promo_campaigns || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `Failed to load promotions${__errDetail ? ": " + __errDetail : ""}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  contentHTML() {
    const columns = [
      { key: "name", name: translate("Promotion Campaign") },
      { key: "amount", name: translate("Amount") },
      { key: "max_cap", name: translate("Max Cap") },
      { key: "status", name: "Status" },
      { key: "scheduled_at", name: `${translate("Scheduled At")} (UTC)` },
      { key: "created_at", name: "Created (UTC)" }
    ]

    return `
      <div class="p-6">
        <div class="bg-card rounded-xl border border-line">
          <div class="flex items-center justify-between px-6 py-4 border-b border-line">
            <h2 class="text-base font-bold text-foreground">${translate("Promotions")}</h2>
            <a href="${Helpers.new_admin_promo_campaign_path()}"
              class="inline-flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm cursor-pointer">
              <span class="material-symbols-outlined text-[18px]!">add</span>
              ${translate("New Promotion Campaign")}
            </a>
          </div>
          <div class="overflow-x-auto">
            ${table({
              rows: this.promoCampaigns,
              columns,
              identifier: this.identifier,
              target: "promoCampaignsList",
              mappingLookup: {},
              renderers: {
                name: (value, record) => `
                  <a href="${Helpers.admin_promo_campaign_path(record.id)}"
                    class="font-medium text-foreground hover:text-primary transition-colors cursor-pointer">
                    ${value || "Unnamed"}
                  </a>`,
                amount: (value) => `<span class="font-mono text-sm font-medium text-success ">${Number(value || 0).toLocaleString()}</span>`,
                max_cap: (value) => `<span class="font-mono text-sm text-muted-foreground">${Number(value || 0).toLocaleString()}</span>`,
                status: (value) => `${Helpers.statusBadge(value)}`,
                scheduled_at: (value) => value ? `<span class="text-sm text-muted-foreground" title="UTC time">${Helpers.timeFormat(value)}</span>` : "—",
                created_at: (value) => value ? `<span class="text-sm text-muted-foreground">${Helpers.timeFormat(value)}</span>` : "—"
              },
              renderActions: (record) => `
                <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                  <a href="${Helpers.admin_promo_campaign_path(record.id)}"
                    class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer">
                    <span class="material-symbols-outlined text-[20px]">visibility</span>
                  </a>
                </td>`
            })}
          </div>
          <div class="flex justify-center py-4 border-t border-line">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}
