import * as Helpers from "controllers/helpers"
import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Branches_IndexController extends Retail_Management_LayoutController {
  static targets = ["branchesList"]

  /** @type {Branch[]} */
  branches = []

  async initialize() {
    super.initialize()
    const response = await Helpers.fetchJson();
    this.branches = response.branches || []
    this.render()
  }

  render() {
    if (!this.hasBranchesListTarget) return
    this.branchesListTarget.innerHTML = this.branchesHTML()
  }

  showBranchDetails(event) {
    // Note: I swapped looking up by name to looking up by the text content for now,
    // but typically you would use data-params-id for this.
    const branchName = event.currentTarget.textContent.trim()
    
    // (Assuming you have a method getBranchIdByName, otherwise consider: this.branches.find(b => b.name === branchName))
    const branch = this.branches.find(b => b.name === branchName)
    
    if (!branch) return

    const modalId = `branch-details-modal-${Helpers.randomId()}`
    
    const modalHTML = `
      <div id="${modalId}" class="flex justify-center items-center">
        <div class="w-full max-w-2xl bg-white dark:bg-slate-900 rounded-xl shadow-lg overflow-hidden border border-slate-200 dark:border-slate-800">
          <div class="p-6 border-b border-slate-200 dark:border-slate-800">
            <h2 class="text-xl font-semibold text-slate-900 dark:text-white">Branch Details - ${branch.name}</h2>
          </div>
          <div class="p-6">
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4"><strong>Address:</strong> ${branch.address_line_1 || ''}, ${branch.city || ''}</p>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4"><strong>Contact Info:</strong> ${branch.phone_number || 'N/A'}</p>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4"><strong>Manager:</strong> ${branch.manager_name || 'N/A'}</p>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4"><strong>Status:</strong> ${Helpers.statusBadge(branch.lifecycle_status)}</p>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4"><strong>POS site:</strong> <a href="${Helpers.retail_pos_branches_path(branch.company_group_id, branch.id)}">POS site</a></p>
          </div>
          <div class="p-6 border-t border-slate-200 dark:border-slate-800 flex justify-end">
            <button
              class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm"
              data-action="click->modal#close">Close</button>
          </div>
        </div>
      </div>
    `
    
    Helpers.openModal({ html: modalHTML })
  }

  /**
   * Opens a modal with a form to add a new branch.
   */
  openAddBranchModal() {
    const modalId = `add-branch-modal-${Helpers.randomId()}`
    
    const modalHTML = `
      <div id="${modalId}" class="flex justify-center items-center">
        <form
          action="${Helpers.retail_management_branches_path()}"
          method="post"
          class="w-full max-w-4xl"
        >
          ${Helpers.formPostSecurityTags()}

          <div class="bg-white dark:bg-slate-900 rounded-2xl shadow-xl overflow-hidden ring-1 ring-slate-200 dark:ring-slate-700">
            <!-- Header -->
            <div class="bg-slate-50 dark:bg-slate-800/70 px-8 py-5 border-b border-slate-200 dark:border-slate-700">
              <h2 class="text-2xl font-semibold text-slate-900 dark:text-white flex items-center gap-3">
                <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-blue-100 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400">
                  <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h-4m-6 0H5m4 0h6m2-8h4m-4-4h4m-8 4h.01M9 8h.01"/>
                  </svg>
                </span>
                Add New Branch
              </h2>
            </div>

            <!-- Form Body -->
            <div class="p-8 space-y-10 max-h-[75vh] overflow-y-auto">
              
              <!-- Basic Information -->
              <section>
                <h3 class="text-lg font-medium text-slate-900 dark:text-white mb-5 flex items-center gap-2">
                  <span class="w-1 h-6 bg-blue-500 rounded-full"></span>
                  Basic Information
                </h3>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  <div class="lg:col-span-2">
                    <label for="branch_name" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                      Branch Name <span class="text-red-500">*</span>
                    </label>
                    <input
                      type="text"
                      name="branch[name]"
                      id="branch_name"
                      required
                      placeholder="Enter branch name"
                      class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                    />
                  </div>

                  <div>
                    <label for="branch_phone_number" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                      Phone Number
                    </label>
                    <input
                      type="tel"
                      name="branch[phone_number]"
                      id="branch_phone_number"
                      placeholder="+1 (555) 000-0000"
                      class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                    />
                  </div>

                  <div class="md:col-span-2 lg:col-span-3">
                    <label for="branch_description" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                      Description
                    </label>
                    <textarea
                      name="branch[description]"
                      id="branch_description"
                      rows="3"
                      placeholder="Optional description of the branch..."
                      class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all resize-none"
                    ></textarea>
                  </div>
                </div>
              </section>

              <!-- Location -->
              <section>
                <h3 class="text-lg font-medium text-slate-900 dark:text-white mb-5 flex items-center gap-2">
                  <span class="w-1 h-6 bg-green-500 rounded-full"></span>
                  Location
                </h3>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  <div class="lg:col-span-3">
                    <label for="branch_address_line_1" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                      Address Line 1
                    </label>
                    <input
                      type="text"
                      name="branch[address_line_1]"
                      id="branch_address_line_1"
                      placeholder="Street address"
                      class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                    />
                  </div>

                  <div>
                    <label for="branch_city" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">City</label>
                    <input type="text" name="branch[city]" id="branch_city" placeholder="City" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_postal_code" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Postal Code</label>
                    <input type="text" name="branch[postal_code]" id="branch_postal_code" placeholder="ZIP/Postal" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_country" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Country</label>
                    <input type="text" name="branch[country]" id="branch_country" placeholder="Country" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_timezone" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Timezone</label>
                    <input type="text" name="branch[timezone]" id="branch_timezone" placeholder="e.g., America/New_York" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>
                </div>
              </section>

              <!-- Business Details -->
              <section>
                <h3 class="text-lg font-medium text-slate-900 dark:text-white mb-5 flex items-center gap-2">
                  <span class="w-1 h-6 bg-purple-500 rounded-full"></span>
                  Business Details
                </h3>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  <div>
                    <label for="branch_registration_number" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Registration Number</label>
                    <input type="text" name="branch[registration_number]" id="branch_registration_number" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_vat_id" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">VAT ID</label>
                    <input type="text" name="branch[vat_id]" id="branch_vat_id" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_tax_id" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Tax ID</label>
                    <input type="text" name="branch[tax_id]" id="branch_tax_id" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_ownership_type" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Ownership Type</label>
                    <input type="text" name="branch[ownership_type]" id="branch_ownership_type" placeholder="e.g., Franchise" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_business_type" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Business Type</label>
                    <input type="text" name="branch[business_type]" id="branch_business_type" placeholder="e.g., Retail" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_currency" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Currency</label>
                    <input type="text" name="branch[currency]" id="branch_currency" placeholder="USD" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_fiscal_year_end_month" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Fiscal Year End Month</label>
                    <input type="number" name="branch[fiscal_year_end_month]" id="branch_fiscal_year_end_month" min="1" max="12" placeholder="12" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>
                </div>
              </section>
            </div>

            <!-- Footer -->
            <div class="bg-slate-50 dark:bg-slate-800/70 px-8 py-5 border-t border-slate-200 dark:border-slate-700 flex justify-end gap-4">
              <button
                type="button"
                class="px-6 py-3 text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 rounded-xl font-medium hover:bg-slate-100 dark:hover:bg-slate-600 transition-all"
                data-action="click->modal#close"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-medium shadow-md hover:shadow-lg transition-all"
              >
                Save Branch
              </button>
            </div>
          </div>
        </form>
      </div>
    `
    
    Helpers.openModal({ html: modalHTML })
  }

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <div class="flex flex-wrap items-center gap-3 w-full sm:w-auto">
              <select class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                <option selected="">Status: All</option>
                <option value="active">Active</option>
              </select>
              <select class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                <option selected="">Region: All</option>
              </select>
            </div>
            <button 
              data-action="click->${this.identifier}#openAddBranchModal"
              class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap">
              <span class="material-symbols-outlined text-[20px]">add</span>
              Add New Branch
            </button>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Branch Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Address</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Contact Info</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Manager</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="branchesList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.branchesHTML()}
              </tbody>
            </table>
          </div>

          <div class="p-4 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
            <span class="text-sm text-slate-500 dark:text-slate-400">Showing 1 to 4 of 12 branches</span>
            <div class="flex items-center gap-2">
              <button class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-400 cursor-not-allowed" disabled>Previous</button>
              <button class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors">Next</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

  branchesHTML() {
    if (this.branches.length === 0) {
      return `<tr><td colspan="6" class="text-center py-4 text-slate-500">No branches found</td></tr>`
    }
    return this.branches.map(branch => `
      <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
        <td class="py-4 px-6 text-sm">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500">
              <span class="material-symbols-outlined">store</span>
            </div>
            <div>
              <p 
                 class="font-medium text-slate-900 dark:text-white cursor-pointer hover:underline"
                 data-action="click->${this.identifier}#showBranchDetails"
              >
                ${branch.name}
              </p>
              <p class="text-xs text-slate-500">ID: #${branch.code || branch.id}</p>
            </div>
          </div>
        </td>
        <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
          ${branch.address_line_1 || ''}<br />
          ${branch.city || ''}
        </td>
        <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
          <div class="flex flex-col gap-1">
            <div class="flex items-center gap-2">
              <span class="material-symbols-outlined text-sm text-slate-400">call</span>
              <span>${branch.phone_number || 'N/A'}</span>
            </div>
          </div>
        </td>
        <td class="py-4 px-6 text-sm">
          <div class="flex items-center gap-3">
            <div class="bg-slate-200 rounded-full h-8 w-8 flex items-center justify-center text-xs">
              ${branch.employee_count || 0}
            </div>
            <span class="text-slate-900 dark:text-white">Employees</span>
          </div>
        </td>
        <td class="py-4 px-6 text-sm">
          ${Helpers.statusBadge(branch.lifecycle_status)}
        </td>
      </tr>
    `).join('')
  }
}
