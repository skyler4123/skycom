import { Controller } from "@hotwired/stimulus"

export default class Companies_Facilities_ShowModalController extends Controller {
  facility = null

  connect() {
    this.facility = /** @type {any} */ (window.currentFacility)

    if (this.facility) {
      this.element.innerHTML = this.html()
    }
  }

  html() {
    const f = this.facility
    const branchFilter = currentBranches()
    const categoryFilter = currentCategories().filter(c => c.resource_name === "facilities")
    const businessTypeFilter = Enums()?.facility?.business_types || []

    return `
      <div class="flex items-center justify-center">
        <div class="relative w-full max-w-[640px] overflow-hidden rounded-xl bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 shadow-2xl">

          <div class="flex items-center justify-between border-b border-slate-200 dark:border-gray-800 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-900 dark:text-white">Facility Details</h3>
            <button data-action="click->${this.identifier}#close" class="rounded-full p-2 text-slate-500 cursor-pointer">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          <div class="p-6">
            ${Helpers.form({
              action: Helpers.edit_company_facility_path(currentCompany().id, f.id),
              method: "PATCH",
              attributes: "class=\"space-y-4\"",
              html: `
                <div>
                  <label class="text-[10px] font-bold text-slate-400 uppercase">Name</label>
                  <input type="text" name="facility[name]" value="${f.name}"
                    class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
                </div>

                <div>
                  <label class="text-[10px] font-bold text-slate-400 uppercase">Branch</label>
                  <select name="facility[branch_id]" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
                    ${selectOptionsHTML(cloneNewKey(branchFilter, "id", "value"), f.branch_id, "Select Branch")}
                  </select>
                </div>

                <div>
                  <label class="text-[10px] font-bold text-slate-400 uppercase">Type</label>
                  <select name="facility[business_type]" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
                    ${selectOptionsHTML(businessTypeFilter, f.business_type, "Select Type")}
                  </select>
                </div>

                <div>
                  <label class="text-[10px] font-bold text-slate-400 uppercase">Category</label>
                  <select name="facility[category_id]" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
                    ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), f.category_id, "No Category")}
                  </select>
                </div>

                <div class="flex justify-end gap-3 pt-4">
                  <button type="submit"
                    class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm">
                    Save Changes
                  </button>
                </div>
              `
            })}
          </div>

        </div>
      </div>
    `
  }

  close(event) {
    event.preventDefault()
    closeModal()
  }
}
