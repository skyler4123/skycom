import { Controller } from "@hotwired/stimulus"

export default class Companies_Services_ShowModalController extends Controller {
  /** @type {Service | null} */
  service = null

  connect() {
    this.service = /** @type {any} */ (window.currentService)

    if (this.service) {
      this.element.innerHTML = this.html()
    }
  }

  html() {
    const s = this.service
    const name = s.name || "N/A"

    return `
      <div class="flex items-center justify-center">
        <div class="relative w-full max-w-[640px] overflow-hidden rounded-xl bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 shadow-2xl">

          <div class="flex items-center justify-between border-b border-slate-200 dark:border-gray-800 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-900 dark:text-white">Service Details</h3>
            <button data-action="click->${this.identifier}#close" class="rounded-full p-2 text-slate-500 dark:text-gray-400 hover:bg-slate-100 dark:hover:bg-gray-800">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          <div class="p-6">
            <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
              <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-rose-100 dark:border-rose-900/30 bg-rose-100 dark:bg-gray-800 shadow-lg flex items-center justify-center">
                <span class="material-symbols-outlined text-4xl text-rose-600 dark:text-rose-400">content_cut</span>
              </div>
              <div class="flex flex-1 flex-col text-center sm:text-left">
                ${editable({
                  dispatch: "updateService",
                  resource: "service",
                  name: "name",
                  id: s.id,
                  value: s.name,
                  url: Helpers.edit_company_service_path(currentCompany().id, s.id),
                  html: `<h2 class="text-2xl font-black text-slate-900 dark:text-white">${name}</h2>`,
                  confirmMessage: "Are you sure you want to change this service name to '{{value}}'?",
                  successMessage: "Service name updated successfully!",
                  errorMessage: "Failed to update service name!"
                })}
                ${editable({
                  dispatch: "updateService",
                  resource: "service",
                  name: "description",
                  id: s.id,
                  value: s.description || '',
                  url: Helpers.edit_company_service_path(currentCompany().id, s.id),
                  html: `<p class="font-semibold text-rose-600 dark:text-rose-400">${s.description || 'No description'}</p>`,
                  confirmMessage: "Change description to '{{value}}'?",
                  successMessage: "Description updated!",
                  errorMessage: "Failed to update description!"
                })}
                <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                  <span class="inline-flex items-center rounded-lg bg-rose-100 dark:bg-rose-900/40 px-3 py-1 text-xs font-bold text-rose-700 dark:text-rose-300 uppercase">${s.code || 'N/A'}</span>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-6 sm:grid-cols-2">

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-rose-600 dark:text-rose-400">
                  <span class="material-symbols-outlined">category</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Type</p>
                  ${(() => {
                    const options = (Enums()?.service?.business_types || []).map(t => ({ name: t.name.toUpperCase(), value: t.value }))
                    return editable({
                      dispatch: "updateService",
                      resource: "service",
                      name: "business_type",
                      id: s.id,
                      value: s.business_type,
                      url: Helpers.edit_company_service_path(currentCompany().id, s.id),
                      type: "select",
                      options: options,
                      className: "dark:bg-gray-800 dark:text-white",
                      html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${s.business_type?.toUpperCase() || 'B2B'}</p>`,
                      confirmMessage: "Change type to '{{value}}'?",
                      successMessage: "Service type updated!",
                      errorMessage: "Failed to update service type!"
                    })
                  })()}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-rose-600 dark:text-rose-400">
                  <span class="material-symbols-outlined">toggle_on</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Status</p>
                  ${(() => {
                    const options = (Enums()?.service?.workflow_statuses || []).map(sv => ({ name: sv.name, value: sv.value }))
                    return editable({
                      dispatch: "updateService",
                      resource: "service",
                      name: "workflow_status",
                      id: s.id,
                      value: s.workflow_status,
                      url: Helpers.edit_company_service_path(currentCompany().id, s.id),
                      type: "select",
                      options: options,
                      className: "dark:bg-gray-800 dark:text-white",
                      html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${Helpers.statusBadge(s.workflow_status).replace(/<[^>]*>/g, '')}</p>`,
                      confirmMessage: "Change status to '{{value}}'?",
                      successMessage: "Service status updated!",
                      errorMessage: "Failed to update service status!"
                    })
                  })()}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-rose-600 dark:text-rose-400">
                  <span class="material-symbols-outlined">schedule</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Duration</p>
                  ${editable({
                    dispatch: "updateService",
                    resource: "service",
                    name: "duration",
                    id: s.id,
                    value: s.duration || '',
                    url: Helpers.edit_company_service_path(currentCompany().id, s.id),
                    html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${s.duration ? s.duration + ' minutes' : 'N/A'}</p>`,
                    confirmMessage: "Change duration to '{{value}}'?",
                    successMessage: "Duration updated!",
                    errorMessage: "Failed to update duration!"
                  })}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-rose-600 dark:text-rose-400">
                  <span class="material-symbols-outlined">qr_code</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Service Code</p>
                  ${editable({
                    dispatch: "updateService",
                    resource: "service",
                    name: "code",
                    id: s.id,
                    value: s.code || '',
                    url: Helpers.edit_company_service_path(currentCompany().id, s.id),
                    html: `<p class="text-sm font-semibold text-slate-900 dark:text-white font-mono">${s.code || 'N/A'}</p>`,
                    confirmMessage: "Change code to '{{value}}'?",
                    successMessage: "Service code updated!",
                    errorMessage: "Failed to update service code!"
                  })}
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