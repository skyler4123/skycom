import { Controller } from "@hotwired/stimulus"

export default class Companies_Branches_PaymentMethodAppointmentsModalController extends Controller {
  static values = {
    branchId: { type: String, default: "" }
  }

  /** @type {Array<{id: string, name: string, code: string, payment_mode: string, lifecycle_status: string, company_level_active: boolean}>} */
  appointments = []

  async connect() {
    this.element.innerHTML = this.loadingHTML()

    try {
      const url = `${Helpers.company_payment_method_appointments_path(currentCompany().id)}?branch_id=${this.branchIdValue}`
      const response = await fetchJson(url)
      this.appointments = response.payment_method_appointments || []
    } catch (error) {
      this.appointments = []
      this.loadError = error.errors?.join(", ") || translate("Failed to load payment methods")
    }

    this.element.innerHTML = this.contentHTML()
  }

  close() {
    closeModal()
  }

  async toggle(event) {
    const checkbox = event.target
    const id = checkbox.dataset.appointmentId
    const newStatus = checkbox.checked ? "active" : "inactive"
    const previousStatus = checkbox.checked ? "inactive" : "active"

    try {
      const response = await fetchJson(Helpers.company_payment_method_appointment_path(currentCompany().id, id), {
        method: "PATCH",
        body: { payment_method_appointment: { lifecycle_status: newStatus } }
      })

      reloadThenToast({ type: "success", message: response.message || translate("Payment method updated successfully") })
    } catch (error) {
      checkbox.checked = previousStatus === "active"
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update payment method") })
    }
  }

  loadingHTML() {
    return `
      <div class="p-8 bg-white dark:bg-slate-900 rounded-2xl w-[520px] shadow-2xl">
        <div class="flex items-center justify-center gap-3 py-10 text-slate-400 dark:text-slate-500">
          <span class="material-symbols-outlined animate-spin text-[20px]">progress_activity</span>
          <span class="text-sm">${translate("Loading...")}</span>
        </div>
      </div>
    `
  }

  contentHTML() {
    const rows = this.loadError ? this.errorHTML() : (this.appointments.length === 0 ? this.emptyHTML() : this.rowsHTML())

    return `
      <div class="p-8 bg-white dark:bg-slate-900 rounded-2xl w-[520px] max-h-[80vh] overflow-y-auto shadow-2xl border border-slate-200 dark:border-slate-800">
        <div class="flex items-start justify-between mb-6">
          <div>
            <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Payment Methods")}</h2>
            <p class="text-sm text-slate-500 mt-1">${translate("Manage payment methods for this branch")}</p>
          </div>
          <button
            type="button"
            data-action="click->${this.identifier}#close"
            class="rounded-full p-2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors cursor-pointer"
          >
            <span class="material-symbols-outlined text-[20px]">close</span>
          </button>
        </div>

        ${rows}

        <div class="flex justify-end pt-6 border-t border-slate-200 dark:border-slate-700 mt-6">
          <button
            type="button"
            data-action="click->${this.identifier}#close"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer"
          >
            ${translate("Close")}
          </button>
        </div>
      </div>
    `
  }

  rowsHTML() {
    return `
      <div class="space-y-3">
        ${this.appointments.map(a => this.rowHTML(a)).join('')}
      </div>
    `
  }

  rowHTML(a) {
    const active = a.lifecycle_status === "active"
    const companyLevelInactive = a.company_level_active === false
    const disabled = companyLevelInactive

    return `
      <div class="flex items-center justify-between gap-4 p-4 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50">
        <div class="min-w-0">
          <div class="flex items-center gap-2">
            <p class="text-sm font-semibold text-slate-900 dark:text-white truncate">${a.name}</p>
            ${this.modeBadge(a.payment_mode)}
          </div>
          <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">${a.code}</p>
          ${companyLevelInactive ? `
            <p class="text-[11px] text-amber-600 dark:text-amber-400 mt-1 flex items-center gap-1">
              <span class="material-symbols-outlined text-[12px]">lock</span>
              ${translate("Enable at company level first")}
            </p>
          ` : ''}
        </div>
        <div class="flex items-center gap-3 shrink-0">
          ${this.toggleHTML(a.id, active, disabled)}
        </div>
      </div>
    `
  }

  toggleHTML(id, active, disabled) {
    const checked = active ? 'checked' : ''
    const disabledAttr = disabled ? 'disabled' : ''
    const opacity = disabled ? 'opacity-40 pointer-events-none' : ''

    return `
      <label class="relative inline-flex items-center cursor-pointer ${opacity}">
        <input type="checkbox" ${checked} ${disabledAttr}
          data-action="change->${this.identifier}#toggle"
          data-appointment-id="${id}"
          class="sr-only peer" />
        <div class="w-9 h-5 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-blue-600 dark:bg-slate-600 dark:peer-checked:bg-blue-500"></div>
      </label>
    `
  }

  modeBadge(mode) {
    const labels = {
      cash: { icon: "payments", classes: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400" },
      qr: { icon: "qr_code_2", classes: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400" },
      redirect: { icon: "open_in_new", classes: "bg-violet-100 text-violet-700 dark:bg-violet-900/30 dark:text-violet-400" }
    }
    const cfg = labels[mode] || labels.cash
    return `
      <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-xs font-medium ${cfg.classes}">
        <span class="material-symbols-outlined text-[12px]">${cfg.icon}</span>
        ${Helpers.capitalize(mode || "cash")}
      </span>
    `
  }

  emptyHTML() {
    return `
      <div class="py-12 text-center">
        <div class="w-14 h-14 mx-auto mb-4 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center">
          <span class="material-symbols-outlined text-slate-400 dark:text-slate-500">payments</span>
        </div>
        <p class="text-sm text-slate-500 dark:text-slate-400">${translate("No payment methods available")}</p>
      </div>
    `
  }

  errorHTML() {
    return `
      <div class="p-6 text-center rounded-xl bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
        <p class="text-sm text-red-600 dark:text-red-400">${this.loadError}</p>
      </div>
    `
  }
}
