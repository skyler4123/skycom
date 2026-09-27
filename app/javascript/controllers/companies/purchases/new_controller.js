import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Purchases_NewController extends Companies_LayoutController {
  // Purchase creation form — dynamic property fields + line-item rows
  // (PurchasePurchaseItemAppointment nested attributes).
  // Depends on BE: Companies::PurchasesController#new (reference lists) + #create
  // Endpoints: GET new_company_purchase_path.json, POST create_company_purchases_path
  // Docs: docs/PURCHASE_WORKFLOW.md
  static targets = ["itemRows"]

  /** @type {string | null} */
  categoryId = null

  /** @type {Array<{id: string, name: string, unit: string, estimated_unit_price: number}>} */
  purchaseItems = []

  /** @type {Array<{id: string, name: string}>} */
  suppliers = []

  /** @type {Array<{purchase_item_id: string, quantity: number, unit_price: string}>} */
  itemRows = []

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    this.categoryId = new URLSearchParams(window.location.search).get('category_id') || this.defaultFilterCategory()?.id || null

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.metadata?.properties || []

    try {
      const response = await fetchJson(`${Helpers.new_company_purchase_path(currentCompany().id)}.json`)
      this.purchaseItems = response.purchase_items || []
      this.suppliers = response.suppliers || []
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load purchase form data") })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  purchasesCategories() {
    return currentCategories().filter(c => c.resource_name === "purchases")
  }

  defaultFilterCategory() {
    return this.purchasesCategories()[0]
  }

  renderField({ key, name, type }) {
    const baseClass = 'w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500'

    switch (type) {
      case 'boolean':
        return `
          <div class="flex items-center gap-3 py-2">
            <input type="hidden" name="purchase[${key}]" value="false">
            <input type="checkbox" name="purchase[${key}]" value="true"
              class="h-5 w-5 rounded border-slate-300 text-blue-600 cursor-pointer">
            <span class="text-sm text-slate-900 dark:text-white">${name}</span>
          </div>`
      case 'integer':
      case 'decimal':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${name}</label>
            <input type="number" name="purchase[${key}]" step="${type === 'decimal' ? '0.01' : '1'}" placeholder="${name}" class="${baseClass}">
          </div>`
      case 'datetime':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${name}</label>
            <input type="datetime-local" name="purchase[${key}]" class="${baseClass}">
          </div>`
      default:
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${name}</label>
            <input type="text" name="purchase[${key}]" placeholder="${name}" class="${baseClass}">
          </div>`
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
      </div>`
  }

  onCategoryChange(event) {
    this.categoryId = event.target.value

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.metadata?.properties || []

    const dynamicDiv = this.element.querySelector('#dynamic-fields')
    if (dynamicDiv) dynamicDiv.innerHTML = this.dynamicFieldsHTML()
  }

  addItemRow() {
    this.itemRows.push({ purchase_item_id: "", quantity: 1, unit_price: "" })
    this.rerenderItemRows()
  }

  removeItemRow(event) {
    this.itemRows.splice(Number(event.params.index), 1)
    this.rerenderItemRows()
  }

  onItemChange(event) {
    const index = Number(event.params.index)
    const item = this.purchaseItems.find(i => i.id === event.target.value)
    if (item && this.itemRows[index]) {
      this.itemRows[index].purchase_item_id = event.target.value
      this.itemRows[index].unit_price = item.estimated_unit_price ?? ""
      this.rerenderItemRows()
    }
  }

  itemOptions(selectedId) {
    return this.purchaseItems.map(item =>
      `<option value="${item.id}" ${item.id === selectedId ? "selected" : ""}>${item.name}</option>`
    ).join('')
  }

  supplierOptions() {
    return [ { id: "", name: `— ${translate("None")} —` }, ...this.suppliers ]
      .map(s => `<option value="${s.id}">${s.name}</option>`).join('')
  }

  itemRowHTML(row, index) {
    const inputClass = 'w-full px-2 py-1.5 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm'
    return `
      <tr>
        <td class="py-2 px-2">
          <select name="purchase[purchase_purchase_item_appointments_attributes][${index}][purchase_item_id]" required
            data-action="change->${this.identifier}#onItemChange" data-${this.identifier}-index-param="${index}"
            class="${inputClass} cursor-pointer">
            <option value="">—</option>
            ${this.itemOptions(row.purchase_item_id)}
          </select>
        </td>
        <td class="py-2 px-2"><input type="number" min="1" step="1" name="purchase[purchase_purchase_item_appointments_attributes][${index}][quantity]" value="${row.quantity}" class="${inputClass}"></td>
        <td class="py-2 px-2"><input type="number" step="0.01" name="purchase[purchase_purchase_item_appointments_attributes][${index}][unit_price]" value="${row.unit_price}" class="${inputClass}"></td>
        <td class="py-2 px-2 text-right">
          <button type="button" data-action="click->${this.identifier}#removeItemRow" data-${this.identifier}-index-param="${index}"
            class="p-1.5 text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-900/30 rounded-lg cursor-pointer">
            <span class="material-symbols-outlined text-[18px]">delete</span>
          </button>
        </td>
      </tr>`
  }

  rerenderItemRows() {
    if (this.hasItemRowsTarget) this.itemRowsTarget.innerHTML = this.itemRows.map((row, i) => this.itemRowHTML(row, i)).join('')
  }

  itemsSectionHTML() {
    return `
      <div class="border-t border-slate-200 dark:border-slate-700 pt-6 mt-6">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">${translate("Items")}</h3>
          <button type="button" data-action="click->${this.identifier}#addItemRow"
            class="inline-flex items-center gap-2 px-3 py-1.5 bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-200 rounded-lg text-sm font-medium cursor-pointer">
            <span class="material-symbols-outlined text-[18px]">add</span>${translate("Add Item")}
          </button>
        </div>
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="text-xs text-slate-500 border-b border-slate-200 dark:border-slate-700">
              <th class="py-2 px-2 font-medium">${translate("Item")}</th>
              <th class="py-2 px-2 font-medium">${translate("Quantity")}</th>
              <th class="py-2 px-2 font-medium">${translate("Unit Price")}</th>
              <th class="py-2 px-2"></th>
            </tr>
          </thead>
          <tbody data-${this.identifier}-target="itemRows"></tbody>
        </table>
      </div>`
  }

  contentHTML() {
    const categoryFilter = this.purchasesCategories()
    const businessTypes = Enums()?.purchase?.business_types || [
      { name: "Office Supply", value: "office_supply" },
      { name: "Equipment", value: "equipment" },
      { name: "Service", value: "service" }
    ]
    const currencies = Enums()?.purchase?.currencies || [ { name: "USD", value: "usd" } ]

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Purchase")}</h2>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Category")}</label>
            <select name="purchase[category_id]" data-action="change->${this.identifier}#onCategoryChange"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), this.categoryId)}
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Name")}</label>
            <input type="text" name="purchase[name]" required placeholder="${translate("e.g. Office supplies restock")}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Type")}</label>
            <select name="purchase[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">
              ${businessTypes.map(t => `<option value="${t.value}">${t.name}</option>`).join('')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Currency")}</label>
            <select name="purchase[currency]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">
              ${currencies.map(c => `<option value="${c.value}">${c.name}</option>`).join('')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Needed By")}</label>
            <input type="datetime-local" name="purchase[needed_by]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Supplier")}</label>
            <select name="purchase[supplier_id]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">
              ${this.supplierOptions()}
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="purchase[description]" rows="3"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500"></textarea>
          </div>
        </div>

        ${this.itemsSectionHTML()}

        <div id="dynamic-fields">
          ${this.dynamicFieldsHTML()}
        </div>

        <div class="flex justify-end pt-6 border-t border-slate-200 dark:border-slate-700">
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Save Purchase")}
          </button>
        </div>
      </div>`

    return `
      <div class="p-4 overflow-y-auto">
        <div class="">
          ${form({
            action: Helpers.create_company_purchases_path(currentCompany().id),
            method: "POST",
            attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false"`,
            html: fields
          })}
        </div>
      </div>`
  }
}
