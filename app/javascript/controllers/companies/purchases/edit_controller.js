import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Purchases_EditController extends Companies_LayoutController {
  // Purchase edit form — prefilled fields + line-item rows (existing
  // PurchasePurchaseItemAppointments carry id + _destroy for removal).
  // Depends on BE: Companies::PurchasesController#edit (record + reference lists) + #update
  // Endpoints: GET edit_company_purchase_path.json, PATCH company_purchase_path
  // Docs: docs/PURCHASE_WORKFLOW.md
  static targets = ["itemRows"]

  /** @type {string | null} */
  categoryId = null

  /** @type {any | null} */
  purchase = null

  /** @type {Array<{id: string, name: string, unit: string, estimated_unit_price: number}>} */
  purchaseItems = []

  /** @type {Array<{id: string, name: string}>} */
  suppliers = []

  /** @type {Array<{id?: string, purchase_item_id: string, quantity: number, unit_price: string, _destroy: boolean}>} */
  itemRows = []

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const recordId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.edit_company_purchase_path(companyId, recordId)}.json`)
      this.purchase = response.purchase
      this.purchaseItems = response.purchase_items || []
      this.suppliers = response.suppliers || []

      if (this.purchase?.category_id) {
        this.categoryId = this.purchase.category_id
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
        this.propertyMetadata = propertyMapping?.metadata?.properties || []
      }

      this.itemRows = (this.purchase?.purchase_purchase_item_appointments || []).map(a => ({
        id: a.id,
        purchase_item_id: a.purchase_item_id,
        quantity: a.quantity ?? 1,
        unit_price: a.unit_price ?? "",
        _destroy: false
      }))

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load purchase.")}</div>`
          return true
        }
        return false
      })
    }
  }

  renderField({ key, name, type }) {
    const baseClass = 'w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white'
    const value = this.purchase?.[key]

    switch (type) {
      case 'boolean':
        return `
          <div class="flex items-center gap-3 py-2">
            <input type="hidden" name="purchase[${key}]" value="false">
            <input type="checkbox" name="purchase[${key}]" value="true" ${value ? 'checked' : ''}
              class="rounded border-slate-300 text-blue-600 cursor-pointer">
            <span class="text-sm text-slate-900 dark:text-white">${name}</span>
          </div>`
      case 'integer':
      case 'decimal':
        return `
          <div>
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${name}</label>
            <input type="number" name="purchase[${key}]" step="${type === 'decimal' ? '0.01' : '1'}" value="${value ?? ''}" class="${baseClass}">
          </div>`
      case 'datetime':
        return `
          <div>
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${name}</label>
            <input type="datetime-local" name="purchase[${key}]" value="${value ? new Date(value).toISOString().slice(0, 16) : ''}" class="${baseClass}">
          </div>`
      default:
        return `
          <div>
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${name}</label>
            <input type="text" name="purchase[${key}]" value="${value ?? ''}" class="${baseClass}">
          </div>`
    }
  }

  dynamicFieldsHTML() {
    if (this.propertyMetadata.length === 0) return ''

    return `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          ${this.propertyMetadata.map(f => this.renderField(f)).join('')}
        </div>
      </div>`
  }

  addItemRow() {
    this.itemRows.push({ purchase_item_id: "", quantity: 1, unit_price: "", _destroy: false })
    this.rerenderItemRows()
  }

  removeItemRow(event) {
    const index = Number(event.params.index)
    const row = this.itemRows[index]
    if (!row) return

    if (row.id) {
      row._destroy = true
    } else {
      this.itemRows.splice(index, 1)
    }
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

  supplierOptions(selectedId) {
    return [ { id: "", name: `— ${translate("None")} —` }, ...this.suppliers ]
      .map(s => `<option value="${s.id}" ${s.id === (selectedId || "") ? "selected" : ""}>${s.name}</option>`).join('')
  }

  itemRowHTML(row, index) {
    const inputClass = 'w-full px-2 py-1.5 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm'
    return `
      <tr ${row._destroy ? 'class="hidden"' : ''}>
        <input type="hidden" name="purchase[purchase_purchase_item_appointments_attributes][${index}][id]" value="${row.id || ''}">
        <input type="hidden" name="purchase[purchase_purchase_item_appointments_attributes][${index}][_destroy]" value="${row._destroy ? '1' : '0'}">
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
          <tbody data-${this.identifier}-target="itemRows">
            ${this.itemRows.map((row, i) => this.itemRowHTML(row, i)).join('')}
          </tbody>
        </table>
      </div>`
  }

  contentHTML() {
    const p = this.purchase
    if (!p) return `<div class="p-8 text-center">${translate("Purchase not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const businessTypes = Enums()?.purchase?.business_types || [
      { name: "Office Supply", value: "office_supply" },
      { name: "Equipment", value: "equipment" },
      { name: "Service", value: "service" }
    ]
    const currencies = Enums()?.purchase?.currencies || [ { name: "USD", value: "usd" } ]

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Purchase")}</h2>
        <p class="text-sm text-slate-500">${p.name}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Name")}</label>
            <input type="text" name="purchase[name]" value="${p.name || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Type")}</label>
            <select name="purchase[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(businessTypes, p.business_type || '')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Currency")}</label>
            <select name="purchase[currency]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(currencies, p.currency || '')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Needed By")}</label>
            <input type="datetime-local" name="purchase[needed_by]" value="${p.needed_by ? new Date(p.needed_by).toISOString().slice(0, 16) : ''}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Supplier")}</label>
            <select name="purchase[supplier_id]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${this.supplierOptions(p.supplier_id)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Category")}</label>
            <input type="text" value="${currentCategories().find(c => c.id === p.category_id)?.name || ''}" disabled
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-slate-700 text-sm text-slate-400">
            <input type="hidden" name="purchase[category_id]" value="${p.category_id}">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Description")}</label>
            <textarea name="purchase[description]" rows="2"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${p.description || ''}</textarea>
          </div>
        </div>

        ${this.itemsSectionHTML()}
        ${this.dynamicFieldsHTML()}

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_purchase_path(companyId, p.id)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Changes")}
          </button>
        </div>
      </div>`

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_purchase_path(companyId, p.id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>`
  }
}
