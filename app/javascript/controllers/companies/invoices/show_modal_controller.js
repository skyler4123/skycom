import { Controller } from "@hotwired/stimulus"

export default class Companies_Invoices_ShowModalController extends Controller {
  /** @type {Invoice | null} */
  invoice = null

  connect() {
    this.invoice = /** @type {any} */ (window.currentInvoice)

    if (this.invoice) {
      this.element.innerHTML = this.html()
    }
  }

  html() {
    const i = this.invoice
    const name = i.name || "N/A"

    return `
      <div class="flex items-center justify-center">
        <div class="relative w-full max-w-[640px] overflow-hidden rounded-xl bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 shadow-2xl">

          <div class="flex items-center justify-between border-b border-slate-200 dark:border-gray-800 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-900 dark:text-white">Invoice Details</h3>
            <button data-action="click->${this.identifier}#close" class="rounded-full p-2 text-slate-500 dark:text-gray-400 hover:bg-slate-100 dark:hover:bg-gray-800">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          <div class="p-6">
            <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
              <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-orange-100 dark:border-orange-900/30 bg-orange-100 dark:bg-gray-800 shadow-lg flex items-center justify-center">
                <span class="material-symbols-outlined text-4xl text-orange-600 dark:text-orange-400">receipt</span>
              </div>
              <div class="flex flex-1 flex-col text-center sm:text-left">
                ${editable({
                  dispatch: "updateInvoice",
                  resource: "invoice",
                  name: "name",
                  id: i.id,
                  value: i.name,
                  url: Helpers.edit_company_invoice_path(currentCompany().id, i.id),
                  html: `<h2 class="text-2xl font-black text-slate-900 dark:text-white">${name}</h2>`,
                  confirmMessage: "Are you sure you want to change this invoice name to '{{value}}'?",
                  successMessage: "Invoice name updated successfully!",
                  errorMessage: "Failed to update invoice name!"
                })}
                <div class="mt-2">
                  <span class="text-lg font-mono text-orange-600 dark:text-orange-400">${i.number || 'N/A'}</span>
                </div>
                <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                  <span class="inline-flex items-center rounded-lg bg-orange-100 dark:bg-orange-900/40 px-3 py-1 text-xs font-bold text-orange-700 dark:text-orange-300 uppercase">${i.currency_code?.toUpperCase() || 'USD'} ${i.total_price || '0.00'}</span>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-6 sm:grid-cols-2">

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-orange-600 dark:text-orange-400">
                  <span class="material-symbols-outlined">category</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Type</p>
                  ${(() => {
                    const options = (Enums()?.invoice?.business_types || []).map(t => ({ name: t.name === 'subscription' ? 'Subscription' : t.name, value: t.value }))
                    return editable({
                      dispatch: "updateInvoice",
                      resource: "invoice",
                      name: "business_type",
                      id: i.id,
                      value: i.business_type,
                      url: Helpers.edit_company_invoice_path(currentCompany().id, i.id),
                      type: "select",
                      options: options,
                      className: "dark:bg-gray-800 dark:text-white",
                      html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${i.business_type === 'subscription' ? 'Subscription' : i.business_type?.toUpperCase() || 'SALES'}</p>`,
                      confirmMessage: "Change type to '{{value}}'?",
                      successMessage: "Invoice type updated!",
                      errorMessage: "Failed to update invoice type!"
                    })
                  })()}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-orange-600 dark:text-orange-400">
                  <span class="material-symbols-outlined">toggle_on</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Status</p>
                  ${(() => {
                    const options = (Enums()?.invoice?.workflow_statuses || []).map(iv => ({ name: iv.name, value: iv.value }))
                    return editable({
                      dispatch: "updateInvoice",
                      resource: "invoice",
                      name: "workflow_status",
                      id: i.id,
                      value: i.workflow_status,
                      url: Helpers.edit_company_invoice_path(currentCompany().id, i.id),
                      type: "select",
                      options: options,
                      className: "dark:bg-gray-800 dark:text-white",
                      html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${Helpers.statusBadge(i.workflow_status).replace(/<[^>]*>/g, '')}</p>`,
                      confirmMessage: "Change status to '{{value}}'?",
                      successMessage: "Invoice status updated!",
                      errorMessage: "Failed to update invoice status!"
                    })
                  })()}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-orange-600 dark:text-orange-400">
                  <span class="material-symbols-outlined">payments</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Total Price</p>
                  ${editable({
                    dispatch: "updateInvoice",
                    resource: "invoice",
                    name: "total_price",
                    id: i.id,
                    value: i.total_price || '',
                    url: Helpers.edit_company_invoice_path(currentCompany().id, i.id),
                    html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${i.currency_code?.toUpperCase() || 'USD'} ${i.total_price || '0.00'}</p>`,
                    confirmMessage: "Change price to '{{value}}'?",
                    successMessage: "Price updated!",
                    errorMessage: "Failed to update price!"
                  })}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-orange-600 dark:text-orange-400">
                  <span class="material-symbols-outlined">calendar_today</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Due Date</p>
                  <p class="text-sm font-semibold text-slate-900 dark:text-white">${i.due_date ? new Date(i.due_date).toLocaleDateString() : 'N/A'}</p>
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