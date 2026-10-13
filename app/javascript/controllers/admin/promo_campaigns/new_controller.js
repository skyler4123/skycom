import Admin_LayoutController from "controllers/admin/layout_controller"

export default class Admin_PromoCampaigns_NewController extends Admin_LayoutController {
  connect() {
    super.connect()

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  contentHTML() {
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Promotion Campaign")}</h2>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">Name</label>
            <input type="text" name="promo_campaign[name]" required placeholder="e.g. Holiday Bonus"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">Description</label>
            <textarea name="promo_campaign[description]" rows="2"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm"></textarea>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Amount")}</label>
            <input type="number" step="1" min="1" name="promo_campaign[amount]" required placeholder="300"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Max Cap")}</label>
            <input type="number" step="1" min="1" name="promo_campaign[max_cap]" required placeholder="1000"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Scheduled At")} (local)</label>
            <input type="datetime-local" name="promo_campaign[scheduled_at]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
          </div>
        </div>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">Conditions</h3>
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase">Country</label>
              <select name="promo_campaign[conditions][country][]"
                class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
                <option value="">All countries</option>
                <option value="us">US</option>
                <option value="vn">VN</option>
              </select>
            </div>

            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase">Business Type</label>
              <select name="promo_campaign[conditions][business_type][]"
                class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
                <option value="">All types</option>
                <option value="retail">Retail</option>
                <option value="restaurant">Restaurant</option>
                <option value="hospital">Hospital</option>
                <option value="education">Education</option>
                <option value="hotel">Hotel</option>
                <option value="fitness">Fitness</option>
              </select>
            </div>

            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase">Employee Count Min</label>
              <input type="number" step="1" min="0" name="promo_campaign[conditions][employee_count_min]"
                class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
            </div>

            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase">Employee Count Max</label>
              <input type="number" step="1" min="0" name="promo_campaign[conditions][employee_count_max]"
                class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
            </div>

            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Promo Balance")} Min</label>
              <input type="number" step="1" min="0" name="promo_campaign[conditions][promo_balance_min]"
                class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
            </div>

            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Promo Balance")} Max</label>
              <input type="number" step="1" min="0" name="promo_campaign[conditions][promo_balance_max]"
                class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm">
            </div>

            <div class="col-span-2 space-y-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase">Company IDs (override other conditions)</label>
              <textarea name="promo_campaign[conditions][company_ids]" rows="2" placeholder="Paste company UUIDs, comma or newline separated (blank = all)"
                class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm font-mono"></textarea>
            </div>
          </div>
        </div>

        <div class="flex justify-end pt-6 border-t border-slate-200 dark:border-slate-700">
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
          action: Helpers.create_admin_promo_campaigns_path(),
          method: "POST",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false"`,
          html: fields
        })}
      </div>
    `
  }
}
