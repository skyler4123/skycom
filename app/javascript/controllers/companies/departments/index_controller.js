import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Departments_IndexController extends Companies_LayoutController {
  static targets = ["departmentsList"]

  async connect() {
    super.connect()
    const response = await fetchJson();
    this.departments = response.departments || []
    poll(() => {
      if (isPresent(this.departments)) {
        this.renderContent();
        return true; // Stop polling
        }
      return false; // Keep polling
    });
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
                <option selected="">Division: All</option>
              </select>
            </div>
            <button 
              data-action="click->${this.identifier}#openAddDepartmentModal"
              class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap">
              <span class="material-symbols-outlined text-[20px]">add</span>
              Add New Department
            </button>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Department</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Head of Department</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Description</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap text-center">Staff</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap text-right">Actions</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="departmentsList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.departmentsHTML()}
              </tbody>
            </table>
          </div>

          <div class="p-4 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
            <span class="text-sm text-slate-500 dark:text-slate-400">Showing ${this.departments?.length} departments</span>
            <div class="flex items-center gap-2">
              <button class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-400 cursor-not-allowed" disabled>Previous</button>
              <button class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors">Next</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

  departmentsHTML() {
    if (!this.departments || this.departments?.length === 0) {
      return `<tr><td colspan="5" class="text-center py-4 text-slate-500">No departments found</td></tr>`
    }
    return this.departments.map(department => `
      <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
        <td class="py-4 px-6 text-sm">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-900/40 text-blue-600 flex items-center justify-center">
              <span class="material-symbols-outlined">hr_resting</span>
            </div>
            <div>
              <p 
                 class="font-medium text-slate-900 dark:text-white cursor-pointer hover:underline"
                 data-action="click->${this.identifier}#showDepartmentDetails"
              >
                ${department.name}
              </p>
              <p class="text-xs text-slate-500">ID: #${department.code || department.id}</p>
            </div>
          </div>
        </td>
        <td class="py-4 px-6 text-sm">
          <div class="flex items-center gap-3">
            <div class="w-8 h-8 rounded-full bg-slate-200 bg-cover"></div>
            <div>
              <p class="text-sm font-medium">Head Name</p>
              <p class="text-xs text-slate-500">Role</p>
            </div>
          </div>
        </td>
        <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 max-w-xs truncate">
          ${department.description || 'No description'}
        </td>
        <td class="py-4 px-6 text-center">
          <span class="px-2 py-1 rounded-full bg-slate-100 dark:bg-slate-800 text-xs font-medium">
            ${department.employee_count || 0} Members
          </span>
        </td>
        <td class="py-4 px-6 text-right space-x-2">
          <button class="text-blue-600 hover:text-blue-700 transition-colors">
            <span class="material-symbols-outlined text-xl">edit</span>
          </button>
          <button class="text-red-500 hover:text-red-600 transition-colors">
            <span class="material-symbols-outlined text-xl">delete</span>
          </button>
        </td>
      </tr>
    `).join('')
  }
}
