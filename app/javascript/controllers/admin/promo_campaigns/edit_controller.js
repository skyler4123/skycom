import Admin_LayoutController from "controllers/admin/layout_controller"

export default class Admin_PromoCampaigns_EditController extends Admin_LayoutController {
  /** @type {Object | null} */ promoCampaign = null

  async connect() {
    super.connect()

    const campaignId = window.location.pathname.split("/")[3]

    try {
      const response = await fetchJson(`${Helpers.admin_promo_campaign_path(campaignId)}.json`)
      this.promoCampaign = response.promo_campaign
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

  contentHTML() {
    const c = this.promoCampaign
    if (!c) return '<div class="p-8 text-center">Campaign not found.</div>'

    const conds = c.conditions || {}
    const scheduledValue = c.scheduled_at ? Helpers.timeFormat(c.scheduled_at, "YYYY-MM-DDTHH:mm") : ""

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Campaign")}</h2>
        <p class="text-sm text-slate-500 dark:text-slate-400">${c.name || ""}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">Name</label>
            <input type="text" name="promo_campaign[name]" value="${c.name || ""}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">Description</label>
            <textarea name="promo_campaign[description]" rows="2"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">${c.description || ""}</textarea>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Notification Title")}</label>
            <input type="text" name="promo_campaign[title]" value="${c.title || ""}" required placeholder="e.g. Skycom gave you 300 credits!"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Notification Body")}</label>
            <textarea name="promo_campaign[body]" rows="2" required placeholder="e.g. Promo 'Holiday Bonus' added 300 promo credits (cap 1000). Thank you for using Skycom! Here is our help to grow your business."
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">${c.body || ""}</textarea>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Amount")}</label>
            <input type="number" step="1" min="1" name="promo_campaign[amount]" value="${c.amount ?? ""}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Max Cap")}</label>
            <input type="number" step="1" min="1" name="promo_campaign[max_cap]" value="${c.max_cap ?? ""}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Scheduled At")} (UTC)</label>
            <input type="datetime-local" name="promo_campaign[scheduled_at]" value="${scheduledValue}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
          </div>
        </div>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">Conditions</h3>
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase">Country</label>
              <input type="text" name="promo_campaign[conditions][country][]" value="${(conds.country || []).join(",")}" placeholder="us (blank = all)"
                class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
            </div>

            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase">Business Type</label>
              <input type="text" name="promo_campaign[conditions][business_type][]" value="${(conds.business_type || []).join(",")}" placeholder="retail (blank = all)"
                class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
            </div>

            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase">Employee Count Min</label>
              <input type="number" step="1" min="0" name="promo_campaign[conditions][employee_count_min]" value="${conds.employee_count_min ?? ""}"
                class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
            </div>

            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase">Employee Count Max</label>
              <input type="number" step="1" min="0" name="promo_campaign[conditions][employee_count_max]" value="${conds.employee_count_max ?? ""}"
                class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
            </div>

            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Promo Balance")} Min</label>
              <input type="number" step="1" min="0" name="promo_campaign[conditions][promo_balance_min]" value="${conds.promo_balance_min ?? ""}"
                class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
            </div>

            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Promo Balance")} Max</label>
              <input type="number" step="1" min="0" name="promo_campaign[conditions][promo_balance_max]" value="${conds.promo_balance_max ?? ""}"
                class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
            </div>

            <div class="col-span-2 space-y-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase">Company IDs (override other conditions)</label>
              <textarea name="promo_campaign[conditions][company_ids]" rows="2" placeholder="Paste company UUIDs, comma or newline separated (blank = all)"
                class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm font-mono">${Array(conds.company_ids || []).join(", ")}</textarea>
            </div>
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-6 border-t border-slate-200 dark:border-slate-700">
          <a href="${Helpers.admin_promo_campaign_path(c.id)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg cursor-pointer">
            Cancel
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Campaign")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.admin_promo_campaign_path(c.id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
