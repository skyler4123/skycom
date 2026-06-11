import { Controller } from "@hotwired/stimulus"

export default class Companies_Products_ShowModalController extends Controller {
  /** @type {Product | null} */
  product = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  connect() {
    this.product = /** @type {any} */ (window.currentProduct)

    if (this.product) {
      const categoryId = this.product.category_id
      const propertyMapping = currentPropertyMappings().find(m => m.category_id === categoryId)
      this.propertyMetadata = propertyMapping?.property_metadata || []

      this.element.innerHTML = this.html()
    }
  }

  formatDisplayValue(value, type) {
    if (value === null || value === undefined) return '<span class="text-slate-300 dark:text-slate-700">—</span>'

    switch (type) {
      case 'boolean':
        return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md ${value ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400' : 'bg-slate-50 text-slate-700 dark:bg-slate-800 dark:text-slate-400'}">${value ? 'Yes' : 'No'}</span>`
      case 'integer':
        return `<span class="font-mono text-slate-900 dark:text-slate-100">${Number(value).toLocaleString()}</span>`
      case 'decimal':
        return `<span class="font-mono font-medium text-blue-600 dark:text-blue-400">${Number(value).toFixed(2)}</span>`
      case 'datetime': {
        const d = new Date(value)
        return `<span class="text-sm text-slate-900 dark:text-white">${d.toLocaleString()}</span>`
      }
      default:
        return `<span class="text-sm text-slate-900 dark:text-white">${value}</span>`
    }
  }

  html() {
    const p = this.product
    const name = p.name || "N/A"

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">Properties</h3>
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => {
            const value = p[field.key]
            const inputType = field.type === 'integer' || field.type === 'decimal' ? 'number' : field.type === 'datetime' ? 'datetime-local' : field.type === 'boolean' ? 'checkbox' : 'text'

            return `
              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600 dark:text-emerald-400">
                  <span class="material-symbols-outlined text-[20px]">${field.type === 'boolean' ? 'check_circle' : field.type === 'datetime' ? 'calendar_month' : 'text_fields'}</span>
                </div>
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${field.label}</p>
                  ${Helpers.editable({
                    dispatch: "updateProduct",
                    resource: "product",
                    name: field.key,
                    id: p.id,
                    value: value,
                    url: Helpers.edit_company_product_path(currentCompany().id, p.id),
                    type: inputType,
                    className: "dark:bg-gray-800 dark:text-white",
                    html: this.formatDisplayValue(value, field.type),
                    confirmMessage: `Change ${field.label} to '{{value}}'?`,
                    successMessage: `${field.label} updated!`,
                    errorMessage: `Failed to update ${field.label}!`
                  })}
                </div>
              </div>
            `
          }).join('')}
        </div>
      </div>
    ` : ''

    return `
      <div class="flex items-center justify-center">
        <div class="relative w-full max-w-[640px] overflow-hidden rounded-xl bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 shadow-2xl">

          <div class="flex items-center justify-between border-b border-slate-200 dark:border-gray-800 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Product Details")}</h3>
            <button data-action="click->${this.identifier}#close" class="rounded-full p-2 text-slate-500 dark:text-gray-400 hover:bg-slate-100 dark:hover:bg-gray-800 cursor-pointer">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          <div class="p-6">
            <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
              <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-emerald-100 dark:border-emerald-900/30 bg-emerald-100 dark:bg-gray-800 shadow-lg flex items-center justify-center">
                <span class="material-symbols-outlined text-4xl text-emerald-600 dark:text-emerald-400">inventory_2</span>
              </div>
              <div class="flex flex-1 flex-col text-center sm:text-left">
                ${Helpers.editable({
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
                ${Helpers.editable({
                  dispatch: "updateProduct",
                  resource: "product",
                  name: "description",
                  id: p.id,
                  value: p.description || '',
                  url: Helpers.edit_company_product_path(currentCompany().id, p.id),
                  html: `<p class="font-semibold text-emerald-600 dark:text-emerald-400">${p.description || translate('No description')}</p>`,
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
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Type")}</p>
                  ${(() => {
                    const options = (Enums()?.product?.business_types || []).map(t => ({ name: t.name, value: t.value }))
                    return Helpers.editable({
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
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Status")}</p>
                  ${(() => {
                    const options = (Enums()?.product?.workflow_statuses || []).map(s => ({ name: s.name, value: s.value }))
                    return Helpers.editable({
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
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("SKU")}</p>
                  ${Helpers.editable({
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
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Barcode")}</p>
                  ${Helpers.editable({
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

            ${dynamicFields}
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
