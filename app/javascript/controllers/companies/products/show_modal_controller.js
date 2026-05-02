import { Controller } from "@hotwired/stimulus"

export default class Companies_Products_ShowModalController extends Controller {
  /** @type {Product | null} */
  product = null

  connect() {
    this.product = /** @type {any} */ (window.currentProduct)

    if (this.product) {
      this.element.innerHTML = this.html()
    }
  }

  html() {
    const p = this.product
    const name = p.name || "N/A"

    return `
      <div class="flex items-center justify-center">
        <div class="relative w-full max-w-[640px] overflow-hidden rounded-xl bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 shadow-2xl">

          <div class="flex items-center justify-between border-b border-slate-200 dark:border-gray-800 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-900 dark:text-white">Product Details</h3>
            <button data-action="click->${this.identifier}#close" class="rounded-full p-2 text-slate-500 dark:text-gray-400 hover:bg-slate-100 dark:hover:bg-gray-800">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          <div class="p-6">
            <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
              <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-emerald-100 dark:border-emerald-900/30 bg-emerald-100 dark:bg-gray-800 shadow-lg flex items-center justify-center">
                <span class="material-symbols-outlined text-4xl text-emerald-600 dark:text-emerald-400">inventory_2</span>
              </div>
              <div class="flex flex-1 flex-col text-center sm:text-left">
                ${editable({
                  dispatch: "updateProduct",
                  resource: "product",
                  name: "name",
                  id: p.id,
                  value: p.name,
                  url: Helpers.edit_company_product_path(currentCompany().id, p.id),
                  html: `<h2 class="text-2xl font-black text-slate-900 dark:text-white">${name}</h2>`,
                  confirmMessage: "Are you sure you want to change this product name to '{{value}}'?",
                  successMessage: "Product name updated successfully!",
                  errorMessage: "Failed to update product name!"
                })}
                ${editable({
                  dispatch: "updateProduct",
                  resource: "product",
                  name: "description",
                  id: p.id,
                  value: p.description || '',
                  url: Helpers.edit_company_product_path(currentCompany().id, p.id),
                  html: `<p class="font-semibold text-emerald-600 dark:text-emerald-400">${p.description || 'No description'}</p>`,
                  confirmMessage: "Change description to '{{value}}'?",
                  successMessage: "Description updated!",
                  errorMessage: "Failed to update description!"
                })}
                <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                  <span class="inline-flex items-center rounded-lg bg-emerald-100 dark:bg-emerald-900/40 px-3 py-1 text-xs font-bold text-emerald-700 dark:text-emerald-300 uppercase">${p.code || 'N/A'}</span>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-6 sm:grid-cols-2">

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600 dark:text-emerald-400">
                  <span class="material-symbols-outlined">category</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Type</p>
                  ${(() => {
                    const options = (Enums()?.product?.business_types || []).map(t => ({ name: t.name, value: t.value }))
                    return editable({
                      dispatch: "updateProduct",
                      resource: "product",
                      name: "business_type",
                      id: p.id,
                      value: p.business_type,
                      url: Helpers.edit_company_product_path(currentCompany().id, p.id),
                      type: "select",
                      options: options,
                      className: "dark:bg-gray-800 dark:text-white",
                      html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${Helpers.capitalize(p.business_type || 'physical')}</p>`,
                      confirmMessage: "Change type to '{{value}}'?",
                      successMessage: "Product type updated!",
                      errorMessage: "Failed to update product type!"
                    })
                  })()}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600 dark:text-emerald-400">
                  <span class="material-symbols-outlined">toggle_on</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Status</p>
                  ${(() => {
                    const options = (Enums()?.product?.workflow_statuses || []).map(s => ({ name: s.name, value: s.value }))
                    return editable({
                      dispatch: "updateProduct",
                      resource: "product",
                      name: "workflow_status",
                      id: p.id,
                      value: p.workflow_status,
                      url: Helpers.edit_company_product_path(currentCompany().id, p.id),
                      type: "select",
                      options: options,
                      className: "dark:bg-gray-800 dark:text-white",
                      html: `<p class="text-sm font-semibold text-slate-900 dark:text-white">${Helpers.statusBadge(p.workflow_status).replace(/<[^>]*>/g, '')}</p>`,
                      confirmMessage: "Change status to '{{value}}'?",
                      successMessage: "Product status updated!",
                      errorMessage: "Failed to update product status!"
                    })
                  })()}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600 dark:text-emerald-400">
                  <span class="material-symbols-outlined">qr_code</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">SKU</p>
                  ${editable({
                    dispatch: "updateProduct",
                    resource: "product",
                    name: "sku",
                    id: p.id,
                    value: p.sku || '',
                    url: Helpers.edit_company_product_path(currentCompany().id, p.id),
                    html: `<p class="text-sm font-semibold text-slate-900 dark:text-white font-mono">${p.sku || 'N/A'}</p>`,
                    confirmMessage: "Change SKU to '{{value}}'?",
                    successMessage: "SKU updated!",
                    errorMessage: "Failed to update SKU!"
                  })}
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600 dark:text-emerald-400">
                  <span class="material-symbols-outlined">pin</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Barcode</p>
                  ${editable({
                    dispatch: "updateProduct",
                    resource: "product",
                    name: "barcode",
                    id: p.id,
                    value: p.barcode || '',
                    url: Helpers.edit_company_product_path(currentCompany().id, p.id),
                    html: `<p class="text-sm font-semibold text-slate-900 dark:text-white font-mono">${p.barcode || 'N/A'}</p>`,
                    confirmMessage: "Change barcode to '{{value}}'?",
                    successMessage: "Barcode updated!",
                    errorMessage: "Failed to update barcode!"
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