// app/javascript/controllers/companies/employees/new_modal_controller.js

import { Controller } from "@hotwired/stimulus"

export default class Companies_Employees_NewModalController extends Controller {
  connect() {
    // We assume branches might be passed via data attributes on the element
    const branches = JSON.parse(this.element.dataset.branches || "[]")
    this.element.innerHTML = this.modalHTML(branches)
  }

  /**
   * Handles the form submission using Skycom global helpers.
   */
  async submit(event) {
    event.preventDefault()
    const formElement = event.target
    const formData = new FormData(formElement)

    // Construct the payload matching your Rails employee_params
    const payload = {
      employee: {
        name: formData.get("employee[name]"),
        business_type: formData.get("employee[business_type]"),
        branch_id: formData.get("employee[branch_id]"),
        description: formData.get("employee[description]")
      }
    }

    try {
      // fetchJson automatically handles CSRF tokens and JSON headers
      const response = await fetchJson(formElement.action, {
        method: "POST",
        body: payload
      })

      if (response && response.status === "success") {
        toast({ text: response.message })
        closeModal()
        
        // Custom Event to notify the IndexController to refresh its list
        this.dispatch("created", { detail: { employee: response.employee } })
      }
    } catch (error) {
      toast({ 
        text: "Could not save employee. Please check your connection.",
        style: { background: "linear-gradient(to right, #ff5f6d, #ffc371)" } 
      })
    }
  }

  modalHTML(branches = []) {
    const branchOptions = branches.map(b => 
      `<option value="${b.id}">${b.name}</option>`
    ).join('')

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">New Employee</h2>
        
        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Full Name</label>
            <input type="text" name="employee[name]" required placeholder="e.g. John Doe"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-sm focus:ring-2 focus:ring-blue-500 outline-none">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Employment Type</label>
            <select name="employee[business_type]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-sm focus:ring-2 focus:ring-blue-500 outline-none">
              <option value="full_time">Full Time</option>
              <option value="part_time">Part Time</option>
              <option value="contractor">Contractor</option>
              <option value="intern">Intern</option>
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Branch</label>
            <select name="employee[branch_id]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-sm focus:ring-2 focus:ring-blue-500 outline-none">
              <option value="">Select a Branch (Optional)</option>
              ${branchOptions}
            </select>
          </div>
        </div>

        <div class="space-y-1">
          <label class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Description</label>
          <textarea name="employee[description]" rows="3"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-sm focus:ring-2 focus:ring-blue-500 outline-none"></textarea>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->modal#close" 
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg transition-colors">
            Cancel
          </button>
          <button type="submit" 
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition-all shadow-lg shadow-blue-500/30">
            Save Employee
          </button>
        </div>
      </div>
    `

    // UPDATED: Added dataAction to point to the submit method of THIS controller
    return form({
      action: pathname(),
      method: "POST",
      dataAction: `submit->${this.identifier}#submit`,
      className: "p-8 bg-white dark:bg-slate-900 rounded-2xl w-[500px] shadow-2xl border border-slate-100 dark:border-slate-800",
      html: fields
    })
  }
}