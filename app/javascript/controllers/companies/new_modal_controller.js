// app/javascript/controllers/companies/new_modal_controller.js

import { Controller } from "@hotwired/stimulus"

export default class Companies_NewModalController extends Controller {
  connect() {
    this.element.innerHTML = this.modalHTML()
  }

  modalHTML() {
    const businessTypes = [
      { value: "retail", label: "Retail" },
      { value: "education", label: "Education" },
      { value: "hospital", label: "Hospital" },
      { value: "restaurant", label: "Restaurant" },
      { value: "shop", label: "Shop" },
      { value: "fitness", label: "Fitness" },
    ]

    const businessTypeOptions = businessTypes.map(type =>
      `<option value="${type.value}">${type.label}</option>`
    ).join('')

    const fields = `
      <div class="space-y-6">
        <div class="flex items-center justify-between border-b border-slate-200 dark:border-gray-800 px-6 py-4">
          <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Company")}</h2>
          <button data-action="click->${this.identifier}#closeModal" class="rounded-full p-2 text-slate-500 hover:text-slate-700 dark:hover:text-slate-200">
            <span class="material-symbols-outlined">close</span>
          </button>
        </div>

        <div class="px-6 space-y-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">Company Name</label>
            <input type="text" name="company[name]" required placeholder="e.g. Acme Inc."
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">Business Type</label>
            <select name="company[business_type]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              <option value="">Select a business type</option>
              ${businessTypeOptions}
            </select>
          </div>
        </div>

        <div class="flex justify-end gap-3 px-6 py-4 border-t border-slate-200 dark:border-gray-800">
          <button type="button" data-action="click->${this.identifier}#closeModal"
            class="px-4 py-2 text-sm font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors">
            ${translate("Cancel")}
          </button>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition-all shadow-lg shadow-blue-500/30">
            ${translate("Create Company")}
          </button>
        </div>
      </div>
    `

    return form({
      action: Helpers.create_companies_path(),
      className: "bg-white dark:bg-slate-900 rounded-2xl w-[480px] shadow-2xl border border-slate-100 dark:border-slate-800 overflow-hidden",
      html: fields
    })
  }
}
