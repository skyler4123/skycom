import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_Facilities_NewModalController from "controllers/companies/facilities/new_modal_controller";
import Companies_Facilities_ShowModalController from "controllers/companies/facilities/show_modal_controller";

export default class Companies_Facilities_IndexController extends Companies_LayoutController {
  static targets = ["facilitiesList"]

  /** @type {Facility[]} */
  facilities = []

  async connect() {
    super.connect()
    try {
      /** @type {{ facilities: Facility[], pagination: any }} */
      const response = await fetchJson()

      this.facilities = response.facilities || []
      this.pagination = response.pagination || {}

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })

    } catch (error) {
      toast({ type: "error", message: "Failed to load facilities" })
    }
  }

  openNewModal() {
    openModal({ html: `<div data-controller="${identifier(Companies_Facilities_NewModalController)}"></div>` })
  }

  openShowModal(event) {
    event.preventDefault()
    const { facilityId } = event.params
    window.currentFacility = findById(this.facilities, facilityId)
    openModal({ html: `<div data-controller="${identifier(Companies_Facilities_ShowModalController)}"></div>` })
  }

  contentHTML() {
    const branchFilter = currentBranches()
    const businessTypeFilter = Enums()?.facility?.business_types || []
    const workflowStatusFilter = Enums()?.facility?.workflow_statuses || []
    const categoryFilter = currentCategories().filter(c => c.resource_name === "facilities")

    const urlParams = new URLSearchParams(window.location.search)

    return `
      <div class="p-4 overflow-y-auto" data-action="filter:changed@window->${this.identifier}#handleFilter">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end justify-between gap-4 mb-6 w-full">
              <div class="flex flex-wrap items-center gap-3 w-full lg:w-auto">

                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Branch</label>
                  <select name="branch_id" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                    ${selectOptionsHTML(cloneNewKey(branchFilter, "id", "value"), urlParams.get('branch_id'), "All Branches")}
                  </select>
                </div>

                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Category</label>
                  <select name="category_id" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                    ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), urlParams.get('category_id'), "All Categories")}
                  </select>
                </div>

                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Type</label>
                  <select name="business_type" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                    ${selectOptionsHTML(businessTypeFilter, urlParams.get('business_type'), "All Types")}
                  </select>
                </div>

                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Status</label>
                  <select name="workflow_status" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                    ${selectOptionsHTML(workflowStatusFilter, urlParams.get('workflow_status'), "All Statuses")}
                  </select>
                </div>

                <div class="flex gap-2 mt-auto">
                  <button type="submit" class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm flex items-center gap-2">
                    <span class="material-symbols-outlined text-[18px]">search</span>
                    Search
                  </button>
                </div>
              </div>

              <button
                type="button"
                data-action="click->${this.identifier}#openNewModal"
                class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap cursor-pointer">
                <span class="material-symbols-outlined text-[20px]">add</span>
                Add
              </button>
            </form>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Facility Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Category</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Branch</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Type</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="facilitiesList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.facilities.map(facility => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td class="py-4 px-6 text-sm">
                      <div class="flex items-center gap-4">
                        <div class="w-10 h-10 rounded-lg bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center">
                          <span class="material-symbols-outlined text-amber-600 dark:text-amber-400">warehouse</span>
                        </div>
                        <div>
                          <p class="font-medium text-slate-900 dark:text-white cursor-pointer hover:underline">
                            ${facility.name}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${facility.category?.name || 'N/A'}</td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${facility.branch?.name || 'N/A'}</td>
                    <td class="py-4 px-6 text-sm">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-300">
                        ${Helpers.capitalize(facility.business_type?.replace('_', ' ') || '')}
                      </span>
                    </td>
                    <td class="py-4 px-6 text-sm">
                      ${Helpers.statusBadge(facility.workflow_status)}
                    </td>
                    <td class="py-4 px-6 text-sm text-right">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer"
                        data-action="click->${this.identifier}#openShowModal"
                        data-${this.identifier}-facility-id-param="${facility.id}"
                      >
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                    </td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>

          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}
