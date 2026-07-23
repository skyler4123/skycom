import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_PaymentMethodAppointments_EditController extends Companies_LayoutController {
  /** @type {{id: string, lifecycle_status: string, payment_method: {name: string, code: string, payment_mode: string, business_type: string}} | null} */
  appointment = null

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const companyId = pathParts[2]
    const appointmentId = pathParts[4]

    try {
      const response = await fetchJson(`${Helpers.edit_company_payment_method_appointment_path(companyId, appointmentId)}.json`)
      this.appointment = response.payment_method_appointment
    } catch (error) {
      toast({ type: "error", message: "Failed to load payment method" })
    }

    this.renderContent()
  }

  contentHTML() {
    const a = this.appointment
    if (!a) return '<div class="p-8 text-center text-slate-400">Payment method not found.</div>'

    const pm = a.payment_method
    const companyId = window.location.pathname.split("/")[2]

    const fields = `
      <div class="space-y-6">
        <div class="flex items-center gap-4 mb-6">
          <div class="w-12 h-12 rounded-xl bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
            <span class="material-symbols-outlined text-emerald-600 dark:text-emerald-400 text-[24px]">payments</span>
          </div>
          <div>
            <h2 class="text-xl font-bold text-slate-900 dark:text-white">${pm.name}</h2>
            <p class="text-sm text-slate-500">${pm.code}</p>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">Payment Mode</label>
            <p class="text-sm text-slate-900 dark:text-white font-medium">${pm.payment_mode}</p>
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">Business Type</label>
            <p class="text-sm text-slate-900 dark:text-white font-medium">${pm.business_type}</p>
          </div>
        </div>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-6 space-y-1">
          <label class="text-[10px] font-bold text-slate-400 uppercase">Status</label>
          <select name="payment_method_appointment[lifecycle_status]"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
            <option value="active" ${a.lifecycle_status === 'active' ? 'selected' : ''}>Enabled</option>
            <option value="inactive" ${a.lifecycle_status === 'inactive' ? 'selected' : ''}>Disabled</option>
          </select>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_payment_method_appointments_path(companyId)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
            Cancel
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            Save Changes
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${Helpers.form({
          action: Helpers.company_payment_method_appointment_path(companyId, a.id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 max-w-lg" data-turbo="false"`,
          html: fields
        })}
      </div>
    `
  }
}
