import { Controller } from "@hotwired/stimulus"

export default class Companies_Orders_ShowModalController extends Controller {
  /** @type {Order | null} */
  order = null

  connect() {
    this.order = /** @type {any} */ (window.currentOrder)

    if (this.order) {
      this.element.innerHTML = this.html()
    }
  }

  html() {
    const o = this.order
    const name = o.name || "N/A"

    return `
      <div class="flex items-center justify-center">
        <div class="relative w-full max-w-[640px] overflow-hidden rounded-xl bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 shadow-2xl">

          <div class="flex items-center justify-between border-b border-slate-200 dark:border-gray-800 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-900 dark:text-white">Order Details</h3>
            <button data-action="click->${this.identifier}#close" class="rounded-full p-2 text-slate-500 dark:text-gray-400 hover:bg-slate-100 dark:hover:bg-gray-800">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          <div class="p-6">
            <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
              <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-amber-100 dark:border-amber-900/30 bg-amber-100 dark:bg-gray-800 shadow-lg flex items-center justify-center">
                <span class="material-symbols-outlined text-4xl text-amber-600 dark:text-amber-400">receipt_long</span>
              </div>
              <div class="flex flex-1 flex-col text-center sm:text-left">
                ${editable({
                  dispatch: "updateOrder",
                  resource: "order",
                  name: "name",
                  id: o.id,
                  value: o.name,
                  url: Helpers.edit_company_order_path(currentCompany().id, o.id),
                  html: `<h2 class="text-2xl font-black text-slate-900 dark:text-white">${name}</h2>`,
                  confirmMessage: "Are you sure you want to change this order name to '{{value}}'?",
                  successMessage: "Order name updated successfully!",
                  errorMessage: "Failed to update order name!"
                })}
                ${editable({
                  dispatch: "updateOrder",
                  resource: "order",
                  name: "description",
                  id: o.id,
                  value: o.description || '',
                  url: Helpers.edit_company_order_path(currentCompany().id, o.id),
                  html: `<p class="font-semibold text-amber-600 dark:text-amber-400">${o.description || 'No description'}</p>`,
                  confirmMessage: "Change description to '{{value}}'?",
                  successMessage: "Description updated!",
                  errorMessage: "Failed to update description!"
                })}
                <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                  <span class="inline-flex items-center rounded-lg bg-amber-100 dark:bg-amber-900/40 px-3 py-1 text-xs font-bold text-amber-700 dark:text-amber-300 uppercase">${o.code || 'N/A'}</span>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-6 sm:grid-cols-2">

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-amber-600 dark:text-amber-400">
                  <span class="material-symbols-outlined">category</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Order Type</p>
                  ${(() => {
                    const options = (Enums()?.order?.business_types || []).map(t => ({ name: t.name === 'in_store' ? 'In Store' : t.name.toUpperCase(), value: t.value }))
                    return editable({
                      dispatch: "updateOrder",
                      resource: "order",
                      name: "business_type",
                      id: o.id,
                      value: o.business_type,
                      url: Helpers.edit_company_order_path(currentCompany().id, o.id),
                      type: "select",
                      options: options,
                      className: "dark:bg-gray-800 dark:text-white",
                      html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${o.business_type === 'in_store' ? 'In Store' : o.business_type?.toUpperCase() || 'ONLINE'}</p>`,
                      confirmMessage: "Change type to '{{value}}'?",
                      successMessage: "Order type updated!",
                      errorMessage: "Failed to update order type!"
                    })
                  })()}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-amber-600 dark:text-amber-400">
                  <span class="material-symbols-outlined">toggle_on</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Status</p>
                  ${(() => {
                    const options = (Enums()?.order?.workflow_statuses || []).map(sv => ({ name: sv.name, value: sv.value }))
                    return editable({
                      dispatch: "updateOrder",
                      resource: "order",
                      name: "workflow_status",
                      id: o.id,
                      value: o.workflow_status,
                      url: Helpers.edit_company_order_path(currentCompany().id, o.id),
                      type: "select",
                      options: options,
                      className: "dark:bg-gray-800 dark:text-white",
                      html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${Helpers.statusBadge(o.workflow_status).replace(/<[^>]*>/g, '')}</p>`,
                      confirmMessage: "Change status to '{{value}}'?",
                      successMessage: "Order status updated!",
                      errorMessage: "Failed to update order status!"
                    })
                  })()}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-amber-600 dark:text-amber-400">
                  <span class="material-symbols-outlined">payments</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Currency</p>
                  ${editable({
                    dispatch: "updateOrder",
                    resource: "order",
                    name: "currency_code",
                    id: o.id,
                    value: o.currency_code || '',
                    url: Helpers.edit_company_order_path(currentCompany().id, o.id),
                    html: `<p class="text-sm font-semibold text-slate-900 dark:text-white font-mono">${o.currency_code?.toUpperCase() || 'USD'}</p>`,
                    confirmMessage: "Change currency to '{{value}}'?",
                    successMessage: "Currency updated!",
                    errorMessage: "Failed to update currency!"
                  })}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-amber-600 dark:text-amber-400">
                  <span class="material-symbols-outlined">qr_code</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Order Code</p>
                  ${editable({
                    dispatch: "updateOrder",
                    resource: "order",
                    name: "code",
                    id: o.id,
                    value: o.code || '',
                    url: Helpers.edit_company_order_path(currentCompany().id, o.id),
                    html: `<p class="text-sm font-semibold text-slate-900 dark:text-white font-mono">${o.code || 'N/A'}</p>`,
                    confirmMessage: "Change code to '{{value}}'?",
                    successMessage: "Order code updated!",
                    errorMessage: "Failed to update order code!"
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