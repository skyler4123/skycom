import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_PaymentMethodAppointments_IndexController extends Companies_LayoutController {
  /** @type {Array<{id: string, name: string, code: string, payment_mode: string, lifecycle_status: string, strategy: string, merchant_number: string|null, merchant_name: string|null, merchant_id: string|null}>} */
  paymentMethodAppointments = []

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(Helpers.company_payment_method_appointments_path(currentCompany().id))
      this.paymentMethodAppointments = response.payment_method_appointments || []
    } catch (error) {
      toast({ type: "error", message: "Failed to load payment methods" })
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
    const rows = this.paymentMethodAppointments.length > 0
      ? this.paymentMethodAppointments.map(pma => {
        const hasBanking = pma.payment_mode !== 'cash' && (pma.merchant_number || pma.merchant_name || pma.merchant_id)
        const bankingLabel = pma.payment_mode === 'cash' ? '—'
          : hasBanking ? `<span class="text-success font-medium">${translate("Configured")}</span>`
          : `<span class="text-warning font-medium">${translate("Not Set")}</span>`
        return `
        <tr class="border-b border-line last:border-0">
          <td class="py-4 px-6 text-sm font-medium text-foreground">${pma.name}</td>
          <td class="py-4 px-6 text-sm text-muted-foreground">${pma.code}</td>
          <td class="py-4 px-6 text-sm text-muted-foreground">${pma.payment_mode}</td>
          <td class="py-4 px-6 text-sm">${bankingLabel}</td>
          <td class="py-4 px-6">${Helpers.statusBadge(pma.lifecycle_status === 'active' ? 'active' : 'inactive')}</td>
          <td class="py-4 px-6 text-right">
            <a href="${Helpers.edit_company_payment_method_appointment_path(currentCompany().id, pma.id)}"
              class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">edit</span>
            </a>
          </td>
        </tr>
      `}).join('')
      : `<tr><td colspan="6" class="py-8 text-center text-sm text-muted-foreground">No payment methods available for your region.</td></tr>`

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <h2 class="text-xl font-bold text-foreground mb-6">Payment Methods</h2>
          <p class="text-sm text-muted-foreground mb-6">Manage which payment methods are enabled for your business.</p>

          <div class="overflow-x-auto">
            <table class="w-full">
              <thead>
                <tr class="border-b border-line">
                  <th class="py-3 px-6 text-left text-xs font-bold text-muted-foreground uppercase tracking-wider">${translate("Name")}</th>
                  <th class="py-3 px-6 text-left text-xs font-bold text-muted-foreground uppercase tracking-wider">${translate("Code")}</th>
                  <th class="py-3 px-6 text-left text-xs font-bold text-muted-foreground uppercase tracking-wider">${translate("Mode")}</th>
                  <th class="py-3 px-6 text-left text-xs font-bold text-muted-foreground uppercase tracking-wider">${translate("Banking")}</th>
                  <th class="py-3 px-6 text-left text-xs font-bold text-muted-foreground uppercase tracking-wider">${translate("Status")}</th>
                  <th class="py-3 px-6 text-right text-xs font-bold text-muted-foreground uppercase tracking-wider">${translate("Actions")}</th>
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
