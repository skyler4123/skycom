import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_TopUps_NewController extends Companies_LayoutController {
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
    const cid = currentCompany()?.id

    return `
      <div class="p-4 md:p-6 overflow-y-auto">
        <div class="max-w-2xl mx-auto p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_billing_path(cid)}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]">arrow_back</span>
            ${translate("Back to Billing")}
          </a>

          <div class="space-y-6">
            <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Top Up Wallet")}</h2>
            <p class="text-sm text-slate-500">${translate("Add funds to your wallet to cover overage charges and feature add-ons.")}</p>

            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Amount")}</label>
              <input type="number" id="top-up-amount" min="1" step="1" required placeholder="e.g. 1000"
                class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white" />
            </div>

            <button type="button" data-action="click->${this.identifier}#submitPlaceholder"
              class="w-full px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer transition-colors">
              ${translate("Confirm Top Up")}
            </button>
          </div>
        </div>
      </div>
    `
  }

  submitPlaceholder(event) {
    event.preventDefault()
    toast({ type: "info", message: translate("Top-up feature coming soon") })
  }
}
