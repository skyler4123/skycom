import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_StockTransfers_EditController extends Companies_LayoutController {
  // Stock transfer edit — prefilled header + line rows, draft/pending only
  // (BE rejects initiated/received/cancelled with 422; show page gates the link too).
  // Depends on BE: Companies::StockTransfersController#edit (record + reference data) + #update
  // Endpoints: GET edit_company_stock_transfer_path.json, PATCH company_stock_transfer_path
  // Docs: docs/STOCK.md §4.3
  static targets = ["lineRows"]

  /** @type {string | null} */
  categoryId = null

  /** @type {any | null} */
  transfer = null

  /** @type {Array<{id: string, name: string}>} */
  warehouses = []

  /** @type {Array<{id: string, product_id: string, product_name: string, warehouse_id: string, warehouse_name: string, quantity: number, pending: number, available: number}>} */
  stocks = []

  /** @type {string | null} */
  warehouseId = null

  /** @type {string | null} */
  destinationWarehouseId = null

  /** @type {Array<{key: string, name: string, type: string}>} */
  propertyMetadata = []

  /** @type {Array<{stock_id: string, quantity: number}>} */
  lineRows = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const recordId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.edit_company_stock_transfer_path(companyId, recordId)}.json`)
      this.transfer = response.stock_transfer
      this.warehouses = response.warehouses || []
      this.stocks = response.stocks || []

      if (this.transfer) {
        this.warehouseId = this.transfer.warehouse_id || null
        this.destinationWarehouseId = this.transfer.destination_warehouse_id || null
      }

      if (this.transfer?.category_id) {
        this.categoryId = this.transfer.category_id
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
        this.propertyMetadata = propertyMapping?.metadata?.properties || []
      }

      this.lineRows = (this.transfer?.lines || []).map(l => ({
        stock_id: l.stock_id,
        quantity: l.quantity ?? 1
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load stock transfer.")}</div>`
          return true
        }
        return false
      })
    }
  }

  stockTransfersCategories() {
    return currentCategories().filter(c => c.resource_name === "stock_transfers")
  }

  defaultFilterCategory() {
    return this.stockTransfersCategories()[0]
  }

  renderField({ key, name, type }) {
    const baseClass = 'w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500'

    switch (type) {
      case 'boolean':
        return `
          <div class="flex items-center gap-3 py-2">
            <input type="hidden" name="stock_transfer[${key}]" value="false">
            <input type="checkbox" name="stock_transfer[${key}]" value="true"
              class="h-5 w-5 rounded border-slate-300 text-blue-600 cursor-pointer">
            <span class="text-sm text-slate-900 dark:text-white">${name}</span>
          </div>`
      case 'integer':
      case 'decimal':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${name}</label>
            <input type="number" name="stock_transfer[${key}]" step="${type === 'decimal' ? '0.01' : '1'}" placeholder="${name}" class="${baseClass}">
          </div>`
      case 'datetime':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${name}</label>
            <input type="datetime-local" name="stock_transfer[${key}]" class="${baseClass}">
          </div>`
      default:
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${name}</label>
            <input type="text" name="stock_transfer[${key}]" placeholder="${name}" class="${baseClass}">
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

  onWarehouseChange(event) {
    this.warehouseId = event.target.value || null
    this.rerenderLineRows()
  }

  onDestinationChange(event) {
    this.destinationWarehouseId = event.target.value || null
  }

  warehouseStocks() {
    if (!this.warehouseId) return []
    return this.stocks.filter(s => s.warehouse_id === this.warehouseId)
  }

  addLineRow() {
    this.lineRows.push({ stock_id: "", quantity: 1 })
    this.rerenderLineRows()
  }

  removeLineRow(event) {
    this.lineRows.splice(Number(event.params.index), 1)
    this.rerenderLineRows()
  }

  onLineStockChange(event) {
    const index = Number(event.params.index)
    if (this.lineRows[index]) this.lineRows[index].stock_id = event.target.value
  }

  onLineQtyChange(event) {
    const index = Number(event.params.index)
    if (this.lineRows[index]) this.lineRows[index].quantity = Number(event.target.value)
  }

  stockOptions(selectedId) {
    return this.warehouseStocks().map(s =>
      `<option value="${s.id}" ${s.id === selectedId ? "selected" : ""}>${s.product_name} (${translate("Available")}: ${s.available})</option>`
    ).join('')
  }

  lineRowHTML(row, index) {
    const inputClass = 'w-full px-2 py-1.5 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm'
    return `
      <tr>
        <td class="py-2 px-2">
          <select data-action="change->${this.identifier}#onLineStockChange" data-${this.identifier}-index-param="${index}"
            class="${inputClass} stock-line-select cursor-pointer">
            <option value="">—</option>
            ${this.stockOptions(row.stock_id)}
          </select>
        </td>
        <td class="py-2 px-2"><input type="number" min="1" step="1" value="${row.quantity}" data-action="change->${this.identifier}#onLineQtyChange" data-${this.identifier}-index-param="${index}" class="${inputClass} stock-line-qty"></td>
        <td class="py-2 px-2 text-right">
          <button type="button" data-action="click->${this.identifier}#removeLineRow" data-${this.identifier}-index-param="${index}"
            class="p-1.5 text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-900/30 rounded-lg cursor-pointer">
            <span class="material-symbols-outlined text-[18px]">delete</span>
          </button>
        </td>
      </tr>`
  }

  rerenderLineRows() {
    if (this.hasLineRowsTarget) this.lineRowsTarget.innerHTML = this.lineRows.map((row, i) => this.lineRowHTML(row, i)).join('')
  }

  linesSectionHTML() {
    return `
      <div class="border-t border-slate-200 dark:border-slate-700 pt-6 mt-6">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">${translate("Stock lines")}</h3>
          <button type="button" data-action="click->${this.identifier}#addLineRow"
            class="inline-flex items-center gap-2 px-3 py-1.5 bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-200 rounded-lg text-sm font-medium cursor-pointer">
            <span class="material-symbols-outlined text-[18px]">add</span>${translate("Add line")}
          </button>
        </div>
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="text-xs text-slate-500 border-b border-slate-200 dark:border-slate-700">
              <th class="py-2 px-2 font-medium">${translate("Stock")}</th>
              <th class="py-2 px-2 font-medium">${translate("Quantity")}</th>
              <th class="py-2 px-2"></th>
            </tr>
          </thead>
          <tbody data-${this.identifier}-target="lineRows">
            ${this.lineRows.map((row, i) => this.lineRowHTML(row, i)).join('')}
          </tbody>
        </table>
      </div>`
  }

  collectFormFields() {
    const root = this.element.querySelector("#transfer-fields")
    const data = {}
    if (!root) return data
    root.querySelectorAll("input[name], select[name], textarea[name]").forEach(el => {
      const match = el.name.match(/^stock_transfer\[(.+)\]$/)
      if (!match || el.type === "button") return
      if (el.type === "checkbox") { data[match[1]] = el.checked; return }
      data[match[1]] = el.value
    })
    return data
  }

  async handleUpdate(event) {
    event.preventDefault()

    if (this.lineRows.length === 0 || this.lineRows.some(r => !r.stock_id || Number(r.quantity) <= 0)) {
      toast({ type: "error", message: translate("Add at least one stock line with a positive quantity") })
      return
    }

    if (!this.warehouseId || !this.destinationWarehouseId || this.warehouseId === this.destinationWarehouseId) {
      toast({ type: "error", message: translate("Source and destination warehouses must differ") })
      return
    }

    const companyId = currentCompany().id
    try {
      const response = await fetchJson(Helpers.company_stock_transfer_path(companyId, this.transfer.id), {
        method: "PATCH",
        body: {
          stock_transfer: { ...this.collectFormFields(), warehouse_id: this.warehouseId, destination_warehouse_id: this.destinationWarehouseId, category_id: this.categoryId },
          stock_items: this.lineRows.map(r => ({ stock_id: r.stock_id, quantity: Number(r.quantity) }))
        }
      })
      toast({ type: "success", message: response.message || translate("Stock transfer updated") })
      window.location.href = Helpers.company_stock_transfer_path(companyId, response.stock_transfer.id)
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update stock transfer") })
    }
  }

  contentHTML() {
    const categoryFilter = this.stockTransfersCategories()

    const fields = `
      <div class="space-y-6" id="transfer-fields">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Stock Transfer")}</h2>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Category")}</label>
            <select name="stock_transfer[category_id]" data-action="change->${this.identifier}#onCategoryChange"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), this.categoryId)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Warehouse")}</label>
            <select name="stock_transfer[warehouse_id]" data-action="change->${this.identifier}#onWarehouseChange"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">
              <option value="">—</option>
              ${this.warehouses.map(w => `<option value="${w.id}" ${w.id === this.warehouseId ? "selected" : ""}>${w.name}</option>`).join('')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Destination warehouse")}</label>
            <select name="stock_transfer[destination_warehouse_id]" data-action="change->${this.identifier}#onDestinationChange"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">
              <option value="">—</option>
              ${this.warehouses.map(w => `<option value="${w.id}" ${w.id === this.destinationWarehouseId ? "selected" : ""}>${w.name}</option>`).join('')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Name")}</label>
            <input type="text" name="stock_transfer[name]" value="${this.transfer?.name || ''}" placeholder="${translate("e.g. Supplier delivery")}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="stock_transfer[description]" rows="3"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500">${this.transfer?.description || ''}</textarea>
          </div>
        </div>

        ${this.linesSectionHTML()}

        <div id="dynamic-fields">
          ${this.dynamicFieldsHTML()}
        </div>

        <div class="flex justify-end pt-6 border-t border-slate-200 dark:border-slate-700">
          <button type="button" data-action="click->${this.identifier}#handleUpdate"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Save Changes")}
          </button>
        </div>
      </div>`

    return `<div class="p-4 overflow-y-auto"><div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">${fields}</div></div>`
  }
}
