// app/javascript/controllers/companies/employees/show_modal_controller.js

import { Controller } from "@hotwired/stimulus"

export default class Companies_Employees_ShowModalController extends Controller {
  /** * Updated type to include the branch object
   * @type {(Employee & { departments: Department[], roles: Role[], branch: Branch }) | null} 
   */
  employee = null

  connect() {
    this.employee = /** @type {any} */ (window.currentEmployee)
    
    if (this.employee) {
      this.element.innerHTML = this.html()
    }
  }

  html() {
    const e = this.employee
    const name = e.name || "N/A"
    
    // Data Extraction
    const branchName = e.branch?.name || "Main Office" // Fallback if branch is optional
    const departmentName = e.departments?.[0]?.name || "General"
    const rolesList = e.roles?.map(r => r.name).join(", ") || "No roles assigned"

    // Enum Labels
    const lifecycleLabel = this.getEnumName('lifecycle_statuses', e.lifecycle_status)
    const workflowLabel = this.getEnumName('workflow_statuses', e.workflow_status)
    const businessTypeLabel = this.getEnumName('business_types', e.business_type)

    return `
      <div class="flex items-center justify-center">
        <div class="relative w-full max-w-[640px] overflow-hidden rounded-xl bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 shadow-2xl">
          
          <div class="flex items-center justify-between border-b border-slate-200 dark:border-gray-800 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-900 dark:text-white">Employee Details</h3>
            <button data-action="click->${this.identifier}#close" class="rounded-full p-2 text-slate-500 dark:text-gray-400 hover:bg-slate-100 dark:hover:bg-gray-800">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          <div class="p-6">
            <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
              <div class="size-32 shrink-0 overflow-hidden rounded-full border-4 border-blue-100 dark:border-blue-900/30 bg-slate-100 dark:bg-gray-800 shadow-lg">
                <img class="h-full w-full object-cover" src="${e.metadata?.avatar_url || 'https://lh3.googleusercontent.com/aida-public/AB6AXuCdl33Dx4Q4diQVh50H-7KAkXuzdatYq7KrBZOTTGLU0DeGklEda8V-NSs8PsfUx86lb_NW5SVSKPhAIUVFftXhbbcHXKiedlL_xcI-4G7YkcGkgf-S-hIDHDRq1Lw6E6STx6JzNq-UOJfa6m4c0jpuwMoSRM0lfdc1R3iF1AOXhod-vEyMZWMawCQoPrHuFMOmddzo7qRXdHmZ-ZdE9xmsu6_OzsjNmbn3WTjPYf4AKbj0OIfHNq41EMeVwOkRDCnZHOvUCGzSBgo'}" alt="${name}" />
              </div>
              <div class="flex flex-1 flex-col text-center sm:text-left">
                ${editable({
                  dispatch: "updateEmployee",
                  resource: "employee",
                  name: "name",
                  id: e.id,
                  value: e.name,
                  url: Helpers.edit_company_employee_path(currentCompany().id, e.id),
                  html: `<h2 class="text-2xl font-black text-slate-900 dark:text-white">${name}</h2>`,
                  confirmMessage: "Are you sure you want to change this employee's name to '{{value}}'?",
                  successMessage: "Employee name updated successfully!",
                  errorMessage: "Failed to update employee name!"
                })}
                ${editable({
                  dispatch: "updateEmployee",
                  resource: "employee",
                  name: "description",
                  id: e.id,
                  value: e.description || '',
                  url: Helpers.edit_company_employee_path(currentCompany().id, e.id),
                  html: `<p class="font-semibold text-blue-600 dark:text-blue-400">${e.description || 'Employee'}</p>`,
                  confirmMessage: "Change description to '{{value}}'?",
                  successMessage: "Description updated!",
                  errorMessage: "Failed to update description!"
                })}
                <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                  <span class="inline-flex items-center rounded-lg bg-blue-100 dark:bg-blue-900/40 px-3 py-1 text-xs font-bold text-blue-700 dark:text-blue-300 uppercase">${lifecycleLabel}</span>
                  <span class="inline-flex items-center rounded-lg bg-slate-100 dark:bg-gray-800 px-3 py-1 text-xs font-medium text-slate-600 dark:text-gray-400">ID: ${e.code || e.id.substring(0, 8)}</span>
                </div>
              </div>
            </div>

<div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-8 sm:grid-cols-2">
               
              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">location_on</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Work Branch</p>
                  ${(() => {
                    const branches = currentBranches() || []
                    const options = branches.map(b => ({ name: b.name, value: b.id }))
                    return editable({
                      dispatch: "updateEmployee",
                      resource: "employee",
                      name: "branch_id",
                      id: e.id,
                      value: e.branch?.id || e.branch_id,
                      url: Helpers.edit_company_employee_path(currentCompany().id, e.id),
                      type: "select",
                      options: options,
                      html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${branchName}</p>`,
                      confirmMessage: "Change branch to '{{value}}'?",
                      successMessage: "Branch updated!",
                      errorMessage: "Failed to update branch!"
                    })
                  })()}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">corporate_fare</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Department</p>
                  <p class="text-sm font-semibold text-slate-900 dark:text-white">${departmentName}</p>
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">shield_person</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Roles</p>
                  <p class="text-sm font-semibold text-slate-900 dark:text-white">${rolesList}</p>
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">account_tree</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Workflow</p>
                  <p class="text-sm font-semibold text-slate-900 dark:text-white">${workflowLabel}</p>
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">badge</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Type</p>
                  <p class="text-sm font-semibold text-slate-900 dark:text-white">${businessTypeLabel}</p>
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">mail</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Email</p>
                  <p class="text-sm font-semibold text-slate-900 dark:text-white">${e.email}</p>
                </div>
              </div>

            </div>
          </div>
          </div>
      </div>
    `
  }

  // Enum helper from previous steps
  getEnumName(collectionKey, value) {
    const options = Enums().employee[collectionKey] || []
    const match = options.find(opt => opt.value === value)
    return match ? match.name : value
  }

  close(event) {
    event.preventDefault()
    window.closeModal()
  }
}