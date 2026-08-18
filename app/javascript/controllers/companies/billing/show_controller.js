import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Billing_ShowController extends Companies_LayoutController {
  /** @type {object | null} */ wallet = null
  /** @type {Array} */ orders = []

  async connect() {
    super.connect()

    poll(() => {
      if (currentCompany()) {
        this.loadData()
        return true
      }
      return false
    })
  }

  async loadData() {
    try {
      const response = await fetchJson(`${Helpers.company_billing_path(currentCompany().id)}.json`)
      this.wallet = response.wallet
      this.orders = response.orders || []
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load billing data") })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  formatCents(cents) {
    const currency = this.wallet?.currency || "usd"
    if (currency === "vnd") {
      return `${Number(cents || 0).toLocaleString("vi-VN")}₫`
    }
    const dollars = Number(cents || 0) / 100
    return `$${dollars.toLocaleString("en-US", { minimumFractionDigits: 2 })}`
  }

  formatCredits(value) {
    return Number(value || 0).toLocaleString("en-US")
  }

  shortId(id) {
    return (id || "").toString().slice(0, 8)
  }

  contentHTML() {
    const balance = this.formatCredits(this.wallet?.credit_balance)

    const rows = this.orders.length > 0
      ? this.orders.map(o => {
          const invoice = o.invoice
          const transactions = invoice?.transactions || []
          return `
            <tr class="border-b border-slate-100 dark:border-slate-800">
              <td class="py-4 px-4 text-sm">
                <p class="font-mono text-xs text-slate-500 dark:text-slate-400">${this.shortId(o.id)}</p>
                <p class="text-xs text-slate-400 dark:text-slate-500">${o.created_at ? new Date(o.created_at).toLocaleDateString() : "—"}</p>
              </td>
              <td class="py-4 px-4 text-sm font-semibold text-slate-900 dark:text-white">${this.formatCents(o.money_amount_cents)}</td>
              <td class="py-4 px-4 text-sm font-mono text-emerald-600 dark:text-emerald-400">${this.formatCredits(o.credit_amount)}</td>
              <td class="py-4 px-4 text-sm">
                ${invoice
                  ? `<p class="font-mono text-xs text-slate-600 dark:text-slate-300">${invoice.invoice_number}</p>${Helpers.statusBadge(invoice.payment_status)}`
                  : `<span class="text-xs text-slate-400">${translate("No invoice")}</span>`}
              </td>
              <td class="py-4 px-4 text-sm">
                ${transactions.length > 0
                  ? transactions.map(t => `
                      <div class="flex items-center gap-2 py-0.5">
                        <span class="text-xs text-slate-600 dark:text-slate-300">${t.billing_payment_method || "—"}</span>
                        ${Helpers.statusBadge(t.status)}
                        <span class="font-mono text-[10px] text-slate-400 truncate max-w-[120px]">${t.gateway_reference || ""}</span>
                      </div>
                    `).join("")
                  : `<span class="text-xs text-slate-400">—</span>`}
              </td>
            </tr>
          `
        }).join("")
      : `
        <tr>
          <td colspan="5" class="py-10 text-center text-sm text-slate-400">${translate("No orders yet")}</td>
        </tr>
      `

    return `
      <div class="p-4 md:p-6 overflow-y-auto space-y-6">
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-5">
          <div class="flex items-center gap-3">
            <div class="size-10 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <span class="material-symbols-outlined text-[22px]">account_balance_wallet</span>
            </div>
            <div>
              <p class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">${translate("Credit Balance")}</p>
              <p class="text-xl font-black text-slate-900 dark:text-white">${balance}</p>
            </div>
          </div>
        </div>

        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden">
          <div class="px-4 py-3 border-b border-slate-100 dark:border-slate-800">
            <h3 class="text-sm font-bold text-slate-700 dark:text-slate-300">${translate("Order History")}</h3>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left">
              <thead>
                <tr class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase border-b border-slate-100 dark:border-slate-800">
                  <th class="py-3 px-4">${translate("Order")}</th>
                  <th class="py-3 px-4">${translate("Amount")}</th>
                  <th class="py-3 px-4">${translate("Credits")}</th>
                  <th class="py-3 px-4">${translate("Invoice")}</th>
                  <th class="py-3 px-4">${translate("Transactions")}</th>
                </tr>
              </thead>
              <tbody>${rows}</tbody>
            </table>
          </div>
        </div>
      </div>
    `
  }
}
