import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Invoices_EditController extends Companies_LayoutController {
  /** @type {(Invoice & { category?: { id: string, name: string } }) | null} */
  invoice = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const invoiceId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_invoice_path(companyId, invoiceId)}.json`)
      this.invoice = response.invoice

      if (this.invoice?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.invoice.category_id)
        this.propertyMetadata = propertyMapping?.metadata?.properties || []
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load invoice.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    const i = this.invoice
    if (!i) return `<div class="p-8 text-center">${translate("Invoice not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const businessTypes = Enums()?.invoice?.business_types || []
    const workflowStatuses = Enums()?.invoice?.workflow_statuses || []
    const currencyCodes = Enums()?.invoice?.currencies || []

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => {
            const value = i[field.key]
            let inputHTML = ''
            switch (field.type) {
              case 'boolean':
                inputHTML = `
                  <input type="hidden" name="invoice[${field.key}]" value="false">
                  <input type="checkbox" name="invoice[${field.key}]" value="true" ${value ? 'checked' : ''}
                    class="rounded border-slate-300 text-blue-600 cursor-pointer">`
                break
              case 'integer':
                inputHTML = `<input type="number" step="1" name="invoice[${field.key}]" value="${value ?? ''}"
                  class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              case 'decimal':
                inputHTML = `<input type="number" step="0.01" name="invoice[${field.key}]" value="${value ?? ''}"
                  class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              case 'datetime':
                inputHTML = `<input type="datetime-local" name="invoice[${field.key}]" value="${value ?? ''}"
                  class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              case 'text':
                inputHTML = `<textarea name="invoice[${field.key}]" rows="3"
                  class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${value ?? ''}</textarea>`
                break
              default:
                inputHTML = `<input type="text" name="invoice[${field.key}]" value="${value ?? ''}"
                  class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
            }
            return `
              <div>
                <label class="text-xs font-medium text-slate-500">${field.name}</label>
                ${inputHTML}
              </div>
            `
          }).join('')}
        </div>
      </div>
    ` : ''

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Invoice")}</h2>
        <p class="text-sm text-slate-500">${i.name}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500">${translate("Name")}</label>
            <input type="text" name="invoice[name]" value="${i.name || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500">${translate("Description")}</label>
            <textarea name="invoice[description]" rows="2"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${i.description || ''}</textarea>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500">${translate("Code")}</label>
            <input type="text" name="invoice[code]" value="${i.code || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500">${translate("Total Price (cents)")}</label>
            <input type="number" name="invoice[price_cents]" value="${i.price_cents || ''}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500">${translate("Type")}</label>
            <select name="invoice[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(businessTypes, i.business_type)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500">${translate("Status")}</label>
            <select name="invoice[workflow_status]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(workflowStatuses, i.workflow_status)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500">${translate("Currency")}</label>
            <select name="invoice[currency]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(currencyCodes, i.currency)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500">${translate("Due Date")}</label>
            <input type="date" name="invoice[due_date]" value="${i.due_date ? i.due_date.split('T')[0] : ''}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500">${translate("Category")}</label>
            <input type="text" value="${currentCategories().find(c => c.id === i.category_id)?.name || ''}" disabled
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-400">
            <input type="hidden" name="invoice[category_id]" value="${i.category_id}">
          </div>
        </div>

        ${dynamicFields}

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_invoice_path(companyId, i.id)}"
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
          action: Helpers.company_invoice_path(companyId, i.id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
