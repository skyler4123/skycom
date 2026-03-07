import Companies_LayoutController from "controllers/companies/layout_controller"


export default class Companies_Branches_EmployeesController extends Companies_LayoutController {
  static targets = ["employeesList"]

    async connect() {
      super.connect()
      const response = await fetchJson();
      this.employees = response.employees || []
      poll(() => {
        if (isPresent(this.employees)) {
          this.renderContent();
          return true; // Stop polling
          }
        return false; // Keep polling
      });
      console.log(this)
    }
  

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <div class="flex flex-wrap items-center gap-3 w-full sm:w-auto">
              <select class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                <option selected="">Department: All</option>
                <option value="sales">Sales</option>
                <option value="hr">HR</option>
                <option value="it">IT</option>
              </select>
              <select class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                <option selected="">Employment Type: All</option>
                <option value="full_time">Full Time</option>
                <option value="part_time">Part Time</option>
                <option value="contractor">Contractor</option>
                <option value="intern">Intern</option>
              </select>
            </div>
            <button
              data-action="click->${this.identifier}#openAddEmployeeModal"
              class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap">
              <span class="material-symbols-outlined text-[20px]">add</span>
              Add New Employee
            </button>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Employee Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Email</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Code</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Employment Type</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="employeesList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.employeesHTML()}
              </tbody>
            </table>
          </div>

          <div class="p-4 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
            <span class="text-sm text-slate-500 dark:text-slate-400">Showing ${this.employees.length} employees</span>
            <div class="flex items-center gap-2">
              <button class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-400 cursor-not-allowed" disabled>Previous</button>
              <button class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors">Next</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

  employeesHTML() {
    if (this.employees.length === 0) {
      return `<tr><td colspan="5" class="text-center py-4 text-slate-500">No employees found</td></tr>`
    }
    return this.employees.map(employee => `
      <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
        <td class="py-4 px-6 text-sm">
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-lg bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 flex items-center justify-center">
              <span class="material-symbols-outlined text-slate-400">person</span>
            </div>
            <div>
              <p
                 class="font-medium text-slate-900 dark:text-white cursor-pointer hover:underline"
                 data-action="click->${this.identifier}#showEmployeeDetails"
              >
                ${employee.name}
              </p>
            </div>
          </div>
        </td>
        <td class="py-4 px-6 text-sm">
          <div class="flex items-center gap-4">
              <p class="text-xs text-blue-600 dark:text-blue-400 font-medium">${employee.user.email || 'N/A'}</p>
            </div>
          </div>
        </td>
        <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">${employee.code || 'N/A'}</td>
        <td class="py-4 px-6 text-sm">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
            employee.business_type === 'full_time' ? 'bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-300' :
            employee.business_type === 'part_time' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-300' :
            employee.business_type === 'contractor' ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/50 dark:text-yellow-300' :
            'bg-purple-100 text-purple-800 dark:bg-purple-900/50 dark:text-purple-300'
          }">
            ${Helpers.capitalize(employee.business_type.replace('_', ' '))}
          </span>
        </td>
        <td class="py-4 px-6 text-sm">
          ${Helpers.statusBadge(employee.lifecycle_status)}
        </td>
        <td class="py-4 px-6 text-sm text-right">
          <div class="flex items-center justify-end gap-2">
            <button class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg"><span
                class="material-symbols-outlined text-[20px]">edit</span></button>
          </div>
        </td>
      </tr>
    `).join('')
  }
}
