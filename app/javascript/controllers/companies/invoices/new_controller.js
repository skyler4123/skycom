import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Invoices_NewController extends Companies_LayoutController {
  /** @type {string | null} */
  categoryId = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  connect() {
    super.connect()

    this.categoryId = new URLSearchParams(window.location.search).get('category_id')
      || this.defaultFilterCategory()?.id || null

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.property_metadata || []

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  invoicesCategories() {
    return currentCategories().filter(c => c.resource_name === "invoices")
  }

  defaultFilterCategory() {
    return this.invoicesCategories()[0]
  }

  onCategoryChange(event) {
    this.categoryId = event.target.value
    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.property_metadata || []
    const dynamicDiv = this.element.querySelector('#dynamic-fields')
    if (dynamicDiv) {
      dynamicDiv.innerHTML = this.dynamicFieldsHTML()
    }
  }

  renderField({ key, label, type }) {
    switch (type) {
      case 'boolean':
        return `
          <div class="flex items-center gap-3 py-2">
            <input type="hidden" name="invoice[${key}]" value="false">
            <input type="checkbox" name="invoice[${key}]" value="true"
              class="h-5 w-5 rounded border-slate-300 text-blue-600 cursor-pointer">
            <span class="text-sm text-slate-900 dark:text-white">${label}</span>
          </div>
        `
      case 'integer':
        return `<input type="number" step="1" name="invoice[${key}]" placeholder="${label}"
          class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">`
      case 'decimal':
        return `<input type="number" step="0.01" name="invoice[${key}]" placeholder="${label}"
          class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">`
      case 'datetime':
        return `<input type="datetime-local" name="invoice[${key}]"
          class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">`
      case 'text':
        return `<textarea name="invoice[${key}]" rows="3" placeholder="${label}"
          class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white"></textarea>`
      default:
        return `<input type="text" name="invoice[${key}]" placeholder="${label}"
          class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">`
    }
  }

  dynamicFieldsHTML() {
    if (this.propertyMetadata.length === 0) return ''
    return `
      <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-2 gap-4">
          ${this.propertyMetadata.map(f => this.renderField(f)).join('')}
        </div>
      </div>
    `
  }

  contentHTML() {
    const categoryFilter = this.invoicesCategories()

    const typeOptions = (Enums()?.invoice?.business_types || []).map(t =>
      `<option value="${t.value}">${t.name === 'subscription' ? translate("Subscription") : (t.name ? t.name.charAt(0).toUpperCase() + t.name.slice(1) : t.value)}</option>`
    ).join('')

    const currencyOptions = (Enums()?.invoice?.currency_codes || []).map(c =>
      `<option value="${c.value}">${c.name?.toUpperCase() || c.value?.toUpperCase()}</option>`
    ).join('')

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Invoice")}</h2>

        <div class="space-y-1">
          <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Category")}</label>
          <select name="invoice[category_id]" data-action="change->${this.identifier}#onCategoryChange"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
            ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), this.categoryId)}
          </select>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Name")}</label>
            <input type="text" name="invoice[name]" required placeholder="${translate("e.g. Invoice for Order #12345")}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Code")}</label>
            <input type="text" name="invoice[code]" required placeholder="${translate("e.g. INV-001")}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Total Price")}</label>
            <input type="number" name="invoice[total_price]" step="0.01" placeholder="${translate("e.g. 100.00")}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Type")}</label>
            <select name="invoice[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${typeOptions}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Currency")}</label>
            <select name="invoice[currency_code]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${currencyOptions}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Due Date")}</label>
            <input type="date" name="invoice[due_date]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Description")}</label>
            <textarea name="invoice[description]" rows="3"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm"></textarea>
          </div>
        </div>

        <div id="dynamic-fields">${this.dynamicFieldsHTML()}</div>

        <div class="flex justify-end pt-6 border-t border-slate-200 dark:border-slate-700">
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Invoice")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.create_company_invoices_path(currentCompany().id),
          method: "POST",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false"`,
          html: fields
        })}
      </div>
    `
  }
}
