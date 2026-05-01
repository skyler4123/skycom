import { Controller } from "@hotwired/stimulus"

export default class Companies_Departments_ShowModalController extends Controller {
  /** @type {Department | null} */
  department = null

  connect() {
    this.department = /** @type {any} */ (window.currentDepartment)

    if (this.department) {
      this.element.innerHTML = this.html()
    }
  }

  html() {
    const d = this.department
    const name = d.name || "N/A"

    return `
      <div class="flex items-center justify-center">
        <div class="relative w-full max-w-[640px] overflow-hidden rounded-xl bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 shadow-2xl">

          <div class="flex items-center justify-between border-b border-slate-200 dark:border-gray-800 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-900 dark:text-white">Department Details</h3>
            <button data-action="click->${this.identifier}#close" class="rounded-full p-2 text-slate-500 dark:text-gray-400 hover:bg-slate-100 dark:hover:bg-gray-800">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          <div class="p-6">
            <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
              <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-indigo-100 dark:border-indigo-900/30 bg-indigo-100 dark:bg-gray-800 shadow-lg flex items-center justify-center">
                <span class="material-symbols-outlined text-4xl text-indigo-600 dark:text-indigo-400">corporate_fare</span>
              </div>
              <div class="flex flex-1 flex-col text-center sm:text-left">
                ${editable({
                  dispatch: "updateDepartment",
                  resource: "department",
                  name: "name",
                  id: d.id,
                  value: d.name,
                  url: Helpers.edit_company_department_path(currentCompany().id, d.id),
                  html: `<h2 class="text-2xl font-black text-slate-900 dark:text-white">${name}</h2>`,
                  confirmMessage: "Are you sure you want to change this department name to '{{value}}'?",
                  successMessage: "Department name updated successfully!",
                  errorMessage: "Failed to update department name!"
                })}
                ${editable({
                  dispatch: "updateDepartment",
                  resource: "department",
                  name: "description",
                  id: d.id,
                  value: d.description || '',
                  url: Helpers.edit_company_department_path(currentCompany().id, d.id),
                  html: `<p class="font-semibold text-indigo-600 dark:text-indigo-400">${d.description || 'No description'}</p>`,
                  confirmMessage: "Change description to '{{value}}'?",
                  successMessage: "Description updated!",
                  errorMessage: "Failed to update description!"
                })}
                <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                  <span class="inline-flex items-center rounded-lg bg-indigo-100 dark:bg-indigo-900/40 px-3 py-1 text-xs font-bold text-indigo-700 dark:text-indigo-300 uppercase">${d.code || 'N/A'}</span>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-6 sm:grid-cols-2">

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400">
                  <span class="material-symbols-outlined">category</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Type</p>
                  ${(() => {
                    const options = (Enums()?.department?.business_types || []).map(t => ({ name: t.name, value: t.value }))
                    return editable({
                      dispatch: "updateDepartment",
                      resource: "department",
                      name: "business_type",
                      id: d.id,
                      value: d.business_type,
                      url: Helpers.edit_company_department_path(currentCompany().id, d.id),
                      type: "select",
                      options: options,
                      className: "dark:bg-gray-800 dark:text-white",
                      html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${Helpers.capitalize(d.business_type?.replace('_', ' ') || 'sales')}</p>`,
                      confirmMessage: "Change type to '{{value}}'?",
                      successMessage: "Department type updated!",
                      errorMessage: "Failed to update department type!"
                    })
                  })()}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400">
                  <span class="material-symbols-outlined">toggle_on</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Status</p>
                  ${(() => {
                    const options = (Enums()?.department?.workflow_statuses || []).map(s => ({ name: s.name, value: s.value }))
                    return editable({
                      dispatch: "updateDepartment",
                      resource: "department",
                      name: "workflow_status",
                      id: d.id,
                      value: d.workflow_status,
                      url: Helpers.edit_company_department_path(currentCompany().id, d.id),
                      type: "select",
                      options: options,
                      className: "dark:bg-gray-800 dark:text-white",
                      html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${Helpers.statusBadge(d.workflow_status).replace(/<[^>]*>/g, '')}</p>`,
                      confirmMessage: "Change status to '{{value}}'?",
                      successMessage: "Department status updated!",
                      errorMessage: "Failed to update department status!"
                    })
                  })()}
                </div>
              </div>

            </div>
          </div>
        </div>
      </div>
    `
  }

  close(event) {
    event.preventDefault()
    window.closeModal()
  }
}