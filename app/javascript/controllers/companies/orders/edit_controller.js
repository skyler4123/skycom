import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Orders_EditController extends Companies_LayoutController {
  /** @type {(Order & { category?: { id: string, name: string } }) | null} */
  order = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const orderId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_order_path(companyId, orderId)}.json`)
      this.order = response.order

      if (this.order?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.order.category_id)
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
          this.contentTarget.innerHTML = '<div class="p-8 text-center text-red-600">Failed to load order.</div>'
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    const o = this.order
    if (!o) return '<div class="p-8 text-center">Order not found.</div>'

    const companyId = window.location.pathname.split("/")[2]
    const businessTypes = Enums()?.order?.business_types || []
    const workflowStatuses = Enums()?.order?.workflow_statuses || []
    const currencyCodes = Enums()?.order?.currency_codes || []

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase mb-4">Properties</h3>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => {
            const value = o[field.key]
            let inputHTML = ''
            switch (field.type) {
              case 'boolean':
                inputHTML = `
                  <input type="hidden" name="order[${field.key}]" value="false">
                  <input type="checkbox" name="order[${field.key}]" value="true" ${value ? 'checked' : ''}
                    class="rounded border-slate-300 text-blue-600 cursor-pointer">`
                break
              case 'integer':
                inputHTML = `<input type="number" step="1" name="order[${field.key}]" value="${value ?? ''}"
                  class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              case 'decimal':
                inputHTML = `<input type="number" step="0.01" name="order[${field.key}]" value="${value ?? ''}"
                  class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              case 'datetime':
                inputHTML = `<input type="datetime-local" name="order[${field.key}]" value="${value ?? ''}"
                  class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              case 'text':
                inputHTML = `<textarea name="order[${field.key}]" rows="3"
                  class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${value ?? ''}</textarea>`
                break
              default:
                inputHTML = `<input type="text" name="order[${field.key}]" value="${value ?? ''}"
                  class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
            }
            return `
              <div>
                <label class="text-xs font-medium text-slate-500">${field.label}</label>
                ${inputHTML}
              </div>
            `
          }).join('')}
        </div>
      </div>
    ` : ''

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">Edit Order</h2>
        <p class="text-sm text-slate-500">${o.name}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500">Name</label>
            <input type="text" name="order[name]" value="${o.name || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500">Description</label>
            <textarea name="order[description]" rows="2"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${o.description || ''}</textarea>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500">Type</label>
            <select name="order[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(businessTypes, o.business_type)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500">Status</label>
            <select name="order[workflow_status]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(workflowStatuses, o.workflow_status)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500">Currency</label>
            <select name="order[currency_code]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(currencyCodes, o.currency_code)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500">Code</label>
            <input type="text" name="order[code]" value="${o.code || ''}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500">Category</label>
            <input type="text" value="${currentCategories().find(c => c.id === o.category_id)?.name || ''}" disabled
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-400">
            <input type="hidden" name="order[category_id]" value="${o.category_id}">
          </div>
        </div>

        ${dynamicFields}

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_order_path(companyId, o.id)}"
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
          action: Helpers.company_order_path(companyId, o.id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
