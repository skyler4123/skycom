import { Controller } from "@hotwired/stimulus"

export default class Companies_Events_NewModalController extends Controller {
  // Board click-to-create modal — full-detail Event form prefilled with the
  // clicked slot. Submits JSON; success refreshes the board without reload.
  // Depends on BE: Companies::EventsController#new (reference data), #create (JSON)
  // Endpoints: GET /companies/:id/events/new.json, POST /companies/:id/events.json
  // Docs: docs/EVENTS.md
  /** @type {string | null} */
  categoryId = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  /** @type {any[]} */ customers = []
  /** @type {any[]} */ employees = []
  /** @type {any[]} */ services = []
  /** @type {any[]} */ facilities = []
  /** @type {any[]} */ stocks = []

  /** @type {Array<{stock_id: string, quantity: number}>} */
  stockRows = [{ stock_id: "", quantity: 1 }]

  async connect() {
    const defaults = window.pendingEventDefaults || {}
    this.defaultStartAt = defaults.start_at || ''
    this.defaultEndAt = defaults.end_at || ''
    window.pendingEventDefaults = null

    this.categoryId = this.defaultFilterCategory()?.id || null

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.metadata?.properties || []

    try {
      const companyId = window.location.pathname.split("/")[2]
      const response = await fetchJson(`${Helpers.new_company_event_path(companyId)}.json`)
      this.customers = response.customers || []
      this.employees = response.employees || []
      this.services = response.services || []
      this.facilities = response.facilities || []
      this.stocks = response.stocks || []
    } catch (error) {
      // Reference lists stay empty — core fields still render.
    }

    this.element.innerHTML = this.modalHTML()
  }

  defaultFilterCategory() {
    return currentCategories().filter(c => c.resource_name === "events")[0]
  }

  branches() {
    return (typeof currentBranches === "function" ? currentBranches() : []) || []
  }

  onCategoryChange(event) {
    this.categoryId = event.target.value
    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.metadata?.properties || []
    const dynamicDiv = this.element.querySelector('#modal-dynamic-fields')
    if (dynamicDiv) dynamicDiv.innerHTML = this.dynamicFieldsHTML()
  }

  addStockRow() {
    this.scrapeStockRows()
    this.stockRows.push({ stock_id: "", quantity: 1 })
    this.rerenderStockRows()
  }

  removeStockRow(event) {
    this.scrapeStockRows()
    this.stockRows.splice(parseInt(event.params.index, 10), 1)
    if (this.stockRows.length === 0) this.stockRows.push({ stock_id: "", quantity: 1 })
    this.rerenderStockRows()
  }

  scrapeStockRows() {
    const selects = this.element.querySelectorAll('[data-stock-row="id"]')
    const qtys = this.element.querySelectorAll('[data-stock-row="qty"]')
    this.stockRows = Array.from(selects).map((sel, i) => ({
      stock_id: sel.value,
      quantity: parseInt(qtys[i]?.value, 10) || 1
    }))
  }

  rerenderStockRows() {
    const container = this.element.querySelector('#modal-stock-rows-container')
    if (container) container.innerHTML = this.stockRowsHTML()
  }

  checkedIds(name) {
    return Array.from(this.element.querySelectorAll(`input[name="modal_${name}"]:checked`)).map(el => el.value)
  }

  async handleSubmit(event) {
    event.preventDefault()

    const formData = new FormData(event.target)
    const payload = {
      name: formData.get("event[name]"),
      description: formData.get("event[description]"),
      category_id: formData.get("event[category_id]"),
      branch_id: formData.get("event[branch_id]") || null,
      business_type: formData.get("event[business_type]"),
      workflow_status: formData.get("event[workflow_status]"),
      start_at: formData.get("event[start_at]"),
      end_at: formData.get("event[end_at]"),
      customer_ids: this.checkedIds("customer_ids"),
      employee_ids: this.checkedIds("employee_ids"),
      service_ids: this.checkedIds("service_ids"),
      facility_ids: this.checkedIds("facility_ids"),
      event_stock_lines: this.stockRows.filter(r => r.stock_id).map(r => ({ stock_id: r.stock_id, quantity: r.quantity }))
    }
    this.propertyMetadata.forEach(f => {
      const raw = formData.get(`event[${f.key}]`)
      payload[f.key] = f.type === 'boolean' ? raw === "true" : raw
    })
    const companyId = window.location.pathname.split("/")[2]
    try {
      const response = await fetchJson(Helpers.create_company_events_path(companyId), {
        method: "POST",
        body: JSON.stringify({ event: payload })
      })
      const created = response.event
      const warnings = response.warnings || []
      closeModal()
      toast({ type: "success", message: response.message || `${created.name || translate("Event")} created` })
      warnings.forEach(w => toast({ type: "warning", message: w }))
      window.dispatchEvent(new CustomEvent("calendar:refresh"))
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load event.") })
    }
  }

  linkCheckboxesHTML(name, items) {
    if (items.length === 0) return `<p class="text-sm text-slate-400">${translate("N/A")}</p>`
    return `
      <div class="grid grid-cols-2 gap-2 max-h-32 overflow-y-auto border border-slate-200 dark:border-slate-700 rounded-lg p-3">
        ${items.map(item => `
          <label class="flex items-center gap-2 text-sm text-slate-700 dark:text-slate-300 cursor-pointer">
            <input type="checkbox" name="modal_${name}" value="${item.id}" class="h-4 w-4 rounded border-slate-300 text-blue-600 cursor-pointer">
            <span class="truncate">${item.name || item.id}</span>
          </label>
        `).join('')}
      </div>
    `
  }

  dynamicFieldsHTML() {
    if (this.propertyMetadata.length === 0) return ''
    const baseClass = 'w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none'
    return `
      <div class="border-t border-slate-200 dark:border-slate-700 pt-4">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-3">${translate("Properties")}</h3>
        <div class="grid grid-cols-2 gap-3">
          ${this.propertyMetadata.map(f => {
            if (f.type === 'boolean') {
              return `
                <div class="flex items-center gap-2 py-1">
                  <input type="hidden" name="event[${f.key}]" value="false">
                  <input type="checkbox" name="event[${f.key}]" value="true" class="h-4 w-4 rounded border-slate-300 text-blue-600 cursor-pointer">
                  <span class="text-sm text-slate-900 dark:text-white">${f.name}</span>
                </div>`
            }
            const inputType = f.type === 'integer' || f.type === 'decimal' ? 'number' : f.type === 'datetime' ? 'datetime-local' : 'text'
            return `
              <div class="space-y-1">
                <label class="text-[10px] font-bold text-slate-400 uppercase">${f.name}</label>
                <input type="${inputType}" name="event[${f.key}]" class="${baseClass}">
              </div>`
          }).join('')}
        </div>
      </div>
    `
  }

  stockRowsHTML() {
    const inputClass = 'w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none'
    return `
      <div class="space-y-2">
        ${this.stockRows.map((row, index) => `
          <div class="grid grid-cols-[1fr_80px_36px] gap-2 items-center">
            <select data-stock-row="id"
              class="${inputClass}">
              <option value="">${translate("Select stock")}</option>
              ${this.stocks.map(s => `<option value="${s.id}" ${String(s.id) === String(row.stock_id) ? 'selected' : ''}>${s.name}</option>`).join('')}
            </select>
            <input type="number" min="1" step="1" data-stock-row="qty" value="${row.quantity}"
              class="${inputClass}">
            <button
              type="button"
              data-action="click->${this.identifier}#removeStockRow"
              data-${this.identifier}-index-param="${index}"
              class="p-2 text-slate-400 hover:text-red-600 rounded-lg cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">delete</span>
            </button>
          </div>
        `).join('')}
      </div>
      <button
        type="button"
        data-action="click->${this.identifier}#addStockRow"
        class="mt-2 inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded-lg cursor-pointer">
        <span class="material-symbols-outlined text-[18px]">add</span>
        ${translate("Add stock")}
      </button>
    `
  }

  modalHTML() {
    const categoryFilter = currentCategories().filter(c => c.resource_name === "events")
    const typeOptions = (Enums()?.event?.business_types || [
      { name: "Appointment", value: "appointment" },
      { name: "Procedure", value: "procedure" },
      { name: "Reservation", value: "reservation" },
      { name: "Banquet", value: "banquet" }
    ]).map(t => `<option value="${t.value}">${t.name}</option>`).join('')
    const statusOptions = (Enums()?.event?.workflow_statuses || [
      { name: "Pending", value: "pending" },
      { name: "Confirmed", value: "confirmed" },
      { name: "In Progress", value: "in_progress" }
    ]).map(t => `<option value="${t.value}">${t.name}</option>`).join('')

    const fields = `
      <div class="space-y-4 max-h-[70vh] overflow-y-auto pr-1">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Event")}</h2>

        <div class="grid grid-cols-2 gap-3">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Category")}</label>
            <select name="event[category_id]" data-action="change->${this.identifier}#onCategoryChange"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), this.categoryId)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Branch")}</label>
            <select name="event[branch_id]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="">—</option>
              ${this.branches().map(b => `<option value="${b.id}">${b.name}</option>`).join('')}
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Event Name")}</label>
            <input type="text" name="event[name]" required placeholder="${translate("e.g. Root Canal Treatment")}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Type")}</label>
            <select name="event[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${typeOptions}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Status")}</label>
            <select name="event[workflow_status]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${statusOptions}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Start At")}</label>
            <input type="datetime-local" name="event[start_at]" value="${this.defaultStartAt || ''}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("End At")}</label>
            <input type="datetime-local" name="event[end_at]" value="${this.defaultEndAt || ''}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Description")}</label>
            <textarea name="event[description]" rows="2"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm"></textarea>
          </div>
        </div>

        <div id="modal-dynamic-fields">${this.dynamicFieldsHTML()}</div>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-4">
          <h3 class="text-sm font-bold text-slate-500 uppercase tracking-wider mb-2">${translate("Customers")}</h3>
          ${this.linkCheckboxesHTML("customer_ids", this.customers)}
        </div>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-4">
          <h3 class="text-sm font-bold text-slate-500 uppercase tracking-wider mb-2">${translate("Employees")}</h3>
          ${this.linkCheckboxesHTML("employee_ids", this.employees)}
        </div>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-4">
          <h3 class="text-sm font-bold text-slate-500 uppercase tracking-wider mb-2">${translate("Services")}</h3>
          ${this.linkCheckboxesHTML("service_ids", this.services)}
        </div>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-4">
          <h3 class="text-sm font-bold text-slate-500 uppercase tracking-wider mb-2">${translate("Facilities")}</h3>
          ${this.linkCheckboxesHTML("facility_ids", this.facilities)}
        </div>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-4">
          <h3 class="text-sm font-bold text-slate-500 uppercase tracking-wider mb-2">${translate("Stocks")}</h3>
          <div id="modal-stock-rows-container">${this.stockRowsHTML()}</div>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->modal#close"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </button>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Event")}
          </button>
        </div>
      </div>
    `

    return form({
      attributes: `
        class="p-8 bg-white dark:bg-slate-900 rounded-2xl w-[560px] max-w-[92vw] shadow-2xl"
        data-action="submit->${this.identifier}#handleSubmit"
      `,
      html: fields
    })
  }
}
