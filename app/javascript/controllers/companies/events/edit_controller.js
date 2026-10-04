import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Events_EditController extends Companies_LayoutController {
  // Edit Event page — prefilled core fields + link sections with checked states.
  // Depends on BE: Companies::EventsController#edit (event + reference data), #update (HTML redirect)
  // Endpoints: GET <event>.json, PATCH /companies/:id/events/:id (data-turbo=false, novalidate)
  // Docs: docs/EVENTS.md
  /** @type {Event | null} */
  event = null

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

    const pathParts = window.location.pathname.split("/")
    const recordId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_event_path(companyId, recordId)}.json`)
      this.event = response.event
      this.customers = response.customers || []
      this.employees = response.employees || []
      this.services = response.services || []
      this.facilities = response.facilities || []
      this.stocks = response.stocks || []
      this.stockRows = (this.event?.stocks || []).map(s => ({ stock_id: s.stock_id, quantity: s.quantity }))

      if (this.event?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.event.category_id)
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load event.")}</div>`
          return true
        }
        return false
      })
    }
  }

  linkCheckboxesHTML(name, items, selectedIds) {
    const selected = new Set((selectedIds || []).map(String))
    if (items.length === 0) return `<p class="text-sm text-slate-400">${translate("N/A")}</p>`
    return `
      <div class="grid grid-cols-2 gap-2 max-h-40 overflow-y-auto border border-slate-200 dark:border-slate-700 rounded-lg p-3">
        ${items.map(item => `
          <label class="flex items-center gap-2 text-sm text-slate-700 dark:text-slate-300 cursor-pointer">
            <input type="checkbox" name="event[${name}][]" value="${item.id}" ${selected.has(String(item.id)) ? 'checked' : ''} class="h-4 w-4 rounded border-slate-300 text-blue-600 cursor-pointer">
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

  toLocalInput(value) {
    if (!value) return ''
    const d = new Date(value)
    const pad = (n) => String(n).padStart(2, '0')
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
  }

  contentHTML() {
    const e = this.event
    if (!e) return `<div class="p-8 text-center">${translate("Event not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const typeOptions = (Enums()?.event?.business_types || [
      { name: "Appointment", value: "appointment" },
      { name: "Procedure", value: "procedure" },
      { name: "Reservation", value: "reservation" },
      { name: "Banquet", value: "banquet" }
    ]).map(t =>
      `<option value="${t.value}" ${e.business_type === t.value ? 'selected' : ''}>${t.name}</option>`
    ).join('')
    const statusOptions = (Enums()?.event?.workflow_statuses || [
      { name: "Pending", value: "pending" },
      { name: "Confirmed", value: "confirmed" },
      { name: "In Progress", value: "in_progress" },
      { name: "Completed", value: "completed" },
      { name: "Cancelled", value: "cancelled" }
    ]).map(t =>
      `<option value="${t.value}" ${e.workflow_status === t.value ? 'selected' : ''}>${t.name}</option>`
    ).join('')

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-2 gap-4">
          ${this.propertyMetadata.map(field => {
            const value = e[field.key] ?? ''
            const baseClass = 'w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none'
            if (field.type === 'boolean') {
              return `
                <div class="flex items-center gap-3 py-2">
                  <input type="hidden" name="event[${field.key}]" value="false">
                  <input type="checkbox" name="event[${field.key}]" value="true" ${value ? 'checked' : ''}
                    class="h-5 w-5 rounded border-slate-300 text-blue-600 cursor-pointer">
                  <span class="text-sm text-slate-900 dark:text-white">${field.name}</span>
                </div>
              `
            }
            const inputType = field.type === 'integer' || field.type === 'decimal' ? 'number' : field.type === 'datetime' ? 'datetime-local' : 'text'
            const step = field.type === 'decimal' ? ' step="0.01"' : field.type === 'integer' ? ' step="1"' : ''
            const displayValue = field.type === 'datetime' && value ? this.toLocalInput(value) : value
            return `
              <div class="space-y-1">
                <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${field.name}</label>
                <input type="${inputType}"${step} name="event[${field.key}]" value="${displayValue}"
                  class="${baseClass}">
              </div>
            `
          }).join('')}
        </div>
      </div>
    ` : ''

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Event")}</h2>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Event Name")}</label>
            <input type="text" name="event[name]" value="${e.name || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="event[description]" rows="3"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">${e.description || ''}</textarea>
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
            <input type="datetime-local" name="event[start_at]" value="${this.toLocalInput(e.start_at)}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("End At")}</label>
            <input type="datetime-local" name="event[end_at]" value="${this.toLocalInput(e.end_at)}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
          </div>
        </div>

        ${dynamicFields}

        <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Customers")}</h3>
          ${this.linkCheckboxesHTML("customer_ids", this.customers, (e.customers || []).map(c => c.customer_id))}
        </div>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Employees")}</h3>
          ${this.linkCheckboxesHTML("employee_ids", this.employees, (e.employees || []).map(x => x.employee_id))}
        </div>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Services")}</h3>
          ${this.linkCheckboxesHTML("service_ids", this.services, (e.services || []).map(s => s.service_id))}
        </div>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Facilities")}</h3>
          ${this.linkCheckboxesHTML("facility_ids", this.facilities, (e.facilities || []).map(f => f.facility_id))}
        </div>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Stocks")}</h3>
          <div id="stock-rows-container">
            ${this.stockRowsHTML()}
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-6 border-t border-slate-200 dark:border-slate-700">
          <a href="${Helpers.company_event_path(companyId, e.id)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
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
            action: Helpers.company_event_path(companyId, e.id),
            method: "PATCH",
            attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
            html: fields
          })}
        </div>
      </div>
    `
  }
}
