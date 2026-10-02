import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Events_NewController extends Companies_LayoutController {
  // New Event page — core fields + time window + link sections (who/what/where/needs).
  // Reference lists (customers/employees/services/facilities/stocks) come from
  // the new JSON of the current URL; dynamic property fields follow the category.
  // Depends on BE: Companies::EventsController#new (reference data), #create (HTML redirect)
  // Endpoints: GET <pathname>.json, POST /companies/:id/events (data-turbo=false)
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
  stockRows = []

  async connect() {
    super.connect()

    this.categoryId = new URLSearchParams(window.location.search).get('category_id') || this.defaultFilterCategory()?.id || null

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.metadata?.properties || []

    try {
      const response = await fetchJson(`${pathname()}.json`)
      this.customers = response.customers || []
      this.employees = response.employees || []
      this.services = response.services || []
      this.facilities = response.facilities || []
      this.stocks = response.stocks || []
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load event.") }${__errDetail ? ": " + __errDetail : ""}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  eventsCategories() {
    return currentCategories().filter(c => c.resource_name === "events")
  }

  defaultFilterCategory() {
    return this.eventsCategories()[0]
  }

  branches() {
    return (typeof currentBranches === "function" ? currentBranches() : []) || []
  }

  renderField({ key, label, type }) {
    const baseClass = 'w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500'

    switch (type) {
      case 'boolean':
        return `
          <div class="flex items-center gap-3 py-2">
            <input type="hidden" name="event[${key}]" value="false">
            <input type="checkbox" name="event[${key}]" value="true"
              class="h-5 w-5 rounded border-slate-300 text-blue-600 cursor-pointer">
            <span class="text-sm text-slate-900 dark:text-white">${label}</span>
          </div>
        `
      case 'integer':
      case 'decimal':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${label}</label>
            <input type="number" name="event[${key}]" step="${type === 'decimal' ? '0.01' : '1'}" placeholder="${label}"
              class="${baseClass}">
          </div>
        `
      case 'datetime':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${label}</label>
            <input type="datetime-local" name="event[${key}]"
              class="${baseClass}">
          </div>
        `
      default:
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${label}</label>
            <input type="text" name="event[${key}]" placeholder="${label}"
              class="${baseClass}">
          </div>
        `
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

  onCategoryChange(event) {
    this.categoryId = event.target.value

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.metadata?.properties || []

    const dynamicDiv = this.element.querySelector('#dynamic-fields')
    if (dynamicDiv) {
      dynamicDiv.innerHTML = this.dynamicFieldsHTML()
    }
  }

  linkCheckboxesHTML(name, items) {
    if (items.length === 0) return `<p class="text-sm text-slate-400">${translate("N/A")}</p>`
    return `
      <div class="grid grid-cols-2 gap-2 max-h-40 overflow-y-auto border border-slate-200 dark:border-slate-700 rounded-lg p-3">
        ${items.map(item => `
          <label class="flex items-center gap-2 text-sm text-slate-700 dark:text-slate-300 cursor-pointer">
            <input type="checkbox" name="event[${name}][]" value="${item.id}" class="h-4 w-4 rounded border-slate-300 text-blue-600 cursor-pointer">
            <span class="truncate">${item.name || item.id}</span>
          </label>
        `).join('')}
      </div>
    `
  }

  stockRowsHTML() {
    const inputClass = 'w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none'
    return `
      <div class="space-y-2" id="stock-rows">
        ${this.stockRows.map((row, index) => `
          <div class="grid grid-cols-[1fr_100px_40px] gap-2 items-center">
            <select name="event[event_stock_lines][${index}][stock_id]"
              class="${inputClass}">
              <option value="">${translate("Select stock")}</option>
              ${this.stocks.map(s => `<option value="${s.id}" ${String(s.id) === String(row.stock_id) ? 'selected' : ''}>${s.name}</option>`).join('')}
            </select>
            <input type="number" min="1" step="1" name="event[event_stock_lines][${index}][quantity]" value="${row.quantity}"
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

  addStockRow() {
    this.stockRows.push({ stock_id: "", quantity: 1 })
    this.rerenderStockRows()
  }

  removeStockRow(event) {
    this.stockRows.splice(event.params.index, 1)
    this.rerenderStockRows()
  }

  rerenderStockRows() {
    const container = this.element.querySelector('#stock-rows-container')
    if (container) container.innerHTML = this.stockRowsHTML()
  }

  contentHTML() {
    const categoryFilter = this.eventsCategories()
    // Static fallback per docs/FLAKY_TESTS.md §6 — dropdown always has options
    // even when the client cache hasn't loaded its enums yet.
    const typeOptions = (Enums()?.event?.business_types || [
      { name: "Appointment", value: "appointment" },
      { name: "Procedure", value: "procedure" },
      { name: "Reservation", value: "reservation" },
      { name: "Banquet", value: "banquet" }
    ]).map(t =>
      `<option value="${t.value}">${t.name}</option>`
    ).join('')
    const statusOptions = (Enums()?.event?.workflow_statuses || [
      { name: "Pending", value: "pending" },
      { name: "Confirmed", value: "confirmed" },
      { name: "In Progress", value: "in_progress" }
    ]).map(t =>
      `<option value="${t.value}">${t.name}</option>`
    ).join('')

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Event")}</h2>

        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Category")}</label>
            <select
              name="event[category_id]"
              data-action="change->${this.identifier}#onCategoryChange"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none"
            >
              ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), this.categoryId)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Branch")}</label>
            <select
              name="event[branch_id]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none"
            >
              <option value="">—</option>
              ${this.branches().map(b => `<option value="${b.id}">${b.name}</option>`).join('')}
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Event Name")}</label>
            <input type="text" name="event[name]" required placeholder="${translate("e.g. Root Canal Treatment")}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Type")}</label>
            <select name="event[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${typeOptions}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Status")}</label>
            <select name="event[workflow_status]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${statusOptions}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Start At")}</label>
            <input type="datetime-local" name="event[start_at]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("End At")}</label>
            <input type="datetime-local" name="event[end_at]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="event[description]" rows="3"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500"></textarea>
          </div>
        </div>

        <div id="dynamic-fields">
          ${this.dynamicFieldsHTML()}
        </div>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Customers")}</h3>
          ${this.linkCheckboxesHTML("customer_ids", this.customers)}
        </div>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Employees")}</h3>
          ${this.linkCheckboxesHTML("employee_ids", this.employees)}
        </div>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Services")}</h3>
          ${this.linkCheckboxesHTML("service_ids", this.services)}
        </div>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Facilities")}</h3>
          ${this.linkCheckboxesHTML("facility_ids", this.facilities)}
        </div>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Stocks")}</h3>
          <div id="stock-rows-container">
            ${this.stockRowsHTML()}
          </div>
        </div>

        <div class="flex justify-end pt-6 border-t border-slate-200 dark:border-slate-700">
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Save Event")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        <div class="">
          ${form({
            action: Helpers.create_company_events_path(currentCompany().id),
            method: "POST",
            attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false"`,
            html: fields
          })}
        </div>
      </div>
    `
  }
}
