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
    const fmtLocalWithOffset = (v) => {
      const d = new Date(v)
      const pad = (n) => String(n).padStart(2, "0")
      const off = -d.getTimezoneOffset()
      const sign = off >= 0 ? "+" : "-"
      return `${d.toLocaleString()} (${sign}${pad(Math.floor(Math.abs(off) / 60))}:${pad(Math.abs(off) % 60)})`
    }
    const columns = [
      { key: "name", name: translate("Promotion Campaign") },
      { key: "amount", name: translate("Amount") },
      { key: "max_cap", name: translate("Max Cap") },
      { key: "status", name: "Status" },
      { key: "scheduled_at", name: translate("Scheduled At") },
      { key: "created_at", name: "Created" }
    ]

    return `
      <div class="p-6">
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <div class="flex items-center justify-between px-6 py-4 border-b border-slate-200 dark:border-slate-800">
            <h2 class="text-base font-bold text-slate-900 dark:text-white">${translate("Promotions")}</h2>
            <a href="${Helpers.new_admin_promo_campaign_path()}"
              class="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer">
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
                    class="font-medium text-slate-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 transition-colors cursor-pointer">
                    ${value || "Unnamed"}
                  </a>`,
                amount: (value) => `<span class="font-mono text-sm font-medium text-emerald-600 dark:text-emerald-400">${Number(value || 0).toLocaleString()}</span>`,
                max_cap: (value) => `<span class="font-mono text-sm text-slate-600 dark:text-slate-400">${Number(value || 0).toLocaleString()}</span>`,
                status: (value) => `${Helpers.statusBadge(value)}`,
                scheduled_at: (value) => value ? `<span class="text-sm text-slate-500 dark:text-slate-400" title="Local time with UTC offset">${fmtLocalWithOffset(value)}</span>` : "—",
                created_at: (value) => value ? `<span class="text-sm text-slate-500 dark:text-slate-400">${new Date(value).toLocaleDateString()}</span>` : "—"
              },
              renderActions: (record) => `
                <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                  <a href="${Helpers.admin_promo_campaign_path(record.id)}"
                    class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg cursor-pointer">
                    <span class="material-symbols-outlined text-[20px]">visibility</span>
                  </a>
                </td>`
            })}
          </div>
          <div class="flex justify-center py-4 border-t border-slate-200 dark:border-slate-800">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}
