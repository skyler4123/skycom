import Admin_LayoutController from "controllers/admin/layout_controller"

export default class Admin_CompanyCredits_IndexController extends Admin_LayoutController {
  static targets = ["companyCreditsList"]

  /** @type {Array} */ companyCredits = []
  /** @type {Object} */ pagination = {}

  async connect() {
    super.connect()

    try {
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson(`${pathname()}.json?${urlParams.toString()}`)
      this.companyCredits = response.company_credits || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `Failed to load company credits${__errDetail ? ": " + __errDetail : ""}` })
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
    const urlParams = new URLSearchParams(window.location.search)
    const columns = [
      { key: "name", name: translate("Company") },
      { key: "code", name: "Code" },
      { key: "business_type", name: "Type" },
      { key: "main_credit_balance", name: "Main" },
      { key: "promo_credit_balance", name: "Promo" },
      { key: "debt_credit_balance", name: "Debt" },
      { key: "total_credit_balance", name: "Total" },
      { key: "owner_name", name: "Owner" }
    ]

    return `
      <div class="p-6">
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <div class="flex items-center justify-between px-6 py-4 border-b border-slate-200 dark:border-slate-800">
            <h2 class="text-base font-bold text-slate-900 dark:text-white">${translate("Company Credits")}</h2>
            <a href="${Helpers.admin_promo_campaigns_path()}"
              class="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer">
              <span class="material-symbols-outlined text-[18px]!">campaign</span>
              ${translate("Promotion")}
            </a>
          </div>
          <form method="get" action="${pathname()}" class="flex flex-wrap items-end gap-3 px-6 py-4 border-b border-slate-200 dark:border-slate-800">
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("Search")}</label>
              <input type="text" name="q" value="${urlParams.get("q") || ""}" placeholder="Name, code, email"
                class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Country</label>
              <input type="text" name="country" value="${urlParams.get("country") || ""}" placeholder="us, vn"
                class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Type</label>
              <input type="text" name="business_type" value="${urlParams.get("business_type") || ""}" placeholder="retail"
                class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
            </div>
            <div class="flex gap-2">
              <button type="submit" class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm flex items-center gap-2 cursor-pointer">
                <span class="material-symbols-outlined text-[18px]!">search</span>
                ${translate("Search")}
              </button>
            </div>
          </form>
          <div class="overflow-x-auto">
            ${table({
              rows: this.companyCredits,
              columns,
              identifier: this.identifier,
              target: "companyCreditsList",
              mappingLookup: {},
              renderers: {
                name: (value, record) => `<span class="font-medium text-slate-900 dark:text-white">${value || "Unnamed"}</span>`,
                code: (value) => `<span class="font-mono text-xs bg-slate-100 dark:bg-slate-800/60 px-2 py-0.5 rounded text-slate-600 dark:text-slate-300 font-medium">${value || "—"}</span>`,
                main_credit_balance: (value) => `<span class="font-mono text-sm text-slate-900 dark:text-white">${Number(value || 0).toLocaleString()}</span>`,
                promo_credit_balance: (value) => `<span class="font-mono text-sm font-medium text-emerald-600 dark:text-emerald-400">${Number(value || 0).toLocaleString()}</span>`,
                debt_credit_balance: (value) => `<span class="font-mono text-sm text-slate-500 dark:text-slate-400">${Number(value || 0).toLocaleString()}</span>`,
                total_credit_balance: (value) => `<span class="font-mono text-sm font-bold text-slate-900 dark:text-white">${Number(value || 0).toLocaleString()}</span>`,
                owner_name: (value) => value ? `<span class="text-sm text-slate-600 dark:text-slate-400">${value}</span>` : '<span class="text-slate-300 dark:text-slate-700">—</span>'
              }
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
