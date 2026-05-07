import { Controller } from "@hotwired/stimulus"

export default class Companies_Permissions_AddResourceModalController extends Controller {
  static values = {
    roleId: { type: String, default: '' },
    roleName: { type: String, default: '' },
    assignedResources: { type: Array, default: [] }
  }

  connect() {
    this.element.innerHTML = this.modalHTML()
  }

  get availableResources() {
    const allResources = currentCompany()?.resource_names || []
    const assigned = this.assignedResourcesValue || []
    return allResources.filter(r => !assigned.includes(r))
  }

  async handleSubmit(event) {
    event.preventDefault()

    try {
      const response = await fetchJson(Helpers.company_permissions_path(currentCompany().id), {
        method: "POST",
        body: new FormData(event.target)
      })

      reloadThenToast({ type: "success", message: response.message || "Resource added successfully" })
    } catch (error) {
      toast({ type: "error", message: error.error || "Failed to add resource" })
    }
  }

  modalHTML() {
    const resources = this.availableResources

    if (resources.length === 0) {
      return this.noResourcesHTML()
    }

    const fields = `
      <div class="space-y-6">
        <div>
          <h2 class="text-xl font-bold text-slate-900 dark:text-white">Add Resource to ${this.roleNameValue}</h2>
          <p class="text-sm text-slate-500 mt-1">Select a resource to add CRUD policies for this role</p>
        </div>

        <div class="space-y-2">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Select Resource</label>
          <select name="permission[resource_name]" required
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
            <option value="">Select a resource...</option>
            ${resources.map(resource => `
              <option value="${resource}">${resource}</option>
            `).join('')}
          </select>
        </div>

        <input type="hidden" name="permission[role_id]" value="${this.roleIdValue}" />

        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->modal#close" 
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg">
            Cancel
          </button>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm">
            Add Resource
          </button>
        </div>
      </div>
    `

    return form({
      action: Helpers.company_permissions_path(currentCompany()?.id),
      method: "POST",
      attributes: `
        class="p-8 bg-white dark:bg-slate-900 rounded-2xl w-[450px] shadow-2xl"
        data-action="submit->${this.identifier}#handleSubmit"
      `,
      html: fields
    })
  }

  noResourcesHTML() {
    return `
      <div class="space-y-6">
        <div>
          <h2 class="text-xl font-bold text-slate-900 dark:text-white">Add Resource to ${this.roleNameValue}</h2>
        </div>

        <div class="p-4 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg">
          <p class="text-sm text-amber-800 dark:text-amber-200">
            All available resources have already been assigned to this role.
          </p>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->modal#close" 
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg">
            Close
          </button>
        </div>
      </div>
    `
  }
}