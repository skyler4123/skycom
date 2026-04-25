import { Controller } from "@hotwired/stimulus"
import * as Helpers from "controllers/helpers"

export default class Companies_NewModalController extends Controller {
  openModal(event) {
    if (event) event.preventDefault()
    Helpers.openModal(this.modalHTML())
    this.setupSuccessHandler()
  }

  setupSuccessHandler() {
    const form = document.querySelector('[data-controller="form"]')
    if (form) {
      form.addEventListener('success', (e) => {
        const response = e.detail.response
        if (response?.company?.id) {
          window.location.href = `/companies/${response.company.id}/dashboard`
        }
      })
    }
  }

  modalHTML() {
    const fields = `
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
            Company Name
          </label>
          <input
            type="text"
            name="company[name]"
            required
            class="w-full px-3 py-2 border border-slate-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            placeholder="Enter company name"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
            Business Type
          </label>
          <select
            name="company[business_type]"
            required
            class="w-full px-3 py-2 border border-slate-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="">Select business type</option>
            ${this.businessTypeOptions()}
          </select>
        </div>
        <div class="flex justify-end gap-3 pt-4">
          <button
            type="button"
            class="px-4 py-2 text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg"
            ${Helpers.closeModalAction()}
          >
            Cancel
          </button>
          <button
            type="submit"
            class="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg"
          >
            Create Company
          </button>
        </div>
      </div>
    `

    return Helpers.form({
      action: "/companies",
      method: "POST",
      className: "p-6 bg-white dark:bg-slate-900 rounded-2xl w-[480px] max-w-[90vw]",
      html: fields
    })
  }

  businessTypeOptions() {
    const types = Helpers.Enums().company?.business_types || []
    return types.map(t => 
      `<option value="${t.value}">${t.name}</option>`
    ).join('')
  }
}