import * as Helpers from "controllers/helpers"
import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Departments_IndexController extends Retail_Management_LayoutController {
  static targets = ["departmentsList"]

  /** @type {Department[]} */
  departments = []

  async initialize() {
    super.initialize()
    const response = await Helpers.fetchJson();
    this.departments = response.departments || []
    this.render()
  }

  render() {
    if (!this.hasDepartmentsListTarget) return
    this.departmentsListTarget.innerHTML = this.departmentsHTML()
  }

  showDepartmentDetails(event) {
    const departmentName = event.currentTarget.textContent.trim()
    const department = this.departments.find(d => d.name === departmentName)
    
    if (!department) return

    const modalId = `department-details-modal-${Helpers.randomId()}`
    
    const modalHTML = `
      <div id="${modalId}" class="flex justify-center items-center">
        <div class="w-full max-w-2xl bg-white dark:bg-slate-900 rounded-xl shadow-lg overflow-hidden border border-slate-200 dark:border-slate-800">
          <div class="p-6 border-b border-slate-200 dark:border-slate-800">
            <h2 class="text-xl font-semibold text-slate-900 dark:text-white">Department Details - ${department.name}</h2>
          </div>
          <div class="p-6">
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4"><strong>Description:</strong> ${department.description || 'N/A'}</p>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4"><strong>Code:</strong> ${department.code || 'N/A'}</p>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4"><strong>Status:</strong> ${Helpers.statusBadge(department.lifecycle_status)}</p>
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
   * Opens a modal with a form to add a new department.
   */
  openAddDepartmentModal() {
    const modalId = `add-department-modal-${Helpers.randomId()}`
    
    const modalHTML = `
      <div id="${modalId}" class="flex justify-center items-center">
        <form
          action="${Helpers.retail_management_departments_path()}"
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
                Add New Department
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
                    <label for="department_name" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                      Department Name <span class="text-red-500">*</span>
                    </label>
                    <input
                      type="text"
                      name="department[name]"
                      id="department_name"
                      required
                      placeholder="Enter department name"
                      class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                    />
                  </div>

                  <div>
                    <label for="department_code" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                      Code
                    </label>
                    <input
                      type="text"
                      name="department[code]"
                      id="department_code"
                      placeholder="DEPT001"
                      class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                    />
                  </div>

                  <div class="md:col-span-2 lg:col-span-3">
                    <label for="department_description" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                      Description
                    </label>
                    <textarea
                      name="department[description]"
                      id="department_description"
                      rows="3"
                      placeholder="Optional description of the department..."
                      class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all resize-none"
                    ></textarea>
                  </div>
                </div>
              </section>
            </div>

            <!-- Footer -->
            <div class="bg-slate-50 dark:bg-slate-800/70 px-8 py-5 border-t border-slate-200 dark:border-slate-700 flex justify-end gap-3">
              <button
                type="button"
                class="px-6 py-2.5 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-xl hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
                data-action="click->modal#close"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="px-6 py-2.5 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-xl transition-colors"
              >
                Create Department
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
            <span class="text-sm text-slate-500 dark:text-slate-400">Showing ${this.departments.length} departments</span>
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
    if (this.departments.length === 0) {
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
