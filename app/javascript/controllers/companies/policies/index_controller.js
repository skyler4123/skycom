import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Policies_IndexController extends Companies_LayoutController {
  static targets = ["policiesList"]

  async connect() {
    super.connect()
    const response = await fetchJson();
    this.policies = response.policies || []
    this.renderContent()
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
                <option value="inactive">Inactive</option>
              </select>
              <select class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                <option selected="">Business Type: All</option>
                <option value="security">Security</option>
                <option value="regulatory">Regulatory</option>
                <option value="operational">Operational</option>
                <option value="compliance">Compliance</option>
              </select>
            </div>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Policy Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Resource</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Action</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Branch</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="policiesList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.policiesHTML()}
              </tbody>
            </table>
          </div>

          <div class="p-4 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
            <span class="text-sm text-slate-500 dark:text-slate-400">Showing ${this.policies.length} policies</span>
            <div class="flex items-center gap-2">
              <button class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-400 cursor-not-allowed" disabled>Previous</button>
              <button class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors">Next</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

  policiesHTML() {
    if (this.policies.length === 0) {
      return `<tr><td colspan="5" class="text-center py-4 text-slate-500">No policies found</td></tr>`
    }
    return this.policies.map(policy => `
      <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
        <td class="py-4 px-6 text-sm">
          <div class="flex flex-col">
            <p class="font-medium text-slate-900 dark:text-white">${policy.name}</p>
            <p class="text-xs text-slate-500">${policy.code || 'No code'}</p>
          </div>
        </td>
        <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${policy.resource}</td>
        <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${policy.action}</td>
        <td class="py-4 px-6 text-sm">
          <span class="text-slate-900 dark:text-white">${policy.branch ? policy.branch.name : 'All branches'}</span>
        </td>
        <td class="py-4 px-6 text-sm">
          ${Helpers.statusBadge(policy.lifecycle_status)}
        </td>
      </tr>
    `).join('')
  }
}
