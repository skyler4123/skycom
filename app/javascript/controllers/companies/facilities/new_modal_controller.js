import { Controller } from "@hotwired/stimulus"

export default class Companies_Facilities_NewModalController extends Controller {
  connect() {
    this.element.innerHTML = this.modalHTML()
  }

  async handleSubmit(event) {
    event.preventDefault()

    try {
      const response = await fetchJson(Helpers.create_company_facilities_path(currentCompany().id), {
        method: "POST",
        body: new FormData(event.target)
      })
      /** @type {Facility} */
      const newFacility = response.facility
      reloadThenToast({
        type: "success",
        message: `${newFacility.name || 'Facility'} created successfully`
      })
    } catch (error) {
      toast({
        type: "error",
        message: error.errors || "Failed to create facility"
      })
    }
  }

  modalHTML() {
    const branchFilter = currentBranches()
    const categoryFilter = currentCategories().filter(c => c.resource_name === "facilities")
    const businessTypeFilter = Enums()?.facility?.business_types || []

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">New Facility</h2>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Facility Name</label>
            <input type="text" name="facility[name]" required placeholder="e.g. Retail Floor"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Branch</label>
            <select name="facility[branch_id]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(cloneNewKey(branchFilter, "id", "value"), '', "Select Branch")}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Type</label>
            <select name="facility[business_type]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(businessTypeFilter, '', "Select Type")}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Category</label>
            <select name="facility[category_id]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), '', "No Category")}
            </select>
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->modal#close"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg">
            Cancel
          </button>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm">
            Save Facility
          </button>
        </div>
      </div>
    `

    return form({
      attributes: `
        class="p-8 bg-white dark:bg-slate-900 rounded-2xl w-[500px] shadow-2xl"
        data-action="submit->${this.identifier}#handleSubmit"
      `,
      html: fields
    })
  }
}
