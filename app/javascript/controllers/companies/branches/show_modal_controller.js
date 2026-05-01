import { Controller } from "@hotwired/stimulus"

export default class Companies_Branches_ShowModalController extends Controller {
  /** @type {Branch | null} */
  branch = null

  connect() {
    this.branch = /** @type {any} */ (window.currentBranch)

    if (this.branch) {
      this.element.innerHTML = this.html()
    }
  }

  html() {
    const b = this.branch
    const name = b.name || "N/A"

    const typeOptions = (Enums()?.branch?.business_types || []).map(t =>
      `<option value="${t.value}">${t.name}</option>`
    ).join('')

    const workflowOptions = (Enums()?.branch?.workflow_statuses || []).map(s =>
      `<option value="${s.value}">${s.name}</option>`
    ).join('')

    return `
      <div class="flex items-center justify-center">
        <div class="relative w-full max-w-[640px] overflow-hidden rounded-xl bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 shadow-2xl">

          <div class="flex items-center justify-between border-b border-slate-200 dark:border-gray-800 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-900 dark:text-white">Branch Details</h3>
            <button data-action="click->${this.identifier}#close" class="rounded-full p-2 text-slate-500 dark:text-gray-400 hover:bg-slate-100 dark:hover:bg-gray-800">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          <div class="p-6">
            <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
              <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-blue-100 dark:border-blue-900/30 bg-blue-100 dark:bg-gray-800 shadow-lg flex items-center justify-center">
                <span class="material-symbols-outlined text-4xl text-blue-600 dark:text-blue-400">store</span>
              </div>
              <div class="flex flex-1 flex-col text-center sm:text-left">
                ${editable({
                  dispatch: "updateBranch",
                  resource: "branch",
                  name: "name",
                  id: b.id,
                  value: b.name,
                  url: Helpers.edit_company_branch_path(currentCompany().id, b.id),
                  html: `<h2 class="text-2xl font-black text-slate-900 dark:text-white">${name}</h2>`,
                  confirmMessage: "Are you sure you want to change this branch name to '{{value}}'?",
                  successMessage: "Branch name updated successfully!",
                  errorMessage: "Failed to update branch name!"
                })}
                ${editable({
                  dispatch: "updateBranch",
                  resource: "branch",
                  name: "description",
                  id: b.id,
                  value: b.description || '',
                  url: Helpers.edit_company_branch_path(currentCompany().id, b.id),
                  html: `<p class="font-semibold text-blue-600 dark:text-blue-400">${b.description || 'No description'}</p>`,
                  confirmMessage: "Change description to '{{value}}'?",
                  successMessage: "Description updated!",
                  errorMessage: "Failed to update description!"
                })}
                <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                  <span class="inline-flex items-center rounded-lg bg-blue-100 dark:bg-blue-900/40 px-3 py-1 text-xs font-bold text-blue-700 dark:text-blue-300 uppercase">${b.code || 'N/A'}</span>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-6 sm:grid-cols-2">

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">category</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Type</p>
                  ${(() => {
                    const options = (Enums()?.branch?.business_types || []).map(t => ({ name: t.name, value: t.value }))
                    return editable({
                      dispatch: "updateBranch",
                      resource: "branch",
                      name: "business_type",
                      id: b.id,
                      value: b.business_type,
                      url: Helpers.edit_company_branch_path(currentCompany().id, b.id),
                      type: "select",
                      options: options,
                      className: "dark:bg-gray-800 dark:text-white",
                      html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${Helpers.capitalize(b.business_type?.replace('_', ' ') || 'storefront')}</p>`,
                      confirmMessage: "Change type to '{{value}}'?",
                      successMessage: "Branch type updated!",
                      errorMessage: "Failed to update branch type!"
                    })
                  })()}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">toggle_on</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Status</p>
                  ${(() => {
                    const options = (Enums()?.branch?.workflow_statuses || []).map(s => ({ name: s.name, value: s.value }))
                    return editable({
                      dispatch: "updateBranch",
                      resource: "branch",
                      name: "workflow_status",
                      id: b.id,
                      value: b.workflow_status,
                      url: Helpers.edit_company_branch_path(currentCompany().id, b.id),
                      type: "select",
                      options: options,
                      className: "dark:bg-gray-800 dark:text-white",
                      html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${Helpers.statusBadge(b.workflow_status).replace(/<[^>]*>/g, '')}</p>`,
                      confirmMessage: "Change status to '{{value}}'?",
                      successMessage: "Branch status updated!",
                      errorMessage: "Failed to update branch status!"
                    })
                  })()}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">location_on</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">City</p>
                  ${editable({
                    dispatch: "updateBranch",
                    resource: "branch",
                    name: "city",
                    id: b.id,
                    value: b.city || '',
                    url: Helpers.edit_company_branch_path(currentCompany().id, b.id),
                    html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${b.city || 'N/A'}</p>`,
                    confirmMessage: "Change city to '{{value}}'?",
                    successMessage: "City updated!",
                    errorMessage: "Failed to update city!"
                  })}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">phone</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Phone</p>
                  ${editable({
                    dispatch: "updateBranch",
                    resource: "branch",
                    name: "phone_number",
                    id: b.id,
                    value: b.phone_number || '',
                    url: Helpers.edit_company_branch_path(currentCompany().id, b.id),
                    html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${b.phone_number || 'N/A'}</p>`,
                    confirmMessage: "Change phone to '{{value}}'?",
                    successMessage: "Phone updated!",
                    errorMessage: "Failed to update phone!"
                  })}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">mail</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Email</p>
                  ${editable({
                    dispatch: "updateBranch",
                    resource: "branch",
                    name: "email",
                    id: b.id,
                    value: b.email || '',
                    url: Helpers.edit_company_branch_path(currentCompany().id, b.id),
                    html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${b.email || 'N/A'}</p>`,
                    confirmMessage: "Change email to '{{value}}'?",
                    successMessage: "Email updated!",
                    errorMessage: "Failed to update email!"
                  })}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">group</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Employee Count</p>
                  <p class="text-sm font-semibold text-slate-900 dark:text-white">${b.employee_count || 0}</p>
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