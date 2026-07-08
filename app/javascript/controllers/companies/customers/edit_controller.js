import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Customers_EditController extends Companies_LayoutController {
  /** @type {Customer | null} */
  customer = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const recordId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_customer_path(companyId, recordId)}.json`)
      this.customer = response.customer

      if (this.customer?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.customer.category_id)
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load customer.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    const c = this.customer
    if (!c) return `<div class="p-8 text-center">${translate('Customer not found.')}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const businessTypes = Enums()?.customer?.business_types || [
      { name: translate("Individual"), value: "individual" },
      { name: translate("Small Business"), value: "small_business" },
      { name: translate("Enterprise"), value: "enterprise" }
    ]
    const workflowStatuses = Enums()?.customer?.workflow_statuses || [
      { name: translate("Draft"), value: "draft" },
      { name: translate("Pending"), value: "pending" },
      { name: translate("Confirmed"), value: "confirmed" },
      { name: translate("In Progress"), value: "in_progress" },
      { name: translate("Completed"), value: "completed" },
      { name: translate("Paid"), value: "paid" }
    ]

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => {
            const value = c[field.key]
            let inputHTML = ''
            switch (field.type) {
              case 'boolean':
                inputHTML = `
                  <input type="hidden" name="customer[${field.key}]" value="false">
                  <input type="checkbox" name="customer[${field.key}]" value="true" ${value ? 'checked' : ''}
                    class="rounded border-slate-300 dark:border-slate-600 text-blue-600 cursor-pointer">`
                break
              case 'integer':
                inputHTML = `<input type="number" step="1" name="customer[${field.key}]" value="${value ?? ''}" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              case 'decimal':
                inputHTML = `<input type="number" step="0.01" name="customer[${field.key}]" value="${value ?? ''}" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              case 'datetime':
                inputHTML = `<input type="datetime-local" name="customer[${field.key}]" value="${value ?? ''}" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              case 'text':
                inputHTML = `<textarea name="customer[${field.key}]" rows="3" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${value ?? ''}</textarea>`
                break
              default:
                inputHTML = `<input type="text" name="customer[${field.key}]" value="${value ?? ''}" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
            }
            return `
              <div>
                <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${field.name}</label>
                ${inputHTML}
              </div>`
          }).join('')}
        </div>
      </div>
    ` : ''

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Customer")}</h2>
        <p class="text-sm text-slate-500">${c.name}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Name")}</label>
            <input type="text" name="customer[name]" value="${c.name || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Email")}</label>
            <input type="email" name="customer[email]" value="${c.email || ''}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Description")}</label>
            <textarea name="customer[description]" rows="2"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${c.description || ''}</textarea>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Type")}</label>
            <select name="customer[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(businessTypes.map(t => ({ name: t.name === 'small_business' ? translate("Small Business") : t.name, value: t.value })), c.business_type || '')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Status")}</label>
            <select name="customer[workflow_status]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(workflowStatuses, c.workflow_status)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Category")}</label>
            <input type="text" value="${currentCategories().find(cat => cat.id === c.category_id)?.name || ''}" disabled
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-slate-700 text-sm text-slate-400">
            <input type="hidden" name="customer[category_id]" value="${c.category_id}">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Code")}</label>
            <input type="text" name="customer[code]" value="${c.code || ''}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
        </div>

        ${dynamicFields}

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_customer_path(companyId, c.id)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Changes")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_customer_path(companyId, c.id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
