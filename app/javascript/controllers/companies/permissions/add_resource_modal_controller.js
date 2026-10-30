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

      reloadThenToast({ type: "success", message: response.message || translate("Resource added successfully") })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to add resource") })
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
          <h2 class="text-xl font-bold text-foreground">${translate("Add Resource to")} ${this.roleNameValue}</h2>
          <p class="text-sm text-muted-foreground mt-1">${translate("Select a resource to add CRUD policies for this role")}</p>
        </div>

        <div class="space-y-2">
          <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Select Resource")}</label>
          <select name="permission[resource_name]" required
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
            <option value="">${translate("Select a resource...")}</option>
            ${resources.map(resource => `
              <option value="${resource}">${resource}</option>
            `).join('')}
          </select>
        </div>

        <input type="hidden" name="permission[role_id]" value="${this.roleIdValue}" />

        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->modal#close" 
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg">
            ${translate("Cancel")}
          </button>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm">
            ${translate("Add Resource")}
          </button>
        </div>
      </div>
    `

    return form({
      action: Helpers.company_permissions_path(currentCompany()?.id),
      method: "POST",
      attributes: `
        class="p-8 bg-card rounded-2xl w-[450px] shadow-2xl"
        data-action="submit->${this.identifier}#handleSubmit"
      `,
      html: fields
    })
  }

  noResourcesHTML() {
    return `
      <div class="space-y-6">
        <div>
          <h2 class="text-xl font-bold text-foreground">${translate("Add Resource to")} ${this.roleNameValue}</h2>
        </div>

        <div class="p-4 bg-warning/10 border border-warning/20 rounded-lg">
          <p class="text-sm text-warning ">
            ${translate("All available resources have already been assigned to this role.")}
          </p>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->modal#close" 
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg">
            ${translate("Close")}
          </button>
        </div>
      </div>
    `
  }
}