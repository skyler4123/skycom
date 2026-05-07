import { Controller } from "@hotwired/stimulus"

export default class Companies_Customers_ShowModalController extends Controller {
  /** @type {Customer | null} */
  customer = null

  connect() {
    this.customer = /** @type {any} */ (window.currentCustomer)

    if (this.customer) {
      this.element.innerHTML = this.html()
    }
  }

  html() {
    const c = this.customer
    const name = c.name || "N/A"

    return `
      <div class="flex items-center justify-center">
        <div class="relative w-full max-w-[640px] overflow-hidden rounded-xl bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 shadow-2xl">

          <div class="flex items-center justify-between border-b border-slate-200 dark:border-gray-800 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-900 dark:text-white">Customer Details</h3>
            <button data-action="click->${this.identifier}#close" class="rounded-full p-2 text-slate-500 dark:text-gray-400 hover:bg-slate-100 dark:hover:bg-gray-800">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          <div class="p-6">
            <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
              <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-purple-100 dark:border-purple-900/30 bg-purple-100 dark:bg-gray-800 shadow-lg flex items-center justify-center">
                <span class="material-symbols-outlined text-4xl text-purple-600 dark:text-purple-400">person</span>
              </div>
              <div class="flex flex-1 flex-col text-center sm:text-left">
                ${editable({
                  dispatch: "updateCustomer",
                  resource: "customer",
                  name: "name",
                  id: c.id,
                  value: c.name,
                  url: Helpers.edit_company_customer_path(currentCompany().id, c.id),
                  html: `<h2 class="text-2xl font-black text-slate-900 dark:text-white">${name}</h2>`,
                  confirmMessage: "Are you sure you want to change this customer name to '{{value}}'?",
                  successMessage: "Customer name updated successfully!",
                  errorMessage: "Failed to update customer name!"
                })}
                ${editable({
                  dispatch: "updateCustomer",
                  resource: "customer",
                  name: "description",
                  id: c.id,
                  value: c.description || '',
                  url: Helpers.edit_company_customer_path(currentCompany().id, c.id),
                  html: `<p class="font-semibold text-purple-600 dark:text-purple-400">${c.description || 'No description'}</p>`,
                  confirmMessage: "Change description to '{{value}}'?",
                  successMessage: "Description updated!",
                  errorMessage: "Failed to update description!"
                })}
                <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                  <span class="inline-flex items-center rounded-lg bg-purple-100 dark:bg-purple-900/40 px-3 py-1 text-xs font-bold text-purple-700 dark:text-purple-300 uppercase">${c.code || 'N/A'}</span>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-6 sm:grid-cols-2">

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-purple-600 dark:text-purple-400">
                  <span class="material-symbols-outlined">category</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Type</p>
                  ${(() => {
                    const options = (Enums()?.customer?.business_types || []).map(t => ({ name: t.name === 'small_business' ? 'Small Business' : t.name, value: t.value }))
                    return editable({
                      dispatch: "updateCustomer",
                      resource: "customer",
                      name: "business_type",
                      id: c.id,
                      value: c.business_type,
                      url: Helpers.edit_company_customer_path(currentCompany().id, c.id),
                      type: "select",
                      options: options,
                      className: "dark:bg-gray-800 dark:text-white",
                      html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${c.business_type === 'small_business' ? 'Small Business' : Helpers.capitalize(c.business_type || 'individual')}</p>`,
                      confirmMessage: "Change type to '{{value}}'?",
                      successMessage: "Customer type updated!",
                      errorMessage: "Failed to update customer type!"
                    })
                  })()}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-purple-600 dark:text-purple-400">
                  <span class="material-symbols-outlined">toggle_on</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Status</p>
                  ${(() => {
                    const options = (Enums()?.customer?.workflow_statuses || []).map(sv => ({ name: sv.name, value: sv.value }))
                    return editable({
                      dispatch: "updateCustomer",
                      resource: "customer",
                      name: "workflow_status",
                      id: c.id,
                      value: c.workflow_status,
                      url: Helpers.edit_company_customer_path(currentCompany().id, c.id),
                      type: "select",
                      options: options,
                      className: "dark:bg-gray-800 dark:text-white",
                      html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${Helpers.statusBadge(c.workflow_status).replace(/<[^>]*>/g, '')}</p>`,
                      confirmMessage: "Change status to '{{value}}'?",
                      successMessage: "Customer status updated!",
                      errorMessage: "Failed to update customer status!"
                    })
                  })()}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-purple-600 dark:text-purple-400">
                  <span class="material-symbols-outlined">mail</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Email</p>
                  ${editable({
                    dispatch: "updateCustomer",
                    resource: "customer",
                    name: "email",
                    id: c.id,
                    value: c.email || '',
                    url: Helpers.edit_company_customer_path(currentCompany().id, c.id),
                    html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${c.email || 'N/A'}</p>`,
                    confirmMessage: "Change email to '{{value}}'?",
                    successMessage: "Email updated!",
                    errorMessage: "Failed to update email!"
                  })}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-purple-600 dark:text-purple-400">
                  <span class="material-symbols-outlined">qr_code</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Customer Code</p>
                  ${editable({
                    dispatch: "updateCustomer",
                    resource: "customer",
                    name: "code",
                    id: c.id,
                    value: c.code || '',
                    url: Helpers.edit_company_customer_path(currentCompany().id, c.id),
                    html: `<p class="text-sm font-semibold text-slate-900 dark:text-white font-mono">${c.code || 'N/A'}</p>`,
                    confirmMessage: "Change code to '{{value}}'?",
                    successMessage: "Customer code updated!",
                    errorMessage: "Failed to update customer code!"
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
    closeModal()
  }
}