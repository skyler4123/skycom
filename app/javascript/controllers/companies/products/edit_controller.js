import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Products_EditController extends Companies_LayoutController {
  /** @type {Product | null} */
  product = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const productId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_product_path(companyId, productId)}.json`)
      this.product = response.product

      if (this.product?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.product.category_id)
        this.propertyMetadata = propertyMapping?.property_metadata || []
      }

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      poll(() => {
        if (this.hasContentTarget) {
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">Failed to load product.</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    const p = this.product
    if (!p) return '<div class="p-8 text-center">Product not found.</div>'

    const companyId = window.location.pathname.split("/")[2]
    const businessTypes = Enums()?.product?.business_types || []
    const workflowStatuses = Enums()?.product?.workflow_statuses || []

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">Properties</h3>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => {
            const value = p[field.key]
            let inputHTML = ''
            switch (field.type) {
              case 'boolean':
                inputHTML = `
                  <input type="hidden" name="product[${field.key}]" value="false">
                  <input type="checkbox" name="product[${field.key}]" value="true" ${value ? 'checked' : ''}
                    class="rounded border-slate-300 dark:border-slate-600 text-blue-600 cursor-pointer">
                `
                break
              case 'integer':
                inputHTML = `<input type="number" step="1" name="product[${field.key}]" value="${value ?? ''}"
                  class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              case 'decimal':
                inputHTML = `<input type="number" step="0.01" name="product[${field.key}]" value="${value ?? ''}"
                  class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              case 'datetime':
                inputHTML = `<input type="datetime-local" name="product[${field.key}]" value="${value ?? ''}"
                  class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              case 'text':
                inputHTML = `<textarea name="product[${field.key}]" rows="3"
                  class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${value ?? ''}</textarea>`
                break
              default:
                inputHTML = `<input type="text" name="product[${field.key}]" value="${value ?? ''}"
                  class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
            }
            return `
              <div>
                <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${field.label}</label>
                ${inputHTML}
              </div>
            `
          }).join('')}
        </div>
      </div>
    ` : ''

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">Edit Product</h2>
        <p class="text-sm text-slate-500">${p.name}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">Name</label>
            <input type="text" name="product[name]" value="${p.name || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">Description</label>
            <textarea name="product[description]" rows="2"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${p.description || ''}</textarea>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">Type</label>
            <select name="product[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(businessTypes, p.business_type || 'physical')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">Status</label>
            <select name="product[workflow_status]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(workflowStatuses, p.workflow_status)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">Category</label>
            <input type="text" value="${currentCategories().find(c => c.id === p.category_id)?.name || ''}" disabled
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-slate-700 text-sm text-slate-400">
            <input type="hidden" name="product[category_id]" value="${p.category_id}">
          </div>
        </div>

        ${dynamicFields}

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_product_path(companyId, p.id)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
            Cancel
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            Save Changes
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_product_path(companyId, p.id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
