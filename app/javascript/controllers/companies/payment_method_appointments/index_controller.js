import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_PaymentMethodAppointments_IndexController extends Companies_LayoutController {
  /** @type {Array<{id: string, name: string, code: string, payment_mode: string, lifecycle_status: string, strategy: string}>} */
  paymentMethodAppointments = []

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(Helpers.company_payment_method_appointments_path(currentCompany().id))
      this.paymentMethodAppointments = response.payment_method_appointments || []
    } catch (error) {
      toast({ type: "error", message: "Failed to load payment methods" })
    }

    this.renderContent()
  }

  contentHTML() {
    const rows = this.paymentMethodAppointments.length > 0
      ? this.paymentMethodAppointments.map(pma => `
        <tr class="border-b border-slate-100 dark:border-slate-800 last:border-0">
          <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">${pma.name}</td>
          <td class="py-4 px-6 text-sm text-slate-500 dark:text-slate-400">${pma.code}</td>
          <td class="py-4 px-6 text-sm text-slate-500 dark:text-slate-400">${pma.payment_mode}</td>
          <td class="py-4 px-6">${Helpers.statusBadge(pma.lifecycle_status === 'active' ? 'active' : 'inactive')}</td>
          <td class="py-4 px-6 text-right">
            <a href="${Helpers.edit_company_payment_method_appointment_path(currentCompany().id, pma.id)}"
              class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">edit</span>
            </a>
          </td>
        </tr>
      `).join('')
      : `<tr><td colspan="5" class="py-8 text-center text-sm text-slate-400">No payment methods available for your region.</td></tr>`

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <h2 class="text-xl font-bold text-slate-900 dark:text-white mb-6">Payment Methods</h2>
          <p class="text-sm text-slate-500 dark:text-slate-400 mb-6">Manage which payment methods are enabled for your business.</p>

          <div class="overflow-x-auto">
            <table class="w-full">
              <thead>
                <tr class="border-b border-slate-200 dark:border-slate-700">
                  <th class="py-3 px-6 text-left text-xs font-bold text-slate-400 uppercase tracking-wider">Name</th>
                  <th class="py-3 px-6 text-left text-xs font-bold text-slate-400 uppercase tracking-wider">Code</th>
                  <th class="py-3 px-6 text-left text-xs font-bold text-slate-400 uppercase tracking-wider">Mode</th>
                  <th class="py-3 px-6 text-left text-xs font-bold text-slate-400 uppercase tracking-wider">Status</th>
                  <th class="py-3 px-6 text-right text-xs font-bold text-slate-400 uppercase tracking-wider">Actions</th>
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
