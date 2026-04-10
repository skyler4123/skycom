import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_Employees_NewModalController from "controllers/companies/employees/new_modal_controller";
import Companies_Employees_ShowModalController from "controllers/companies/employees/show_modal_controller";

export default class Companies_Branches_EmployeesController extends Companies_LayoutController {
  static targets = ["employeesList"]

  /** @type {Employee[]} */
  employees = []

  async connect() {
    super.connect() // Start parent layout logic
    
    try {
      /** @type {{ employees: Employee[], pagination: any }} */
      const response = await fetchJson()
      
      // 1. Save the data to the instance immediately
      this.employees = response.employees || []
      this.pagination = response.pagination || {}
  
      // 2. Wait for the Layout to actually put the 'content' div into the DOM
      window.poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true // Success! Stop polling.
        }
        return false // Layout isn't ready yet, keep waiting.
      })
  
    } catch (error) {
      toast({ type: "error", message: "Failed to load employees" })
    }
  }

  openNewModal() {
    openModal({ html: `<div data-controller="${identifier(Companies_Employees_NewModalController)}"></div>` })
  }

  openShowModal() {
    openModal({ html: `<div data-controller="${identifier(Companies_Employees_ShowModalController)}"></div>` })
  }

  contentHTML() {
    // Local aliases for cleaner template interpolation
    const departmentFilter = Helpers.currentDepartments();
    const roleFilter = Helpers.currentRoles();
    const workflowStatusFilter = Helpers.employee().enum.workflow_statuses;
    const typeFilter = Helpers.employee().enum.business_types;
    
    const urlParams = new URLSearchParams(window.location.search);

    return `
      <div class="p-4 overflow-y-auto" data-action="filter:changed@window->${this.identifier}#handleFilter">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end justify-between gap-4 mb-6 w-full">
              <div class="flex flex-wrap items-center gap-3 w-full lg:w-auto">
                
                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Department</label>
                  <select name="department_id" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                    ${selectOptionsHTML(cloneNewKey(departmentFilter, "id", "value"), urlParams.get('department_id'), "All Departments")}
                  </select>
                </div>

                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Role</label>
                  <select name="role_id" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                    ${selectOptionsHTML(cloneNewKey(roleFilter, "id", "value"), urlParams.get('role_id'), "All Roles")}
                  </select>
                </div>

                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Status</label>
                  <select name="workflow_status" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                    ${selectOptionsHTML(workflowStatusFilter, urlParams.get('workflow_status'), "All Statuses")}
                  </select>
                </div>

                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Type</label>
                  <select name="business_type" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                    ${selectOptionsHTML(typeFilter, urlParams.get('business_type'), "All Types")}
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
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Employee Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Departments</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Roles</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Code</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Type</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="employeesList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.employees.map(employee => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td class="py-4 px-6 text-sm">
                      <div class="flex items-center gap-4">
                        <div class="w-10 h-10 rounded-lg bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 flex items-center justify-center">
                          <span class="material-symbols-outlined text-slate-400">person</span>
                        </div>
                        <div>
                          <p class="font-medium text-slate-900 dark:text-white cursor-pointer hover:underline" data-action="click->${this.identifier}#showEmployeeDetails">
                            ${employee.name}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td class="py-4 px-6">
                      <div class="flex flex-wrap gap-1">
                        ${employee.departments?.length > 0 
                          ? employee.departments.map(dept => `
                              <span class="px-2 py-0.5 bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 text-[10px] font-bold rounded border border-blue-100 dark:border-blue-800">
                                ${dept.name}
                              </span>
                            `).join('')
                          : '<span class="text-slate-400 text-[10px] italic">N/A</span>'
                        }
                      </div>
                    </td>
                    <td class="py-4 px-6">
                      <div class="flex flex-wrap gap-1">
                        ${(employee.roles || []).map(role => `
                          <span class="px-2 py-0.5 bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 text-[10px] font-bold rounded border border-slate-200 dark:border-slate-700">
                            ${role.name}
                          </span>
                        `).join('')}
                      </div>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">${employee.code || 'N/A'}</td>
                    <td class="py-4 px-6 text-sm">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        employee.business_type === 'full_time' ? 'bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-300' :
                        'bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-300'
                      }">
                        ${Helpers.capitalize(employee.business_type?.replace('_', ' ') || 'full_time')}
                      </span>
                    </td>
                    <td class="py-4 px-6 text-sm">
                      ${Helpers.statusBadge(employee.workflow_status)}
                    </td>
                    <td class="py-4 px-6 text-sm text-right">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer"
                        data-action="click->${this.identifier}#openShowModal"
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
