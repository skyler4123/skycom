import * as Helpers from "controllers/helpers"
import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Branches_IndexController extends Retail_Management_LayoutController {
  static targets = ["branchesList"]

  /** @type {Branch[]} */
  branches = []

  async init() {
    const response = await Helpers.fetchJson({ params: { page: 1, active: true } });
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
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4"><strong>POS site:</strong> <a href="${Helpers.retailPosBranchPath(branch.company_group_id, branch.id)}">POS site</a></p>
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
            <button class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap">
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
